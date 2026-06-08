import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/db/app_database.dart';
import 'core/db/history_repository.dart';
import 'core/engine/binary_resolver.dart';
import 'core/engine/engine_updater.dart';
import 'core/engine/ytdlp_service.dart';
import 'core/settings/settings_controller.dart';
import 'core/settings/settings_store.dart';
import 'features/auth/auth_controller.dart';
import 'features/download/download_queue.dart';
import 'shared/notifications.dart';
import 'shared/providers.dart';
import 'shared/window/app_window.dart';

/// Command-line URL argument (lets TubeVault be registered as a URL handler).
final initialUrlProvider = Provider<String?>((ref) => null);

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop window + tray.
  final appWindow = AppWindow();
  await appWindow.init();

  // Async bootstrap of all infrastructure.
  final config = await AppConfig.load();
  final binaries = await BinaryResolver.ensureReady();
  final database = await AppDatabase.init();
  final settingsStore = await SettingsStore.create();
  final notifications = NotificationService();
  await notifications.init();

  final ytDlp = YtDlpService(binaries);
  final updater = EngineUpdater(binaries);
  final historyRepo = HistoryRepository(database);

  final initialUrl =
      args.isNotEmpty && args.first.startsWith('http') ? args.first : null;

  final container = ProviderContainer(overrides: [
    appConfigProvider.overrideWithValue(config),
    binaryResolverProvider.overrideWithValue(binaries),
    ytDlpServiceProvider.overrideWithValue(ytDlp),
    engineUpdaterProvider.overrideWithValue(updater),
    historyRepositoryProvider.overrideWithValue(historyRepo),
    settingsStoreProvider.overrideWithValue(settingsStore),
    notificationServiceProvider.overrideWithValue(notifications),
    initialUrlProvider.overrideWithValue(initialUrl),
  ]);

  // Hydrate settings, wire tray behaviour, restore session + interrupted jobs.
  await container.read(settingsControllerProvider.notifier).load();
  final settings = container.read(settingsControllerProvider);
  notifications.enabled = settings.notificationsEnabled;
  appWindow.minimizeToTrayEnabled =
      () => container.read(settingsControllerProvider).minimizeToTray;

  await container.read(authControllerProvider.notifier).bootstrap();
  await container.read(downloadQueueProvider.notifier).restoreInterrupted();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TubeVaultApp(),
    ),
  );
}
