import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/observability/critical_flow_telemetry.dart';
import '../../../../core/services/models/plant_tree_response.dart';
import '../../../../core/services/models/tree_nation_exception.dart';
import '../../../../core/services/models/tree_planting_deferred_exception.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/services/tree_planting_function_service.dart';
import '../../../../core/utils/env.dart';
import '../../../../core/utils/purchases_safe_call.dart';
import '../services/earned_trees.dart';
import '../../domain/entities/pending_tree_entity.dart';
import '../../domain/entities/planted_tree_entity.dart';
import '../../domain/entities/tree_progress_entity.dart';
import '../../domain/repositories/tree_garden_repository.dart';

/// Implementação concreta do [TreeGardenRepository].
///
/// Guarda o progresso em uma única linha (id fixo 1) na tabela [TreeProgress]
/// do Drift. Cada anúncio assistido (início/fim de corrida, banner) credita a
/// receita real que pagou (ou uma estimativa, se a conta AdMob ainda não
/// reporta receita por impressão); ao acumular [treePriceUsd], uma árvore de
/// verdade é plantada pela Cloud Function `plantPersonalTree`
/// ([TreePlantingFunctionService]) — o token da Tree-Nation e a espécie ficam
/// só no servidor.
class TreeGardenRepositoryImpl implements TreeGardenRepository {
  /// Preço da árvore lido do `.env`. `tryParse` em vez de `parse` porque um
  /// valor ausente/vazio/malformado estouraria uma `FormatException` no
  /// inicializador estático, derrubando todo o fluxo de crédito de anúncio.
  static double treePriceUsd = _readTreePriceUsd();

  static double _readTreePriceUsd() {
    final raw = envOrNull('TREE_PRICE');
    final parsed = double.tryParse(raw ?? '');
    if (parsed == null || parsed <= 0) {
      debugPrint(
        '[Garden] TREE_PRICE inválido no .env: "${raw ?? '<ausente>'}"',
      );
      return 0;
    }
    return parsed;
  }

  static const int _rowId = 1;

  final AppDatabase _db;
  final TreePlantingFunctionService _plantingService;

  TreeGardenRepositoryImpl({
    AppDatabase? db,
    TreePlantingFunctionService? plantingService,
  }) : _db = db ?? AppDatabase.instance,
       _plantingService = plantingService ?? TreePlantingFunctionService();

  @override
  Future<TreeProgressEntity> getProgress() async {
    final row = await _getOrCreateRow();
    final entity = _toEntity(row);
    debugPrint(
      '[Garden] getProgress: saldo \$${entity.revenueAccumulatedUsd} | '
      'preço \$${entity.treePriceUsd} | árvores ${entity.treesPlanted} | '
      '${(entity.progressPercent * 100).toStringAsFixed(1)}%',
    );
    return entity;
  }

