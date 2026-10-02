/// Entidade pura do domínio: representa uma sessão de corrida completa.
///
/// Sem dependência de Flutter, Drift ou JSON — apenas dados de negócio.
class RunSessionEntity {
  /// Identificador único (autoincrement do banco, null se ainda não salvo).
  final int? id;

  /// Duração total em segundos.
  final int durationSeconds;

  /// Distância percorrida em quilômetros.
  final double distanceKm;

  /// Calorias estimadas queimadas.
  final double calories;

  /// Velocidade média em km/h.
  final double averageSpeed;

  /// Velocidade máxima atingida em km/h.
  final double maxSpeed;

  /// Ritmo (min/km).
  final double pace;

  /// Polyline serializada como JSON string.
  final String polyline;

  /// Temperatura no momento da corrida.
  final String? temperature;

  /// Se a corrida foi noturna.
  final bool isNight;

  /// Quantidade de árvores ganhas nessa corrida.
  final int treesEarned;

  /// Tipo de exercício: "run", "walk" ou "bike".
  final String exerciseType;

  /// Data e hora de criação da sessão.
  final DateTime createdAt;

  const RunSessionEntity({
    this.id,
    required this.durationSeconds,
    required this.distanceKm,
    required this.calories,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.pace,
    required this.polyline,
    this.temperature,
    required this.isNight,
    required this.treesEarned,
    required this.exerciseType,
    required this.createdAt,
  });
}
