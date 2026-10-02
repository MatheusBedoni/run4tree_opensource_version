import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'anonymous_auth_service.dart';
import 'models/plant_tree_response.dart';
import 'models/tree_nation_exception.dart';
import 'models/tree_planting_deferred_exception.dart';

/// Resultado de conquistar uma árvore pessoal.
sealed class PersonalPlantingResult {
  const PersonalPlantingResult();
}

/// A Tree-Nation plantou na hora: a árvore já tem certificado.
class TreePlanted extends PersonalPlantingResult {
  final PlantTreeResponse response;
  final String? orderId;

  /// Nº da árvore do usuário (0 no caminho antigo, sem pedido).
  final int treeNumber;

  const TreePlanted(this.response, {this.orderId, this.treeNumber = 0});
}

/// A árvore está garantida, mas o plantio ficou para depois (Tree-Nation
/// fora do ar, conta com problema...). O pedido segue no servidor e o
/// certificado chega pela sincronização, com push.
class TreePending extends PersonalPlantingResult {
  final String orderId;
  final int treeNumber;

  /// `pending`, `retry` ou `manual`.
  final String orderStatus;

  /// Código do motivo (ex: `tree_template`, `tree_nation_unavailable`).
  final String reason;

  const TreePending({
    required this.orderId,
    required this.treeNumber,
    required this.orderStatus,
    required this.reason,
  });
}

/// Pede à Cloud Function `plantPersonalTree` para plantar a árvore pessoal.
///
/// O token da Tree-Nation vive só no servidor (Secret Manager) — o app não
/// fala mais com a Tree-Nation, e o token não está mais dentro do APK. A
/// função confere o login anônimo, o intervalo mínimo por usuário e o teto
/// diário antes de plantar, e também publica a árvore no mural global.
class TreePlantingFunctionService {
  static const String functionName = 'plantPersonalTree';

  /// Mesma região das funções (Firestore em `nam5`).
  static const String region = 'us-central1';

  final FirebaseFunctions? _functionsOverride;
  final AnonymousAuthService _auth;

  TreePlantingFunctionService({
    FirebaseFunctions? functions,
    AnonymousAuthService? auth,
  }) : _functionsOverride = functions,
       _auth = auth ?? AnonymousAuthService.instance;

  /// Resolvido só no uso: sem Firebase inicializado, acessar a instância
  /// lança — e isso vira uma falha de plantio tratável, não um crash.
  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instanceFor(region: region);

