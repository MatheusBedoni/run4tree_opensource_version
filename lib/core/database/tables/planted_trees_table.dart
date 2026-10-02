import 'package:drift/drift.dart';

/// Tabela Drift com cada árvore individual plantada de verdade via
/// Tree-Nation (`trees[]` na resposta de `POST /api/plant`).
///
/// Diferente de [TreeProgress] (contador agregado usado no cálculo de
/// progresso), esta tabela guarda o registro completo de cada árvore — usado
/// para exibir a "floresta" do usuário e o CO2 total compensado.
class PlantedTrees extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Id da árvore na Tree-Nation (`trees[].id`).
  IntColumn get treeNationId => integer()();

  TextColumn get token => text()();
  TextColumn get collectUrl => text()();
  TextColumn get certificateUrl => text()();
  TextColumn get country => text()();
  IntColumn get projectId => integer()();
  TextColumn get projectName => text()();
  TextColumn get projectUrl => text()();
  IntColumn get speciesId => integer()();
  TextColumn get speciesName => text()();

  /// CO2 (kg) que a espécie compensa ao longo de sua vida útil.
  RealColumn get speciesLifeTimeCo2 =>
      real().withDefault(const Constant(0.0))();

  IntColumn get paymentId => integer().nullable()();

  DateTimeColumn get plantedAt => dateTime().withDefault(currentDateAndTime)();
}
