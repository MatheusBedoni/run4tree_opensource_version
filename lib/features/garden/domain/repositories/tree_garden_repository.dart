import '../entities/pending_tree_entity.dart';
import '../entities/planted_tree_entity.dart';
import '../entities/tree_progress_entity.dart';

/// Contrato de repositório: define o que o domínio espera da camada de dados
/// para o fluxo "receita de anúncio -> ganhar semente -> plantar árvore".
abstract class TreeGardenRepository {
  Future<TreeProgressEntity> getProgress();

  /// Credita [revenueUsd] (já obtida e verificada por quem assistiu o
  /// anúncio) ao progresso acumulado e, se atingir o limiar, conquista uma
  /// árvore: plantada na hora, ou garantida com o plantio a caminho.
  Future<TreeProgressEntity> creditAdRevenueAndUpdateProgress(
    double revenueUsd,
  );

  /// Todas as árvores já plantadas de verdade, mais recentes primeiro —
  /// usado para exibir a floresta do usuário.
  Future<List<PlantedTreeEntity>> getPlantedTrees();

  /// Árvores conquistadas cujo plantio ainda está a caminho.
  Future<List<PendingTreeEntity>> getPendingTrees();

  /// O pedido [orderId] foi plantado: move a árvore pendente para a floresta,
  /// com o certificado. Retorna `false` se não havia essa pendência (já
  /// processada, ou de outra instalação).
  Future<bool> completePendingTree({
    required String orderId,
    required PlantedTreeEntity tree,
    int? paymentId,
  });
}
