import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/verify_2fa_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';

class BoardAdminApp extends StatelessWidget {
  const BoardAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Board Admin',
      theme: AppTheme.lightTheme.copyWith(
        textTheme: GoogleFonts.interTextTheme(),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const LoginScreen(),
        '/verify-2fa': (_) => const Verify2FAScreen(),
        '/dashboard': (_) => const DashboardScreen(),
      },
    );
  }
}
