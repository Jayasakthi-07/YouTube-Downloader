import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// ============================================================================
/// TubeVault "Aurora Glass" design-system widgets.
/// ============================================================================

extension AccentX on BuildContext {
  Color get accent => Theme.of(this).colorScheme.primary;
  Color get accent2 => Theme.of(this).colorScheme.secondary;
  ColorScheme get scheme => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  List<Color> get accentGradient => [accent, accent2];
}

/// Animated aurora background: drifting blurred color blobs over the canvas.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key, required this.child, this.intensity = 1});
  final Widget child;
  final double intensity;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 18))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final base = dark ? Palette.darkBg : Palette.lightBg;
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: base)),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) => CustomPaint(
              painter: _AuroraPainter(
                t: _c.value,
                intensity: widget.intensity * (dark ? 1 : 0.5),
                colors: [
                  context.accent,
                  Palette.auroraViolet,
                  Palette.auroraCyan,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(
      {required this.t, required this.intensity, required this.colors});
  final double t;
  final double intensity;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final tau = 6.28318;
    final blobs = [
      (Offset(0.18 + 0.04 * _s(t), 0.12 + 0.03 * _c2(t)), 0.55, colors[0]),
      (Offset(0.86 + 0.03 * _c2(t), 0.20 + 0.04 * _s(t)), 0.48, colors[1]),
      (Offset(0.72 + 0.04 * _s(t * 1.3), 0.92 + 0.03 * _c2(t)), 0.5, colors[2]),
    ];
    for (final (pos, r, color) in blobs) {
      final center = Offset(pos.dx * size.width, pos.dy * size.height);
      final radius = r * size.shortestSide;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.32 * intensity),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
      canvas.drawCircle(center, radius, paint);
    }
    // ignore: unused_local_variable
    final _ = tau;
  }

  double _s(double v) => (v * 6.28318).abs();
  double _c2(double v) => 1 - v;

  @override
  bool shouldRepaint(_AuroraPainter old) => old.t != t;
}

/// Frosted glass surface with a hairline gradient border and soft shadow.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = Spacing.cardPadding,
    this.radius = Radii.cardRadius,
    this.onTap,
    this.blur = 18,
    this.glow,
    this.highlight = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius radius;
  final VoidCallback? onTap;
  final double blur;
  final Color? glow;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final fill = dark
        ? Colors.white.withValues(alpha: highlight ? 0.07 : 0.045)
        : Colors.white.withValues(alpha: highlight ? 0.9 : 0.72);
    final borderColors = dark
        ? [
            Colors.white.withValues(alpha: highlight ? 0.22 : 0.12),
            Colors.white.withValues(alpha: 0.02),
          ]
        : [
            Colors.white.withValues(alpha: 0.9),
            context.scheme.outline.withValues(alpha: 0.4),
          ];

    Widget content = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(color: fill, borderRadius: radius),
          padding: padding,
          child: child,
        ),
      ),
    );

    content = Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: borderColors,
        ),
        boxShadow: glow != null
            ? Shadows.glow(glow!)
            : Shadows.soft(context.accent),
      ),
      padding: const EdgeInsets.all(1),
      child: content,
    );

    if (onTap == null) return content;
    return HoverLift(onTap: onTap, child: content);
  }
}

/// Backwards-compatible alias used widely across screens.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = Spacing.cardPadding,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) =>
      GlassCard(padding: padding, child: child);
}

/// Hover/press micro-interaction: lifts and brightens slightly on hover.
class HoverLift extends StatefulWidget {
  const HoverLift({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 1.012,
    this.lift = 2,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final double lift;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final scale = _down ? 0.985 : (_hover ? widget.scale : 1.0);
    final dy = _hover && !_down ? -widget.lift : 0.0;
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: Motion.fast,
          curve: Motion.spring,
          child: AnimatedSlide(
            offset: Offset(0, dy / 100),
            duration: Motion.fast,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Staggered entrance: fade + slide-up on mount, with optional [delay].
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offsetY = 16,
  });
  final Widget child;
  final Duration delay;
  final double offsetY;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: Motion.slow);
  late final Animation<double> _a =
      CurvedAnimation(parent: _c, curve: Motion.standard);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _a.value) * widget.offsetY),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Gradient-filled primary action with glow + spring press.
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.expand = false,
  });
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expand;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final scale = _down ? 0.97 : (_hover ? 1.02 : 1.0);
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: () => setState(() => _down = false),
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: scale,
          duration: Motion.fast,
          curve: Motion.spring,
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.5,
            duration: Motion.fast,
            child: Container(
              width: widget.expand ? double.infinity : null,
              padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: Radii.fieldRadius,
                gradient: LinearGradient(colors: context.accentGradient),
                boxShadow: enabled && _hover
                    ? Shadows.glow(context.accent, strength: 1.1)
                    : Shadows.glow(context.accent, strength: 0.5),
              ),
              child: Row(
                mainAxisSize:
                    widget.expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  else if (widget.icon != null)
                    Icon(widget.icon, size: 19, color: Colors.white),
                  if (widget.icon != null || widget.loading)
                    const SizedBox(width: Spacing.xs),
                  Text(
                    widget.label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gradient-shaded text (for hero numerals / wordmarks).
class GradientText extends StatelessWidget {
  const GradientText(this.text, {super.key, this.style, this.colors});
  final String text;
  final TextStyle? style;
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: colors ?? context.accentGradient,
      ).createShader(bounds),
      child: Text(text,
          style: (style ?? const TextStyle()).copyWith(color: Colors.white)),
    );
  }
}

