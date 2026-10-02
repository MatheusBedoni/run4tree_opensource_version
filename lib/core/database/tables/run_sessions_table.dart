import 'package:drift/drift.dart';

/// Tabela Drift para sessões de corrida.
///
/// Cada linha representa uma corrida/caminhada/pedalada completa,
/// armazenada offline no SQLite via Drift.
class RunSessions extends Table {
  /// Identificador único, autoincrement.
  IntColumn get id => integer().autoIncrement()();

  /// Duração total da sessão em segundos.
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();

  /// Distância percorrida em quilômetros.
  RealColumn get distanceKm => real().withDefault(const Constant(0.0))();

  /// Calorias estimadas queimadas.
  RealColumn get calories => real().withDefault(const Constant(0.0))();

  /// Velocidade média em km/h.
  RealColumn get averageSpeed => real().withDefault(const Constant(0.0))();

  /// Velocidade máxima atingida em km/h.
  RealColumn get maxSpeed => real().withDefault(const Constant(0.0))();

  /// Ritmo (min/km).
  RealColumn get pace => real().withDefault(const Constant(0.0))();

  /// Polyline serializada como JSON string (List<List<double>>).
  TextColumn get polyline => text().withDefault(const Constant(''))();

  /// Temperatura no momento da corrida (ex: "25°C").
  TextColumn get temperature => text().nullable()();

  /// Se a corrida foi noturna.
  BoolColumn get isNight => boolean().withDefault(const Constant(false))();

  /// Quantidade de árvores ganhas nessa corrida.
  IntColumn get treesEarned => integer().withDefault(const Constant(0))();

  /// Tipo de exercício: "run", "walk" ou "bike".
  TextColumn get exerciseType => text().withDefault(const Constant('run'))();

  /// Data e hora de criação da sessão.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
