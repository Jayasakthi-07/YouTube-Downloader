import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/engine/ytdlp_service.dart';
import '../../core/models/video_info.dart';
import '../../shared/providers.dart';
import '../../shared/utils/youtube_url.dart';

/// Drives metadata fetching for the Home/Download screen. Holds an
/// [AsyncValue] so the UI can render skeleton/loading/error/data states.
class MetadataController extends StateNotifier<AsyncValue<VideoInfo?>> {
  MetadataController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<void> fetch(String url) async {
    final trimmed = url.trim();
    if (!YoutubeUrl.isValid(trimmed)) {
      state = AsyncError(
        'That doesn\'t look like a YouTube URL.',
        StackTrace.current,
      );
      return;
    }
    state = const AsyncLoading();
    try {
      final engine = _ref.read(ytDlpServiceProvider);
      final info = YoutubeUrl.isPlaylist(trimmed)
          ? await engine.fetchPlaylist(trimmed)
          : await engine.fetchMetadata(trimmed);
      state = AsyncData(info);
    } on EngineException catch (e) {
      state = AsyncError(e.message, StackTrace.current);
    } catch (e, st) {
      state = AsyncError(e.toString(), st);
    }
  }

  void clear() => state = const AsyncData(null);
}

final metadataControllerProvider =
    StateNotifierProvider<MetadataController, AsyncValue<VideoInfo?>>(
  (ref) => MetadataController(ref),
);
