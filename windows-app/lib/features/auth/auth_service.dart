import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import 'google_user.dart';

/// Implements Google OAuth 2.0 for **Windows desktop** using the
/// Installed-App / loopback flow:
///   1. Bind a temporary HTTP server on `127.0.0.1:<random-port>`.
///   2. Open the system browser to Google's consent page.
///   3. Capture the `code` from the loopback redirect.
///   4. Exchange the code for access + refresh tokens.
///   5. Persist the refresh token in `flutter_secure_storage`.
///
/// `google_sign_in` does not support Windows; this is the supported path.
class AuthService {
  AuthService(this._config, {Dio? dio}) : _dio = dio ?? Dio();

  final AppConfig _config;
  final Dio _dio;
  final _storage = const FlutterSecureStorage();

  static const _authEndpoint = 'https://accounts.google.com/o/oauth2/v2/auth';
  static const _tokenEndpoint = 'https://oauth2.googleapis.com/token';
  static const _userInfoEndpoint =
      'https://www.googleapis.com/oauth2/v3/userinfo';
  static const _scopes = ['openid', 'email', 'profile'];

  static const _kRefresh = 'google_refresh_token';
  static const _kUser = 'google_user_json';

  bool get isConfigured => _config.hasGoogleOAuth;

  /// Restores a previously signed-in user, refreshing the access token.
  /// Returns null if not signed in or the refresh token is invalid/revoked.
  Future<GoogleUser?> restoreSession() async {
    final refresh = await _storage.read(key: _kRefresh);
    if (refresh == null) return null;
    try {
      await _refreshAccessToken(refresh); // validate it still works
      final cached = await _storage.read(key: _kUser);
      if (cached != null) {
        return GoogleUser.fromJson(
            jsonDecode(cached) as Map<String, Object?>);
      }
      return null;
    } catch (e) {
      debugPrint('restoreSession failed (revoked/expired?): $e');
      await signOut();
      return null;
    }
  }

  /// Runs the full interactive consent flow. Throws on failure/cancel.
  Future<GoogleUser> signIn() async {
    if (!isConfigured) {
      throw const AuthException(
          'Google OAuth is not configured. Add your Client ID and Secret to '
          'config/secrets.json.');
    }

    final server =
        await HttpServer.bind(InternetAddress.loopbackIPv4, 0, shared: true);
    try {
      final port = server.port;
      final redirectUri = 'http://localhost:$port';

      final authUrl = Uri.parse(_authEndpoint).replace(queryParameters: {
        'response_type': 'code',
        'client_id': _config.googleClientId,
        'redirect_uri': redirectUri,
        'scope': _scopes.join(' '),
        'access_type': 'offline',
        'prompt': 'consent',
      });

      if (!await launchUrl(authUrl, mode: LaunchMode.externalApplication)) {
        throw const AuthException('Could not open the browser for sign-in.');
      }

      final code = await _waitForCode(server);
      final tokens = await _exchangeCode(code, redirectUri);

      final refresh = tokens['refresh_token'] as String?;
      final access = tokens['access_token'] as String;
      if (refresh != null) {
        await _storage.write(key: _kRefresh, value: refresh);
      }

      final user = await _fetchUserInfo(access);
      await _storage.write(key: _kUser, value: jsonEncode(user.toJson()));
      return user;
    } finally {
      await server.close(force: true);
    }
  }

  Future<void> signOut() async {
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kUser);
  }

  /// Returns a fresh access token, refreshing via the stored refresh token.
  Future<String?> accessToken() async {
    final refresh = await _storage.read(key: _kRefresh);
    if (refresh == null) return null;
    final tokens = await _refreshAccessToken(refresh);
    return tokens['access_token'] as String?;
  }

  // ---------------------------------------------------------------------------

  Future<String> _waitForCode(HttpServer server) async {
    final completer = Completer<String>();
    late StreamSubscription sub;
    sub = server.listen((HttpRequest request) async {
      final code = request.uri.queryParameters['code'];
      final error = request.uri.queryParameters['error'];
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.html
        ..write(_closeTabHtml(success: code != null));
      await request.response.close();
      await sub.cancel();
      if (code != null) {
        if (!completer.isCompleted) completer.complete(code);
      } else {
        if (!completer.isCompleted) {
          completer.completeError(
              AuthException('Authorization failed: ${error ?? "no code"}'));
        }
      }
    });
    return completer.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () => throw const AuthException('Sign-in timed out.'),
    );
  }

  Future<Map<String, dynamic>> _exchangeCode(
      String code, String redirectUri) async {
    final res = await _dio.post(
      _tokenEndpoint,
      data: {
        'code': code,
        'client_id': _config.googleClientId,
        'client_secret': _config.googleClientSecret,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _refreshAccessToken(String refreshToken) async {
    final res = await _dio.post(
      _tokenEndpoint,
      data: {
        'client_id': _config.googleClientId,
        'client_secret': _config.googleClientSecret,
        'refresh_token': refreshToken,
        'grant_type': 'refresh_token',
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    return res.data as Map<String, dynamic>;
  }

  Future<GoogleUser> _fetchUserInfo(String accessToken) async {
    final res = await _dio.get(
      _userInfoEndpoint,
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    final j = res.data as Map<String, dynamic>;
    return GoogleUser(
      id: j['sub'] as String? ?? '',
      email: j['email'] as String? ?? '',
      name: j['name'] as String?,
      pictureUrl: j['picture'] as String?,
    );
  }

  String _closeTabHtml({required bool success}) => '''
<!doctype html><html><head><meta charset="utf-8"><title>TubeVault</title>
<style>body{font-family:Segoe UI,sans-serif;background:#0E0F13;color:#fff;
display:flex;align-items:center;justify-content:center;height:100vh;margin:0}
.card{background:#16181F;padding:40px 56px;border-radius:16px;text-align:center;
border:1px solid #2A2E3A}h1{color:#7C5CFF;margin:0 0 8px}p{color:#9aa0ab}</style>
</head><body><div class="card"><h1>${success ? 'Signed in' : 'Sign-in failed'}</h1>
<p>You can close this tab and return to TubeVault.</p></div></body></html>''';
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}
