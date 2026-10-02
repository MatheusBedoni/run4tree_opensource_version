import 'reforestation_project_entity.dart';

/// Projetos financiáveis + de onde eles vieram.
///
/// A tela precisa saber a diferença: quando a Tree-Nation não responde, o app
/// ainda mostra a lista que veio embutida no build, e avisa o usuário que
/// aquilo não acabou de ser conferido.
class FundableProjectsResult {
  final List<ReforestationProjectEntity> projects;

  /// `true` quando a lista veio da API agora; `false` quando é a cópia local.
  final bool isLive;

  const FundableProjectsResult({required this.projects, required this.isLive});
}
