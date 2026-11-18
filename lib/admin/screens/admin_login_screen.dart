import 'package:flutter/material.dart';

import '../../app/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/vb_logo.dart';
import '../../core/widgets/vb_primary_button.dart';
import '../../core/widgets/vb_text_field.dart';
import '../controllers/admin_login_controller.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _controller = AdminLoginController();
  final _usuario = TextEditingController();
  final _senha = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usuario.addListener(_controller.clearError);
    _senha.addListener(_controller.clearError);
  }

  @override
  void dispose() {
    _usuario.dispose();
    _senha.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final success =
        await _controller.signIn(usuario: _usuario.text, senha: _senha.text);
    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.adminDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([_controller, _usuario, _senha]),
        builder: (context, _) {
          final canSubmit = _usuario.text.trim().isNotEmpty &&
              _senha.text.isNotEmpty &&
              !_controller.loading;
          return Stack(
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
                            'Portal do Gestor / Empresa',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 40),
                          VbTextField(
                            controller: _usuario,
                            hint: 'Usuário Admin (ex: admin)',
                            icon: Icons.admin_panel_settings_outlined,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          VbTextField(
                            controller: _senha,
                            hint: 'Senha (ex: admin123)',
                            icon: Icons.lock_outline_rounded,
                            obscure: _controller.obscure,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) {
                              if (canSubmit) _submit();
                            },
                            suffix: IconButton(
                              onPressed: _controller.toggleObscure,
                              icon: Icon(
                                _controller.obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          if (_controller.error != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.dangerSoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _controller.error!,
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          VbPrimaryButton(
                            label: 'Entrar como Admin',
                            loading: _controller.loading,
                            onPressed: canSubmit ? _submit : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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
