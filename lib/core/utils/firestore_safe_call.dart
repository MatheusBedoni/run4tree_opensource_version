import 'package:flutter/foundation.dart';

/// Chamadas ao Firestore falham se o Firebase ainda não foi inicializado
/// (`firebase_options.dart` não configurado, sem rede, projeto sem Firestore
/// habilitado) — o que nunca deve derrubar o fluxo local de plantio de
/// árvores, já que o mural global é um complemento best-effort.
///
/// Usa em chamadas fire-and-forget (ex: publicar uma árvore no mural global).
void fireAndForgetFirestoreCall(String label, Future<void> Function() call) {
  call().catchError((Object e) {
    debugPrint('Firestore: $label falhou: $e');
  });
}

/// Usa em chamadas que precisam do resultado (ex: ler a lista/contagem
/// global). Retorna `null` em caso de falha — quem chamar deve tratar `null`
/// como "mural global indisponível agora".
Future<T?> safeFirestoreCall<T>(String label, Future<T> Function() call) async {
  try {
    return await call();
  } catch (e) {
    debugPrint('Firestore: $label falhou: $e');
    return null;
  }
}
