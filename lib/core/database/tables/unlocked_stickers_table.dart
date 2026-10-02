import 'package:drift/drift.dart';

/// Tabela Drift com os adesivos (stickers) já desbloqueados pelo usuário.
///
/// O catálogo em si vive no domínio (`StickerCatalog`) — aqui guardamos apenas
/// o estado: quais ids foram conquistados, quando, e qual deles está em uso
/// como avatar/marcador do mapa. Assim, adicionar adesivos novos no futuro é só
/// acrescentar entradas no catálogo, sem migração de banco.
class UnlockedStickers extends Table {
  /// Id do adesivo no catálogo (ex: "1", "monarch").
  TextColumn get stickerId => text()();

  DateTimeColumn get unlockedAt => dateTime().withDefault(currentDateAndTime)();

  /// Se este é o adesivo escolhido como avatar. No máximo uma linha `true`
  /// (garantido pelo repositório, que limpa as demais ao selecionar).
  BoolColumn get isSelected => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {stickerId};
}
