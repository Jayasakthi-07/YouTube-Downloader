import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/settings_controller.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/sign_in_screen.dart';
import '../l10n/app_localizations.dart';
import '../shared/widgets/common.dart';
import '../shared/widgets/window_caption.dart';
import 'app_shell.dart';
import 'theme/app_theme.dart';

/// Root widget: applies the theme and gates content behind Google Sign-In.
class TubeVaultApp extends ConsumerWidget {
  const TubeVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(
        settingsControllerProvider.select((s) => s.themeMode));
    final languageCode = ref.watch(
        settingsControllerProvider.select((s) => s.languageCode));
    final accent = Color(ref.watch(
        settingsControllerProvider.select((s) => s.accentColor)));

    return MaterialApp(
      title: 'TubeVault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(accent),
      darkTheme: AppTheme.dark(accent),
      themeMode: themeMode,
      locale: Locale(languageCode),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    final Widget child = switch (auth.status) {
      AuthStatus.signedIn => const AppShell(),
      AuthStatus.unknown => const _SplashScreen(),
      _ => const SignInScreen(),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      child: child,
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        child: Column(
          children: [
            const WindowCaption(),
            const Expanded(
              child: Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
