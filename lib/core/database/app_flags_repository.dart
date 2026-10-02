import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'app_database.dart';

/// Acesso às marcas de estado do app ([AppFlags]).
///
/// Best-effort: uma falha de banco aqui nunca deve derrubar o fluxo que
/// consultou a marca (ex: pedir permissão de notificação).
class AppFlagsRepository {
  /// Já mostramos a explicação antes do pedido de notificação.
  static const String pushPermissionAsked = 'push_permission_asked';

  final AppDatabase _db;

  AppFlagsRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  Future<bool> isSet(String key) async {
    try {
      final row = await (_db.select(
        _db.appFlags,
      )..where((t) => t.key.equals(key))).getSingleOrNull();
      return row != null;
    } catch (e) {
      debugPrint('[AppFlags] leitura de "$key" falhou: $e');
      return false;
    }
  }

  /// Valor da marca, ou `null` se nunca foi gravada.
  Future<String?> getValue(String key) async {
    try {
      final row = await (_db.select(
        _db.appFlags,
      )..where((t) => t.key.equals(key))).getSingleOrNull();
      return row?.value;
    } catch (e) {
      debugPrint('[AppFlags] leitura de "$key" falhou: $e');
      return null;
    }
  }

  Future<void> set(String key, {String value = 'true'}) async {
    try {
      await _db
          .into(_db.appFlags)
          .insertOnConflictUpdate(
            AppFlagsCompanion(
              key: Value(key),
              value: Value(value),
              updatedAt: Value(DateTime.now()),
            ),
          );
    } catch (e) {
      debugPrint('[AppFlags] gravação de "$key" falhou: $e');
    }
  }
}
