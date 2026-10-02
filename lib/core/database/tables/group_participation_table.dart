import 'package:drift/drift.dart';

/// Tabela Drift com o desafio em grupo do qual o usuário participa.
///
/// Mantém uma única linha (id fixo 1), como [TreeProgress]: o usuário está
/// em no máximo um grupo por vez. O Firestore é a fonte da verdade do
/// desafio; aqui fica só o vínculo local, para o app saber em qual grupo o
/// usuário entrou mesmo antes da rede responder.
class GroupParticipation extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();

  /// Id do documento em `group_challenges`.
  TextColumn get challengeId => text()();

  /// `uid` anônimo do Firebase usado ao entrar — também é o id do documento
  /// em `group_challenges/{challengeId}/participants`.
  TextColumn get participantId => text()();

  DateTimeColumn get joinedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
