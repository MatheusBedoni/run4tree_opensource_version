import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../garden/data/repositories/tree_garden_repository_impl.dart';
import '../../../garden/domain/repositories/tree_garden_repository.dart';
import '../../../onboarding/data/repositories/user_profile_repository_impl.dart';
import '../../../onboarding/domain/repositories/user_profile_repository.dart';
import '../../../runs/data/datasources/run_session_local_datasource_impl.dart';
import '../../../runs/data/repositories/run_session_repository_impl.dart';
import '../../../runs/domain/repositories/run_session_repository.dart';
import '../../domain/entities/sticker_definition.dart';
import '../../domain/entities/sticker_entity.dart';
import '../../domain/entities/sticker_stats.dart';
import '../../domain/repositories/sticker_repository.dart';

/// Implementação concreta do [StickerRepository].
///
/// O catálogo é código ([StickerCatalog]); o banco guarda só o que foi
/// conquistado. As métricas de desbloqueio são derivadas na hora a partir do
/// histórico de corridas + progresso de árvores, como o `ProfileRepositoryImpl`
/// já faz para o perfil.
class StickerRepositoryImpl implements StickerRepository {
  final AppDatabase _db;
  final RunSessionRepository _runSessionRepository;
  final TreeGardenRepository _treeGardenRepository;
  final UserProfileRepository _userProfileRepository;

  StickerRepositoryImpl({
    AppDatabase? db,
    RunSessionRepository? runSessionRepository,
    TreeGardenRepository? treeGardenRepository,
    UserProfileRepository? userProfileRepository,
  }) : _db = db ?? AppDatabase.instance,
       _runSessionRepository =
           runSessionRepository ??
           RunSessionRepositoryImpl(
             RunSessionLocalDataSourceImpl(db ?? AppDatabase.instance),
           ),
       _treeGardenRepository =
           treeGardenRepository ?? TreeGardenRepositoryImpl(),
       _userProfileRepository =
           userProfileRepository ?? UserProfileRepositoryImpl();

  @override
  Future<List<StickerEntity>> getStickers() async {
    final stats = await _loadStats();
    final rows = await _unlockedRowsById();
    return _buildEntities(stats, rows);
  }

  @override
  Future<List<StickerEntity>> syncUnlocks() async {
    final stats = await _loadStats();
    final rows = await _unlockedRowsById();

    final newlyUnlockedIds = <String>[];
    for (final definition in StickerCatalog.all) {
      if (rows.containsKey(definition.id)) continue;
      if (definition.requirement.isSatisfiedBy(stats)) {
        newlyUnlockedIds.add(definition.id);
      }
    }
    if (newlyUnlockedIds.isEmpty) return const [];

    final now = DateTime.now();
    await _db.batch((batch) {
      batch.insertAll(
        _db.unlockedStickers,
        newlyUnlockedIds.map(
          (id) => UnlockedStickersCompanion.insert(
            stickerId: id,
            unlockedAt: Value(now),
          ),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    });

    final updatedRows = await _unlockedRowsById();
    return _buildEntities(stats, updatedRows)
        .where(
          // Os adesivos livres entram calados: já nascem com o usuário, não são
          // recompensa a comemorar.
          (sticker) =>
              newlyUnlockedIds.contains(sticker.id) &&
              !sticker.definition.isFree,
        )
        .toList();
  }

  @override
  Future<StickerEntity> getSelectedSticker() async {
    final stickers = await getStickers();
    for (final sticker in stickers) {
      if (sticker.isSelected) return sticker;
    }
    // Sem escolha ainda: usa o primeiro desbloqueado (ou o padrão do catálogo,
    // caso o sync inicial ainda não tenha rodado).
    for (final sticker in stickers) {
      if (sticker.isUnlocked) return sticker;
    }
    return stickers.first;
  }

  @override
  Future<void> selectSticker(String stickerId) async {
    if (StickerCatalog.byId(stickerId) == null) return;

    final row = await (_db.select(
      _db.unlockedStickers,
    )..where((t) => t.stickerId.equals(stickerId))).getSingleOrNull();
    // Só adesivos já conquistados podem virar avatar.
    if (row == null) return;

    await _db.transaction(() async {
      await (_db.update(_db.unlockedStickers)
            ..where((t) => t.isSelected.equals(true)))
          .write(const UnlockedStickersCompanion(isSelected: Value(false)));
      await (_db.update(_db.unlockedStickers)
            ..where((t) => t.stickerId.equals(stickerId)))
          .write(const UnlockedStickersCompanion(isSelected: Value(true)));
    });
  }

  // ─── Internos ──────────────────────────────────────────────────────────────

  List<StickerEntity> _buildEntities(
    StickerStats stats,
    Map<String, UnlockedSticker> rows,
  ) {
    return StickerCatalog.all.map((definition) {
      final row = rows[definition.id];
      return StickerEntity.from(
        definition: definition,
        stats: stats,
        unlockedAt: row?.unlockedAt,
        isSelected: row?.isSelected ?? false,
      );
    }).toList();
  }

  Future<Map<String, UnlockedSticker>> _unlockedRowsById() async {
    final rows = await _db.select(_db.unlockedStickers).get();
    return {for (final row in rows) row.stickerId: row};
  }

  /// Deriva as métricas do usuário a partir das corridas salvas, das árvores
  /// plantadas e da meta semanal do questionário. O cálculo em si mora no
  /// domínio ([StickerStats.fromHistory]).
  Future<StickerStats> _loadStats() async {
    final runs = await _runSessionRepository.getAllRuns();
    final treeProgress = await _treeGardenRepository.getProgress();
    final userProfile = await _userProfileRepository.getUserProfile();

    return StickerStats.fromHistory(
      runs: runs,
      treesPlanted: treeProgress.treesPlanted,
      weeklyGoalKm: userProfile?.weeklyGoalKm ?? 0,
    );
  }
}
