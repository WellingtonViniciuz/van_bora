import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class OfflineModeView extends StatelessWidget {
  const OfflineModeView({super.key, required this.pendingCount});

  final ValueListenable<int> pendingCount;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: AppColors.navy,
          padding: EdgeInsets.fromLTRB(24, topPadding + 32, 24, 32),
          child: Column(
            children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 56),
              const SizedBox(height: 16),
              Text(
                'Sem conexão com a internet',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 22,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A operação pode continuar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFB9D3DA), fontSize: 15),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const _StatusTile(
                icon: Icons.check_circle_rounded,
                color: AppColors.primary,
                title: 'Localização sendo salva',
                subtitle: 'Os registros ficam no dispositivo.',
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<int>(
                valueListenable: pendingCount,
                builder: (context, count, _) => _StatusTile(
                  icon: Icons.sync_rounded,
                  color: AppColors.warning,
                  title: 'Envio pendente',
                  subtitle: 'Será sincronizado quando a conexão voltar.',
                  trailing: count > 0 ? '$count' : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: textTheme.bodyMedium),
              ],
            ),
          ),
          if (trailing != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                trailing!,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}
