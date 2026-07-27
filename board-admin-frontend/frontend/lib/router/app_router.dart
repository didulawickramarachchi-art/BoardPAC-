import 'package:flutter/material.dart';

import '../features/auth/presentation/landing_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/verify_2fa_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';

class AppRouter {
  static const String landing = '/';
  static const String login = '/login';
  static const String verify2fa = '/verify-2fa';
  static const String dashboard = '/dashboard';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case landing:
        return MaterialPageRoute(builder: (_) => const LandingScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case verify2fa:
        return MaterialPageRoute(builder: (_) => const Verify2FAScreen());

      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());

      default:
        return MaterialPageRoute(builder: (_) => const LandingScreen());
    }
  }
}
