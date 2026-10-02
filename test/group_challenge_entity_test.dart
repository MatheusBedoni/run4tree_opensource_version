import 'package:flutter_test/flutter_test.dart';
import 'package:run_4_tree/features/community/domain/entities/group_challenge_entity.dart';

GroupChallengeEntity _challenge({
  String id = 'c1',
  GroupChallengeStatus status = GroupChallengeStatus.active,
  required DateTime startsAt,
  required DateTime endsAt,
  int treeGoal = 5,
  int seedsPerTree = 10,
  int seedsCollected = 0,
}) {
  return GroupChallengeEntity(
    id: id,
    title: 'Desafio',
    description: '',
    status: status,
    startsAt: startsAt,
    endsAt: endsAt,
    treeGoal: treeGoal,
    seedsPerTree: seedsPerTree,
    seedsCollected: seedsCollected,
    participantsCount: 0,
    treesPlanted: 0,
    workoutsCount: 0,
  );
}

void main() {
  final now = DateTime(2026, 9, 14, 12);
  final yesterday = now.subtract(const Duration(days: 1));
  final tomorrow = now.add(const Duration(days: 1));

  group('GroupChallengeEntity progresso', () {
    test('converte sementes em progresso e árvores cultivadas', () {
      final challenge = _challenge(
        startsAt: yesterday,
        endsAt: tomorrow,
        seedsCollected: 23,
      );

      expect(challenge.seedsGoal, 50);
      expect(challenge.progress, closeTo(0.46, 0.0001));
      expect(challenge.treesGrown, 2);
      expect(challenge.isGoalReached, isFalse);
    });

    test('limita progresso e árvores à meta', () {
      final challenge = _challenge(
        startsAt: yesterday,
        endsAt: tomorrow,
        seedsCollected: 80,
      );

      expect(challenge.progress, 1.0);
      expect(challenge.treesGrown, 5);
      expect(challenge.isGoalReached, isTrue);
    });

    test('meta mal configurada não divide por zero', () {
      final challenge = _challenge(
        startsAt: yesterday,
        endsAt: tomorrow,
        seedsPerTree: 0,
        seedsCollected: 10,
      );

      expect(challenge.progress, 0);
      expect(challenge.treesGrown, 0);
    });
  });

  group('GroupChallengeEntity.isOpenAt', () {
    test('aberto só se ativo e dentro da janela', () {
      expect(
        _challenge(startsAt: yesterday, endsAt: tomorrow).isOpenAt(now),
        isTrue,
      );
      expect(
        _challenge(startsAt: tomorrow, endsAt: tomorrow).isOpenAt(now),
        isFalse,
      );
      expect(
        _challenge(startsAt: yesterday, endsAt: now).isOpenAt(now),
        isFalse,
      );
      expect(
        _challenge(
          status: GroupChallengeStatus.draft,
          startsAt: yesterday,
          endsAt: tomorrow,
        ).isOpenAt(now),
        isFalse,
      );
    });
  });

  group('GroupChallengeEntity.pickFeatured', () {
    final endsSoon = _challenge(
      id: 'soon',
      startsAt: yesterday,
      endsAt: now.add(const Duration(hours: 2)),
    );
    final endsLater = _challenge(
      id: 'later',
      startsAt: yesterday,
      endsAt: now.add(const Duration(days: 5)),
    );
    final notStarted = _challenge(
      id: 'future',
      startsAt: tomorrow,
      endsAt: now.add(const Duration(days: 9)),
    );

    test('nenhum aberto → null (atalho some da home)', () {
      expect(GroupChallengeEntity.pickFeatured([notStarted], now: now), isNull);
      expect(GroupChallengeEntity.pickFeatured(const [], now: now), isNull);
    });

    test('prefere o desafio em que o usuário já entrou', () {
      final featured = GroupChallengeEntity.pickFeatured(
        [endsSoon, endsLater],
        now: now,
        joinedChallengeId: 'later',
      );
      expect(featured?.id, 'later');
    });

    test('sem participação, destaca o que termina primeiro', () {
      final featured = GroupChallengeEntity.pickFeatured(
        [endsLater, notStarted, endsSoon],
        now: now,
        joinedChallengeId: 'future',
      );
      expect(featured?.id, 'soon');
    });
  });
}
