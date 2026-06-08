import 'package:flutter/material.dart';

import 'tokens.dart';

/// Builds the TubeVault "Aurora Glass" themes. The [accent] is user-selectable
/// and flows into the color scheme, gradients and glows across the app.
abstract final class AppTheme {
  static ThemeData dark(Color accent) => _build(Brightness.dark, accent);
  static ThemeData light(Color accent) => _build(Brightness.light, accent);

  /// Monospace style for numeric/technical readouts (tabular figures).
  static TextStyle mono(BuildContext context, {double? size, Color? color}) =>
      TextStyle(
        fontFamily: Fonts.mono,
        fontSize: size,
        color: color,
        height: 1.1,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static ThemeData _build(Brightness brightness, Color accent) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(
      primary: accent,
      secondary: Accents.gradientPartner(accent),
      surface: isDark ? Palette.darkSurface : Palette.lightSurface,
      surfaceContainerHighest:
          isDark ? Palette.darkSurfaceHi : Palette.lightSurfaceHi,
      onSurface: isDark ? Palette.darkText : Palette.lightText,
      error: Palette.danger,
      outline: isDark ? Palette.darkBorder : Palette.lightBorder,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: Fonts.sans,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: isDark ? Palette.darkBg : Palette.lightBg,
      splashFactory: NoSplash.splashFactory,
      visualDensity: VisualDensity.standard,
    );

    final dim = isDark ? Palette.darkTextDim : Palette.lightTextDim;
    final tt = base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final textTheme = tt.copyWith(
      displaySmall: tt.displaySmall?.copyWith(
          fontWeight: FontWeight.w700, letterSpacing: -1.0),
      headlineLarge: tt.headlineLarge
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.8),
      headlineMedium: tt.headlineMedium
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.6),
      headlineSmall: tt.headlineSmall
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4),
      titleLarge: tt.titleLarge
          ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.3),
      titleMedium: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: tt.labelLarge
          ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0),
      bodySmall: tt.bodySmall?.copyWith(color: dim),
    );

    final cursor = WidgetStateProperty.all(SystemMouseCursors.click);

    return base.copyWith(
      textTheme: textTheme,
      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: scheme.onSurface.withValues(alpha: 0.9)),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg, vertical: Spacing.md),
          shape: const RoundedRectangleBorder(borderRadius: Radii.fieldRadius),
          textStyle: textTheme.labelLarge,
        ).copyWith(mouseCursor: cursor),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md, vertical: Spacing.sm + 2),
          shape: const RoundedRectangleBorder(borderRadius: Radii.fieldRadius),
          side: BorderSide(color: scheme.outline),
        ).copyWith(mouseCursor: cursor),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent)
            .copyWith(mouseCursor: cursor),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom().copyWith(mouseCursor: cursor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Palette.lightSurfaceHi,
        hintStyle: TextStyle(color: dim),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: Spacing.md, vertical: Spacing.md),
        border: const OutlineInputBorder(
          borderRadius: Radii.fieldRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Radii.fieldRadius,
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Radii.fieldRadius,
          borderSide: BorderSide(color: accent, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: Radii.pillRadius),
        side: BorderSide(color: scheme.outline),
        backgroundColor: Colors.transparent,
        selectedColor: accent.withValues(alpha: 0.16),
        showCheckmark: false,
        labelStyle: textTheme.labelLarge,
        padding:
            const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 8),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? Palette.darkSurfaceHi : Palette.lightSurface,
        contentTextStyle: textTheme.bodyMedium,
        shape: const RoundedRectangleBorder(borderRadius: Radii.fieldRadius),
        elevation: 12,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? Palette.darkSurfaceHi : Palette.lightSurface,
        shape: const RoundedRectangleBorder(borderRadius: Radii.panelRadius),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? Palette.darkSurfaceHi : Colors.black87,
          borderRadius: const BorderRadius.all(Radii.xs),
          border: Border.all(color: scheme.outline),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: scheme.onSurface),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: scheme.onSurface.withValues(alpha: 0.10),
        borderRadius: const BorderRadius.all(Radii.pill),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
            scheme.onSurface.withValues(alpha: 0.18)),
        radius: const Radius.circular(8),
        thickness: WidgetStateProperty.all(6),
      ),
    );
  }
}
