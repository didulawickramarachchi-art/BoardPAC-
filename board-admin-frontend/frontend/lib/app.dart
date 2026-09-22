import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/responsive/responsive_layout.dart';
import 'features/auth/presentation/landing_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/reset_password_screen.dart';
import 'features/auth/presentation/verify_2fa_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';

class BoardAdminApp extends ConsumerWidget {
  const BoardAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Board Admin',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.watch(themeModeProvider),
      builder: (context, child) =>
          ResponsiveAppViewport(child: child ?? const SizedBox.shrink()),
      initialRoute: '/',
      routes: {
        '/': (_) => const LandingScreen(),
        '/login': (_) => const LoginScreen(),
        '/verify-2fa': (_) => const Verify2FAScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/reset-password': (_) => ResetPasswordScreen(
          token:
              Uri.base.queryParameters['token'] ??
              Uri.tryParse(Uri.base.fragment)?.queryParameters['token'] ??
              '',
        ),
      },
      onGenerateRoute: (settings) {
        final uri = Uri.tryParse(settings.name ?? '');
        if (uri?.path == '/reset-password') {
          return MaterialPageRoute<void>(
            builder: (_) =>
                ResetPasswordScreen(token: uri?.queryParameters['token'] ?? ''),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
