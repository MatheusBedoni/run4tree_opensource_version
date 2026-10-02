import '../entities/planted_tree_entity.dart';
import '../repositories/tree_garden_repository.dart';

class GetPlantedTreesUseCase {
  final TreeGardenRepository _repository;

  const GetPlantedTreesUseCase(this._repository);

  Future<List<PlantedTreeEntity>> call() => _repository.getPlantedTrees();
}
