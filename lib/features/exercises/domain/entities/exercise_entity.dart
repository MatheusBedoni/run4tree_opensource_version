class ExerciseEntity {
  final String id;
  final String name;
  final String description;
  final String category;
  final int? durationInMinutes;
  final double? caloriesBurned;

  const ExerciseEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.durationInMinutes,
    this.caloriesBurned,
  });
}
