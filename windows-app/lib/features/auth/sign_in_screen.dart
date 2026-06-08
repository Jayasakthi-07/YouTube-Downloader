import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/window_caption.dart';
import 'auth_controller.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final configured = ref.watch(authConfiguredProvider);
    final t = Theme.of(context).textTheme;
    final l = AppL10n.of(context);
    final signingIn = auth.status == AuthStatus.signingIn;

    return Scaffold(
      body: AuroraBackground(
        intensity: 1.3,
        child: Column(
          children: [
            const WindowCaption(),
            Expanded(
              child: Center(
                child: Entrance(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: GlassCard(
                      padding: const EdgeInsets.all(Spacing.xl),
                      highlight: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: _PulseLogo()),
                          const SizedBox(height: Spacing.lg),
                          Center(
                            child: GradientText(
                              'TubeVault',
                              style: t.headlineMedium,
                            ),
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            l.signInSubtitle,
                            textAlign: TextAlign.center,
                            style: t.bodyMedium?.copyWith(
                                color: context.scheme.onSurface
                                    .withValues(alpha: 0.65)),
                          ),
                          const SizedBox(height: Spacing.xl),
                          GradientButton(
                            label: signingIn ? l.signInWaiting : l.signInButton,
                            icon: signingIn ? null : Icons.login_rounded,
                            loading: signingIn,
                            expand: true,
                            onPressed: (!configured || signingIn)
                                ? null
                                : () => ref
                                    .read(authControllerProvider.notifier)
                                    .signIn(),
                          ),
                          if (!configured) ...[
                            const SizedBox(height: Spacing.md),
                            const _ConfigHint(),
                          ],
                          if (auth.error != null) ...[
                            const SizedBox(height: Spacing.md),
                            Text(auth.error!,
                                textAlign: TextAlign.center,
                                style: t.bodySmall
                                    ?.copyWith(color: Palette.danger)),
                          ],
                          const SizedBox(height: Spacing.md),
                          Text(
                            'Your downloads stay on this device. We respect '
                            'content owners — download only what you may.',
                            textAlign: TextAlign.center,
                            style: t.bodySmall?.copyWith(
                                color: context.scheme.onSurface
                                    .withValues(alpha: 0.4)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseLogo extends StatefulWidget {
  const _PulseLogo();
  @override
  State<_PulseLogo> createState() => _PulseLogoState();
}

class _PulseLogoState extends State<_PulseLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(seconds: 3))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final glow = 0.6 + _c.value * 0.6;
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: Shadows.glow(context.accent, strength: glow),
          ),
          child: child,
        );
      },
      child: const AppLogo(size: 76),
    );
  }
}

class _ConfigHint extends StatelessWidget {
  const _ConfigHint();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: Palette.warning.withValues(alpha: 0.12),
        borderRadius: Radii.fieldRadius,
        border: Border.all(color: Palette.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: Palette.warning),
          const SizedBox(width: Spacing.xs),
          Expanded(
            child: Text(
              'Add your Google Client ID & Secret to config/secrets.json to enable sign-in.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
