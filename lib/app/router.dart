import 'package:flutter/material.dart';
import 'package:restaurant_pos/screens/login_screen.dart';
import 'package:restaurant_pos/screens/main_screen.dart';
import 'package:restaurant_pos/screens/splash_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
      case '/splash':
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case '/login':
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case '/main':
        return MaterialPageRoute(
          builder: (_) => const MainScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
    }
  }
}
