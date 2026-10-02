import 'package:flutter_test/flutter_test.dart';
import 'package:run_4_tree/core/services/models/plant_tree_response.dart';
import 'package:run_4_tree/core/services/models/tree_nation_exception.dart';
import 'package:run_4_tree/core/services/models/tree_planting_deferred_exception.dart';
import 'package:run_4_tree/core/services/tree_planting_function_service.dart';

void main() {
  group('PlantTreeResponse', () {
    test('tolera corpo de erro sem a chave trees', () {
      final response = PlantTreeResponse.fromJson({
        'status': 'error',
        'errorCode': 'tree_template',
        'errorMessage': 'no tree template',
      });

      expect(response.isOk, isFalse);
      expect(response.trees, isEmpty);
      expect(response.errorCode, 'tree_template');
    });
  });

  group('TreePlantingFunctionService.parseResponse', () {
    test('converte o retorno da função (mapas sem tipo) nas árvores', () {
      // O plugin entrega mapas aninhados como Map<Object?, Object?>.
      final data = <Object?, Object?>{
        'status': 'ok',
        'payment_id': 99,
        'trees': <Object?>[
          <Object?, Object?>{
            'id': 1,
            'internal_id': null,
            'token': 'tok',
            'collect_url': 'https://c',
            'certificate_url': 'https://cert',
            'country': 'BR',
            'project_id': 7,
            'project_name': 'Projeto',
            'project_url': 'https://p',
            'species_id': 3,
            'species_name': 'Ipê',
            'species_life_time_CO2': 12.5,
          },
        ],
      };

      final result = TreePlantingFunctionService.parseResponse(data);

      expect(result.isOk, isTrue);
      expect(result.trees.single.id, 1);
      expect(result.trees.single.speciesLifeTimeCo2, 12.5);
      expect(result.paymentId, 99);
    });

    test('status ok sem árvores não conta como plantio', () {
      expect(
        () => TreePlantingFunctionService.parseResponse(<Object?, Object?>{
          'status': 'ok',
          'trees': <Object?>[],
        }),
        throwsFormatException,
      );
    });
  });

  group('TreePlantingFunctionService.parseResult', () {
    test('status ok vira árvore plantada, com o pedido', () {
      final result = TreePlantingFunctionService.parseResult(<Object?, Object?>{
        'status': 'ok',
        'orderStatus': 'planted',
        'orderId': 'personal_uid_3',
        'treeNumber': 3,
        'payment_id': 7,
        'trees': <Object?>[
          <Object?, Object?>{
            'id': 42,
            'token': '',
            'collect_url': 'https://c',
            'certificate_url': 'https://cert/42',
            'country': 'Tanzania',
            'project_id': 0,
            'project_name': 'Mkussu',
            'project_url': '',
            'species_id': 0,
            'species_name': 'Ceriops tagal',
            'species_life_time_CO2': 20,
          },
        ],
      });

      expect(
        result,
        isA<TreePlanted>()
            .having((r) => r.orderId, 'orderId', 'personal_uid_3')
            .having((r) => r.response.trees.single.id, 'tree id', 42),
      );
    });

    test('status pending vira árvore garantida, sem erro', () {
      final result = TreePlantingFunctionService.parseResult(<Object?, Object?>{
        'status': 'pending',
        'orderStatus': 'manual',
        'orderId': 'personal_uid_4',
        'treeNumber': 4,
        'reason': 'tree_template',
      });

      expect(
        result,
        isA<TreePending>()
            .having((r) => r.orderId, 'orderId', 'personal_uid_4')
            .having((r) => r.treeNumber, 'treeNumber', 4)
            .having((r) => r.orderStatus, 'orderStatus', 'manual')
            .having((r) => r.reason, 'reason', 'tree_template'),
      );
    });

    test('pedido pendente sem id é resposta inválida', () {
      expect(
        () => TreePlantingFunctionService.parseResult(<Object?, Object?>{
          'status': 'pending',
        }),
        throwsFormatException,
      );
    });
  });

  group('TreePlantingFunctionService.mapFunctionError', () {
    test('failed-precondition vira TreeNationException com o código real', () {
      final error = TreePlantingFunctionService.mapFunctionError(
        code: 'failed-precondition',
        message: 'Tree-Nation recusou o plantio',
        details: {
          'errorCode': 'tree_template',
          'errorMessage': 'no tree template',
        },
      );

      expect(
        error,
        isA<TreeNationException>()
            .having((e) => e.errorCode, 'errorCode', 'tree_template')
            .having((e) => e.errorMessage, 'errorMessage', 'no tree template')
            .having(
              (e) => e.isAccountConfigError,
              'isAccountConfigError',
              isTrue,
            )
            .having((e) => e.hint, 'hint', contains('tree template')),
      );
    });

    test('intervalo mínimo é adiamento silencioso, com tempo de espera', () {
      final error = TreePlantingFunctionService.mapFunctionError(
        code: 'resource-exhausted',
        message: 'Aguarde para plantar outra árvore.',
        details: {'reason': 'cooldown', 'retryAfterSeconds': 120},
      );

      expect(
        error,
        isA<TreePlantingDeferredException>()
            .having((e) => e.reason, 'reason', 'cooldown')
            .having(
              (e) => e.retryAfter,
              'retryAfter',
              const Duration(minutes: 2),
            )
            .having((e) => e.shouldReport, 'shouldReport', isFalse),
      );
    });

    test('teto diário é adiamento que vale alerta', () {
      final error = TreePlantingFunctionService.mapFunctionError(
        code: 'resource-exhausted',
        details: {'reason': 'daily_budget'},
      );

      expect(
        error,
        isA<TreePlantingDeferredException>()
            .having((e) => e.reason, 'reason', 'daily_budget')
            .having((e) => e.shouldReport, 'shouldReport', isTrue),
      );
    });

    test('indisponibilidade sem detalhes usa o código como motivo', () {
      final error = TreePlantingFunctionService.mapFunctionError(
        code: 'unavailable',
      );

      expect(
        error,
        isA<TreePlantingDeferredException>().having(
          (e) => e.reason,
          'reason',
          'unavailable',
        ),
      );
    });

    test('função inexistente (não publicada) é erro comum', () {
      final error = TreePlantingFunctionService.mapFunctionError(
        code: 'not-found',
        message: 'NOT_FOUND',
      );

      expect(error, isNot(isA<TreePlantingDeferredException>()));
      expect(error, isNot(isA<TreeNationException>()));
    });
  });
}
