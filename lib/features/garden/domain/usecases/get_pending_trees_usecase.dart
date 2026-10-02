import '../entities/pending_tree_entity.dart';
import '../repositories/tree_garden_repository.dart';

class GetPendingTreesUseCase {
  final TreeGardenRepository _repository;

  const GetPendingTreesUseCase(this._repository);

  Future<List<PendingTreeEntity>> call() => _repository.getPendingTrees();
}
