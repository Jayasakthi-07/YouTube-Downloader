import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tokens.dart';
import '../../core/db/history_repository.dart';
import '../../core/models/app_enums.dart';
import '../../core/models/download_task.dart';
import '../../shared/providers.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/common.dart';
import '../download/download_queue.dart';
import 'file_actions.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _search = '';
  DownloadType? _typeFilter;
  TaskStatus? _statusFilter;
  HistorySort _sort = HistorySort.dateDesc;

  late Future<List<DownloadTask>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<DownloadTask>> _load() {
    return ref.read(historyRepositoryProvider).query(
          search: _search,
          type: _typeFilter,
          status: _statusFilter,
          sort: _sort,
        );
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    // Rebuild list when the queue completes something.
    ref.listen(downloadQueueProvider, (_, _) => _refresh());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Spacing.lg, Spacing.lg, Spacing.lg, Spacing.sm),
            child: Row(
              children: [
                Text('History',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    final ok = await _confirm(context, 'Clear all history?',
                        'This removes history records (files are kept).');
                    if (ok) {
                      await ref.read(historyRepositoryProvider).clearAll();
                      _refresh();
                    }
                  },
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Clear all'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: _Toolbar(
              onSearch: (v) {
                _search = v;
                _refresh();
              },
              sort: _sort,
              onSort: (s) {
                setState(() => _sort = s);
                _refresh();
              },
              typeFilter: _typeFilter,
              onType: (t) {
                setState(() => _typeFilter = t);
                _refresh();
              },
              statusFilter: _statusFilter,
              onStatus: (s) {
                setState(() => _statusFilter = s);
                _refresh();
              },
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Expanded(
            child: FutureBuilder<List<DownloadTask>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.history_rounded,
                    title: 'No downloads yet',
                    message: 'Completed downloads will be listed here.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      Spacing.lg, 0, Spacing.lg, Spacing.lg),
                  itemCount: items.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: _HistoryTile(task: items[i], onChanged: _refresh),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.onSearch,
    required this.sort,
    required this.onSort,
    required this.typeFilter,
    required this.onType,
    required this.statusFilter,
    required this.onStatus,
  });

  final ValueChanged<String> onSearch;
  final HistorySort sort;
  final ValueChanged<HistorySort> onSort;
  final DownloadType? typeFilter;
  final ValueChanged<DownloadType?> onType;
  final TaskStatus? statusFilter;
  final ValueChanged<TaskStatus?> onStatus;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            onChanged: onSearch,
            decoration: const InputDecoration(
              hintText: 'Search downloads…',
              prefixIcon: Icon(Icons.search_rounded),
              isDense: true,
            ),
          ),
        ),
        _Dropdown<HistorySort>(
          icon: Icons.sort_rounded,
          value: sort,
          items: const {
            HistorySort.dateDesc: 'Newest',
            HistorySort.dateAsc: 'Oldest',
            HistorySort.nameAsc: 'Name',
            HistorySort.sizeDesc: 'Size',
          },
          onChanged: onSort,
        ),
        _Dropdown<DownloadType?>(
          icon: Icons.category_outlined,
          value: typeFilter,
          items: const {
            null: 'All types',
            DownloadType.video: 'Video',
            DownloadType.audio: 'Audio',
            DownloadType.thumbnail: 'Thumbnail',
            DownloadType.subtitles: 'Subtitles',
          },
          onChanged: onType,
        ),
        _Dropdown<TaskStatus?>(
          icon: Icons.flag_outlined,
          value: statusFilter,
          items: const {
            null: 'Any status',
            TaskStatus.completed: 'Completed',
            TaskStatus.failed: 'Failed',
            TaskStatus.paused: 'Paused',
          },
          onChanged: onStatus,
        ),
      ],
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final IconData icon;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: Radii.fieldRadius,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        DropdownButton<T>(
          value: value,
          underline: const SizedBox.shrink(),
          isDense: true,
          borderRadius: Radii.cardRadius,
          items: [
            for (final e in items.entries)
              DropdownMenuItem(value: e.key, child: Text(e.value)),
          ],
          onChanged: (v) => onChanged(v as T),
        ),
      ]),
    );
  }
}

class _HistoryTile extends ConsumerWidget {
  const _HistoryTile({required this.task, required this.onChanged});
  final DownloadTask task;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final exists = task.filePath != null && File(task.filePath!).existsSync();

