import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// Windows file-management operations for downloaded files.
abstract final class FileActions {
  /// Opens a file with its default application.
  static Future<bool> open(String filePath) async {
    if (!File(filePath).existsSync()) return false;
    final r = await Process.run('cmd', ['/c', 'start', '', filePath]);
    return r.exitCode == 0;
  }

  /// Reveals a file in Windows Explorer (selecting it).
  static Future<void> revealInExplorer(String filePath) async {
    if (File(filePath).existsSync()) {
      await Process.run('explorer.exe', ['/select,', filePath]);
    } else {
      final dir = p.dirname(filePath);
      if (Directory(dir).existsSync()) {
        await Process.run('explorer.exe', [dir]);
      }
    }
  }

  /// Renames a file in place (keeps the same directory). Returns the new path.
  static Future<String> rename(String filePath, String newBaseName) async {
    final file = File(filePath);
    final ext = p.extension(filePath);
    final sanitized = _sanitize(newBaseName);
    final newPath = p.join(p.dirname(filePath), '$sanitized$ext');
    final renamed = await file.rename(newPath);
    return renamed.path;
  }

  /// Moves a file to [targetDir]. Returns the new path.
  static Future<String> move(String filePath, String targetDir) async {
    final newPath = p.join(targetDir, p.basename(filePath));
    final file = File(filePath);
    try {
      final moved = await file.rename(newPath); // fast path (same volume)
      return moved.path;
    } on FileSystemException {
      // Cross-volume move: copy then delete.
      await file.copy(newPath);
      await file.delete();
      return newPath;
    }
  }

  static Future<void> delete(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) await file.delete();
  }

  /// "Share" on desktop = copy the file path to the clipboard.
  static Future<void> copyPath(String filePath) =>
      Clipboard.setData(ClipboardData(text: filePath));

  static Future<void> copyText(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  static String _sanitize(String name) =>
      name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
}
