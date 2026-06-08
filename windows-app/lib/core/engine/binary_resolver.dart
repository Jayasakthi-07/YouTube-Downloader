import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Locates and provisions the bundled `yt-dlp.exe` and `ffmpeg.exe`.
///
/// Resolution strategy (first hit wins):
///   1. Writable app-support `bin/` dir — where the engine self-updater writes.
///   2. A `bin/` folder next to the running executable (Inno Setup install).
///   3. Bundled Flutter assets (`assets/bin/`) — copied into (1) on first run.
///
/// `yt-dlp.exe` must end up in the writable location so "Update engine" can
/// replace it. `ffmpeg.exe` is resolved the same way for consistency.
class BinaryResolver {
  BinaryResolver._(this.ytDlpPath, this.ffmpegPath);

  final String ytDlpPath;
  final String ffmpegPath;

  static BinaryResolver? _instance;
  static BinaryResolver get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('BinaryResolver not initialized. Call ensureReady().');
    }
    return i;
  }

  static const _ytDlp = 'yt-dlp.exe';
  static const _ffmpeg = 'ffmpeg.exe';

  /// Directory (writable) that holds the binaries we actually invoke.
  static Future<Directory> binDir() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'bin'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Ensures both binaries are present in the writable bin dir, then caches
  /// the resolver instance. Returns the instance.
  static Future<BinaryResolver> ensureReady() async {
    final dir = await binDir();
    final ytdlp = await _provision(dir, _ytDlp);
    final ffmpeg = await _provision(dir, _ffmpeg);
    return _instance = BinaryResolver._(ytdlp, ffmpeg);
  }

  static Future<String> _provision(Directory dir, String name) async {
    final target = File(p.join(dir.path, name));
    if (await target.exists()) return target.path;

    // 2) Next to the executable.
    final exeDir = p.dirname(Platform.resolvedExecutable);
    for (final candidate in [
      File(p.join(exeDir, 'bin', name)),
      File(p.join(exeDir, name)),
      File(p.join(exeDir, 'data', 'flutter_assets', 'assets', 'bin', name)),
    ]) {
      if (await candidate.exists()) {
        await candidate.copy(target.path);
        return target.path;
      }
    }

    // 3) Bundled asset fallback (debug / dev runs).
    try {
      final data = await rootBundle.load('assets/bin/$name');
      await target.writeAsBytes(data.buffer.asUint8List(), flush: true);
      return target.path;
    } catch (e) {
      // Not fatal here: surfaced to the user when an action needs the binary.
      debugPrint('BinaryResolver: $name not found in any location ($e).');
      // Return expected path; callers verify existence before invoking.
      return target.path;
    }
  }

  bool get ytDlpExists => File(ytDlpPath).existsSync();
  bool get ffmpegExists => File(ffmpegPath).existsSync();

  /// Human-readable readiness report for the Settings/About screen.
  String get statusReport => 'yt-dlp: ${ytDlpExists ? "ready" : "MISSING"}  •  '
      'ffmpeg: ${ffmpegExists ? "ready" : "MISSING"}';
}
