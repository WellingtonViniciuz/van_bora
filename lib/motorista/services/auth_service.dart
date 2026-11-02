import 'package:firebase_auth/firebase_auth.dart';
import 'modo_teste.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  static const _dominioEmail = 'vanbora.com.br';

  String? get currentUid => _auth.currentUser?.uid;

  Future<String> signIn({required String usuario, required String senha}) async {
    if (ModoTeste.credenciaisValidas(usuario, senha)) {
      return ModoTeste.uid;
    }
    final login = usuario.trim();
    final email = login.contains('@') ? login : '$login@$_dominioEmail';
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: senha);
    return credential.user!.uid;
  }

  Future<void> signOut() => _auth.signOut();

  static String mensagemDeErro(Object erro) {
    if (erro is FirebaseAuthException) {
      switch (erro.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
        case 'invalid-email':
          return 'Usuário ou senha incorretos.';
        case 'user-disabled':
          return 'Este acesso foi desativado. Fale com o gestor.';
        case 'too-many-requests':
          return 'Muitas tentativas. Aguarde alguns minutos.';
        case 'network-request-failed':
          return 'Sem conexão. Verifique a internet e tente de novo.';
      }
    }
    return 'Não foi possível entrar. Tente novamente.';
  }
}
