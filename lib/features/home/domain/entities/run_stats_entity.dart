/// Entidade pura do domínio: representa o snapshot de stats do usuário em uma sessão.
/// Sem dependência de Flutter ou JSON — apenas lógica de negócio.
class RunStatsEntity {
  /// Quantidade total de árvores plantadas pelo usuário.
  final int treesPlanted;

  /// Distância percorrida na sessão atual em quilômetros.
  final double distanceKm;

  /// Progresso para plantar a próxima árvore (0.0 a 1.0).
  final double progressPercent;

  /// Temperatura atual em graus Celsius.
  final int weatherTemp;

  /// Ícone de clima atual (ex: "sunny", "cloudy", "rainy").
  final String weatherCondition;

  const RunStatsEntity({
    required this.treesPlanted,
    required this.distanceKm,
    required this.progressPercent,
    required this.weatherTemp,
    required this.weatherCondition,
  });

  RunStatsEntity copyWith({int? treesPlanted, double? progressPercent}) =>
      RunStatsEntity(
        treesPlanted: treesPlanted ?? this.treesPlanted,
        distanceKm: distanceKm,
        progressPercent: progressPercent ?? this.progressPercent,
        weatherTemp: weatherTemp,
        weatherCondition: weatherCondition,
      );
}
