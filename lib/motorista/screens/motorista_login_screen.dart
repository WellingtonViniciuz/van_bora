import 'package:flutter/material.dart';

import '../../app/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/vb_logo.dart';
import '../../core/widgets/vb_primary_button.dart';
import '../../core/widgets/vb_text_field.dart';
import '../controllers/motorista_login_controller.dart';
import '../models/driver_assignment.dart';
import '../services/motorista_services.dart';

class MotoristaLoginScreen extends StatefulWidget {
  const MotoristaLoginScreen({super.key, required this.services});

  final MotoristaServices services;

  @override
  State<MotoristaLoginScreen> createState() => _MotoristaLoginScreenState();
}

class _MotoristaLoginScreenState extends State<MotoristaLoginScreen> {
  late final MotoristaLoginController _controller = MotoristaLoginController(
    auth: widget.services.auth,
    remote: widget.services.remote,
  );
  final _usuario = TextEditingController();
  final _senha = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usuario.addListener(_controller.clearError);
    _senha.addListener(_controller.clearError);
    _restoreSession();
  }

  @override
  void dispose() {
    _usuario.dispose();
    _senha.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _restoreSession() async {
    final assignment = await _controller.restoreSession();
    if (assignment != null && mounted) _goToQueue(assignment);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final assignment = await _controller.signIn(usuario: _usuario.text, senha: _senha.text);
    if (assignment != null && mounted) _goToQueue(assignment);
  }

  void _goToQueue(DriverAssignment assignment) {
    Navigator.of(context).pushReplacementNamed(AppRoutes.queue, arguments: assignment);
  }

  void _showForgotPassword() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Esqueceu a senha?'),
        content: const Text('Peça ao gestor da sua empresa para redefinir o seu acesso.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
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
          if (_controller.checkingSession) {
            return const Center(child: CircularProgressIndicator());
          }
          final canSubmit =
              _usuario.text.trim().isNotEmpty && _senha.text.isNotEmpty && !_controller.loading;
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
                            'Acesso do motorista',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 40),
                          VbTextField(
                            controller: _usuario,
                            hint: 'Usuário',
                            icon: Icons.person_outline_rounded,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          VbTextField(
                            controller: _senha,
                            hint: 'Senha',
                            icon: Icons.lock_outline_rounded,
                            obscure: _controller.obscure,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) {
                              if (canSubmit) _submit();
                            },
                            suffix: IconButton(
                              tooltip: _controller.obscure ? 'Mostrar senha' : 'Ocultar senha',
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
                            _ErrorBanner(message: _controller.error!),
                          ],
                          const SizedBox(height: 24),
                          VbPrimaryButton(
                            label: 'Entrar',
                            loading: _controller.loading,
                            onPressed: canSubmit ? _submit : null,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _showForgotPassword,
                            child: const Text('Esqueci minha senha?'),
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.dangerSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.danger),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w500),
              ),
            ),
          ],
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
