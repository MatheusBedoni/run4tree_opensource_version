// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_run_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProgressRun _$ProgressRunFromJson(Map<String, dynamic> json) => ProgressRun(
  id: (json['id'] as num?)?.toInt(),
  duracao: (json['duracao'] as num?)?.toInt() ?? 0,
  date: json['date'] as String? ?? '',
  temperature: json['temperature'] as String? ?? '',
  km: json['km'] == null ? 0 : ProgressRun._parseDouble(json['km']),
  nigth: json['nigth'] as bool? ?? false,
  calories: (json['calories'] as num?)?.toDouble() ?? 0,
  tree: (json['tree'] as num?)?.toInt() ?? 0,
  ritmo: (json['ritmo'] as num?)?.toDouble() ?? 0,
  velocidadeMaxima: (json['velocidadeMaxima'] as num?)?.toDouble() ?? 0,
  velocidadeMedia: (json['velocidadeMedia'] as num?)?.toDouble() ?? 0,
  polyLine: json['polyLine'] as String?,
);

Map<String, dynamic> _$ProgressRunToJson(ProgressRun instance) =>
    <String, dynamic>{
      'id': instance.id,
      'duracao': instance.duracao,
      'date': instance.date,
      'temperature': instance.temperature,
      'km': ProgressRun._doubleToString(instance.km),
      'nigth': instance.nigth,
      'calories': instance.calories,
      'tree': instance.tree,
      'ritmo': instance.ritmo,
      'velocidadeMedia': instance.velocidadeMedia,
      'velocidadeMaxima': instance.velocidadeMaxima,
      'polyLine': instance.polyLine,
    };
