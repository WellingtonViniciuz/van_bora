import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../models/queue_entry.dart';

class AheadVehicleTile extends StatelessWidget {
  const AheadVehicleTile({super.key, required this.ordinal, required this.entry});

  final int ordinal;
  final QueueEntry entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$ordinalº',
              style: textTheme.titleMedium?.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${entry.vanNome} – ${entry.motoristaNome}', style: textTheme.titleMedium),
                const SizedBox(height: 2),
                Text('Aguardando saída', style: textTheme.bodyMedium),
              ],
            ),
          ),
          const Icon(Icons.airport_shuttle_outlined, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
