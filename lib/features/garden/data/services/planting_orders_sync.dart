import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/planted_tree_entity.dart';
import '../../domain/repositories/tree_garden_repository.dart';
import '../repositories/tree_garden_repository_impl.dart';

/// Acompanha os pedidos de plantio do próprio usuário (`planting_orders`
/// onde `uid == eu`) e, quando um pedido pendente vira `planted` — pela API
/// ou pelo admin —, troca a árvore "a caminho" pela real, com o certificado.
///
/// O push "seu certificado está pronto" vem do servidor; isto só mantém a
/// floresta local em dia.
class PlantingOrdersSync {
  PlantingOrdersSync._();

  static final PlantingOrdersSync instance = PlantingOrdersSync._();

  /// Incrementa a cada árvore que chega — a floresta escuta para recarregar.
  final ValueNotifier<int> completed = ValueNotifier<int>(0);

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  TreeGardenRepository? _repository;

  void start(String uid, {TreeGardenRepository? repository}) {
    if (_subscription != null) return;
    _repository = repository ?? TreeGardenRepositoryImpl();
    try {
      _subscription = FirebaseFirestore.instance
          .collection('planting_orders')
          .where('uid', isEqualTo: uid)
          .snapshots()
          .listen(
            _onSnapshot,
            onError: (Object e) =>
                debugPrint('[PlantingOrders] escuta falhou: $e'),
          );
      debugPrint('[PlantingOrders] acompanhando pedidos de $uid');
    } catch (e) {
      debugPrint('[PlantingOrders] não foi possível acompanhar: $e');
    }
  }

  Future<void> _onSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    final repository = _repository;
    if (repository == null) return;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['status'] != 'planted') continue;
      final tree = treeFromOrder(data);
      if (tree == null) continue;

      final paymentId = (data['tree'] as Map)['paymentId'];
      final moved = await repository.completePendingTree(
        orderId: doc.id,
        tree: tree,
        paymentId: paymentId is num ? paymentId.toInt() : null,
      );
      if (moved) {
        completed.value++;
        debugPrint(
          '[PlantingOrders] certificado chegou: ${doc.id} → '
          '${tree.certificateUrl}',
        );
      }
    }
  }

  /// Converte `tree` de um pedido plantado; `null` sem certificado.
  @visibleForTesting
  static PlantedTreeEntity? treeFromOrder(Map<String, dynamic> order) {
    final tree = order['tree'];
    if (tree is! Map) return null;
    final certificateUrl = tree['certificateUrl'];
    if (certificateUrl is! String || certificateUrl.isEmpty) return null;

    String text(String key) => tree[key] is String ? tree[key] as String : '';
    final treeNationId = tree['treeNationId'];
    final co2 = tree['co2LifeTimeKg'];
    final plantedAt = order['plantedAt'];

    return PlantedTreeEntity(
      treeNationId: treeNationId is num ? treeNationId.toInt() : 0,
      certificateUrl: certificateUrl,
      collectUrl: text('collectUrl'),
      country: text('country'),
      projectName: text('projectName'),
      projectUrl: text('projectUrl'),
      speciesName: text('speciesName'),
      co2LifeTimeKg: co2 is num ? co2.toDouble() : 0,
      plantedAt: plantedAt is Timestamp ? plantedAt.toDate() : DateTime.now(),
    );
  }
}
