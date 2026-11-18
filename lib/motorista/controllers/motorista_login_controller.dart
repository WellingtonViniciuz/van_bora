import 'package:flutter/foundation.dart';

import '../models/driver_assignment.dart';
import '../services/auth_service.dart';
import '../services/motorista_remote_service.dart';

class MotoristaLoginController extends ChangeNotifier {
  MotoristaLoginController({
    required AuthService auth,
    required MotoristaRemoteService remote,
  })  : _auth = auth,
        _remote = remote;

  final AuthService _auth;
  final MotoristaRemoteService _remote;

  bool _checkingSession = true;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  bool get checkingSession => _checkingSession;
  bool get loading => _loading;
  bool get obscure => _obscure;
  String? get error => _error;

  void toggleObscure() {
    _obscure = !_obscure;
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  /// Reaproveita a sessão salva para não pedir login a cada abertura do app.
  Future<DriverAssignment?> restoreSession() async {
    DriverAssignment? assignment;
    final uid = _auth.currentUid;
    if (uid != null) {
      try {
        assignment = await _remote.fetchAssignment(uid);
      } catch (_) {
        assignment = null;
      }
    }
    _checkingSession = false;
    notifyListeners();
    return assignment;
  }

  Future<DriverAssignment?> signIn({required String usuario, required String senha}) async {
    if (_loading) return null;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final uid = await _auth.signIn(usuario: usuario, senha: senha);
      final assignment = await _remote.fetchAssignment(uid);
      if (assignment == null) {
        await _auth.signOut();
        _error = 'Seu acesso não tem rota vinculada. Fale com o gestor.';
        return null;
      }
      return assignment;
    } catch (erro) {
      _error = AuthService.mensagemDeErro(erro);
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
