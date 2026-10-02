class UserProfileEntity {
  final String name;
  final int age;
  final double weeklyGoalKm;
  final double weightKg;
  final double heightCm;

  /// Data em que o questionário foi respondido pela primeira vez.
  /// `null` ao criar um perfil novo — o repositório preenche com a data
  /// atual e preserva o valor original em edições futuras.
  final DateTime? createdAt;

  const UserProfileEntity({
    required this.name,
    required this.age,
    required this.weeklyGoalKm,
    required this.weightKg,
    required this.heightCm,
    this.createdAt,
  });
}
