import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_4_tree/core/services/push_notification_service.dart';
import 'package:run_4_tree/features/global_forest/data/repositories/feed_repository_impl.dart';
import 'package:run_4_tree/features/global_forest/domain/repositories/feed_repository.dart';

void main() {
  group('FeedRepositoryImpl.fromData', () {
    test('item pessoal plantado, com post', () {
      final item = FeedRepositoryImpl.fromData('personal_ana_1', {
        'source': 'personal',
        'authorId': 'ana',
        'treeNumber': 1,
        'status': 'planted',
        'hidden': false,
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 9, 21, 10)),
        'tree': {
          'speciesName': 'Ceriops tagal',
          'country': 'Tanzania',
          'certificateUrl': 'https://cert/1',
          'co2LifeTimeKg': 20,
        },
        'post': {
          'message': 'Primeira árvore!',
          'stickerId': '3',
          'authorName': 'Ana',
          'postedAt': Timestamp.fromDate(DateTime.utc(2026, 9, 21, 11)),
        },
      });

      expect(item.isGroup, isFalse);
      expect(item.isPlanted, isTrue);
      expect(item.tree?.country, 'Tanzania');
      expect(item.tree?.co2LifeTimeKg, 20);
      expect(item.post?.authorName, 'Ana');
      expect(
        item.shownAt.isAtSameMomentAs(DateTime.utc(2026, 9, 21, 11)),
        isTrue,
        reason: 'post sobe o item',
      );
      expect(item.isMine('ana'), isTrue);
      expect(item.canPost('ana'), isFalse, reason: 'já comemorou');
    });

    test('árvore a caminho, sem post: o dono pode comemorar', () {
      final item = FeedRepositoryImpl.fromData('personal_bia_2', {
        'source': 'personal',
        'authorId': 'bia',
        'treeNumber': 2,
        'status': 'pending',
        'tree': null,
        'post': null,
      });

      expect(item.isPlanted, isFalse);
      expect(item.tree, isNull);
      expect(item.post, isNull);
      expect(item.canPost('bia'), isTrue);
      expect(item.canPost('outra'), isFalse);
    });

    test('árvore de grupo nunca é "minha"', () {
      final item = FeedRepositoryImpl.fromData('group_c1_1', {
        'source': 'group',
        'authorId': '',
        'challengeTitle': 'Setembro Verde',
        'status': 'planted',
      });

      expect(item.isGroup, isTrue);
      expect(item.challengeTitle, 'Setembro Verde');
      expect(item.isMine(''), isFalse);
      expect(item.canPost(''), isFalse);
    });

    test('post sem mensagem (apagado) conta como sem post', () {
      final item = FeedRepositoryImpl.fromData('x', {
        'source': 'personal',
        'post': {'message': ''},
      });
      expect(item.post, isNull);
    });
  });

  group('FeedRepositoryImpl.mapFailure', () {
    test('usa o motivo da função', () {
      expect(
        FeedRepositoryImpl.mapFailure('already-exists', {'reason': 'already_posted'}),
        FeedFailure.alreadyPosted,
      );
      expect(
        FeedRepositoryImpl.mapFailure('resource-exhausted', {'reason': 'rate_limited'}),
        FeedFailure.rateLimited,
      );
      expect(
        FeedRepositoryImpl.mapFailure('permission-denied', {'reason': 'not_owner'}),
        FeedFailure.notAllowed,
      );
    });

    test('sem motivo, cai no código', () {
      expect(FeedRepositoryImpl.mapFailure('unavailable', null), FeedFailure.network);
      expect(FeedRepositoryImpl.mapFailure('internal', null), FeedFailure.unknown);
    });
  });

  group('PushNotificationService.feedItemIdFrom', () {
    test('push do feed traz o item', () {
      expect(
        PushNotificationService.feedItemIdFrom({'type': 'feed_post', 'itemId': 'personal_ana_1'}),
        'personal_ana_1',
      );
    });

    test('outros pushes não abrem o feed', () {
      expect(
        PushNotificationService.feedItemIdFrom({'type': 'personal_tree', 'itemId': 'x'}),
        isNull,
      );
      expect(PushNotificationService.feedItemIdFrom(null), isNull);
    });
  });
}
