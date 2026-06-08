import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers.dart';
import '../models/app_enums.dart';
import 'app_settings.dart';

/// Holds and persists [AppSettings]. Initialized with a synchronous default
/// then hydrated from disk via [load].
class SettingsController extends StateNotifier<AppSettings> {
  SettingsController(this._ref) : super(const AppSettings());

  final Ref _ref;

  Future<void> load() async {
    state = await _ref.read(settingsStoreProvider).load();
  }

  Future<void> _update(AppSettings next) async {
    state = next;
    await _ref.read(settingsStoreProvider).save(next);
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _update(state.copyWith(themeMode: mode));

  Future<void> setDownloadDir(String dir) =>
      _update(state.copyWith(downloadDir: dir));

  Future<void> setDefaultQuality(VideoQuality q) =>
      _update(state.copyWith(defaultQuality: q));

  Future<void> setDefaultContainer(VideoContainer c) =>
      _update(state.copyWith(defaultContainer: c));

  Future<void> setDefaultAudioFormat(AudioFormat a) =>
      _update(state.copyWith(defaultAudioFormat: a));

  Future<void> setDefaultAudioBitrate(AudioBitrate b) =>
      _update(state.copyWith(defaultAudioBitrate: b));

  Future<void> setMaxConcurrent(int n) =>
      _update(state.copyWith(maxConcurrent: n.clamp(1, 5)));

  Future<void> setNotificationsEnabled(bool v) =>
      _update(state.copyWith(notificationsEnabled: v));

  Future<void> setMinimizeToTray(bool v) =>
      _update(state.copyWith(minimizeToTray: v));

  Future<void> setLanguage(String code) =>
      _update(state.copyWith(languageCode: code));

  Future<void> acceptLegalNotice() =>
      _update(state.copyWith(acceptedLegalNotice: true));

  Future<void> setAccentColor(int argb) =>
      _update(state.copyWith(accentColor: argb));
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AppSettings>(
  (ref) => SettingsController(ref),
);
