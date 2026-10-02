/// O servidor não plantou agora, mas pode plantar depois.
///
/// Motivos (`reason`, vindos da Cloud Function `plantPersonalTree`):
/// - `cooldown`: intervalo mínimo entre árvores do mesmo usuário
/// - `in_progress`: outro plantio deste usuário ainda está rodando
/// - `daily_budget`: teto diário de árvores do app atingido
/// - `unavailable` / `deadline-exceeded`: Tree-Nation ou rede fora do ar
/// - `unauthenticated` / `not_signed_in`: sem login anônimo no momento
///
/// A receita acumulada continua guardada no aparelho; a próxima tentativa
/// acontece no próximo crédito de anúncio.
class TreePlantingDeferredException implements Exception {
  final String reason;
  final String message;

  /// Quando o servidor informa, quanto falta para poder tentar de novo.
  final Duration? retryAfter;

  const TreePlantingDeferredException({
    required this.reason,
    required this.message,
    this.retryAfter,
  });

  /// Intervalo mínimo e plantio em andamento são o funcionamento normal —
  /// não valem alerta na telemetria.
  bool get shouldReport => reason != 'cooldown' && reason != 'in_progress';

  @override
  String toString() {
    final wait = retryAfter == null
        ? ''
        : ' (tentar de novo em ${retryAfter!.inMinutes} min)';
    return 'TreePlantingDeferredException($reason): $message$wait';
  }
}
