import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Estado vazio, de erro ou de carregamento, com ação opcional.
class PassengerStateView extends StatelessWidget {
  const PassengerStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  const PassengerStateView.loading({super.key, this.message = 'Carregando as vans...'})
      : icon = null,
        title = null,
        actionLabel = null,
        onAction = null;

  final IconData? icon;
  final String? title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon == null)
              const CircularProgressIndicator()
            else
              Icon(icon, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            if (title != null) ...[
              Text(title!, textAlign: TextAlign.center, style: textTheme.titleLarge),
              const SizedBox(height: 8),
            ],
            Text(message, textAlign: TextAlign.center, style: textTheme.bodyMedium),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(160, 48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
