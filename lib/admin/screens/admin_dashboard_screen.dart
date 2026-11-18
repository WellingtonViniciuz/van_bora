import 'package:flutter/material.dart';

import '../../app/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/vb_confirm_dialog.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../models/admin_driver.dart';
import '../models/admin_route.dart';
import '../models/admin_vehicle.dart';
import '../services/admin_remote_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AdminDashboardController _controller =
      AdminDashboardController(remote: AdminRemoteService());
  late final TabController _tabController =
      TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
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
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.welcome, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Painel Administrativo'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _signOut,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Veículos', icon: Icon(Icons.directions_bus_rounded)),
            Tab(text: 'Rotas', icon: Icon(Icons.map_rounded)),
            Tab(text: 'Motoristas', icon: Icon(Icons.badge_rounded)),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => TabBarView(
          controller: _tabController,
          children: [
            _VehiclesTab(controller: _controller),
            _RoutesTab(controller: _controller),
            _DriversTab(controller: _controller),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final index = _tabController.index;
    if (index == 0) {
      _showVehicleDialog(context, null);
    } else if (index == 1) {
      _showRouteDialog(context, null);
    } else {
      _showDriverDialog(context, null);
    }
  }

  void _showVehicleDialog(BuildContext context, AdminVehicle? vehicle) {
    final nameC = TextEditingController(text: vehicle?.vanNome ?? '');
    final placaC = TextEditingController(text: vehicle?.placa ?? '');
    final capC =
        TextEditingController(text: vehicle?.capacidade.toString() ?? '15');

    showDialog(
      context: context,
      builder: (dlgContext) => AlertDialog(
        title: Text(vehicle == null ? 'Nova Van / Veículo' : 'Editar Veículo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameC,
              decoration:
                  const InputDecoration(labelText: 'Nome da Van (ex: Van 10)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: placaC,
              decoration:
                  const InputDecoration(labelText: 'Placa (ex: ABC-1234)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: capC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Capacidade'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final v = AdminVehicle(
                id: vehicle?.id ?? '',
                vanNome: nameC.text,
                placa: placaC.text,
                capacidade: int.tryParse(capC.text) ?? 15,
                status: vehicle?.status ?? 'disponivel',
              );
              await _controller.saveVehicle(v);
              if (dlgContext.mounted) Navigator.pop(dlgContext);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showRouteDialog(BuildContext context, AdminRoute? route) {
    final codC = TextEditingController(text: route?.codigo ?? '');
    final origC = TextEditingController(text: route?.origem ?? '');
    final destC = TextEditingController(text: route?.destino ?? '');
    final intC =
        TextEditingController(text: route?.intervaloMinutos.toString() ?? '30');

    showDialog(
      context: context,
      builder: (dlgContext) => AlertDialog(
        title: Text(route == null ? 'Nova Rota' : 'Editar Rota'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codC,
              decoration: const InputDecoration(
                  labelText: 'Código da Rota (ex: RF12)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: origC,
              decoration: const InputDecoration(labelText: 'Origem'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: destC,
              decoration: const InputDecoration(labelText: 'Destino'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: intC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Intervalo (min)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final r = AdminRoute(
                id: route?.id ?? '',
                codigo: codC.text,
                origem: origC.text,
                destino: destC.text,
                intervaloMinutos: int.tryParse(intC.text) ?? 30,
              );
              await _controller.saveRoute(r);
              if (dlgContext.mounted) Navigator.pop(dlgContext);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showDriverDialog(BuildContext context, AdminDriver? driver) {
    final nomeC = TextEditingController(text: driver?.nome ?? '');
    showDialog(
      context: context,
      builder: (dlgContext) => AlertDialog(
        title: Text(driver == null ? 'Novo Motorista' : 'Editar Motorista'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeC,
              decoration:
                  const InputDecoration(labelText: 'Nome do Motorista'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final d = AdminDriver(
                id: driver?.id ?? '',
                nome: nomeC.text,
                vanId: driver?.vanId ?? 'van12',
                vanNome: driver?.vanNome ?? 'Van 12',
                placa: driver?.placa ?? 'QXV-4821',
                rotaId: driver?.rotaId ?? 'rf09',
                rotaCodigo: driver?.rotaCodigo ?? 'RF09',
                origem: driver?.origem ?? 'Centro',
                destino: driver?.destino ?? 'IFPE',
              );
              await _controller.saveDriver(d);
              if (dlgContext.mounted) Navigator.pop(dlgContext);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

class _VehiclesTab extends StatelessWidget {
  const _VehiclesTab({required this.controller});
  final AdminDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final list = controller.vehicles;
    if (list.isEmpty) {
      return const Center(child: Text('Nenhum veículo cadastrado.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final v = list[index];
        return Card(
          child: ListTile(
            leading:
                const Icon(Icons.directions_bus_rounded, color: AppColors.primary),
            title:
                Text(v.vanNome, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Placa: ${v.placa} · Capacidade: ${v.capacidade}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.danger),
              onPressed: () => controller.deleteVehicle(v.id),
            ),
          ),
        );
      },
    );
  }
}

class _RoutesTab extends StatelessWidget {
  const _RoutesTab({required this.controller});
  final AdminDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final list = controller.routes;
    if (list.isEmpty) return const Center(child: Text('Nenhuma rota cadastrada.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final r = list[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.map_rounded, color: AppColors.primary),
            title: Text('Rota ${r.codigo}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                '${r.origem} → ${r.destino} · Intervalo: ${r.intervaloMinutos} min'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.danger),
              onPressed: () => controller.deleteRoute(r.id),
            ),
          ),
        );
      },
    );
  }
}

class _DriversTab extends StatelessWidget {
  const _DriversTab({required this.controller});
  final AdminDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final list = controller.drivers;
    if (list.isEmpty) return const Center(child: Text('Nenhum motorista cadastrado.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final d = list[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.badge_rounded, color: AppColors.primary),
            title:
                Text(d.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Van: ${d.vanNome} · Rota: ${d.rotaCodigo}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.danger),
              onPressed: () => controller.deleteDriver(d.id),
            ),
          ),
        );
      },
    );
  }
}
