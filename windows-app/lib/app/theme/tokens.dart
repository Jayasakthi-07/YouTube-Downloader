import 'package:flutter/widgets.dart';

/// Design tokens for the TubeVault "Aurora Glass" design system — a dark-first,
/// luxury aesthetic: deep graphite canvas, frosted glass surfaces, hairline
/// gradient borders, aurora glows and a user-selectable accent.

abstract final class Spacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 72;

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(lg, lg, lg, lg);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
}

abstract final class Radii {
  static const Radius xs = Radius.circular(10);
  static const Radius sm = Radius.circular(14);
  static const Radius md = Radius.circular(20);
  static const Radius lg = Radius.circular(26);
  static const Radius xl = Radius.circular(34);
  static const Radius pill = Radius.circular(999);

  static const BorderRadius cardRadius = BorderRadius.all(md);
  static const BorderRadius panelRadius = BorderRadius.all(lg);
  static const BorderRadius fieldRadius = BorderRadius.all(sm);
  static const BorderRadius pillRadius = BorderRadius.all(pill);
}

abstract final class Motion {
  static const Duration instant = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 480);
  static const Duration slower = Duration(milliseconds: 720);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1); // gentle overshoot
}

abstract final class Fonts {
  static const String sans = 'Inter';
  static const String mono = 'JetBrains Mono';
}

/// Neutral palette + status colors. The accent is supplied at runtime from
/// settings (see [Accents]); [Palette.fallbackAccent] is only a default.
abstract final class Palette {
  static const Color fallbackAccent = Color(0xFF5B7CFF);

  static const Color success = Color(0xFF2BD4A0);
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFFF5C72);

  // Dark canvas (near-black with a cool tint)
  static const Color darkBg = Color(0xFF090A0F);
  static const Color darkBgAlt = Color(0xFF0C0E14);
  static const Color darkSurface = Color(0xFF13151D);
  static const Color darkSurfaceHi = Color(0xFF1B1E28);
  static const Color darkBorder = Color(0xFF262A36);
  static const Color darkText = Color(0xFFEDEFF5);
  static const Color darkTextDim = Color(0xFF9AA0AE);

  // Light canvas
  static const Color lightBg = Color(0xFFF3F4F9);
  static const Color lightBgAlt = Color(0xFFEDEFF6);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceHi = Color(0xFFF1F3F9);
  static const Color lightBorder = Color(0xFFE2E5EE);
  static const Color lightText = Color(0xFF11131A);
  static const Color lightTextDim = Color(0xFF61677A);

  // Aurora glow hues used in the animated background
  static const Color auroraViolet = Color(0xFF7C5CFF);
  static const Color auroraBlue = Color(0xFF4F8CFF);
  static const Color auroraCyan = Color(0xFF22D3EE);
  static const Color auroraPink = Color(0xFFFF6BD6);
}

/// Selectable accent presets for the Settings accent picker.
abstract final class Accents {
  static const List<({String name, int argb})> presets = [
    (name: 'Cobalt', argb: 0xFF5B7CFF),
    (name: 'Violet', argb: 0xFF8B5CF6),
    (name: 'Cyan', argb: 0xFF22D3EE),
    (name: 'Emerald', argb: 0xFF2BD4A0),
    (name: 'Rose', argb: 0xFFFF5C8A),
    (name: 'Amber', argb: 0xFFFF9F0A),
    (name: 'Crimson', argb: 0xFFFF4D4D),
  ];

  /// A complementary "to" color for accent gradients (slightly hue-shifted).
  static Color gradientPartner(Color accent) {
    final hsl = HSLColor.fromColor(accent);
    return hsl
        .withHue((hsl.hue + 28) % 360)
        .withSaturation((hsl.saturation + 0.05).clamp(0.0, 1.0))
        .toColor();
  }
}

/// Soft layered shadows for elevated glass surfaces.
abstract final class Shadows {
  static List<BoxShadow> soft(Color tint) => [
        BoxShadow(
          color: const Color(0xFF000000).withValues(alpha: 0.28),
          blurRadius: 28,
          spreadRadius: -6,
          offset: const Offset(0, 14),
        ),
        BoxShadow(
          color: tint.withValues(alpha: 0.10),
          blurRadius: 40,
          spreadRadius: -10,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> glow(Color color, {double strength = 0.5}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.40 * strength),
          blurRadius: 24,
          spreadRadius: -2,
          offset: const Offset(0, 6),
        ),
      ];
}
