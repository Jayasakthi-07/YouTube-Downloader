import 'package:flutter/material.dart' show ThemeMode;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

import '../models/app_enums.dart';
import 'app_settings.dart';

/// Persists [AppSettings] to `shared_preferences`.
class SettingsStore {
  SettingsStore(this._prefs);
  final SharedPreferences _prefs;

  static Future<SettingsStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsStore(prefs);
  }

  static const _kTheme = 'theme_mode';
  static const _kQuality = 'default_quality';
  static const _kContainer = 'default_container';
  static const _kAudio = 'default_audio';
  static const _kAudioBitrate = 'default_audio_bitrate';
  static const _kDir = 'download_dir';
  static const _kConcurrent = 'max_concurrent';
  static const _kNotif = 'notifications_enabled';
  static const _kTray = 'minimize_to_tray';
  static const _kLang = 'language_code';
  static const _kLegal = 'accepted_legal';
  static const _kAccent = 'accent_color';

  Future<AppSettings> load() async {
    final dir = _prefs.getString(_kDir) ?? await _defaultDownloadDir();
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == _prefs.getString(_kTheme),
        orElse: () => ThemeMode.dark,
      ),
      defaultQuality: VideoQuality.values.firstWhere(
        (q) => q.name == _prefs.getString(_kQuality),
        orElse: () => VideoQuality.q1080,
      ),
      defaultContainer: VideoContainer.values.firstWhere(
        (c) => c.name == _prefs.getString(_kContainer),
        orElse: () => VideoContainer.mp4,
      ),
      defaultAudioFormat: AudioFormat.values.firstWhere(
        (a) => a.name == _prefs.getString(_kAudio),
        orElse: () => AudioFormat.mp3,
      ),
      defaultAudioBitrate: AudioBitrate.values.firstWhere(
        (b) => b.name == _prefs.getString(_kAudioBitrate),
        orElse: () => AudioBitrate.source,
      ),
      downloadDir: dir,
      maxConcurrent: _prefs.getInt(_kConcurrent) ?? 2,
      notificationsEnabled: _prefs.getBool(_kNotif) ?? true,
      minimizeToTray: _prefs.getBool(_kTray) ?? true,
      languageCode: _prefs.getString(_kLang) ?? 'en',
      acceptedLegalNotice: _prefs.getBool(_kLegal) ?? false,
      accentColor: _prefs.getInt(_kAccent) ?? 0xFF5B7CFF,
    );
  }

  Future<void> save(AppSettings s) async {
    await _prefs.setString(_kTheme, s.themeMode.name);
    await _prefs.setString(_kQuality, s.defaultQuality.name);
    await _prefs.setString(_kContainer, s.defaultContainer.name);
    await _prefs.setString(_kAudio, s.defaultAudioFormat.name);
    await _prefs.setString(_kAudioBitrate, s.defaultAudioBitrate.name);
    if (s.downloadDir != null) await _prefs.setString(_kDir, s.downloadDir!);
    await _prefs.setInt(_kConcurrent, s.maxConcurrent);
    await _prefs.setBool(_kNotif, s.notificationsEnabled);
    await _prefs.setBool(_kTray, s.minimizeToTray);
    await _prefs.setString(_kLang, s.languageCode);
    await _prefs.setBool(_kLegal, s.acceptedLegalNotice);
    await _prefs.setInt(_kAccent, s.accentColor);
  }

  static Future<String> _defaultDownloadDir() async {
    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) {
        return p.join(downloads.path, 'TubeVault');
      }
    } catch (_) {}
    final docs = await getApplicationDocumentsDirectory();
    return p.join(docs.path, 'TubeVault');
  }
}
