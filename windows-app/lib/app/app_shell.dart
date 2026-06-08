import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/settings_controller.dart';
import '../features/auth/auth_controller.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/download/download_queue.dart';
import '../features/download/home_screen.dart';
import '../features/files/history_screen.dart';
import '../features/playlist/playlist_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/queue/queue_screen.dart';
import '../features/settings/settings_screen.dart';
import '../l10n/app_localizations.dart';
import '../shared/widgets/common.dart';
import '../shared/widgets/window_caption.dart';
import 'theme/tokens.dart';

final navIndexProvider = StateProvider<int>((ref) => 0);

class _NavDest {
  const _NavDest(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

List<_NavDest> _buildDestinations(AppL10n l) => [
      _NavDest(Icons.space_dashboard_outlined, Icons.space_dashboard_rounded,
          l.navDashboard),
      _NavDest(Icons.add_circle_outline_rounded, Icons.add_circle_rounded,
          l.navDownload),
      _NavDest(Icons.downloading_outlined, Icons.downloading_rounded,
          l.navQueue),
      _NavDest(Icons.history_rounded, Icons.history_rounded, l.navHistory),
      _NavDest(Icons.playlist_play_outlined, Icons.playlist_play_rounded,
          l.navPlaylists),
      _NavDest(Icons.tune_outlined, Icons.tune_rounded, l.navSettings),
      _NavDest(Icons.person_outline_rounded, Icons.person_rounded,
          l.navProfile),
    ];

const _screens = [
  DashboardScreen(),
  HomeScreen(),
  QueueScreen(),
  HistoryScreen(),
  PlaylistScreen(),
  SettingsScreen(),
  ProfileScreen(),
];

const _tileHeight = 50.0;

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowLegal());
  }

  Future<void> _maybeShowLegal() async {
    final accepted = ref.read(settingsControllerProvider).acceptedLegalNotice;
    if (accepted || !mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.gavel_rounded, color: ctx.accent),
        title: const Text('Before you start'),
        content: const Text(
          'Please download only content you own or have permission to '
          'download, and respect the rights of content owners and YouTube\'s '
          'Terms of Service.\n\nTubeVault is a tool; how you use it is your '
          'responsibility.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              ref
                  .read(settingsControllerProvider.notifier)
                  .acceptLegalNotice();
              Navigator.pop(ctx);
            },
            child: const Text('I understand'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(navIndexProvider);
    return Scaffold(
      body: AuroraBackground(
        child: Column(
          children: [
            const WindowCaption(),
            Expanded(
              child: Row(
                children: [
                  _Sidebar(index: index),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: Motion.normal,
                      switchInCurve: Motion.standard,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0.015, 0),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(index),
                        child: _screens[index],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.index});
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinations = _buildDestinations(AppL10n.of(context));
    final activeCount = ref.watch(activeDownloadsProvider).length;

    return Container(
      width: 244,
      margin: const EdgeInsets.fromLTRB(Spacing.sm, 0, 0, Spacing.sm),
      child: ClipRRect(
        borderRadius: Radii.panelRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white
                  .withValues(alpha: context.isDark ? 0.04 : 0.6),
              borderRadius: Radii.panelRadius,
              border: Border.all(
                  color: context.scheme.onSurface.withValues(alpha: 0.06)),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: Spacing.sm, vertical: Spacing.md),
            child: Column(
              children: [
                Expanded(
                  child: SizedBox(
                    height: destinations.length * _tileHeight,
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          duration: Motion.normal,
                          curve: Motion.spring,
                          top: index * _tileHeight,
                          left: 0,
                          right: 0,
                          height: _tileHeight,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: Radii.fieldRadius,
                                gradient: LinearGradient(colors: [
                                  context.accent.withValues(alpha: 0.22),
                                  context.accent2.withValues(alpha: 0.10),
                                ]),
                                border: Border.all(
                                    color: context.accent
                                        .withValues(alpha: 0.30)),
                              ),
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            for (var i = 0; i < destinations.length; i++)
                              _NavTile(
                                dest: destinations[i],
                                selected: i == index,
                                badge:
                                    i == 2 && activeCount > 0 ? activeCount : null,
                                onTap: () => ref
                                    .read(navIndexProvider.notifier)
                                    .state = i,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const _ProfileChip(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.dest,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final _NavDest dest;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? context.accent
        : context.scheme.onSurface.withValues(alpha: 0.62);
    return SizedBox(
      height: _tileHeight,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
            child: Row(
              children: [
                Icon(selected ? dest.activeIcon : dest.icon,
                    size: 21, color: color),
                const SizedBox(width: Spacing.sm),
                Text(
                  dest.label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected ? context.scheme.onSurface : color,
                      ),
                ),
                const Spacer(),
                if (badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      gradient:
                          LinearGradient(colors: context.accentGradient),
                      borderRadius: Radii.pillRadius,
                    ),
                    child: Text('$badge',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileChip extends ConsumerWidget {
  const _ProfileChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    return HoverLift(
      onTap: () => ref.read(navIndexProvider.notifier).state = 6,
      child: Container(
        padding: const EdgeInsets.all(Spacing.xs),
        decoration: BoxDecoration(
          color: context.scheme.onSurface.withValues(alpha: 0.04),
          borderRadius: Radii.fieldRadius,
          border: Border.all(
              color: context.scheme.onSurface.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            ClipOval(
              child: SizedBox(
                width: 34,
                height: 34,
                child: user?.pictureUrl != null
                    ? CachedNetworkImage(
                        imageUrl: user!.pictureUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => _avatarFallback(context, user.initial),
                      )
                    : _avatarFallback(context, user?.initial ?? '?'),
              ),
            ),
            const SizedBox(width: Spacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.displayName ?? 'Guest',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Text(user?.email ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18,
                color: context.scheme.onSurface.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(BuildContext context, String initial) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: context.accentGradient),
        ),
        child: Center(
          child: Text(initial,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      );
}
