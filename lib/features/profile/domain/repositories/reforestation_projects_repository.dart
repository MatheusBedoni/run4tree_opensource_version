import '../entities/fundable_projects_result.dart';

/// Fonte dos projetos de reflorestamento que o Run4Tree pode financiar.
abstract class ReforestationProjectsRepository {
  /// Projetos ativos cujo preço por árvore cabe no orçamento dos anúncios.
  ///
  /// Não lança: se a Tree-Nation estiver fora do ar, devolve a cópia local
  /// com `isLive: false`.
  Future<FundableProjectsResult> getFundableProjects();
}
