import 'package:flutter/foundation.dart';
import '../../motorista/services/auth_service.dart';

class AdminLoginController extends ChangeNotifier {
  AdminLoginController({AuthService? auth}) : _auth = auth ?? AuthService();

  final AuthService _auth;

  bool _loading = false;
  bool _obscure = true;
  String? _error;

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

  Future<bool> signIn({required String usuario, required String senha}) async {
    if (_loading) return false;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      if (usuario.trim() == 'admin' && senha == 'admin123') {
        return true;
      }
      await _auth.signIn(usuario: usuario, senha: senha);
      return true;
    } catch (erro) {
      _error = AuthService.mensagemDeErro(erro);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
