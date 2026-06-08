import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_enums.dart';
import '../../core/models/download_options.dart';
import '../../core/settings/settings_controller.dart';

/// Holds the user's current download-option selections for the Home screen,
/// seeded from saved defaults.
class OptionsController extends StateNotifier<DownloadOptions> {
  OptionsController(super.initial);

  void setType(DownloadType t) => state = state.copyWith(type: t);
  void setQuality(VideoQuality q) => state = state.copyWith(quality: q);
  void setContainer(VideoContainer c) => state = state.copyWith(container: c);
  void setAudioFormat(AudioFormat a) => state = state.copyWith(audioFormat: a);
  void setAudioBitrate(AudioBitrate b) =>
      state = state.copyWith(audioBitrate: b);

  void toggleEmbedThumbnail(bool v) =>
      state = state.copyWith(embedThumbnail: v);
  void toggleEmbedSubtitles(bool v) =>
      state = state.copyWith(embedSubtitles: v);
  void toggleWriteSubtitles(bool v) =>
      state = state.copyWith(writeSubtitleFiles: v);
  void toggleAutoSubtitles(bool v) =>
      state = state.copyWith(autoSubtitles: v);
  void setSubtitleLangs(List<String> langs) =>
      state = state.copyWith(subtitleLangs: langs);

  // Advanced
  void toggleSponsorBlock(bool v) => state = state.copyWith(sponsorBlock: v);
  void setSponsorCategories(List<String> c) =>
      state = state.copyWith(sponsorCategories: c);
  void toggleEmbedMetadata(bool v) =>
      state = state.copyWith(embedMetadata: v);
  void toggleEmbedChapters(bool v) =>
      state = state.copyWith(embedChapters: v);
  void setConcurrentFragments(int n) =>
      state = state.copyWith(concurrentFragments: n.clamp(1, 16));
  void setRateLimit(int? kbps) => state = (kbps == null || kbps <= 0)
      ? state.copyWith(clearRateLimit: true)
      : state.copyWith(rateLimitKbps: kbps);

  void setClip(String? start, String? end) {
    final empty = (start == null || start.isEmpty) && (end == null || end.isEmpty);
    state = empty
        ? state.copyWith(clearClip: true)
        : state.copyWith(clipStart: start, clipEnd: end);
  }

  void applyPreset(DownloadOptions Function(DownloadOptions) build) =>
      state = build(state);
}

final optionsControllerProvider =
    StateNotifierProvider<OptionsController, DownloadOptions>((ref) {
  final s = ref.read(settingsControllerProvider);
  return OptionsController(DownloadOptions(
    quality: s.defaultQuality,
    container: s.defaultContainer,
    audioFormat: s.defaultAudioFormat,
    audioBitrate: s.defaultAudioBitrate,
  ));
});
