import 'package:flutter/material.dart';

import '../motorista/models/driver_assignment.dart';
import '../motorista/screens/login_screen.dart';
import '../motorista/screens/operation_screen.dart';
import '../motorista/screens/queue_screen.dart';
import '../motorista/services/motorista_services.dart';
import 'route_names.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic>? onGenerateRoute(RouteSettings settings, MotoristaServices services) {
    final args = settings.arguments;
    final Widget? page = switch (settings.name) {
      AppRoutes.login => LoginScreen(services: services),
      AppRoutes.queue => QueueScreen(services: services, assignment: args as DriverAssignment),
      AppRoutes.operation => OperationScreen(services: services, assignment: args as DriverAssignment),
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
