import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tokens.dart';
import '../../shared/widgets/common.dart';
import '../auth/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final t = Theme.of(context).textTheme;

    return ListView(
      padding: Spacing.pagePadding,
      children: [
        Entrance(child: Text('Profile', style: t.headlineLarge)),
        const SizedBox(height: Spacing.lg),
        Entrance(
          delay: const Duration(milliseconds: 80),
          child: GlassCard(
            highlight: true,
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(
              children: [
                _Avatar(url: user?.pictureUrl, initial: user?.initial ?? '?'),
                const SizedBox(height: Spacing.md),
                Text(user?.displayName ?? 'Not signed in',
                    style: t.headlineSmall),
                const SizedBox(height: 2),
                Text(user?.email ?? '',
                    style: t.bodyMedium?.copyWith(
                        color: context.scheme.onSurface
                            .withValues(alpha: 0.6))),
                const SizedBox(height: Spacing.lg),
                OutlinedButton.icon(
                  onPressed: () => _confirmSignOut(context, ref),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content:
            const Text('You will need to sign in again to use TubeVault.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.initial});
  final String? url;
  final String initial;

  @override
  Widget build(BuildContext context) {
    const size = 96.0;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: Shadows.glow(context.accent, strength: 0.8),
      ),
      child: ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: url != null
              ? CachedNetworkImage(
                  imageUrl: url!,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => _fallback(context),
                )
              : _fallback(context),
        ),
      ),
    );
  }

  Widget _fallback(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: context.accentGradient)),
        child: Center(
          child: Text(initial,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w700)),
        ),
      );
}
