import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class QueuePositionCard extends StatelessWidget {
  const QueuePositionCard({super.key, required this.position, required this.total});

  final int position;
  final int total;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final motoristas = total == 1 ? 'motorista' : 'motoristas';
    return Semantics(
      label: 'Sua posição na fila: ${position}º lugar de $total $motoristas',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              'Sua posição na fila',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text('${position}º lugar', style: textTheme.displaySmall),
            const SizedBox(height: 6),
            Text('De $total $motoristas', style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
