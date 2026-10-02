/// Entidade pura do domínio: uma árvore individual já plantada de verdade
/// via Tree-Nation, usada para exibir a "floresta" do usuário.
class PlantedTreeEntity {
  final int treeNationId;
  final String certificateUrl;
  final String collectUrl;
  final String country;
  final String projectName;
  final String projectUrl;
  final String speciesName;

  /// CO2 (kg) que essa árvore compensa ao longo de sua vida útil.
  final double co2LifeTimeKg;

  final DateTime plantedAt;

  const PlantedTreeEntity({
    required this.treeNationId,
    required this.certificateUrl,
    required this.collectUrl,
    required this.country,
    required this.projectName,
    required this.projectUrl,
    required this.speciesName,
    required this.co2LifeTimeKg,
    required this.plantedAt,
  });
}
