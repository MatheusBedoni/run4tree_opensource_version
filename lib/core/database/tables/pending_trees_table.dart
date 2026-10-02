import 'package:drift/drift.dart';

/// Árvores pessoais já conquistadas cujo plantio ainda não saiu na
/// Tree-Nation (pedido `pending`/`retry`/`manual` em `planting_orders`).
///
/// Quando o pedido vira `planted`, a sincronização move a árvore para
/// [PlantedTrees], com o certificado, e apaga a linha daqui.
class PendingTrees extends Table {
  /// Id do pedido no Firestore (`personal_{uid}_{n}`).
  TextColumn get orderId => text()();

  /// Nº da árvore do usuário.
  IntColumn get treeNumber => integer()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {orderId};
}
