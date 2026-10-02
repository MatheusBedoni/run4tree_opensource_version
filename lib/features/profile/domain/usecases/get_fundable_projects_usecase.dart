import '../entities/fundable_projects_result.dart';
import '../repositories/reforestation_projects_repository.dart';

class GetFundableProjectsUseCase {
  final ReforestationProjectsRepository _repository;

  const GetFundableProjectsUseCase(this._repository);

  Future<FundableProjectsResult> call() => _repository.getFundableProjects();
}
