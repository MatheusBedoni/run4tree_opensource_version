import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Leitura tolerante do `.env`.
///
/// `dotenv.env` lança [NotInitializedError] quando acessado antes de
/// `dotenv.load()` — o que acontece em testes e em qualquer caminho de código
/// que rode antes do bootstrap do app. Como toda leitura aqui é de
/// configuração opcional, falhar silenciosamente com `null` é preferível a
/// derrubar o fluxo (ex: o crédito de receita de anúncio).
String? envOrNull(String key) {
  try {
    final value = dotenv.env[key]?.trim();
    return (value == null || value.isEmpty) ? null : value;
  } catch (e) {
    debugPrint('[Env] dotenv indisponível ao ler "$key": $e');
    return null;
  }
}
