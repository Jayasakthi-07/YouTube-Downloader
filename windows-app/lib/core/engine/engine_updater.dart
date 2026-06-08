import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import 'binary_resolver.dart';

/// Downloads the latest `yt-dlp.exe` from the official GitHub release and
/// atomically replaces the bundled copy in the writable bin dir.
class EngineUpdater {
  EngineUpdater(this._bin, {Dio? dio}) : _dio = dio ?? Dio();

  final BinaryResolver _bin;
  final Dio _dio;

  static const _latestUrl =
      'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe';

  /// Downloads to a temp file then renames over the existing binary.
  /// [onProgress] receives 0.0–1.0 (or null while total is unknown).
  Future<void> updateYtDlp({void Function(double?)? onProgress}) async {
    final target = _bin.ytDlpPath;
    final tmp = '$target.download';

    await _dio.download(
      _latestUrl,
      tmp,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          onProgress?.call(received / total);
        } else {
          onProgress?.call(null);
        }
      },
      options: Options(
        followRedirects: true,
        receiveTimeout: const Duration(minutes: 5),
      ),
    );

    final tmpFile = File(tmp);
    if (!await tmpFile.exists() || await tmpFile.length() < 1024) {
      throw Exception('Downloaded engine file looks invalid.');
    }

    // Replace existing. On Windows, rename over an existing file fails, so
    // remove first (the running app does not hold the file open).
    final old = File(target);
    if (await old.exists()) {
      final backup = p.join(p.dirname(target), 'yt-dlp.old.exe');
      try {
        await old.rename(backup);
      } catch (_) {
        await old.delete();
      }
    }
    await tmpFile.rename(target);
  }
}
