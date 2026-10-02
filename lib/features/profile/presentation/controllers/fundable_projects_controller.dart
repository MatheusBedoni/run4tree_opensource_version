import 'package:flutter/foundation.dart';

import '../../domain/entities/reforestation_project_entity.dart';
import '../../domain/usecases/get_fundable_projects_usecase.dart';

/// Alimenta a seção "the projects your trees pay for" da
/// `HowWePlantTreesPage` com os projetos reais vindos da Tree-Nation.
class FundableProjectsController extends ChangeNotifier {
  final GetFundableProjectsUseCase _getFundableProjects;

  FundableProjectsController(this._getFundableProjects);

  List<ReforestationProjectEntity> _projects = const [];
  bool _isLoading = false;

  /// `false` quando a lista exibida é a cópia local (app sem internet).
  bool _isLive = true;

  List<ReforestationProjectEntity> get projects => _projects;
  bool get isLoading => _isLoading;
  bool get isLive => _isLive;

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _getFundableProjects();
      _projects = result.projects;
      _isLive = result.isLive;
    } catch (e) {
      // O repositório já cai para a cópia local; aqui só sobra o inesperado.
      debugPrint('FundableProjectsController.load error: $e');
      _isLive = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
