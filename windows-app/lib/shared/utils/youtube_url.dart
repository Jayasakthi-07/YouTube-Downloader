/// YouTube URL validation and normalization.
abstract final class YoutubeUrl {
  static final _hostPattern = RegExp(
    r'^(www\.|m\.|music\.)?(youtube\.com|youtu\.be)$',
    caseSensitive: false,
  );

  /// True if [input] looks like a YouTube video/playlist/channel URL.
  static bool isValid(String input) {
    final uri = Uri.tryParse(input.trim());
    if (uri == null || !uri.hasScheme) return false;
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    return _hostPattern.hasMatch(uri.host);
  }

  /// True if the URL references a playlist.
  static bool isPlaylist(String input) {
    final uri = Uri.tryParse(input.trim());
    if (uri == null) return false;
    return uri.queryParameters.containsKey('list') ||
        uri.path.startsWith('/playlist');
  }

  /// Extracts a video id where possible (`youtu.be/<id>` or `?v=<id>`).
  static String? videoId(String input) {
    final uri = Uri.tryParse(input.trim());
    if (uri == null) return null;
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    return uri.queryParameters['v'];
  }
}
