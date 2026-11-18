import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/vb_confirm_dialog.dart';
import '../../core/widgets/vb_primary_button.dart';
import '../../core/widgets/vb_status_badge.dart';
import '../controllers/motorista_operation_controller.dart';
import '../models/driver_assignment.dart';
import '../services/motorista_services.dart';
import '../widgets/offline_mode_view.dart';
import '../widgets/occupancy_selector.dart';
import '../widgets/trip_start_button.dart';
import '../widgets/van_summary_card.dart';

class MotoristaOperationScreen extends StatefulWidget {
  const MotoristaOperationScreen({super.key, required this.services, required this.assignment});

  final MotoristaServices services;
  final DriverAssignment assignment;

  @override
  State<MotoristaOperationScreen> createState() => _MotoristaOperationScreenState();
}

class _MotoristaOperationScreenState extends State<MotoristaOperationScreen> {
  late final MotoristaOperationController _controller = MotoristaOperationController(
    assignment: widget.assignment,
    services: widget.services,
  );

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmEnd() async {
    final confirmed = await showVbConfirm(
      context,
      title: 'Encerrar rota?',
      message: 'A localização da van deixará de ser enviada.',
      confirmLabel: 'Encerrar',
      danger: true,
    );
    if (confirmed) await _controller.endTrip();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final online = _controller.isOnline;
        return Scaffold(
          appBar: online ? _buildAppBar() : null,
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: online
                ? _buildPanel()
                : OfflineModeView(
                    key: const ValueKey('offline'),
                    pendingCount: widget.services.store.pendingCount,
                  ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final active = _controller.isTripActive;
    return AppBar(
      title: const Text('Painel do motorista'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: active
                ? const VbStatusBadge(
                    label: 'Em operação',
                    color: AppColors.success,
                    background: AppColors.successSoft,
                  )
                : const VbStatusBadge(
                    label: 'Parado',
                    color: AppColors.textMuted,
                    background: AppColors.neutralSoft,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPanel() {
    final c = _controller;
    final assignment = widget.assignment;
    return SingleChildScrollView(
      key: const ValueKey('panel'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VanSummaryCard(title: assignment.vanTitle, subtitle: assignment.rotaSubtitle),
          const SizedBox(height: 20),
          TripStartButton(
            active: c.isTripActive,
            busy: c.isBusy,
            onPressed: c.isTripActive || c.isBusy ? null : c.startTrip,
          ),
          const SizedBox(height: 28),
          Text('Informar lotação', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            c.isTripActive
                ? 'Toque para atualizar a lotação da van.'
                : 'Inicie a rota para informar a lotação.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OccupancySelector(
            selected: c.occupancy,
            enabled: c.isTripActive && !c.isBusy,
            onSelected: c.setOccupancy,
          ),
          const SizedBox(height: 28),
          VbPrimaryButton(
            label: 'ENCERRAR ROTA',
            icon: Icons.stop_rounded,
            danger: true,
            height: 64,
            onPressed: c.isTripActive && !c.isBusy ? _confirmEnd : null,
          ),
          if (c.message != null) ...[
            const SizedBox(height: 12),
            Text(
              c.message!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w500),
            ),
          ],
          ValueListenableBuilder<int>(
            valueListenable: widget.services.store.pendingCount,
            builder: (context, count, _) {
              if (count == 0) return const SizedBox.shrink();
              final texto = count == 1 ? 'registro aguardando' : 'registros aguardando';
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '$count $texto envio',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
