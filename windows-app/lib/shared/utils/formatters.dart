/// Formatting helpers for sizes, speeds, durations and ETAs.
abstract final class Fmt {
  static String bytes(int? b) {
    if (b == null || b <= 0) return '—';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = b.toDouble();
    var i = 0;
    while (size >= 1024 && i < units.length - 1) {
      size /= 1024;
      i++;
    }
    final digits = size >= 100 || i == 0 ? 0 : 1;
    return '${size.toStringAsFixed(digits)} ${units[i]}';
  }

  static String speed(double? bytesPerSec) {
    if (bytesPerSec == null || bytesPerSec <= 0) return '—';
    return '${bytes(bytesPerSec.round())}/s';
  }

  static String duration(Duration? d) {
    if (d == null) return '—';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static String eta(int? seconds) {
    if (seconds == null || seconds < 0) return '—';
    return duration(Duration(seconds: seconds));
  }

  static String percent(double fraction) =>
      '${(fraction * 100).clamp(0, 100).toStringAsFixed(0)}%';

  /// "2026-06-05" style date.
  static String date(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static String bitrate(double? kbps) =>
      kbps == null ? '—' : '${kbps.toStringAsFixed(0)} kbps';

  /// Compact count formatting: 1234 -> 1.2K, 3400000 -> 3.4M.
  static String compact(int? n) {
    if (n == null) return '—';
    if (n < 1000) return '$n';
    const units = ['K', 'M', 'B'];
    var v = n.toDouble();
    var i = -1;
    while (v >= 1000 && i < units.length - 1) {
      v /= 1000;
      i++;
    }
    return '${v.toStringAsFixed(v >= 100 ? 0 : 1)}${units[i]}';
  }
}