    return SurfaceCard(
      padding: const EdgeInsets.all(Spacing.sm),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radii.xs),
            child: SizedBox(
              width: 88,
              height: 56,
              child: task.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: task.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          const Icon(Icons.movie_outlined))
                  : ColoredBox(
                      color:
                          context.scheme.onSurface.withValues(alpha: 0.05)),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        t.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${task.options.summary} · ${Fmt.bytes(task.fileSizeBytes)} · '
                  '${Fmt.date(task.createdAt)}',
                  style: t.bodySmall,
                ),
                if (!exists && task.status == TaskStatus.completed)
                  Text('File moved or deleted',
                      style: t.bodySmall?.copyWith(color: Palette.warning)),
              ],
            ),
          ),
          _StatusBadge(status: task.status),
          _ActionMenu(task: task, exists: exists, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ActionMenu extends ConsumerWidget {
  const _ActionMenu(
      {required this.task, required this.exists, required this.onChanged});
  final DownloadTask task;
  final bool exists;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (value) => _handle(context, ref, value),
      itemBuilder: (context) => [
        if (exists)
          const PopupMenuItem(value: 'open', child: _MenuRow(Icons.open_in_new, 'Open')),
        if (exists)
          const PopupMenuItem(
              value: 'reveal', child: _MenuRow(Icons.folder_open, 'Reveal in Explorer')),
        if (exists)
          const PopupMenuItem(value: 'rename', child: _MenuRow(Icons.drive_file_rename_outline, 'Rename')),
        if (exists)
          const PopupMenuItem(value: 'move', child: _MenuRow(Icons.drive_file_move_outline, 'Move')),
        const PopupMenuItem(value: 'copyPath', child: _MenuRow(Icons.share_outlined, 'Copy path')),
        const PopupMenuItem(value: 'copyUrl', child: _MenuRow(Icons.link, 'Copy source URL')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'deleteFile', child: _MenuRow(Icons.delete_outline, 'Delete file')),
        const PopupMenuItem(value: 'removeRecord', child: _MenuRow(Icons.playlist_remove, 'Remove from history')),
      ],
    );
  }

  Future<void> _handle(
      BuildContext context, WidgetRef ref, String action) async {
    final repo = ref.read(historyRepositoryProvider);
    final path = task.filePath;
    switch (action) {
      case 'open':
        if (path != null) await FileActions.open(path);
      case 'reveal':
        if (path != null) await FileActions.revealInExplorer(path);
      case 'rename':
        if (path == null) return;
        final name = await _promptText(
            context, 'Rename file', 'New name (without extension)');
        if (name != null && name.isNotEmpty) {
          await FileActions.rename(path, name);
          onChanged();
        }
      case 'move':
        if (path == null) return;
        final dir = await FilePicker.platform.getDirectoryPath();
        if (dir != null) {
          await FileActions.move(path, dir);
          onChanged();
        }
      case 'copyPath':
        if (path != null) await FileActions.copyPath(path);
        if (context.mounted) showToast(context, 'Path copied to clipboard');
      case 'copyUrl':
        await FileActions.copyText(task.url);
        if (context.mounted) showToast(context, 'Source URL copied');
      case 'deleteFile':
        if (path == null) return;
        final ok = await _confirm(
            context, 'Delete file?', 'This permanently deletes the file.');
        if (ok) {
          await FileActions.delete(path);
          onChanged();
        }
      case 'removeRecord':
        await repo.delete(task.id);
        onChanged();
    }
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 18),
        const SizedBox(width: Spacing.sm),
        Text(label),
      ]);
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final TaskStatus status;
  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      TaskStatus.completed => (Palette.success, 'Done'),
      TaskStatus.failed => (Palette.danger, 'Failed'),
      TaskStatus.paused => (Palette.warning, 'Paused'),
      TaskStatus.canceled => (Theme.of(context).colorScheme.outline, 'Canceled'),
      _ => (context.accent, 'Pending'),
    };
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: Radii.pillRadius,
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

Future<bool> _confirm(BuildContext context, String title, String body) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm')),
      ],
    ),
  );
  return result ?? false;
}

Future<String?> _promptText(
    BuildContext context, String title, String hint) async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save')),
      ],
    ),
  );
}
