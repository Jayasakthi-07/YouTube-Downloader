import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_shell.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/db/history_repository.dart';
import '../../core/models/app_enums.dart';
import '../../core/models/download_task.dart';
import '../../shared/providers.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/common.dart';
import '../auth/auth_controller.dart';
import '../download/download_queue.dart';
import '../download/options_controller.dart';
import '../download/presets.dart';
import '../files/file_actions.dart';

class DashboardData {
  DashboardData(
      {required this.total,
      required this.completed,
      required this.storageBytes,
      required this.recent});
  final int total;
  final int completed;
  final int storageBytes;
  final List<DownloadTask> recent;
}

final dashboardDataProvider =
    FutureProvider.autoDispose<DashboardData>((ref) async {
  ref.watch(downloadQueueProvider); // refresh when the queue changes
  final repo = ref.read(historyRepositoryProvider);
  final all = await repo.query(sort: HistorySort.dateDesc);
  final completed =
      all.where((t) => t.status == TaskStatus.completed).toList();
  final storage =
      completed.fold<int>(0, (s, t) => s + (t.fileSizeBytes ?? 0));
  return DashboardData(
    total: all.length,
    completed: completed.length,
    storageBytes: storage,
    recent: completed.take(6).toList(),
  );
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardDataProvider);
    final active = ref.watch(activeDownloadsProvider).length;
    final user = ref.watch(authControllerProvider).user;
    final t = Theme.of(context).textTheme;

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';
    final name = user?.name?.split(' ').first ?? '';

    return ListView(
      padding: Spacing.pagePadding,
      children: [
        Entrance(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$greeting${name.isEmpty ? '' : ', $name'}',
                        style: t.headlineLarge),
                    const SizedBox(height: 4),
                    Text('Your download library at a glance.',
                        style: t.bodyLarge?.copyWith(
                            color: context.scheme.onSurface
                                .withValues(alpha: 0.6))),
                  ],
                ),
              ),
              GradientButton(
                label: 'New download',
                icon: Icons.add_rounded,
                onPressed: () =>
                    ref.read(navIndexProvider.notifier).state = 1,
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),

        // Stats
        data.when(
          loading: () => const _StatsSkeleton(),
          error: (e, _) => Text('$e'),
          data: (d) => Entrance(
            delay: const Duration(milliseconds: 80),
            child: Row(
              children: [
                _StatTile(
                    icon: Icons.download_done_rounded,
                    value: d.completed,
                    label: 'Completed',
                    color: Palette.success),
                const SizedBox(width: Spacing.md),
                _StatTile(
                    icon: Icons.playlist_add_check_rounded,
                    value: d.total,
                    label: 'Total items',
                    color: context.accent),
                const SizedBox(width: Spacing.md),
                _StatTile(
                    icon: Icons.bolt_rounded,
                    value: active,
                    label: 'Active now',
                    color: Palette.warning),
                const SizedBox(width: Spacing.md),
                _StorageTile(bytes: d.storageBytes),
              ],
            ),
          ),
        ),
        const SizedBox(height: Spacing.lg),

        // Quick presets
        Entrance(
          delay: const Duration(milliseconds: 160),
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader('Quick start',
                    icon: Icons.flash_on_rounded),
                Wrap(
                  spacing: Spacing.sm,
                  runSpacing: Spacing.sm,
                  children: [
                    for (final p in DownloadPreset.all)
                      _PresetChip(
                        preset: p,
                        onTap: () {
                          ref
                              .read(optionsControllerProvider.notifier)
                              .applyPreset(p.build);
                          ref.read(navIndexProvider.notifier).state = 1;
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Spacing.lg),

        // Recent
        Entrance(
          delay: const Duration(milliseconds: 240),
          child: SectionHeader(
            'Recent downloads',
            icon: Icons.history_rounded,
            trailing: TextButton(
              onPressed: () => ref.read(navIndexProvider.notifier).state = 3,
              child: const Text('View all'),
            ),
          ),
        ),
        data.maybeWhen(
          data: (d) => d.recent.isEmpty
              ? const Padding(
                  padding: EdgeInsets.only(top: Spacing.xl),
                  child: EmptyState(
                    icon: Icons.movie_filter_outlined,
                    title: 'Nothing downloaded yet',
                    message:
                        'Your finished downloads will show up here for quick access.',
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < d.recent.length; i++)
                      Entrance(
                        delay: Duration(milliseconds: 280 + i * 50),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.sm),
                          child: _RecentTile(task: d.recent[i]),
                        ),
                      ),
                  ],
                ),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: Radii.fieldRadius,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: Spacing.md),
            AnimatedCount(value,
                style: AppTheme.mono(context, size: 28)
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label, style: t.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _StorageTile extends StatelessWidget {
  const _StorageTile({required this.bytes});
  final int bytes;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: context.accent2.withValues(alpha: 0.16),
                borderRadius: Radii.fieldRadius,
              ),
              child: Icon(Icons.sd_storage_rounded,
                  color: context.accent2, size: 20),
            ),
            const SizedBox(height: Spacing.md),
            Text(Fmt.bytes(bytes),
                style: AppTheme.mono(context, size: 28)
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('Storage used', style: t.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.preset, required this.onTap});
  final DownloadPreset preset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HoverLift(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md, vertical: Spacing.sm),
        decoration: BoxDecoration(
          color: context.scheme.onSurface.withValues(alpha: 0.04),
          borderRadius: Radii.fieldRadius,
          border: Border.all(
              color: context.scheme.onSurface.withValues(alpha: 0.08)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(preset.icon, size: 18, color: context.accent),
          const SizedBox(width: Spacing.xs),
          Text(preset.label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.task});
  final DownloadTask task;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final exists = task.filePath != null && File(task.filePath!).existsSync();
    return GlassCard(
      padding: const EdgeInsets.all(Spacing.sm),
      onTap: exists ? () => FileActions.open(task.filePath!) : null,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radii.xs),
            child: SizedBox(
              width: 92,
              height: 52,
              child: task.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: task.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          const Icon(Icons.movie_outlined))
                  : ColoredBox(
                      color: context.scheme.onSurface
                          .withValues(alpha: 0.05)),
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
                Text('${task.options.summary} · ${Fmt.bytes(task.fileSizeBytes)}',
                    style: t.bodySmall),
              ],
            ),
          ),
          Icon(
            exists ? Icons.play_circle_outline_rounded : Icons.link_off_rounded,
            color: context.scheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(width: Spacing.xs),
        ],
      ),
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          const Expanded(
              child: GlassCard(
                  padding: EdgeInsets.all(Spacing.md),
                  child: SizedBox(
                    height: 92,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 38, height: 38, radius: 12),
                        SizedBox(height: 12),
                        SkeletonBox(width: 70, height: 22),
                      ],
                    ),
                  ))),
          if (i < 3) const SizedBox(width: Spacing.md),
        ],
      ],
    );
  }
}
