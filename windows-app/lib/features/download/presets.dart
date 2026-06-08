import 'package:flutter/material.dart';

import '../../core/models/app_enums.dart';
import '../../core/models/download_options.dart';

/// One-tap download profiles surfaced as quick chips on the Download screen.
class DownloadPreset {
  const DownloadPreset({
    required this.id,
    required this.label,
    required this.icon,
    required this.build,
  });

  final String id;
  final String label;
  final IconData icon;

  /// Produces the options for this preset, preserving the user's current
  /// subtitle/clip choices where it makes sense.
  final DownloadOptions Function(DownloadOptions current) build;

  static final List<DownloadPreset> all = [
    DownloadPreset(
      id: 'max4k',
      label: 'Max Quality',
      icon: Icons.four_k_rounded,
      build: (c) => c.copyWith(
        type: DownloadType.video,
        quality: VideoQuality.best,
        container: VideoContainer.mp4,
        audioBitrate: AudioBitrate.source,
        embedMetadata: true,
        embedChapters: true,
      ),
    ),
    DownloadPreset(
      id: 'hd1080',
      label: '1080p MP4',
      icon: Icons.hd_rounded,
      build: (c) => c.copyWith(
        type: DownloadType.video,
        quality: VideoQuality.q1080,
        container: VideoContainer.mp4,
        embedMetadata: true,
        embedChapters: true,
      ),
    ),
    DownloadPreset(
      id: 'music',
      label: 'Music · 320',
      icon: Icons.music_note_rounded,
      build: (c) => c.copyWith(
        type: DownloadType.audio,
        audioFormat: AudioFormat.mp3,
        audioBitrate: AudioBitrate.k320,
        embedThumbnail: true,
        embedMetadata: true,
        sponsorBlock: true,
      ),
    ),
    DownloadPreset(
      id: 'podcast',
      label: 'Podcast · M4A',
      icon: Icons.podcasts_rounded,
      build: (c) => c.copyWith(
        type: DownloadType.audio,
        audioFormat: AudioFormat.m4a,
        audioBitrate: AudioBitrate.k192,
        embedMetadata: true,
      ),
    ),
    DownloadPreset(
      id: 'shorts',
      label: 'Data Saver',
      icon: Icons.data_saver_on_rounded,
      build: (c) => c.copyWith(
        type: DownloadType.video,
        quality: VideoQuality.q480,
        container: VideoContainer.mp4,
      ),
    ),
  ];
}
