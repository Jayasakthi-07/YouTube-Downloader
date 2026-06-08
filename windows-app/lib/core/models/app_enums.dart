// Domain enums and their mappings onto yt-dlp arguments.

/// What kind of artifact the user wants from a URL.
enum DownloadType { video, audio, thumbnail, subtitles }

/// Selectable video qualities (capped by height). [best] means "no cap".
enum VideoQuality {
  q144(144, '144p'),
  q240(240, '240p'),
  q360(360, '360p'),
  q480(480, '480p'),
  q720(720, '720p HD'),
  q1080(1080, '1080p Full HD'),
  q1440(1440, '1440p 2K'),
  q2160(2160, '2160p 4K'),
  best(0, 'Best available');

  const VideoQuality(this.maxHeight, this.label);

  /// Maximum frame height; 0 means uncapped (best).
  final int maxHeight;
  final String label;
}

/// Output container for merged video.
enum VideoContainer {
  mp4('mp4', 'MP4'),
  webm('webm', 'WEBM'),
  mkv('mkv', 'MKV');

  const VideoContainer(this.ext, this.label);
  final String ext;
  final String label;
}

/// Output format for audio-only extraction.
enum AudioFormat {
  mp3('mp3', 'MP3'),
  m4a('m4a', 'M4A'),
  aac('aac', 'AAC'),
  wav('wav', 'WAV');

  const AudioFormat(this.codec, this.label);
  final String codec;
  final String label;

  /// WAV is uncompressed, so a target bitrate doesn't apply to it.
  bool get supportsBitrate => this != AudioFormat.wav;
}

/// Target audio bitrate. [source] keeps YouTube's best track without
/// re-encoding (a fast, lossless remux for video). A fixed value re-encodes
/// the audio to that constant bitrate via FFmpeg.
///
/// Note: YouTube's source audio is ~128 kbps AAC or ~160 kbps Opus, so a fixed
/// 320 kbps re-encodes *up* from that source — the file is nominally 320 kbps
/// but its fidelity is bounded by the source. It maximizes compatibility and
/// guarantees a constant bitrate; it does not add detail YouTube didn't send.
enum AudioBitrate {
  source(0, 'Best (source)'),
  k128(128, '128 kbps'),
  k192(192, '192 kbps'),
  k256(256, '256 kbps'),
  k320(320, '320 kbps');

  const AudioBitrate(this.kbps, this.label);

  /// Target bitrate in kbps; 0 means "keep source / no re-encode".
  final int kbps;
  final String label;

  bool get isFixed => this != AudioBitrate.source;

  /// yt-dlp `--audio-quality` value (e.g. "320K"); "0" = best for source.
  String get ytdlpAudioQuality => isFixed ? '${kbps}K' : '0';
}

/// Lifecycle of a download task.
enum TaskStatus {
  queued,
  fetching, // resolving metadata
  downloading,
  paused,
  completed,
  failed,
  canceled;

  bool get isTerminal =>
      this == completed || this == failed || this == canceled;
  bool get isActive => this == downloading || this == fetching;
}

extension VideoQualitySelector on VideoQuality {
  /// yt-dlp `-f` format selector for this quality with the chosen container.
  ///
  /// Prefers a video stream within the height cap merged with the best audio,
  /// falling back to the best progressive stream.
  ///
  /// When [bestAudioAnyCodec] is true (we will re-encode the audio anyway),
  /// the best audio track is chosen regardless of codec — that picks YouTube's
  /// higher-bitrate Opus (~160 kbps) over its 128 kbps AAC, giving the encoder
  /// the best possible source. Otherwise mp4 prefers an m4a track so the merge
  /// is a fast, lossless remux.
  String formatSelector(VideoContainer container,
      {bool bestAudioAnyCodec = false}) {
    final wantMp4 = container == VideoContainer.mp4;
    final vExtPref = wantMp4 ? '[ext=mp4]' : '';
    final aExtPref = (wantMp4 && !bestAudioAnyCodec) ? '[ext=m4a]' : '';
    if (this == VideoQuality.best) {
      return 'bestvideo$vExtPref+bestaudio$aExtPref/bestvideo+bestaudio/best';
    }
    final h = maxHeight;
    return 'bestvideo[height<=$h]$vExtPref+bestaudio$aExtPref/'
        'bestvideo[height<=$h]+bestaudio/'
        'best[height<=$h]/best';
  }
}
