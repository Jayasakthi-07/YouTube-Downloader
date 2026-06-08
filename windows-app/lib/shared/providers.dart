import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/db/history_repository.dart';
import '../core/engine/binary_resolver.dart';
import '../core/engine/engine_updater.dart';
import '../core/engine/ytdlp_service.dart';
import '../core/settings/settings_store.dart';
import 'notifications.dart';

/// Infrastructure providers. These are *overridden* in `main()` with the
/// instances built during async bootstrap, so they never hit the throwing
/// default at runtime.
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('appConfigProvider must be overridden'),
);

final binaryResolverProvider = Provider<BinaryResolver>(
  (ref) => throw UnimplementedError('binaryResolverProvider must be overridden'),
);

final ytDlpServiceProvider = Provider<YtDlpService>(
  (ref) => throw UnimplementedError('ytDlpServiceProvider must be overridden'),
);

final engineUpdaterProvider = Provider<EngineUpdater>(
  (ref) => throw UnimplementedError('engineUpdaterProvider must be overridden'),
);

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) =>
      throw UnimplementedError('historyRepositoryProvider must be overridden'),
);

final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => throw UnimplementedError('settingsStoreProvider must be overridden'),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError(
      'notificationServiceProvider must be overridden'),
);
