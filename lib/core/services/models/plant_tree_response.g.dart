// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plant_tree_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlantedTree _$PlantedTreeFromJson(Map<String, dynamic> json) => PlantedTree(
  id: (json['id'] as num).toInt(),
  internalId: json['internal_id'] as String?,
  token: json['token'] as String,
  collectUrl: json['collect_url'] as String,
  certificateUrl: json['certificate_url'] as String,
  country: json['country'] as String,
  projectId: (json['project_id'] as num).toInt(),
  projectName: json['project_name'] as String,
  projectUrl: json['project_url'] as String,
  speciesId: (json['species_id'] as num).toInt(),
  speciesName: json['species_name'] as String,
  speciesLifeTimeCo2: (json['species_life_time_CO2'] as num).toDouble(),
);

Map<String, dynamic> _$PlantedTreeToJson(PlantedTree instance) =>
    <String, dynamic>{
      'id': instance.id,
      'internal_id': instance.internalId,
      'token': instance.token,
      'collect_url': instance.collectUrl,
      'certificate_url': instance.certificateUrl,
      'country': instance.country,
      'project_id': instance.projectId,
      'project_name': instance.projectName,
      'project_url': instance.projectUrl,
      'species_id': instance.speciesId,
      'species_name': instance.speciesName,
      'species_life_time_CO2': instance.speciesLifeTimeCo2,
    };

PlantTreeResponse _$PlantTreeResponseFromJson(Map<String, dynamic> json) =>
    PlantTreeResponse(
      status: json['status'] as String,
      trees:
          (json['trees'] as List<dynamic>?)
              ?.map((e) => PlantedTree.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      paymentId: (json['payment_id'] as num?)?.toInt(),
      errorCode: json['errorCode'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );

Map<String, dynamic> _$PlantTreeResponseToJson(PlantTreeResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'trees': instance.trees,
      'payment_id': instance.paymentId,
      'errorCode': instance.errorCode,
      'errorMessage': instance.errorMessage,
    };
