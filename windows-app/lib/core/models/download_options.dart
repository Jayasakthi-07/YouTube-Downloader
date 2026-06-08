import 'app_enums.dart';

/// User-selected options describing how a URL should be downloaded.
class DownloadOptions {
  const DownloadOptions({
    this.type = DownloadType.video,
    this.quality = VideoQuality.q1080,
    this.container = VideoContainer.mp4,
    this.audioFormat = AudioFormat.mp3,
    this.audioBitrate = AudioBitrate.source,
    this.embedThumbnail = false,
    this.embedSubtitles = false,
    this.writeSubtitleFiles = false,
    this.autoSubtitles = false,
    this.subtitleLangs = const ['en'],
    this.playlistItems,
    // Advanced
    this.sponsorBlock = false,
    this.sponsorCategories = const [
      'sponsor',
      'selfpromo',
      'interaction',
      'music_offtopic',
    ],
    this.embedMetadata = true,
    this.embedChapters = true,
    this.clipStart,
    this.clipEnd,
    this.rateLimitKbps,
    this.concurrentFragments = 4,
  });

  final DownloadType type;
  final VideoQuality quality;
  final VideoContainer container;
  final AudioFormat audioFormat;
  final AudioBitrate audioBitrate;

  final bool embedThumbnail;
  final bool embedSubtitles;
  final bool writeSubtitleFiles;
  final bool autoSubtitles;
  final List<String> subtitleLangs;

  /// yt-dlp `--playlist-items` spec (e.g. "1,3,5-8"); null = all / single video.
  final String? playlistItems;

  // --- Advanced -------------------------------------------------------------

  /// Remove SponsorBlock segments (`--sponsorblock-remove`).
  final bool sponsorBlock;
  final List<String> sponsorCategories;

  /// Embed metadata / chapters into the output file.
  final bool embedMetadata;
  final bool embedChapters;

  /// Optional clip section as `HH:MM:SS` (or seconds) strings.
  final String? clipStart;
  final String? clipEnd;

  /// Download rate limit in KB/s; null = unlimited.
  final int? rateLimitKbps;

  /// Parallel fragment downloads (`-N`) for faster DASH downloads.
  final int concurrentFragments;

  bool get hasClip =>
      (clipStart != null && clipStart!.isNotEmpty) ||
      (clipEnd != null && clipEnd!.isNotEmpty);

  DownloadOptions copyWith({
    DownloadType? type,
    VideoQuality? quality,
    VideoContainer? container,
    AudioFormat? audioFormat,
    AudioBitrate? audioBitrate,
    bool? embedThumbnail,
    bool? embedSubtitles,
    bool? writeSubtitleFiles,
    bool? autoSubtitles,
    List<String>? subtitleLangs,
    String? playlistItems,
    bool? sponsorBlock,
    List<String>? sponsorCategories,
    bool? embedMetadata,
    bool? embedChapters,
    String? clipStart,
    String? clipEnd,
    int? rateLimitKbps,
    int? concurrentFragments,
    bool clearClip = false,
    bool clearRateLimit = false,
  }) {
    return DownloadOptions(
      type: type ?? this.type,
      quality: quality ?? this.quality,
      container: container ?? this.container,
      audioFormat: audioFormat ?? this.audioFormat,
      audioBitrate: audioBitrate ?? this.audioBitrate,
      embedThumbnail: embedThumbnail ?? this.embedThumbnail,
      embedSubtitles: embedSubtitles ?? this.embedSubtitles,
      writeSubtitleFiles: writeSubtitleFiles ?? this.writeSubtitleFiles,
      autoSubtitles: autoSubtitles ?? this.autoSubtitles,
      subtitleLangs: subtitleLangs ?? this.subtitleLangs,
      playlistItems: playlistItems ?? this.playlistItems,
      sponsorBlock: sponsorBlock ?? this.sponsorBlock,
      sponsorCategories: sponsorCategories ?? this.sponsorCategories,
      embedMetadata: embedMetadata ?? this.embedMetadata,
      embedChapters: embedChapters ?? this.embedChapters,
      clipStart: clearClip ? null : (clipStart ?? this.clipStart),
      clipEnd: clearClip ? null : (clipEnd ?? this.clipEnd),
      rateLimitKbps:
          clearRateLimit ? null : (rateLimitKbps ?? this.rateLimitKbps),
      concurrentFragments: concurrentFragments ?? this.concurrentFragments,
    );
  }

  /// Short human description used in lists.
  String get summary {
    final extras = <String>[];
    if (sponsorBlock) extras.add('SponsorBlock');
    if (hasClip) extras.add('clip');
    final suffix = extras.isEmpty ? '' : ' · ${extras.join(" · ")}';
    switch (type) {
      case DownloadType.video:
        final audio =
            audioBitrate.isFixed ? ' · ${audioBitrate.label} audio' : '';
        return '${quality.label} · ${container.label}$audio$suffix';
      case DownloadType.audio:
        final br = audioFormat.supportsBitrate && audioBitrate.isFixed
            ? ' · ${audioBitrate.label}'
            : '';
        return 'Audio · ${audioFormat.label}$br$suffix';
      case DownloadType.thumbnail:
        return 'Thumbnail';
      case DownloadType.subtitles:
        return 'Subtitles (${subtitleLangs.join(", ")})';
    }
  }
}
