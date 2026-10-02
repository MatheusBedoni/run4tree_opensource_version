/// Erro de negócio devolvido pela Tree-Nation.
///
/// A API responde **HTTP 200 mesmo em caso de erro**, sinalizando a falha no
/// corpo (`{"status": "error", "errorCode": ..., "errorMessage": ...}`) e sem
/// a chave `trees`. Sem esse tratamento explícito o parse do
/// [PlantTreeResponse] estourava com um cast obscuro
/// (`Null is not a subtype of List<dynamic>`), escondendo o motivo real.
class TreeNationException implements Exception {
  /// Código de erro da API (ex: `tree_template`, `insufficient_credit`).
  final String? errorCode;

  /// Mensagem legível devolvida pela API (ex: `no tree template`).
  final String? errorMessage;

  /// Corpo cru da resposta, para diagnóstico.
  final Object? raw;

  const TreeNationException({this.errorCode, this.errorMessage, this.raw});

  /// Erros de configuração da conta: repetir a chamada não adianta enquanto
  /// a conta na Tree-Nation não for ajustada.
  bool get isAccountConfigError => const {
    'tree_template',
    'insufficient_credit',
    'no_credit',
    'unauthorized',
  }.contains(errorCode);

  /// Dica acionável para o desenvolvedor, já que a correção é no dashboard
  /// da Tree-Nation e não no código.
  String? get hint => switch (errorCode) {
    'tree_template' =>
      'A conta/token da Tree-Nation não tem um "tree template" configurado. '
          'Cada token está ligado a um único template — configure-o no painel '
          'da Tree-Nation, ou defina TREE_NATION_SPECIES_ID nas Cloud '
          'Functions (functions/README.md) com o id de uma espécie com '
          'stock > 0 (GET /api/projects/{id}/species).',
    'insufficient_credit' || 'no_credit' =>
      'A conta da Tree-Nation está sem créditos — plantios são debitados do '
          'saldo comprado.',
    'unauthorized' =>
      'O secret TREE_NATION_API_TOKEN das Cloud Functions é inválido ou de '
          'outro ambiente (sandbox x produção) que o TREE_NATION_BASE_URL.',
    _ => null,
  };

  @override
  String toString() {
    final base =
        'TreeNationException(${errorCode ?? 'sem código'}): '
        '${errorMessage ?? 'sem mensagem'}';
    return hint == null ? base : '$base\n  → $hint';
  }
}
