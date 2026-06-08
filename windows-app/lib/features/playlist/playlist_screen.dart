import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_shell.dart';
import '../../app/theme/tokens.dart';
import '../../core/engine/ytdlp_service.dart';
import '../../core/models/video_info.dart';
import '../../shared/providers.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/utils/youtube_url.dart';
import '../../shared/widgets/common.dart';
import '../download/download_queue.dart';
import '../download/options_controller.dart';

class PlaylistScreen extends ConsumerStatefulWidget {
  const PlaylistScreen({super.key});

  @override
  ConsumerState<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends ConsumerState<PlaylistScreen> {
  final _controller = TextEditingController();
  final _selected = <String>{};
  VideoInfo? _playlist;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    final url = _controller.text.trim();
    if (!YoutubeUrl.isValid(url)) {
      setState(() => _error = 'Enter a valid YouTube playlist URL.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _playlist = null;
      _selected.clear();
    });
    try {
      final info = await ref.read(ytDlpServiceProvider).fetchPlaylist(url);
      setState(() {
        _playlist = info;
        _selected.addAll(info.playlistEntries.map((e) => e.id));
      });
    } on EngineException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _enqueueSelected() async {
    final pl = _playlist;
    if (pl == null) return;
    final opts = ref.read(optionsControllerProvider);
    final queue = ref.read(downloadQueueProvider.notifier);
    final chosen =
        pl.playlistEntries.where((e) => _selected.contains(e.id)).toList();
    for (final e in chosen) {
      await queue.enqueue(
        url: e.url,
        title: e.title,
        options: opts,
        thumbnailUrl: e.thumbnailUrl,
      );
    }
    if (mounted) {
      showToast(context, 'Queued ${chosen.length} videos');
      ref.read(navIndexProvider.notifier).state = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pl = _playlist;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Spacing.lg, Spacing.lg, Spacing.lg, Spacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Playlists',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: Spacing.md),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _fetch(),
                      decoration: const InputDecoration(
                        hintText: 'Paste a playlist URL…',
                        prefixIcon: Icon(Icons.playlist_play_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  FilledButton.icon(
                    onPressed: _loading ? null : _fetch,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.search_rounded),
                    label: const Text('Load'),
                  ),
                ]),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: Spacing.xs),
                    child: Text(_error!,
                        style: const TextStyle(color: Palette.danger)),
                  ),
              ],
            ),
          ),
          if (pl != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Row(children: [
                Text('${pl.title} · ${pl.playlistEntries.length} videos',
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                TextButton(
                    onPressed: () => setState(() =>
                        _selected.addAll(pl.playlistEntries.map((e) => e.id))),
                    child: const Text('Select all')),
                TextButton(
                    onPressed: () => setState(_selected.clear),
                    child: const Text('Clear')),
              ]),
            ),
          Expanded(
            child: pl == null
                ? const EmptyState(
                    icon: Icons.playlist_play_rounded,
                    title: 'No playlist loaded',
                    message:
                        'Paste a playlist link to pick which videos to download.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                        Spacing.lg, Spacing.xs, Spacing.lg, Spacing.lg),
                    itemCount: pl.playlistEntries.length,
                    itemBuilder: (context, i) {
                      final e = pl.playlistEntries[i];
                      final checked = _selected.contains(e.id);
                      return CheckboxListTile(
                        value: checked,
                        onChanged: (v) => setState(() => v == true
                            ? _selected.add(e.id)
                            : _selected.remove(e.id)),
                        title: Text(e.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          '${e.uploader ?? ''}  ${Fmt.duration(e.durationSeconds == null ? null : Duration(seconds: e.durationSeconds!))}',
                        ),
                        secondary: CircleAvatar(child: Text('${i + 1}')),
                      );
                    },
                  ),
          ),
          if (pl != null)
            Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Row(children: [
                Text('${_selected.length} selected',
                    style: Theme.of(context).textTheme.bodyMedium),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _selected.isEmpty ? null : _enqueueSelected,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Download selected'),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}
