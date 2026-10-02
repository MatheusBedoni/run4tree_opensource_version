import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_4_tree/features/home/presentation/pages/home_page.dart';
import 'package:run_4_tree/features/stickers/domain/entities/sticker_definition.dart';
import 'package:run_4_tree/features/stickers/domain/entities/sticker_entity.dart';
import 'package:run_4_tree/features/stickers/domain/entities/sticker_stats.dart';
import 'package:run_4_tree/features/stickers/domain/repositories/sticker_repository.dart';
import 'package:run_4_tree/features/stickers/domain/usecases/get_stickers_usecase.dart';
import 'package:run_4_tree/features/stickers/domain/usecases/select_sticker_avatar_usecase.dart';
import 'package:run_4_tree/features/stickers/domain/usecases/sync_sticker_unlocks_usecase.dart';
import 'package:run_4_tree/features/stickers/presentation/controllers/sticker_controller.dart';
import 'package:run_4_tree/features/stickers/presentation/pages/sticker_collection_page.dart';
import 'package:run_4_tree/features/stickers/presentation/widgets/sticker_tile.dart';
import 'package:run_4_tree/l10n/generated/app_localizations.dart';

/// Repositório de mentira: guarda tudo em memória, sem banco.
class _FakeStickerRepository implements StickerRepository {
  final StickerStats stats;
  final Set<String> unlocked;
  String? selected;

  _FakeStickerRepository({required this.stats, required this.unlocked});

  @override
  Future<List<StickerEntity>> getStickers() async {
    return StickerCatalog.all
        .map(
          (definition) => StickerEntity.from(
            definition: definition,
            stats: stats,
            unlockedAt: unlocked.contains(definition.id)
                ? DateTime(2026, 1, 1)
                : null,
            isSelected: selected == definition.id,
          ),
        )
        .toList();
  }

  @override
  Future<StickerEntity> getSelectedSticker() async {
    final stickers = await getStickers();
    return stickers.firstWhere(
      (sticker) => sticker.isSelected,
      orElse: () => stickers.first,
    );
  }

  @override
  Future<void> selectSticker(String stickerId) async {
    if (unlocked.contains(stickerId)) selected = stickerId;
  }

  @override
  Future<List<StickerEntity>> syncUnlocks() async {
    final newly = <StickerEntity>[];
    final stickers = await getStickers();
    for (final sticker in stickers) {
      if (sticker.isUnlocked) continue;
      if (sticker.requirement.isSatisfiedBy(stats)) {
        unlocked.add(sticker.id);
        // Livres entram calados, como na implementação real.
        if (!sticker.definition.isFree) newly.add(sticker);
      }
    }
    return newly;
  }
}

StickerController _controllerFor(_FakeStickerRepository repository) {
  return StickerController(
    GetStickersUseCase(repository),
    SyncStickerUnlocksUseCase(repository),
    SelectStickerAvatarUseCase(repository),
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  setUp(() {
    // Tela alta o bastante para a grade preguiçosa renderizar as primeiras
    // linhas de adesivos, incluindo os bloqueados.
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first;
    view.physicalSize = const Size(1200, 2600);
    view.devicePixelRatio = 1.0;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });
  });

  testWidgets('coleção mostra todos os adesivos do catálogo', (tester) async {
    final repository = _FakeStickerRepository(
      stats: const StickerStats.empty(),
      unlocked: {'1', '2', '3'},
    );
    final controller = _controllerFor(repository);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _wrap(StickerCollectionPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('3 of 14 unlocked'), findsOneWidget);
    // A grade é rolável: confere que os primeiros tiles renderizaram.
    expect(find.byType(StickerTile), findsWidgets);
    // Aparece no cabeçalho (avatar em uso) e no próprio tile.
    expect(find.text('Dawn Swallow'), findsNWidgets(2));
  });

  testWidgets('tocar num adesivo desbloqueado define o avatar', (tester) async {
    final repository = _FakeStickerRepository(
      stats: const StickerStats.empty(),
      unlocked: {'1', '2', '3'},
    );
    final controller = _controllerFor(repository);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _wrap(StickerCollectionPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Monarch'));
    await tester.pumpAndSettle();

    expect(repository.selected, '2');
    expect(controller.selectedSticker?.id, '2');
    expect(find.text('In use'), findsOneWidget);
  });

  testWidgets('adesivo bloqueado mostra requisito e progresso', (tester) async {
    final repository = _FakeStickerRepository(
      stats: const StickerStats.empty(),
      unlocked: {'1', '2', '3'},
    );
    final controller = _controllerFor(repository);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _wrap(StickerCollectionPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    // Adesivo 4: "Finish your first activity".
    expect(find.text('Finish your first activity'), findsOneWidget);
    // Adesivo 5: 10 km acumulados, ainda em zero.
    expect(find.text('Cover 10 km in total'), findsOneWidget);
    expect(find.text('0.0 / 10 km'), findsOneWidget);

    // Bloqueado não responde ao toque.
    await tester.tap(find.text('Tiger Moth'));
    await tester.pumpAndSettle();
    expect(repository.selected, isNull);
  });

  testWidgets('conquista nova abre a celebração ao entrar na coleção', (
    tester,
  ) async {
    final repository = _FakeStickerRepository(
      stats: const StickerStats(
        totalRuns: 1,
        totalDistanceKm: 3,
        longestRunKm: 3,
        currentStreakDays: 1,
        treesPlanted: 0,
        weeklyGoalWeeksReached: 0,
        nightRuns: 0,
        distinctExerciseTypes: 1,
      ),
      unlocked: {'1', '2', '3'},
    );
    final controller = _controllerFor(repository);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _wrap(StickerCollectionPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('New sticker unlocked!'), findsOneWidget);

    await tester.tap(find.text('Use as avatar').last);
    await tester.pumpAndSettle();

    expect(repository.selected, '4');
    expect(controller.pendingCelebrations, isEmpty);
  });

  testWidgets('grade cabe numa tela de celular sem estourar o layout', (
    tester,
  ) async {
    final view = tester.view;
    view.physicalSize = const Size(1125, 2436); // iPhone X @3x
    view.devicePixelRatio = 3.0;

    final repository = _FakeStickerRepository(
      stats: const StickerStats.empty(),
      unlocked: {'1', '2', '3'},
    );
    final controller = _controllerFor(repository);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _wrap(StickerCollectionPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    // Rola até o fim da coleção: qualquer overflow vira exceção no teste.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Dragonfly'), findsOneWidget);
  });

  test('a home continua compilando com o marcador de adesivo', () {
    expect(const HomePage(), isA<HomePage>());
  });
}
