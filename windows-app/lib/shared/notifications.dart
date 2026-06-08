import 'package:flutter/foundation.dart';
import 'package:local_notifier/local_notifier.dart';

/// Thin wrapper over `local_notifier` for Windows toast notifications.
class NotificationService {
  bool _ready = false;
  bool enabled = true;

  Future<void> init() async {
    try {
      await localNotifier.setup(
        appName: 'TubeVault',
        shortcutPolicy: ShortcutPolicy.requireCreate,
      );
      _ready = true;
    } catch (e) {
      debugPrint('NotificationService init failed: $e');
    }
  }

  Future<void> show(String title, String body) async {
    if (!_ready || !enabled) return;
    try {
      final n = LocalNotification(title: title, body: body);
      await n.show();
    } catch (e) {
      debugPrint('Notification show failed: $e');
    }
  }

  Future<void> downloadComplete(String title) =>
      show('Download complete', title);

  Future<void> downloadFailed(String title) =>
      show('Download failed', title);
}
