import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../models/admin_overview.dart';

/// "Visão geral" da operação: vans rodando, fila, conexão e atividade recente.
class AdminOverviewTab extends StatelessWidget {
  const AdminOverviewTab({super.key, required this.controller, required this.onOpenVan});

  final AdminDashboardController controller;

  /// Chamado ao tocar em uma atividade de van sem conexão.
  final ValueChanged<String> onOpenVan;

  @override
  Widget build(BuildContext context) {
    if (!controller.loaded) return const Center(child: CircularProgressIndicator());
    final o = controller.overview;
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (controller.error != null) ...[
              _ErrorBanner(message: controller.error!),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.directions_bus_rounded,
                    value: o.emOperacao,
                    label: 'Vans em operação',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.format_list_bulleted_rounded,
                    value: o.naFila,
                    label: 'Na fila',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.wifi_rounded,
                    value: o.conectadas,
                    label: 'Conectadas',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.wifi_off_rounded,
                    iconColor: AppColors.danger,
                    value: o.semConexao,
                    label: 'Sem conexão',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text('Atividade recente', style: textTheme.titleLarge),
            const SizedBox(height: 12),
            if (o.atividades.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Nenhuma atividade registrada ainda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            else
              for (final a in o.atividades)
                _ActivityTile(
                  activity: a,
                  onTap: a.kind == AdminActivityKind.semConexao
                      ? () => onOpenVan(a.vanId)
                      : null,
                ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor = AppColors.primary,
  });

  final IconData icon;
  final int value;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.neutralSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: iconColor),
          const SizedBox(height: 10),
          Text(
            '$value',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity, this.onTap});

  final AdminActivity activity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (activity.kind) {
      AdminActivityKind.iniciada => (Icons.check_rounded, AppColors.success),
      AdminActivityKind.encerrada => (Icons.flag_rounded, AppColors.primary),
      AdminActivityKind.semConexao => (Icons.priority_high_rounded, AppColors.warning),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Icon(icon, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.titulo,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activity.subtitulo,
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w500),
      ),
    );
  }
}