  @override
  Future<TreeProgressEntity> creditAdRevenueAndUpdateProgress(
    double revenueUsd,
  ) async {
    final row = await _getOrCreateRow();
    var revenue = row.revenueAccumulatedUsd + revenueUsd;
    var trees = row.treesPlanted;

    debugPrint(
      '[Garden] crédito de anúncio: +\$$revenueUsd | '
      'acumulado ${row.revenueAccumulatedUsd} -> $revenue | '
      'preço da árvore \$$treePriceUsd | árvores $trees',
    );

    // Preço inválido (TREE_PRICE ausente/zerado no .env) tornaria o `while`
    // abaixo um laço infinito e zeraria o progresso exibido. Aborta cedo e
    // deixa o motivo explícito no log.
    if (treePriceUsd <= 0) {
      debugPrint(
        '[Garden] ERRO: TREE_PRICE inválido ($treePriceUsd). '
        'Defina TREE_PRICE no .env — nenhuma árvore será plantada.',
      );
      await _persist(revenue, trees);
      return TreeProgressEntity(
        revenueAccumulatedUsd: revenue,
        treePriceUsd: treePriceUsd,
        treesPlanted: trees,
      );
    }

    // Identifica o plantio com o appUserID da RevenueCat, ligando o registro
    // real da Tree-Nation ao mesmo usuário rastreado nos eventos de anúncio.
    // Sem RevenueCat configurado, planta sem esse vínculo em vez de falhar.
    final planterId = await safePurchasesCall(
      'appUserID',
      () => Purchases.appUserID,
    );
    debugPrint('[Garden] planterId=${planterId ?? "<null: RevenueCat off>"}');

    if (revenue < treePriceUsd) {
      debugPrint(
        '[Garden] ainda não dá para plantar: faltam '
        '\$${(treePriceUsd - revenue).toStringAsFixed(4)}',
      );
    }

    while (revenue >= treePriceUsd) {
      debugPrint('[Garden] tentando plantar árvore (saldo \$$revenue)...');
      try {
        await CriticalFlowTelemetry.treePlantingStarted();
        final result = await _plantingService.plantPersonalTree(
          planterId: planterId,
        );
        // Nos dois casos a árvore está conquistada: o anel zera e o usuário
        // segue plantando. Se a Tree-Nation falhou, o pedido fica no servidor
        // e o certificado chega depois (sincronização + push).
        switch (result) {
          case TreePlanted(:final response, :final orderId, :final treeNumber):
            await _savePlantedTrees(response);
            unawaited(CriticalFlowTelemetry.treePlanted());
            debugPrint('[Garden] árvore plantada na hora!');
            final tree = response.trees.firstOrNull;
            EarnedTrees.instance.add(
              EarnedTree(
                orderId: orderId,
                treeNumber: treeNumber,
                isPlanted: true,
                speciesName: tree?.speciesName ?? '',
                country: tree?.country ?? '',
              ),
            );
          case TreePending(:final orderId, :final treeNumber, :final reason):
            await _savePendingTree(orderId, treeNumber);
            debugPrint(
              '[Garden] árvore #$treeNumber garantida (pedido $orderId, '
              'motivo: $reason) — o certificado chega quando for plantada',
            );
            EarnedTrees.instance.add(
              EarnedTree(
                orderId: orderId,
                treeNumber: treeNumber,
                isPlanted: false,
              ),
            );
        }
        revenue -= treePriceUsd;
        trees += 1;
        debugPrint(
          '[Garden] árvores conquistadas=$trees | saldo restante \$$revenue',
        );
      } on TreePlantingDeferredException catch (e) {
        // O servidor não plantou agora (intervalo mínimo, teto diário, plantio
        // em andamento, sem rede): a receita fica guardada e a próxima
        // tentativa acontece no próximo crédito de anúncio.
        debugPrint('[Garden] plantio adiado pelo servidor: $e');
        _logStuckAtFullRing(revenue);
        if (e.shouldReport) {
          unawaited(
            CriticalFlowTelemetry.treePlantingFailed(
              reason: 'deferred_${e.reason}',
              error: e,
              stackTrace: StackTrace.current,
            ),
          );
        }
        break;
      } on TreeNationException catch (e) {
        // Erro de negócio da API. Se for de configuração da conta (sem tree
        // template, sem crédito, token inválido), repetir não resolve — o
        // ajuste é no painel da Tree-Nation.
        debugPrint('[Garden] FALHA ao plantar: $e');
        if (e.isAccountConfigError) {
          debugPrint(
            '[Garden] erro de CONFIGURAÇÃO da conta Tree-Nation — nenhuma '
            'tentativa futura vai funcionar até ser corrigido no painel.',
          );
        }
        _logStuckAtFullRing(revenue);
        unawaited(
          CriticalFlowTelemetry.treePlantingFailed(
            reason: e.isAccountConfigError
                ? 'account_configuration'
                : 'provider_rejected',
            error: e,
            stackTrace: StackTrace.current,
          ),
        );
        break;
      } catch (e, st) {
        // Falha ao plantar de verdade (rede/API indisponível): mantém a
        // receita acumulada para tentar novamente na próxima vez. Enquanto
        // isso o progresso fica travado em 100%, porque `revenue` continua
        // >= treePriceUsd — é esse o sintoma visível do anel cheio.
        debugPrint('[Garden] FALHA ao plantar: $e');
        debugPrint('[Garden] stack: $st');
        _logStuckAtFullRing(revenue);
        unawaited(
          CriticalFlowTelemetry.treePlantingFailed(
            reason: 'request_failed',
            error: e,
            stackTrace: st,
          ),
        );
        break;
      }
    }

    await _persist(revenue, trees);

    // Expõe o progresso no perfil do usuário na RevenueCat (visível no
    // dashboard e disponível para segmentação/CRM), sem exigir assinatura.
    // Best-effort: não deve bloquear o progresso local se falhar.
    fireAndForgetPurchasesCall(
      'setAttributes',
      () => Purchases.setAttributes({
        'ad_revenue_accumulated_usd': revenue.toStringAsFixed(4),
        'trees_planted': '$trees',
      }),
    );

    final result = TreeProgressEntity(
      revenueAccumulatedUsd: revenue,
      treePriceUsd: treePriceUsd,
      treesPlanted: trees,
    );

    // Mesmos números como tags do OneSignal: é o que permite segmentar os
    // pushes por progresso (ex: quem está a uma semente da próxima árvore).
    unawaited(
      PushNotificationService.instance.setTags({
        'trees_planted': '$trees',
        'seeds': '${result.seedsAccumulated}',
      }),
    );
    debugPrint(
      '[Garden] progresso final: ${(result.progressPercent * 100).toStringAsFixed(1)}% '
      '(${result.seedsAccumulated}/${TreeProgressEntity.seedsPerTree} sementes) | '
      'árvores=${result.treesPlanted}',
    );
    return result;
  }

