import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../controllers/passenger_controller.dart';
import '../services/passageiro_services.dart';
import 'passenger_map_tab.dart';
import 'routes_screen.dart';

/// Entrada do módulo do passageiro. Abre direto, sem login nem cadastro,
/// com duas abas: mapa das vans e lista de rotas.
class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key, required this.services});

  final PassageiroServices services;

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  late final PassengerController _controller = PassengerController(services: widget.services);
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _controller.init(askLocation: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          PassengerMapTab(controller: _controller),
          RoutesTab(controller: _controller),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primarySoft,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded, color: AppColors.primary),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.alt_route_outlined),
            selectedIcon: Icon(Icons.alt_route_rounded, color: AppColors.primary),
            label: 'Rotas',
          ),
        ],
      ),
    );
  }
}