  /// Conquista uma árvore. [planterId] liga o plantio ao cliente da RevenueCat.
  ///
  /// Devolve [TreePlanted] ou [TreePending] — um erro da Tree-Nation não
  /// perde mais a árvore. Lança [TreePlantingDeferredException] só quando o
  /// servidor nem criou o pedido (intervalo mínimo, sem rede, sem login).
  Future<PersonalPlantingResult> plantPersonalTree({String? planterId}) async {
    final uid = await _auth.ensureUserId();
    if (uid == null) {
      debugPrint('[TreePlanting] sem login anônimo — plantio adiado');
      throw const TreePlantingDeferredException(
        reason: 'not_signed_in',
        message: 'login anônimo indisponível (sem rede ou provedor desativado)',
      );
    }

    debugPrint(
      '[TreePlanting] chamando $functionName ($region) uid=$uid '
      'planterId=${planterId ?? '<nenhum>'}',
    );
    final stopwatch = Stopwatch()..start();
    try {
      final result = await _functions
          .httpsCallable(
            functionName,
            options: HttpsCallableOptions(timeout: const Duration(seconds: 45)),
          )
          // Avisa o servidor que este app sabe lidar com árvore garantida
          // (pedido pendente) em vez de erro.
          .call<Object?>({
            'planterId': ?planterId,
            'supportsPendingOrders': true,
          });

      debugPrint(
        '[TreePlanting] resposta em ${stopwatch.elapsedMilliseconds}ms: '
        '${result.data}',
      );

      final planting = parseResult(result.data);
      switch (planting) {
        case TreePlanted(:final response):
          for (final tree in response.trees) {
            debugPrint(
              '[TreePlanting] plantada: ${tree.id} ${tree.speciesName} '
              '(${tree.country}) certificado=${tree.certificateUrl}',
            );
          }
        case TreePending(:final orderId, :final orderStatus, :final reason):
          debugPrint(
            '[TreePlanting] garantida, plantio a caminho: pedido=$orderId '
            'status=$orderStatus motivo=$reason',
          );
      }
      return planting;
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        '[TreePlanting] função recusou em ${stopwatch.elapsedMilliseconds}ms: '
        'code=${e.code} message=${e.message} details=${e.details}',
      );
      final mapped = mapFunctionError(
        code: e.code,
        message: e.message,
        details: e.details,
      );
      debugPrint('[TreePlanting] tratado como: $mapped');
      throw mapped;
    } catch (e, st) {
      debugPrint(
        '[TreePlanting] erro inesperado em ${stopwatch.elapsedMilliseconds}ms: '
        '$e\n$st',
      );
      rethrow;
    }
  }

  /// Lê a resposta da função: `status: ok` (plantada, com as árvores) ou
  /// `status: pending` (garantida, com o pedido).
  @visibleForTesting
  static PersonalPlantingResult parseResult(Object? data) {
    final info = data is Map ? data : const <Object?, Object?>{};
    if (info['status'] == 'pending') {
      final orderId = info['orderId'];
      if (orderId is! String || orderId.isEmpty) {
        throw FormatException('pedido pendente sem orderId: $data');
      }
      final treeNumber = info['treeNumber'];
      return TreePending(
        orderId: orderId,
        treeNumber: treeNumber is num ? treeNumber.toInt() : 0,
        orderStatus: info['orderStatus'] is String
            ? info['orderStatus'] as String
            : 'pending',
        reason: info['reason'] is String ? info['reason'] as String : '',
      );
    }
    final orderId = info['orderId'];
    final treeNumber = info['treeNumber'];
    return TreePlanted(
      parseResponse(data),
      orderId: orderId is String ? orderId : null,
      treeNumber: treeNumber is num ? treeNumber.toInt() : 0,
    );
  }

  /// Converte o retorno da função (mapas aninhados sem tipo) no modelo que o
  /// app já usava com a Tree-Nation.
  @visibleForTesting
  static PlantTreeResponse parseResponse(Object? data) {
    final json = jsonDecode(jsonEncode(data));
    if (json is! Map<String, dynamic>) {
      throw FormatException('resposta inesperada de $functionName: $data');
    }
    final response = PlantTreeResponse.fromJson(json);
    if (!response.isOk || response.trees.isEmpty) {
      throw FormatException('$functionName não devolveu árvores: $data');
    }
    return response;
  }

  /// Traduz o erro da função para as exceções que o jardim já trata.
  @visibleForTesting
  static Exception mapFunctionError({
    required String code,
    String? message,
    Object? details,
  }) {
    final info = details is Map ? details : const <Object?, Object?>{};
    String? text(String key) =>
        info[key] is String ? info[key] as String : null;

    switch (code) {
      case 'failed-precondition':
        return TreeNationException(
          errorCode: text('errorCode'),
          errorMessage: text('errorMessage') ?? message,
          raw: details,
        );
      case 'resource-exhausted':
      case 'aborted':
      case 'unavailable':
      case 'deadline-exceeded':
      case 'unauthenticated':
        final seconds = info['retryAfterSeconds'];
        return TreePlantingDeferredException(
          reason: text('reason') ?? code,
          message: message ?? code,
          retryAfter: seconds is num
              ? Duration(seconds: seconds.toInt())
              : null,
        );
      default:
        return Exception('$functionName falhou ($code): ${message ?? ''}');
    }
  }
}
