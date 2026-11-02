import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../motorista/services/motorista_services.dart';
import 'app_router.dart';
import 'route_names.dart';

class MotoristaApp extends StatelessWidget {
  const MotoristaApp({super.key, required this.services});

  final MotoristaServices services;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Van Bora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: AppRoutes.login,
      onGenerateRoute: (settings) => AppRouter.onGenerateRoute(settings, services),
    );
  }
}
