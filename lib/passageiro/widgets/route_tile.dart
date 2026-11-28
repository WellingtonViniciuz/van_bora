import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../models/passenger_route.dart';

/// Cartão de rota na lista "Rotas disponíveis".
class RouteTile extends StatelessWidget {
  const RouteTile({
    super.key,
    required this.route,
    required this.vansEmOperacao,
    required this.onTap,
  });

  final PassengerRoute route;
  final int vansEmOperacao;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ativa = vansEmOperacao > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_bus_rounded, color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.titulo,
                        style: textTheme.titleMedium?.copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: 2),
                      Text(route.percurso, style: textTheme.bodyMedium),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      ativa ? '$vansEmOperacao em rota' : 'Sem vans',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ativa ? AppColors.success : AppColors.textMuted,
                      ),
                    ),
                    if (route.intervaloMinutos != null)
                      Text(
                        'a cada ${route.intervaloMinutos} min',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                  ],
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
