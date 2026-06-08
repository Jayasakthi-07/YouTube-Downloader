import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Loads OAuth credentials and optional API keys from a bundled config file.
///
/// Secrets are NEVER hardcoded. Provide `config/secrets.json` (gitignored)
/// based on `config/secrets.example.json`:
/// ```json
/// {
///   "googleClientId": "....apps.googleusercontent.com",
///   "googleClientSecret": "....",
///   "youtubeDataApiKey": ""          // optional, enriches search only
/// }
/// ```
class AppConfig {
  const AppConfig({
    required this.googleClientId,
    required this.googleClientSecret,
    this.youtubeDataApiKey,
  });

  final String googleClientId;
  final String googleClientSecret;
  final String? youtubeDataApiKey;

  bool get hasGoogleOAuth =>
      googleClientId.isNotEmpty && googleClientSecret.isNotEmpty;

  static AppConfig? _instance;
  static AppConfig get instance =>
      _instance ?? const AppConfig(googleClientId: '', googleClientSecret: '');

  /// Loads from the bundled asset; falls back to an empty config so the app
  /// can still launch and show a helpful "configure credentials" message.
  static Future<AppConfig> load() async {
    try {
      final raw = await rootBundle.loadString('config/secrets.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return _instance = AppConfig(
        googleClientId: json['googleClientId'] as String? ?? '',
        googleClientSecret: json['googleClientSecret'] as String? ?? '',
        youtubeDataApiKey: json['youtubeDataApiKey'] as String?,
      );
    } catch (e) {
      debugPrint('AppConfig: secrets.json not found or invalid ($e). '
          'Sign-in will be unavailable until you add config/secrets.json.');
      return _instance =
          const AppConfig(googleClientId: '', googleClientSecret: '');
    }
  }
}
