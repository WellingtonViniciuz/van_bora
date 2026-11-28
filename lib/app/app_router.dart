import 'package:flutter/material.dart';

import '../admin/screens/admin_dashboard_screen.dart';
import '../admin/screens/admin_login_screen.dart';
import '../motorista/models/driver_assignment.dart';
import '../motorista/screens/motorista_login_screen.dart';
import '../motorista/screens/motorista_operation_screen.dart';
import '../motorista/screens/motorista_queue_screen.dart';
import '../motorista/services/motorista_services.dart';
import '../passageiro/screens/passenger_home_screen.dart';
import '../passageiro/screens/route_details_screen.dart';
import '../passageiro/screens/van_details_screen.dart';
import '../passageiro/screens/van_tracking_screen.dart';
import '../passageiro/services/passageiro_services.dart';
import 'screens/welcome_screen.dart';
import 'route_names.dart';

class AppRouter {
  AppRouter._();

  /// Serviços do passageiro, criados na primeira vez que o módulo é aberto.
  /// Reaproveitam o monitor de conexão do motorista.
  static PassageiroServices? _passageiro;

  static PassageiroServices _passageiroServices(MotoristaServices services) =>
      _passageiro ??= PassageiroServices.create(connectivity: services.connectivity);

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
      AppRoutes.passengerHome => PassengerHomeScreen(services: _passageiroServices(services)),
      AppRoutes.passengerVan =>
        VanDetailsScreen(services: _passageiroServices(services), vanId: args as String),
      AppRoutes.passengerRoute =>
        RouteDetailsScreen(services: _passageiroServices(services), routeId: args as String),
      AppRoutes.passengerTracking =>
        VanTrackingScreen(services: _passageiroServices(services), vanId: args as String),
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
