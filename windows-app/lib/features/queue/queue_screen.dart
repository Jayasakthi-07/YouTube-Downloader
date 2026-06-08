import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/models/app_enums.dart';
import '../../core/models/download_task.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/common.dart';
import '../download/download_queue.dart';

class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(downloadQueueProvider);
    final queue = ref.read(downloadQueueProvider.notifier);
    final t = Theme.of(context).textTheme;
    final active = tasks.where((x) => x.status.isActive).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              Spacing.lg, Spacing.lg, Spacing.lg, Spacing.sm),
          child: Entrance(
            child: Row(
              children: [
                Text('Queue', style: t.headlineLarge),
                const SizedBox(width: Spacing.sm),
                if (active > 0)
                  PillTag(
                      label: '$active active',
                      icon: Icons.bolt_rounded,
                      color: Palette.warning),
                const Spacer(),
                if (tasks.any((x) => x.status.isTerminal))
                  TextButton.icon(
                    onPressed: queue.clearFinished,
                    icon: const Icon(Icons.cleaning_services_outlined, size: 18),
                    label: const Text('Clear finished'),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: tasks.isEmpty
              ? const EmptyState(
                  icon: Icons.downloading_rounded,
                  title: 'Your queue is empty',
                  message:
                      'Downloads you start will appear here with live progress, '
                      'speed and ETA.',
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.lg, vertical: Spacing.xs),
                  itemCount: tasks.length,
                  buildDefaultDragHandles: false,
                  proxyDecorator: (child, index, anim) => child,
                  onReorderItem: queue.reorder,
                  itemBuilder: (context, i) => Padding(
                    key: ValueKey(tasks[i].id),
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: _TaskTile(task: tasks[i], index: i),
                  ),
                ),
        ),
      ],
    );
  }
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task, required this.index});
  final DownloadTask task;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.read(downloadQueueProvider.notifier);
    final t = Theme.of(context).textTheme;
    final p = task.progress;
    final showProgress = task.status == TaskStatus.downloading ||
        task.status == TaskStatus.paused;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusOrb(status: task.status, fraction: p.fraction),
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
                    Text('${_statusLabel(task.status)} · ${task.options.summary}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall),
                  ],
                ),
              ),
              _Controls(task: task, queue: queue),
              ReorderableDragStartListener(
                index: index,
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(Icons.drag_indicator_rounded,
                        size: 20,
                        color: context.scheme.onSurface
                            .withValues(alpha: 0.32)),
                  ),
                ),
              ),
            ],
          ),
          if (showProgress) ...[
            const SizedBox(height: Spacing.md),
            AnimatedBar(value: p.fraction > 0 ? p.fraction : null),
            const SizedBox(height: Spacing.xs),
            DefaultTextStyle(
              style: AppTheme.mono(context,
                  size: 12,
                  color: context.scheme.onSurface.withValues(alpha: 0.75)),
              child: Row(children: [
                Text(Fmt.percent(p.fraction),
                    style: AppTheme.mono(context, size: 12, color: context.accent)
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: Spacing.md),
                Text('${Fmt.bytes(p.downloadedBytes)} / ${Fmt.bytes(p.totalBytes)}'),
                const Spacer(),
                Icon(Icons.speed_rounded,
                    size: 14,
                    color: context.scheme.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Text(Fmt.speed(p.speedBytesPerSec)),
                const SizedBox(width: Spacing.md),
                Text('ETA ${Fmt.eta(p.etaSeconds)}'),
              ]),
            ),
          ],
          if (task.status == TaskStatus.failed && task.error != null) ...[
            const SizedBox(height: Spacing.xs),
            Text(task.error!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall?.copyWith(color: Palette.danger)),
          ],
        ],
      ),
    );
  }

  String _statusLabel(TaskStatus s) => switch (s) {
        TaskStatus.queued => 'Queued',
        TaskStatus.fetching => 'Fetching',
        TaskStatus.downloading => 'Downloading',
        TaskStatus.paused => 'Paused',
        TaskStatus.completed => 'Completed',
        TaskStatus.failed => 'Failed',
        TaskStatus.canceled => 'Canceled',
      };
}

class _Controls extends StatelessWidget {
  const _Controls({required this.task, required this.queue});
  final DownloadTask task;
  final DownloadQueue queue;

  @override
  Widget build(BuildContext context) {
    final b = <Widget>[];
    switch (task.status) {
      case TaskStatus.downloading:
        b.add(_btn(Icons.pause_rounded, 'Pause', () => queue.pause(task.id)));
        b.add(_btn(Icons.close_rounded, 'Cancel', () => queue.cancel(task.id)));
      case TaskStatus.paused:
        b.add(_btn(Icons.play_arrow_rounded, 'Resume',
            () => queue.resume(task.id)));
        b.add(_btn(Icons.close_rounded, 'Cancel', () => queue.cancel(task.id)));
      case TaskStatus.queued:
        b.add(_btn(Icons.close_rounded, 'Remove', () => queue.remove(task.id)));
      case TaskStatus.failed:
        b.add(_btn(Icons.refresh_rounded, 'Retry', () => queue.retry(task.id)));
        b.add(_btn(Icons.delete_outline_rounded, 'Remove',
            () => queue.remove(task.id)));
      case TaskStatus.completed:
      case TaskStatus.canceled:
        b.add(_btn(Icons.delete_outline_rounded, 'Remove',
            () => queue.remove(task.id)));
      case TaskStatus.fetching:
        break;
    }
    return Row(mainAxisSize: MainAxisSize.min, children: b);
  }

  Widget _btn(IconData icon, String tip, VoidCallback onTap) =>
      IconButton(icon: Icon(icon, size: 20), tooltip: tip, onPressed: onTap);
}

/// Circular status orb that doubles as a progress ring while downloading.
class _StatusOrb extends StatelessWidget {
  const _StatusOrb({required this.status, required this.fraction});
  final TaskStatus status;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      TaskStatus.completed => (Palette.success, Icons.check_rounded),
      TaskStatus.failed => (Palette.danger, Icons.priority_high_rounded),
      TaskStatus.downloading => (context.accent, Icons.arrow_downward_rounded),
      TaskStatus.paused => (Palette.warning, Icons.pause_rounded),
      TaskStatus.canceled => (
          context.scheme.onSurface.withValues(alpha: 0.5),
          Icons.block_rounded
        ),
      _ => (context.accent, Icons.schedule_rounded),
    };
    return SizedBox(
      width: 38,
      height: 38,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (status == TaskStatus.downloading)
            SizedBox(
              width: 38,
              height: 38,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
                duration: Motion.normal,
                builder: (_, v, _) => CircularProgressIndicator(
                  value: v > 0 ? v : null,
                  strokeWidth: 3,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.15),
                ),
              ),
            ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
        ],
      ),
    );
  }
}
