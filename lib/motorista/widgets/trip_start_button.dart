import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class TripStartButton extends StatelessWidget {
  const TripStartButton({
    super.key,
    required this.onPressed,
    this.active = false,
    this.busy = false,
  });

  final VoidCallback? onPressed;
  final bool active;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: active ? 'Rota em andamento' : 'Iniciar rota',
      child: Material(
        color: active ? AppColors.success : AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(minHeight: 128),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                  child: busy
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                        )
                      : Icon(
                          active ? Icons.check_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  active ? 'ROTA EM ANDAMENTO' : 'INICIAR ROTA',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  active ? 'Monitoramento ativo' : 'Começar o monitoramento',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
