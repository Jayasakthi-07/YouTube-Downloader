import 'media_format.dart';

/// Metadata for a single video, parsed from yt-dlp `--dump-json`.
class VideoInfo {
  const VideoInfo({
    required this.id,
    required this.title,
    required this.webpageUrl,
    this.uploader,
    this.channel,
    this.durationSeconds,
    this.thumbnailUrl,
    this.description,
    this.viewCount,
    this.uploadDate,
    this.formats = const [],
    this.subtitleLangs = const [],
    this.autoSubtitleLangs = const [],
    this.isPlaylist = false,
    this.playlistEntries = const [],
  });

  final String id;
  final String title;
  final String webpageUrl;
  final String? uploader;
  final String? channel;
  final int? durationSeconds;
  final String? thumbnailUrl;
  final String? description;
  final int? viewCount;
  final String? uploadDate;
  final List<MediaFormat> formats;

  /// Manually-provided subtitle language codes.
  final List<String> subtitleLangs;

  /// Auto-generated caption language codes.
  final List<String> autoSubtitleLangs;

  final bool isPlaylist;
  final List<PlaylistEntry> playlistEntries;

  String get channelName => channel ?? uploader ?? 'Unknown channel';

  Duration? get duration =>
      durationSeconds == null ? null : Duration(seconds: durationSeconds!);

  /// Distinct heights available among video formats, descending.
  List<int> get availableHeights {
    final set = <int>{};
    for (final f in formats) {
      if (f.hasVideo && f.height != null) set.add(f.height!);
    }
    final list = set.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    final type = json['_type'] as String?;
    if (type == 'playlist') {
      final entries = (json['entries'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PlaylistEntry.fromJson)
          .toList();
      return VideoInfo(
        id: '${json['id']}',
        title: json['title'] as String? ?? 'Playlist',
        webpageUrl: json['webpage_url'] as String? ?? '',
        uploader: json['uploader'] as String?,
        isPlaylist: true,
        playlistEntries: entries,
        thumbnailUrl: entries.isNotEmpty ? entries.first.thumbnailUrl : null,
      );
    }

    final formats = (json['formats'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(MediaFormat.fromJson)
        .toList();

    final subs = (json['subtitles'] as Map?)?.keys.map((e) => '$e').toList() ??
        const <String>[];
    final autoSubs =
        (json['automatic_captions'] as Map?)?.keys.map((e) => '$e').toList() ??
            const <String>[];

    return VideoInfo(
      id: '${json['id']}',
      title: json['title'] as String? ?? 'Untitled',
      webpageUrl: json['webpage_url'] as String? ?? '',
      uploader: json['uploader'] as String?,
      channel: json['channel'] as String?,
      durationSeconds: (json['duration'] as num?)?.toInt(),
      thumbnailUrl: json['thumbnail'] as String?,
      description: json['description'] as String?,
      viewCount: (json['view_count'] as num?)?.toInt(),
      uploadDate: json['upload_date'] as String?,
      formats: formats,
      subtitleLangs: subs,
      autoSubtitleLangs: autoSubs,
    );
  }
}

/// A lightweight entry from a `--flat-playlist` listing.
class PlaylistEntry {
  const PlaylistEntry({
    required this.id,
    required this.title,
    required this.url,
    this.durationSeconds,
    this.thumbnailUrl,
    this.uploader,
  });

  final String id;
  final String title;
  final String url;
  final int? durationSeconds;
  final String? thumbnailUrl;
  final String? uploader;

  factory PlaylistEntry.fromJson(Map<String, dynamic> json) {
    String? thumb;
    final thumbs = json['thumbnails'] as List?;
    if (thumbs != null && thumbs.isNotEmpty) {
      thumb = (thumbs.last as Map)['url'] as String?;
    }
    return PlaylistEntry(
      id: '${json['id']}',
      title: json['title'] as String? ?? 'Untitled',
      url: json['url'] as String? ??
          'https://www.youtube.com/watch?v=${json['id']}',
      durationSeconds: (json['duration'] as num?)?.toInt(),
      thumbnailUrl: json['thumbnail'] as String? ?? thumb,
      uploader: json['uploader'] as String?,
    );
  }
}
