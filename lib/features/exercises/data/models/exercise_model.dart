import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/exercise_entity.dart';

part 'exercise_model.g.dart';

@JsonSerializable()
class ExerciseModel extends ExerciseEntity {
  const ExerciseModel({
    required super.id,
    required super.name,
    required super.description,
    required super.category,
    super.durationInMinutes,
    super.caloriesBurned,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) =>
      _$ExerciseModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseModelToJson(this);
}