/// Brand logo mark: gradient rounded square with a play glyph + glow.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: context.accentGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: Shadows.glow(context.accent, strength: 0.9),
      ),
      child: Icon(Icons.play_arrow_rounded,
          color: Colors.white, size: size * 0.6),
    );
  }
}

/// Section heading with optional accent icon + trailing widget.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.icon});
  final String title;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: context.accent),
            const SizedBox(width: Spacing.xs),
          ],
          Text(title, style: t.titleMedium),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

/// A compact status/info pill with an icon.
class PillTag extends StatelessWidget {
  const PillTag(
      {super.key, required this.label, this.icon, this.color, this.filled = true});
  final String label;
  final IconData? icon;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? c.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: Radii.pillRadius,
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 5),
        ],
        Text(label,
            style: TextStyle(
                color: c, fontSize: 11.5, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// Animated integer counter (used in stat tiles).
class AnimatedCount extends StatelessWidget {
  const AnimatedCount(this.value, {super.key, this.style, this.suffix = ''});
  final int value;
  final TextStyle? style;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: Motion.slower,
      curve: Motion.standard,
      builder: (_, v, _) => Text('${v.round()}$suffix', style: style),
    );
  }
}

/// Gradient progress bar with glow; indeterminate when [value] is null.
class AnimatedBar extends StatelessWidget {
  const AnimatedBar({super.key, this.value, this.height = 8});
  final double? value;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(
            height: height,
            color: context.scheme.onSurface.withValues(alpha: 0.08),
          ),
          if (value == null)
            SizedBox(
              height: height,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                color: context.accent,
              ),
            )
          else
            LayoutBuilder(
              builder: (_, c) => TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value!.clamp(0.0, 1.0)),
                duration: Motion.normal,
                curve: Motion.standard,
                builder: (_, v, _) => Container(
                  height: height,
                  width: c.maxWidth * v,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: context.accentGradient),
                    borderRadius: BorderRadius.circular(height),
                    boxShadow: Shadows.glow(context.accent, strength: 0.7),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Shimmering skeleton placeholder.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox(
      {super.key, this.width = double.infinity, this.height = 16, this.radius = 8});
  final double width;
  final double height;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1300))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.scheme.onSurface.withValues(alpha: 0.06);
    final hi = context.scheme.onSurface.withValues(alpha: 0.14);
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final x = _c.value * 2 - 1;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(x - 0.6, 0),
                end: Alignment(x + 0.6, 0),
                colors: [base, hi, base],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Friendly empty state with a glass orb icon.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Entrance(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    context.accent.withValues(alpha: 0.22),
                    context.accent.withValues(alpha: 0.0),
                  ]),
                ),
                child: Icon(icon, size: 44, color: context.accent),
              ),
              const SizedBox(height: Spacing.md),
              Text(title, textAlign: TextAlign.center, style: t.titleLarge),
              if (message != null) ...[
                const SizedBox(height: Spacing.xs),
                Text(message!,
                    textAlign: TextAlign.center, style: t.bodyMedium),
              ],
              if (action != null) ...[
                const SizedBox(height: Spacing.lg),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating glass toast.
void showToast(BuildContext context, String message, {bool error = false}) {
  final color = error ? Palette.danger : Palette.success;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      width: 420,
      content: Row(children: [
        Icon(error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: color, size: 20),
        const SizedBox(width: Spacing.sm),
        Expanded(child: Text(message)),
      ]),
      duration: const Duration(seconds: 3),
    ));
}
