import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../app/theme/tokens.dart';
import 'common.dart';

/// Custom frameless title bar: draggable region + window controls.
class WindowCaption extends StatelessWidget {
  const WindowCaption({super.key, this.title = 'TubeVault', this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: DragToMoveArea(
              child: Padding(
                padding: const EdgeInsets.only(left: Spacing.lg),
                child: Row(
                  children: [
                    const AppLogo(size: 22),
                    const SizedBox(width: Spacing.xs),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          letterSpacing: 0.3,
                          color: context.scheme.onSurface
                              .withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ?trailing,
          const _WindowButtons(),
        ],
      ),
    );
  }
}

class _WindowButtons extends StatelessWidget {
  const _WindowButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CaptionBtn(
          icon: Icons.remove_rounded,
          onTap: () => windowManager.minimize(),
        ),
        _CaptionBtn(
          icon: Icons.crop_square_rounded,
          iconSize: 15,
          onTap: () async => await windowManager.isMaximized()
              ? windowManager.unmaximize()
              : windowManager.maximize(),
        ),
        _CaptionBtn(
          icon: Icons.close_rounded,
          hoverColor: Palette.danger,
          onTap: () => windowManager.close(),
        ),
      ],
    );
  }
}

class _CaptionBtn extends StatefulWidget {
  const _CaptionBtn({
    required this.icon,
    required this.onTap,
    this.hoverColor,
    this.iconSize = 18,
  });
  final IconData icon;
  final VoidCallback onTap;
  final Color? hoverColor;
  final double iconSize;

  @override
  State<_CaptionBtn> createState() => _CaptionBtnState();
}

class _CaptionBtnState extends State<_CaptionBtn> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final isClose = widget.hoverColor != null;
    final bg = _hover
        ? (isClose
            ? widget.hoverColor!
            : context.scheme.onSurface.withValues(alpha: 0.08))
        : Colors.transparent;
    final fg = _hover && isClose
        ? Colors.white
        : context.scheme.onSurface.withValues(alpha: 0.7);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Motion.fast,
          width: 46,
          height: 44,
          color: bg,
          child: Icon(widget.icon, size: widget.iconSize, color: fg),
        ),
      ),
    );
  }
}
