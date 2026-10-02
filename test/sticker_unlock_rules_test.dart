import 'package:flutter_test/flutter_test.dart';
import 'package:run_4_tree/features/runs/domain/entities/run_session_entity.dart';
import 'package:run_4_tree/features/stickers/domain/entities/sticker_definition.dart';
import 'package:run_4_tree/features/stickers/domain/entities/sticker_requirement.dart';
import 'package:run_4_tree/features/stickers/domain/entities/sticker_stats.dart';

RunSessionEntity _run({
  double distanceKm = 5,
  String exerciseType = 'run',
  required DateTime createdAt,
}) {
  return RunSessionEntity(
    durationSeconds: 1800,
    distanceKm: distanceKm,
    calories: 300,
    averageSpeed: 10,
    maxSpeed: 12,
    pace: 6,
    polyline: '[]',
    isNight: false,
    treesEarned: 0,
    exerciseType: exerciseType,
    createdAt: createdAt,
  );
}

void main() {
  final now = DateTime(2026, 9, 6, 12); // domingo

  group('StickerStats.fromHistory', () {
    test('sem corridas, zera tudo menos as árvores', () {
      final stats = StickerStats.fromHistory(
        runs: const [],
        treesPlanted: 3,
        weeklyGoalKm: 10,
        now: now,
      );

      expect(stats.totalRuns, 0);
      expect(stats.totalDistanceKm, 0);
      expect(stats.currentStreakDays, 0);
      expect(stats.treesPlanted, 3);
    });

    test('soma distância, guarda a maior e conta tipos distintos', () {
      final stats = StickerStats.fromHistory(
        runs: [
          _run(distanceKm: 4, createdAt: now),
          _run(distanceKm: 7.5, exerciseType: 'walk', createdAt: now),
          _run(distanceKm: 2, exerciseType: 'bike', createdAt: now),
        ],
        treesPlanted: 0,
        weeklyGoalKm: 0,
        now: now,
      );

      expect(stats.totalRuns, 3);
      expect(stats.totalDistanceKm, closeTo(13.5, 0.001));
      expect(stats.longestRunKm, 7.5);
      expect(stats.distinctExerciseTypes, 3);
    });

    test('sequência conta dias consecutivos terminando hoje', () {
      final stats = StickerStats.fromHistory(
        runs: [
          _run(createdAt: now),
          _run(createdAt: now.subtract(const Duration(days: 1))),
          _run(createdAt: now.subtract(const Duration(days: 2))),
          // buraco no dia 3 — a sequência para aqui
          _run(createdAt: now.subtract(const Duration(days: 4))),
        ],
        treesPlanted: 0,
        weeklyGoalKm: 0,
        now: now,
      );

      expect(stats.currentStreakDays, 3);
    });

    test('sequência sobrevive ao dia corrente ainda sem atividade', () {
      final stats = StickerStats.fromHistory(
        runs: [
          _run(createdAt: now.subtract(const Duration(days: 1))),
          _run(createdAt: now.subtract(const Duration(days: 2))),
        ],
        treesPlanted: 0,
        weeklyGoalKm: 0,
        now: now,
      );

      expect(stats.currentStreakDays, 2);
    });

    test('sequência zera quando a última atividade é antiga', () {
      final stats = StickerStats.fromHistory(
        runs: [_run(createdAt: now.subtract(const Duration(days: 3)))],
        treesPlanted: 0,
        weeklyGoalKm: 0,
        now: now,
      );

      expect(stats.currentStreakDays, 0);
    });

    test('duas atividades no mesmo dia contam como um dia só', () {
      final stats = StickerStats.fromHistory(
        runs: [
          _run(createdAt: now),
          _run(createdAt: now.subtract(const Duration(hours: 6))),
        ],
        treesPlanted: 0,
        weeklyGoalKm: 0,
        now: now,
      );

      expect(stats.currentStreakDays, 1);
    });

    test('conta atividades noturnas pelo horário de início', () {
      final stats = StickerStats.fromHistory(
        runs: [
          _run(createdAt: DateTime(2026, 9, 6, 21)),
          _run(createdAt: DateTime(2026, 9, 5, 4)),
          _run(createdAt: DateTime(2026, 9, 4, 13)),
        ],
        treesPlanted: 0,
        weeklyGoalKm: 0,
        now: now,
      );

      expect(stats.nightRuns, 2);
    });

    test('conta as semanas em que a meta semanal foi batida', () {
      final stats = StickerStats.fromHistory(
        runs: [
          // Semana corrente: 12 km — bateu a meta de 10.
          _run(distanceKm: 8, createdAt: DateTime(2026, 9, 2)),
          _run(distanceKm: 4, createdAt: DateTime(2026, 9, 4)),
          // Semana anterior: 6 km — não bateu.
          _run(distanceKm: 6, createdAt: DateTime(2026, 8, 26)),
        ],
        treesPlanted: 0,
        weeklyGoalKm: 10,
        now: now,
      );

      expect(stats.weeklyGoalWeeksReached, 1);
    });

    test('sem meta definida, nenhuma semana conta', () {
      final stats = StickerStats.fromHistory(
        runs: [_run(distanceKm: 30, createdAt: now)],
        treesPlanted: 0,
        weeklyGoalKm: 0,
        now: now,
      );

      expect(stats.weeklyGoalWeeksReached, 0);
    });
  });

  group('StickerRequirement', () {
    test('adesivo livre já nasce satisfeito', () {
      const requirement = StickerRequirement.free();

      expect(requirement.isSatisfiedBy(const StickerStats.empty()), isTrue);
      expect(requirement.progress(const StickerStats.empty()), 1);
    });

    test('progresso é proporcional e limitado a 1', () {
      const requirement =
          StickerRequirement(StickerRequirementType.totalDistanceKm, 10);
      final stats = StickerStats.fromHistory(
        runs: [_run(distanceKm: 2.5, createdAt: now)],
        treesPlanted: 0,
        weeklyGoalKm: 0,
        now: now,
      );

      expect(requirement.progress(stats), closeTo(0.25, 0.001));
      expect(requirement.isSatisfiedBy(stats), isFalse);

      final done = StickerStats.fromHistory(
        runs: [_run(distanceKm: 42, createdAt: now)],
        treesPlanted: 0,
        weeklyGoalKm: 0,
        now: now,
      );
      expect(requirement.progress(done), 1);
      expect(requirement.isSatisfiedBy(done), isTrue);
    });
  });

  group('StickerCatalog', () {
    test('ids são únicos', () {
      final ids = StickerCatalog.all.map((sticker) => sticker.id).toSet();

      expect(ids.length, StickerCatalog.all.length);
    });

    test('os três primeiros adesivos são livres e o resto é conquistado', () {
      expect(StickerCatalog.freeStickers.length, 3);
      expect(
        StickerCatalog.all.take(3).every((sticker) => sticker.isFree),
        isTrue,
      );
      expect(
        StickerCatalog.all.skip(3).any((sticker) => sticker.isFree),
        isFalse,
      );
    });

    test('todo adesivo conquistável tem alvo positivo', () {
      for (final sticker in StickerCatalog.all.where((s) => !s.isFree)) {
        expect(
          sticker.requirement.target,
          greaterThan(0),
          reason: 'adesivo ${sticker.id} sem alvo',
        );
      }
    });
  });
}
