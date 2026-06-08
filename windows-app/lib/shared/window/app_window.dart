import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Manages the desktop window lifecycle and the system tray, implementing
/// minimize-to-tray so downloads continue when the window is closed.
class AppWindow with WindowListener, TrayListener {
  AppWindow();

  /// Provides the current "minimize to tray" setting at close time.
  bool Function() minimizeToTrayEnabled = () => true;

  bool _trayReady = false;

  Future<void> init() async {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(1300, 860),
      minimumSize: Size(1040, 680),
      center: true,
      title: 'TubeVault',
      backgroundColor: Color(0x00000000),
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    await _initTray();
  }

  Future<void> _initTray() async {
    try {
      // Icon is optional; tray still registers a context menu without it.
      try {
        await trayManager.setIcon('assets/icons/tray.ico');
      } catch (e) {
        debugPrint('Tray icon not set (drop assets/icons/tray.ico): $e');
      }
      await trayManager.setToolTip('TubeVault');
      await trayManager.setContextMenu(Menu(items: [
        MenuItem(key: 'show', label: 'Open TubeVault'),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: 'Quit'),
      ]));
      trayManager.addListener(this);
      _trayReady = true;
    } catch (e) {
      debugPrint('Tray init failed: $e');
    }
  }

  Future<void> _showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _quit() async {
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
    exit(0);
  }

  // --- WindowListener -------------------------------------------------------
  @override
  void onWindowClose() async {
    if (minimizeToTrayEnabled() && _trayReady) {
      await windowManager.hide();
    } else {
      await _quit();
    }
  }

  // --- TrayListener ---------------------------------------------------------
  @override
  void onTrayIconMouseDown() => _showWindow();

  @override
  void onTrayIconRightMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        _showWindow();
      case 'quit':
        _quit();
    }
  }
}
