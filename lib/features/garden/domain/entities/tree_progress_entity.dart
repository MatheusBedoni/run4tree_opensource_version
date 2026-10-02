/// Entidade pura do domínio: progresso do usuário em direção à próxima
/// árvore plantada, financiada pela receita real de anúncios assistidos.
///
/// A receita em USD nunca é exposta na UI — para o usuário, o progresso
/// aparece como "sementes" ([seedsAccumulated]/[seedsPerTree]), uma unidade
/// de exibição que mascara o valor real ganho por anúncio.
class TreeProgressEntity {
  /// Receita de anúncios (USD) acumulada, ainda não convertida em árvore.
  final double revenueAccumulatedUsd;

  /// Preço de uma árvore (USD) na Tree-Nation.
  final double treePriceUsd;

  /// Total de árvores plantadas via anúncios até agora.
  final int treesPlanted;

  const TreeProgressEntity({
    required this.revenueAccumulatedUsd,
    required this.treePriceUsd,
    required this.treesPlanted,
  });

  /// Quantas "sementes" (de [seedsPerTree]) equivalem ao progresso atual.
  /// Puramente de exibição — não representa nenhum valor monetário real.
  static const int seedsPerTree = 10;

  double get progressPercent => treePriceUsd == 0
      ? 0
      : (revenueAccumulatedUsd / treePriceUsd).clamp(0, 1).toDouble();

  int get seedsAccumulated =>
      (progressPercent * seedsPerTree).floor().clamp(0, seedsPerTree);
}
