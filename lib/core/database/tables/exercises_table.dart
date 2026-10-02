import 'package:drift/drift.dart';

/// Tabela Drift para exercícios salvos localmente.
///
/// Substitui a antiga tabela `exercises` criada manualmente via sqflite.
class Exercises extends Table {
  /// Identificador do exercício (UUID vindo da API ou gerado local).
  TextColumn get id => text()();

  /// Nome do exercício.
  TextColumn get name => text()();

  /// Descrição do exercício.
  TextColumn get description => text()();

  /// Categoria (ex: "cardio", "força").
  TextColumn get category => text()();

  /// Duração em minutos (opcional).
  IntColumn get durationInMinutes => integer().nullable()();

  /// Calorias queimadas (opcional).
  RealColumn get caloriesBurned => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
