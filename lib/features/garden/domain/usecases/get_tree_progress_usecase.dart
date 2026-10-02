import '../entities/tree_progress_entity.dart';
import '../repositories/tree_garden_repository.dart';

class GetTreeProgressUseCase {
  final TreeGardenRepository _repository;

  const GetTreeProgressUseCase(this._repository);

  Future<TreeProgressEntity> call() => _repository.getProgress();
}
