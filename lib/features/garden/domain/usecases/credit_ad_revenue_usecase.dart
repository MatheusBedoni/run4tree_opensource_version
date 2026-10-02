import '../entities/tree_progress_entity.dart';
import '../repositories/tree_garden_repository.dart';

class CreditAdRevenueUseCase {
  final TreeGardenRepository _repository;

  const CreditAdRevenueUseCase(this._repository);

  Future<TreeProgressEntity> call(double revenueUsd) =>
      _repository.creditAdRevenueAndUpdateProgress(revenueUsd);
}
