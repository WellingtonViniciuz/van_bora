import 'package:flutter/material.dart';

import '../../app/route_names.dart';
import '../../core/widgets/vb_confirm_dialog.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../services/admin_remote_service.dart';
import 'admin_drivers_tab.dart';
import 'admin_overview_tab.dart';
import 'admin_routes_tab.dart';
import 'admin_vehicles_tab.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final AdminDashboardController _controller =
      AdminDashboardController(remote: AdminRemoteService());
  int _index = 0;

  static const _titles = ['Visão geral', 'Vans', 'Rotas', 'Motoristas'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    final confirmed = await showVbConfirm(
      context,
      title: 'Sair da conta?',
      message: 'Você precisará entrar novamente para acessar o painel.',
      confirmLabel: 'Sair',
      danger: true,
    );
    if (!confirmed || !mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.welcome, (route) => false);
  }

  void _openVan(String vanId) {
    setState(() => _index = 1);
    final van = _controller.vehicleById(vanId);
    if (van != null) showVehicleForm(context, _controller, van);
  }

  Widget? _fab() {
    final (label, open) = switch (_index) {
      1 => ('Nova van', () => showVehicleForm(context, _controller)),
      2 => ('Nova rota', () => showRouteForm(context, _controller)),
      3 => ('Novo motorista', () => showDriverForm(context, _controller)),
      _ => (null, null),
    };
    if (label == null || open == null) return null;
    return FloatingActionButton.extended(
      onPressed: open,
      icon: const Icon(Icons.add_rounded),
      label: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_titles[_index]),
        titleTextStyle: Theme.of(context).textTheme.headlineSmall,
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => IndexedStack(
            index: _index,
            children: [
              AdminOverviewTab(controller: _controller, onOpenVan: _openVan),
              AdminVehiclesTab(controller: _controller),
              AdminRoutesTab(controller: _controller),
              AdminDriversTab(controller: _controller),
            ],
          ),
        ),
      ),
      floatingActionButton: _fab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_bus_outlined),
            selectedIcon: Icon(Icons.directions_bus_rounded),
            label: 'Vans',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'Rotas',
          ),
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge_rounded),
            label: 'Motoristas',
          ),
        ],
      ),
    );
  }
}
