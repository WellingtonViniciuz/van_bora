import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../motorista/services/motorista_services.dart';
import 'app_router.dart';
import 'screens/welcome_screen.dart';

class VanBoraApp extends StatelessWidget {
  const VanBoraApp({super.key, required this.services});

  final MotoristaServices services;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Van Bora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const WelcomeScreen(),
      onGenerateRoute: (settings) => AppRouter.onGenerateRoute(settings, services),
    );
  }
}
