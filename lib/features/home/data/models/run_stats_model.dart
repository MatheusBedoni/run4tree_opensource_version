import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/run_stats_entity.dart';

part 'run_stats_model.g.dart';

/// Model da camada data: estende a entidade e adiciona serialização JSON.
/// Pronto para integrar com uma API REST ou Firestore no futuro.
@JsonSerializable(fieldRename: FieldRename.snake)
class RunStatsModel extends RunStatsEntity {
  const RunStatsModel({
    required super.treesPlanted,
    required super.distanceKm,
    required super.progressPercent,
    required super.weatherTemp,
    required super.weatherCondition,
  });

  /// Cria um [RunStatsModel] a partir de um mapa JSON.
  factory RunStatsModel.fromJson(Map<String, dynamic> json) =>
      _$RunStatsModelFromJson(json);

  /// Serializa o model para JSON.
  Map<String, dynamic> toJson() => _$RunStatsModelToJson(this);
}
