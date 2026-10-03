import 'package:flutter_test/flutter_test.dart';
import 'package:run_4_tree/core/services/push_notification_service.dart';

void main() {
  group('PushNotificationService.certificateUriFrom', () {
    test('push de árvore pessoal abre o certificado', () {
      final uri = PushNotificationService.certificateUriFrom({
        'type': 'personal_tree',
        'treeId': 42,
        'certificateUrl': 'https://tree-nation.com/certificate/42',
      });

      expect(uri, Uri.parse('https://tree-nation.com/certificate/42'));
    });

    test('outros pushes não abrem nada', () {
      expect(
        PushNotificationService.certificateUriFrom({
          'type': 'group_workout',
          'challengeId': 'setembro',
        }),
        isNull,
      );
      expect(PushNotificationService.certificateUriFrom(null), isNull);
    });

    test('link sem https é ignorado', () {
      expect(
        PushNotificationService.certificateUriFrom({
          'type': 'personal_tree',
          'certificateUrl': 'javascript:alert(1)',
        }),
        isNull,
      );
      expect(
        PushNotificationService.certificateUriFrom({
          'type': 'personal_tree',
          'certificateUrl': 'http://tree-nation.com/c/1',
        }),
        isNull,
      );
    });
  });
}
