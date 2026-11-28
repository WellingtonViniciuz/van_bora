import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../controllers/passenger_controller.dart';
import '../services/passenger_location_service.dart';

/// Faixas de aviso do passageiro: dados simulados, sem internet e
/// localização indisponível. Mostra só as que se aplicam.
class PassengerBanners extends StatelessWidget {
  const PassengerBanners({super.key, required this.controller, this.showLocation = true});

  final PassengerController controller;
  final bool showLocation;

  @override
  Widget build(BuildContext context) {
    final access = controller.locationAccess;
    final children = <Widget>[
      if (controller.isDemo)
        const _Banner(
          icon: Icons.science_outlined,
          color: AppColors.warning,
          background: AppColors.warningSoft,
          text: 'Modo demonstração: vans e posições simuladas, não são dados reais.',
        ),
      if (!controller.isOnline)
        const _Banner(
          icon: Icons.wifi_off_rounded,
          color: AppColors.danger,
          background: AppColors.dangerSoft,
          text: 'Sem internet. As posições podem estar desatualizadas.',
        ),
      if (showLocation && access != null && !access.isGranted)
        _Banner(
          icon: Icons.location_off_outlined,
          color: AppColors.textMuted,
          background: AppColors.neutralSoft,
          text: access.message,
          actionLabel: access == LocationAccess.denied ? 'Permitir' : 'Abrir ajustes',
          onAction: access == LocationAccess.denied
              ? () => controller.refreshLocation()
              : controller.openLocationSettings,
        ),
    ];
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final c in children) Padding(padding: const EdgeInsets.only(bottom: 8), child: c),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.color,
    required this.background,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.3),
              ),
            ),
            if (actionLabel != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                child: Text(actionLabel!),
              ),
          ],
        ),
      ),
    );
  }
}
