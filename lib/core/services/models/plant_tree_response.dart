import 'package:json_annotation/json_annotation.dart';

part 'plant_tree_response.g.dart';

/// Uma árvore individual plantada, conforme retornada pela Tree-Nation em
/// `trees[]` na resposta de `/api/plant`.
@JsonSerializable()
class PlantedTree {
  final int id;

  @JsonKey(name: 'internal_id')
  final String? internalId;

  final String token;

  @JsonKey(name: 'collect_url')
  final String collectUrl;

  @JsonKey(name: 'certificate_url')
  final String certificateUrl;

  final String country;

  @JsonKey(name: 'project_id')
  final int projectId;

  @JsonKey(name: 'project_name')
  final String projectName;

  @JsonKey(name: 'project_url')
  final String projectUrl;

  @JsonKey(name: 'species_id')
  final int speciesId;

  @JsonKey(name: 'species_name')
  final String speciesName;

  @JsonKey(name: 'species_life_time_CO2')
  final double speciesLifeTimeCo2;

  PlantedTree({
    required this.id,
    this.internalId,
    required this.token,
    required this.collectUrl,
    required this.certificateUrl,
    required this.country,
    required this.projectId,
    required this.projectName,
    required this.projectUrl,
    required this.speciesId,
    required this.speciesName,
    required this.speciesLifeTimeCo2,
  });

  factory PlantedTree.fromJson(Map<String, dynamic> json) =>
      _$PlantedTreeFromJson(json);

  Map<String, dynamic> toJson() => _$PlantedTreeToJson(this);
}

/// Resposta completa de `POST /api/plant` da Tree-Nation.
///
/// A API responde HTTP 200 tanto no sucesso (`status: "ok"`, com `trees`)
/// quanto no erro (`status: "error"`, com `errorCode`/`errorMessage` e **sem**
/// `trees`) — por isso `trees` tolera ausência e os campos de erro existem.
@JsonSerializable()
class PlantTreeResponse {
  final String status;

  @JsonKey(defaultValue: <PlantedTree>[])
  final List<PlantedTree> trees;

  @JsonKey(name: 'payment_id')
  final int? paymentId;

  /// Código do erro quando `status == 'error'` (ex: `tree_template`).
  final String? errorCode;

  /// Mensagem do erro quando `status == 'error'` (ex: `no tree template`).
  final String? errorMessage;

  PlantTreeResponse({
    required this.status,
    required this.trees,
    this.paymentId,
    this.errorCode,
    this.errorMessage,
  });

  bool get isOk => status == 'ok';

  factory PlantTreeResponse.fromJson(Map<String, dynamic> json) =>
      _$PlantTreeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PlantTreeResponseToJson(this);
}