  void _logStuckAtFullRing(double revenue) => debugPrint(
    '[Garden] progresso travado em 100%: saldo \$$revenue >= '
    'preço \$$treePriceUsd e a árvore não foi criada.',
  );

  Future<void> _persist(double revenue, int trees) => _db
      .into(_db.treeProgress)
      .insertOnConflictUpdate(
        TreeProgressCompanion(
          id: const Value(_rowId),
          revenueAccumulatedUsd: Value(revenue),
          treesPlanted: Value(trees),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<TreeProgressData> _getOrCreateRow() async {
    final existing = await (_db.select(
      _db.treeProgress,
    )..where((t) => t.id.equals(_rowId))).getSingleOrNull();
    if (existing != null) return existing;

    await _db
        .into(_db.treeProgress)
        .insertOnConflictUpdate(const TreeProgressCompanion(id: Value(_rowId)));
    return (_db.select(
      _db.treeProgress,
    )..where((t) => t.id.equals(_rowId))).getSingle();
  }

  TreeProgressEntity _toEntity(TreeProgressData row) => TreeProgressEntity(
    revenueAccumulatedUsd: row.revenueAccumulatedUsd,
    treePriceUsd: treePriceUsd,
    treesPlanted: row.treesPlanted,
  );

  /// Persiste cada árvore de [response.trees] na "floresta" local — usado
  /// para exibir o grid de árvores e o CO2 total compensado na GardenPage.
  /// O mural global já foi publicado pela Cloud Function, no servidor.
  Future<void> _savePlantedTrees(PlantTreeResponse response) async {
    debugPrint(
      '[Garden] salvando ${response.trees.length} árvore(s) no SQLite',
    );
    for (final tree in response.trees) {
      await _db
          .into(_db.plantedTrees)
          .insert(
            PlantedTreesCompanion.insert(
              treeNationId: tree.id,
              token: tree.token,
              collectUrl: tree.collectUrl,
              certificateUrl: tree.certificateUrl,
              country: tree.country,
              projectId: tree.projectId,
              projectName: tree.projectName,
              projectUrl: tree.projectUrl,
              speciesId: tree.speciesId,
              speciesName: tree.speciesName,
              speciesLifeTimeCo2: Value(tree.speciesLifeTimeCo2),
              paymentId: Value(response.paymentId),
            ),
          );
    }
  }

  Future<void> _savePendingTree(String orderId, int treeNumber) => _db
      .into(_db.pendingTrees)
      .insertOnConflictUpdate(
        PendingTreesCompanion.insert(orderId: orderId, treeNumber: treeNumber),
      );

  @override
  Future<List<PendingTreeEntity>> getPendingTrees() async {
    final rows = await (_db.select(
      _db.pendingTrees,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
    return rows
        .map(
          (row) => PendingTreeEntity(
            orderId: row.orderId,
            treeNumber: row.treeNumber,
            createdAt: row.createdAt,
          ),
        )
        .toList();
  }

  @override
  Future<bool> completePendingTree({
    required String orderId,
    required PlantedTreeEntity tree,
    int? paymentId,
  }) {
    // A árvore já foi contada ao ser conquistada: aqui só troca a pendência
    // pela árvore real, com o certificado.
    return _db.transaction(() async {
      final deleted = await (_db.delete(
        _db.pendingTrees,
      )..where((t) => t.orderId.equals(orderId))).go();
      if (deleted == 0) return false;

      await _db
          .into(_db.plantedTrees)
          .insert(
            PlantedTreesCompanion.insert(
              treeNationId: tree.treeNationId,
              token: '',
              collectUrl: tree.collectUrl,
              certificateUrl: tree.certificateUrl,
              country: tree.country,
              projectId: 0,
              projectName: tree.projectName,
              projectUrl: tree.projectUrl,
              speciesId: 0,
              speciesName: tree.speciesName,
              speciesLifeTimeCo2: Value(tree.co2LifeTimeKg),
              paymentId: Value(paymentId),
              plantedAt: Value(tree.plantedAt),
            ),
          );
      return true;
    });
  }

  @override
  Future<List<PlantedTreeEntity>> getPlantedTrees() async {
    final rows = await (_db.select(
      _db.plantedTrees,
    )..orderBy([(t) => OrderingTerm.desc(t.plantedAt)])).get();

    return rows
        .map(
          (row) => PlantedTreeEntity(
            treeNationId: row.treeNationId,
            certificateUrl: row.certificateUrl,
            collectUrl: row.collectUrl,
            country: row.country,
            projectName: row.projectName,
            projectUrl: row.projectUrl,
            speciesName: row.speciesName,
            co2LifeTimeKg: row.speciesLifeTimeCo2,
            plantedAt: row.plantedAt,
          ),
        )
        .toList();
  }
}
