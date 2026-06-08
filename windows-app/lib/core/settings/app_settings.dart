import 'package:flutter/material.dart' show ThemeMode;

import '../models/app_enums.dart';

/// Immutable snapshot of user-configurable settings.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.defaultQuality = VideoQuality.q1080,
    this.defaultContainer = VideoContainer.mp4,
    this.defaultAudioFormat = AudioFormat.mp3,
    this.defaultAudioBitrate = AudioBitrate.source,
    this.downloadDir,
    this.maxConcurrent = 2,
    this.notificationsEnabled = true,
    this.minimizeToTray = true,
    this.languageCode = 'en',
    this.acceptedLegalNotice = false,
    this.accentColor = 0xFF5B7CFF,
  });

  final ThemeMode themeMode;
  final VideoQuality defaultQuality;
  final VideoContainer defaultContainer;
  final AudioFormat defaultAudioFormat;
  final AudioBitrate defaultAudioBitrate;
  final String? downloadDir;
  final int maxConcurrent;
  final bool notificationsEnabled;
  final bool minimizeToTray;
  final String languageCode;
  final bool acceptedLegalNotice;

  /// Accent color as an ARGB int (user-selectable in Settings).
  final int accentColor;

  AppSettings copyWith({
    ThemeMode? themeMode,
    VideoQuality? defaultQuality,
    VideoContainer? defaultContainer,
    AudioFormat? defaultAudioFormat,
    AudioBitrate? defaultAudioBitrate,
    String? downloadDir,
    int? maxConcurrent,
    bool? notificationsEnabled,
    bool? minimizeToTray,
    String? languageCode,
    bool? acceptedLegalNotice,
    int? accentColor,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      defaultQuality: defaultQuality ?? this.defaultQuality,
      defaultContainer: defaultContainer ?? this.defaultContainer,
      defaultAudioFormat: defaultAudioFormat ?? this.defaultAudioFormat,
      defaultAudioBitrate: defaultAudioBitrate ?? this.defaultAudioBitrate,
      downloadDir: downloadDir ?? this.downloadDir,
      maxConcurrent: maxConcurrent ?? this.maxConcurrent,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      minimizeToTray: minimizeToTray ?? this.minimizeToTray,
      languageCode: languageCode ?? this.languageCode,
      acceptedLegalNotice: acceptedLegalNotice ?? this.acceptedLegalNotice,
      accentColor: accentColor ?? this.accentColor,
    );
  }
}
