import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/vb_logo.dart';
import '../route_names.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Stack(
        children: [
          const Align(
            alignment: Alignment.bottomCenter,
            child: _WaveBackground(),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const VbLogo(),
                      const SizedBox(height: 12),
                      Text(
                        'Sistema de Gestão de Transporte',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 48),
                      _RoleButton(
                        icon: Icons.person_outline_rounded,
                        title: 'É um passageiro?',
                        subtitle: 'Acesse as rotas disponíveis',
                        onPressed: () {
                          // Passageiro não tem login: entra direto no mapa.
                          Navigator.of(context).pushNamed(AppRoutes.passengerHome);
                        },
                      ),
                      const SizedBox(height: 16),
                      _RoleButton(
                        icon: Icons.directions_bus_rounded,
                        title: 'É um motorista?',
                        subtitle: 'Acesse seu login',
                        onPressed: () {
                          Navigator.of(context).pushNamed(AppRoutes.login);
                        },
                      ),
                      const SizedBox(height: 16),
                      _RoleButton(
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'É um administrador?',
                        subtitle: 'Acesse sua conta',
                        onPressed: () {
                          Navigator.of(context).pushNamed(AppRoutes.adminLogin);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 15, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaveBackground extends StatelessWidget {
  const _WaveBackground();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 180,
      child: CustomPaint(painter: _WavePainter()),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.45)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.15, size.width * 0.5, size.height * 0.4)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.7, size.width, size.height * 0.3)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.primarySoft);
  }
}
