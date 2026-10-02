// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_stats_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RunStatsModel _$RunStatsModelFromJson(Map<String, dynamic> json) =>
    RunStatsModel(
      treesPlanted: (json['trees_planted'] as num).toInt(),
      distanceKm: (json['distance_km'] as num).toDouble(),
      progressPercent: (json['progress_percent'] as num).toDouble(),
      weatherTemp: (json['weather_temp'] as num).toInt(),
      weatherCondition: json['weather_condition'] as String,
    );

Map<String, dynamic> _$RunStatsModelToJson(RunStatsModel instance) =>
    <String, dynamic>{
      'trees_planted': instance.treesPlanted,
      'distance_km': instance.distanceKm,
      'progress_percent': instance.progressPercent,
      'weather_temp': instance.weatherTemp,
      'weather_condition': instance.weatherCondition,
    };
