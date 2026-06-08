/// Live progress snapshot parsed from yt-dlp's `--progress-template` output.
class DownloadProgress {
  const DownloadProgress({
    this.fraction = 0,
    this.downloadedBytes,
    this.totalBytes,
    this.speedBytesPerSec,
    this.etaSeconds,
    this.phase,
  });

  /// 0.0 – 1.0.
  final double fraction;
  final int? downloadedBytes;
  final int? totalBytes;
  final double? speedBytesPerSec;
  final int? etaSeconds;

  /// e.g. "downloading", "post-processing".
  final String? phase;

  static const empty = DownloadProgress();

  /// Parses a line emitted by our progress template:
  /// `TVPROG|<status>|<downloaded>|<total>|<speed>|<eta>`
  static DownloadProgress? tryParseLine(String line) {
    if (!line.startsWith('TVPROG|')) return null;
    final parts = line.trim().split('|');
    if (parts.length < 6) return null;

    int? num0(String s) {
      if (s.isEmpty || s == 'NA' || s == 'None') return null;
      return int.tryParse(s.split('.').first);
    }

    double? dnum(String s) {
      if (s.isEmpty || s == 'NA' || s == 'None') return null;
      return double.tryParse(s);
    }

    final status = parts[1];
    final downloaded = num0(parts[2]);
    final total = num0(parts[3]);
    final speed = dnum(parts[4]);
    final eta = num0(parts[5]);

    double frac = 0;
    if (downloaded != null && total != null && total > 0) {
      frac = (downloaded / total).clamp(0.0, 1.0);
    }
    return DownloadProgress(
      fraction: frac,
      downloadedBytes: downloaded,
      totalBytes: total,
      speedBytesPerSec: speed,
      etaSeconds: eta,
      phase: status,
    );
  }
}
