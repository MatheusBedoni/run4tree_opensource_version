import 'package:drift/drift.dart';

/// Tabela Drift com os dados coletados no questionário de boas-vindas.
///
/// Mantém uma única linha (id fixo 1), assim como [TreeProgress]. Usada para
/// personalizar a experiência do usuário e, futuramente, calcular métricas
/// (ex: progresso em relação à meta semanal de km).
class UserProfile extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();

  TextColumn get name => text()();

  IntColumn get age => integer()();

  /// Meta de quilômetros por semana definida pelo usuário.
  RealColumn get weeklyGoalKm => real()();

  RealColumn get weightKg => real()();

  RealColumn get heightCm => real()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
