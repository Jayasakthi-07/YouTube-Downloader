import 'dart:io';

import 'package:flutter/foundation.dart';

/// Disk/storage helpers for the Settings screen.
abstract final class StorageInfo {
  /// Sum of file sizes (bytes) within [dirPath], recursively. 0 if missing.
  static Future<int> folderSize(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return 0;
    var total = 0;
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          total += await entity.length().catchError((_) => 0);
        }
      }
    } catch (e) {
      debugPrint('folderSize failed: $e');
    }
    return total;
  }

  /// Free bytes on the volume containing [dirPath], via PowerShell. Null on
  /// failure (UI degrades gracefully).
  static Future<int?> freeSpace(String dirPath) async {
    try {
      final drive = dirPath.length >= 2 && dirPath[1] == ':'
          ? dirPath.substring(0, 1)
          : null;
      if (drive == null) return null;
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        "(Get-PSDrive $drive).Free",
      ]);
      final out = result.stdout.toString().trim();
      return int.tryParse(out);
    } catch (e) {
      debugPrint('freeSpace failed: $e');
      return null;
    }
  }

  /// Deletes `.part`/`.ytdl` temp files under [dirPath]. Returns count removed.
  static Future<int> clearTempFiles(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return 0;
    var removed = 0;
    await for (final e in dir.list(recursive: true, followLinks: false)) {
      if (e is File &&
          (e.path.endsWith('.part') || e.path.endsWith('.ytdl'))) {
        try {
          await e.delete();
          removed++;
        } catch (_) {}
      }
    }
    return removed;
  }
}
