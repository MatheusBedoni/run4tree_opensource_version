import 'package:drift/drift.dart';

/// Marcas simples de estado do app (chave → valor), como "já explicamos o
/// pedido de notificação". Evita criar uma tabela nova a cada sinalizador.
class AppFlags extends Table {
  TextColumn get key => text()();

  TextColumn get value => text().withDefault(const Constant(''))();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}
