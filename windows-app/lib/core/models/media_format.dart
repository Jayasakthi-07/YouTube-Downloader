/// A single downloadable stream/format as reported by yt-dlp `--dump-json`.
class MediaFormat {
  const MediaFormat({
    required this.formatId,
    this.ext,
    this.height,
    this.width,
    this.fps,
    this.vcodec,
    this.acodec,
    this.tbr,
    this.abr,
    this.filesize,
    this.filesizeApprox,
    this.formatNote,
  });

  final String formatId;
  final String? ext;
  final int? height;
  final int? width;
  final double? fps;
  final String? vcodec;
  final String? acodec;

  /// Total bitrate (kbps).
  final double? tbr;

  /// Audio bitrate (kbps).
  final double? abr;

  /// Exact filesize in bytes, when known.
  final int? filesize;

  /// Approximate filesize in bytes.
  final int? filesizeApprox;
  final String? formatNote;

  bool get hasVideo => vcodec != null && vcodec != 'none';
  bool get hasAudio => acodec != null && acodec != 'none';
  bool get isVideoOnly => hasVideo && !hasAudio;
  bool get isAudioOnly => !hasVideo && hasAudio;

  int? get effectiveSize => filesize ?? filesizeApprox;

  String get resolution {
    if (width != null && height != null) return '${width}x$height';
    if (height != null) return '${height}p';
    return '—';
  }

  factory MediaFormat.fromJson(Map<String, dynamic> json) {
    double? toD(Object? v) => v == null ? null : (v as num).toDouble();
    int? toI(Object? v) => v == null ? null : (v as num).toInt();
    return MediaFormat(
      formatId: '${json['format_id']}',
      ext: json['ext'] as String?,
      height: toI(json['height']),
      width: toI(json['width']),
      fps: toD(json['fps']),
      vcodec: json['vcodec'] as String?,
      acodec: json['acodec'] as String?,
      tbr: toD(json['tbr']),
      abr: toD(json['abr']),
      filesize: toI(json['filesize']),
      filesizeApprox: toI(json['filesize_approx']),
      formatNote: json['format_note'] as String?,
    );
  }
}
