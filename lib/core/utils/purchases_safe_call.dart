import 'package:flutter/foundation.dart';

/// Chamadas ao SDK da RevenueCat (`Purchases.*`) estouram
/// `UninitializedPropertyAccessException` quando o SDK ainda não foi
/// configurado (chave ausente no `.env`, ou falha de configuração) — o que
/// nunca deve derrubar o fluxo de anúncios/corrida, já que a maior parte
/// dessas chamadas é tracking best-effort.
///
/// Usa em chamadas fire-and-forget (ex: `Purchases.adTracker.trackX`).
void fireAndForgetPurchasesCall(String label, Future<void> Function() call) {
  call().catchError((Object e) {
    debugPrint('RevenueCat: $label falhou: $e');
  });
}

/// Usa em chamadas que precisam do resultado (ex: geração de token de
/// verificação de recompensa). Retorna `null` em caso de falha — quem chamar
/// deve tratar `null` como "não foi possível confirmar via RevenueCat".
Future<T?> safePurchasesCall<T>(String label, Future<T> Function() call) async {
  try {
    return await call();
  } catch (e) {
    debugPrint('RevenueCat: $label falhou: $e');
    return null;
  }
}
