import 'package:flutter/material.dart';

import '../admin/screens/admin_dashboard_screen.dart';
import '../admin/screens/admin_login_screen.dart';
import '../motorista/models/driver_assignment.dart';
import '../motorista/screens/motorista_login_screen.dart';
import '../motorista/screens/motorista_operation_screen.dart';
import '../motorista/screens/motorista_queue_screen.dart';
import '../motorista/services/motorista_services.dart';
import 'screens/welcome_screen.dart';
import 'route_names.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic>? onGenerateRoute(
      RouteSettings settings, MotoristaServices services) {
    final args = settings.arguments;
    final Widget? page = switch (settings.name) {
      AppRoutes.welcome => const WelcomeScreen(),
      AppRoutes.login => MotoristaLoginScreen(services: services),
      AppRoutes.queue =>
        MotoristaQueueScreen(services: services, assignment: args as DriverAssignment),
      AppRoutes.operation =>
        MotoristaOperationScreen(services: services, assignment: args as DriverAssignment),
      AppRoutes.adminLogin => const AdminLoginScreen(),
      AppRoutes.adminDashboard => const AdminDashboardScreen(),
      _ => null,
    };
    if (page == null) return null;
    return PageRouteBuilder<void>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}
