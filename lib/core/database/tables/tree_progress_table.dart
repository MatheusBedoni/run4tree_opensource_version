import 'package:drift/drift.dart';

/// Tabela Drift com o progresso global de receita de anúncios acumulada,
/// convertida em árvores plantadas (modelo Ecosia: cada árvore custa um
/// valor fixo em USD, financiado pelo que os anúncios pagaram).
///
/// Mantém uma única linha (id fixo 1) como contador global do usuário local.
class TreeProgress extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();

  /// Receita de anúncios (USD) acumulada, ainda não convertida em árvore.
  RealColumn get revenueAccumulatedUsd =>
      real().withDefault(const Constant(0.0))();

  /// Total de árvores plantadas via Tree-Nation a partir de anúncios.
  IntColumn get treesPlanted => integer().withDefault(const Constant(0))();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
