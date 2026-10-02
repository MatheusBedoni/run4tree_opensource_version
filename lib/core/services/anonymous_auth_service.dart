import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Identidade invisível do usuário no Firebase (Anonymous Auth).
///
/// O app não tem login, mas os desafios em grupo precisam de um `uid` estável
/// para as regras do Firestore amarrarem cada participante e cada semente a
/// quem realmente escreveu. Não há tela nem dado pessoal: o Firebase só gera
/// um id por instalação.
///
/// Best-effort como o resto do Firebase no app: sem rede, sem o provedor
/// Anônimo habilitado no console ou sem Firebase inicializado, devolve `null`
/// e as funcionalidades em grupo simplesmente não aparecem.
class AnonymousAuthService {
  AnonymousAuthService._();

  static final AnonymousAuthService instance = AnonymousAuthService._();

  /// Login em andamento — chamadas simultâneas compartilham o mesmo pedido.
  Future<String?>? _pendingSignIn;

  String? get currentUserId {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  /// `uid` do usuário, fazendo o login anônimo na primeira vez.
  Future<String?> ensureUserId() {
    final uid = currentUserId;
    if (uid != null) return Future.value(uid);
    // Limpa ao terminar para uma falha (ex: sem rede) poder tentar de novo.
    return _pendingSignIn ??= _signIn().whenComplete(
      () => _pendingSignIn = null,
    );
  }

  Future<String?> _signIn() async {
    try {
      final credential = await FirebaseAuth.instance.signInAnonymously();
      return credential.user?.uid;
    } catch (e) {
      debugPrint('FirebaseAuth: login anônimo falhou: $e');
      return null;
    }
  }
}
