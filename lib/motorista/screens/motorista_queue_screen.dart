import 'package:flutter/material.dart';

import '../../app/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/vb_confirm_dialog.dart';
import '../../core/widgets/vb_primary_button.dart';
import '../controllers/motorista_queue_controller.dart';
import '../models/driver_assignment.dart';
import '../services/motorista_services.dart';
import '../widgets/ahead_vehicle_tile.dart';
import '../widgets/queue_position_card.dart';

class MotoristaQueueScreen extends StatefulWidget {
  const MotoristaQueueScreen({super.key, required this.services, required this.assignment});

  final MotoristaServices services;
  final DriverAssignment assignment;

  @override
  State<MotoristaQueueScreen> createState() => _MotoristaQueueScreenState();
}

class _MotoristaQueueScreenState extends State<MotoristaQueueScreen> {
  late final MotoristaQueueController _controller = MotoristaQueueController(
    assignment: widget.assignment,
    remote: widget.services.remote,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    final confirmed = await showVbConfirm(
      context,
      title: 'Sair da conta?',
      message: 'Você precisará entrar novamente para acompanhar a fila.',
      confirmLabel: 'Sair',
      danger: true,
    );
    if (!confirmed || !mounted) return;
    await widget.services.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.welcome, (route) => false);
  }

  void _goToPanel() {
    Navigator.of(context).pushNamed(AppRoutes.operation, arguments: widget.assignment);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Fila de saída'),
        actions: [
          IconButton(
            tooltip: 'Sair da conta',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final c = _controller;
    if (!c.loaded) return const Center(child: CircularProgressIndicator());
    if (c.error != null) {
      return _EmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Fila indisponível',
        message: c.error!,
      );
    }
    final position = c.position;
    if (position == null) {
      return const _EmptyState(
        icon: Icons.hourglass_empty_rounded,
        title: 'Você não está na fila',
        message: 'Peça ao gestor para incluir você na fila de hoje.',
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              QueuePositionCard(position: position.position, total: position.total),
              const SizedBox(height: 28),
              Text('À sua frente', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (position.ahead.isEmpty)
                Text('Nenhuma van à sua frente.', style: Theme.of(context).textTheme.bodyMedium)
              else
                for (var i = 0; i < position.ahead.length; i++)
                  AheadVehicleTile(ordinal: i + 1, entry: position.ahead[i]),
            ],
          ),
        ),
        if (c.isFirst)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: VbPrimaryButton(
              label: 'Ir para o painel',
              icon: Icons.arrow_forward_rounded,
              onPressed: _goToPanel,
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
