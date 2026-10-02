/// Perfil do usuário, combinando as respostas do questionário de boas-vindas
/// com métricas reais calculadas a partir do histórico de corridas e do
/// progresso de árvores plantadas.
class ProfileEntity {
  final String name;
  final int age;
  final double weightKg;
  final double heightCm;
  final double weeklyGoalKm;

  final int treesPlanted;
  final int totalRuns;
  final double totalDistanceKm;

  /// Distância percorrida na semana corrente (segunda a domingo).
  final double weeklyDistanceKm;

  final DateTime memberSince;

  const ProfileEntity({
    required this.name,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.weeklyGoalKm,
    required this.treesPlanted,
    required this.totalRuns,
    required this.totalDistanceKm,
    required this.weeklyDistanceKm,
    required this.memberSince,
  });

  /// Índice de massa corporal (kg/m²).
  double get bmi {
    if (heightCm <= 0) return 0;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  /// Progresso em relação à meta semanal de km, de 0.0 a 1.0.
  double get weeklyGoalProgress {
    if (weeklyGoalKm <= 0) return 0;
    return (weeklyDistanceKm / weeklyGoalKm).clamp(0, 1);
  }
}
