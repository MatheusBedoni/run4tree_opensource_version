import 'sticker_requirement.dart';

/// Definição imutável de um adesivo do catálogo: a arte e como conquistá-lo.
class StickerDefinition {
  /// Id estável, usado como chave no banco e nas traduções.
  final String id;

  /// Caminho do PNG em `assets/images/stickers/`.
  final String assetPath;

  /// O que o usuário precisa fazer para desbloqueá-lo.
  final StickerRequirement requirement;

  const StickerDefinition({
    required this.id,
    required this.assetPath,
    required this.requirement,
  });

  bool get isFree => requirement.type == StickerRequirementType.free;
}

/// Catálogo de adesivos do app, em ordem de exibição (dos iniciais aos mais
/// difíceis).
///
/// **Para adicionar um adesivo novo:** solte o PNG em
/// `assets/images/stickers/`, acrescente uma entrada em [all] com um id
/// inédito e o requisito desejado e, opcionalmente, um nome em
/// `stickerName<id>` no arquivo `lib/l10n/app_en.arb` (sem ele, a UI mostra um
/// nome genérico). Nada mais precisa ser tocado: banco, progresso, dialog de
/// desbloqueio e seleção de avatar funcionam a partir daqui.
class StickerCatalog {
  const StickerCatalog._();

  static const List<StickerDefinition> all = [
    // ── Livres desde a instalação ────────────────────────────────────────
    StickerDefinition(
      id: '1',
      assetPath: 'assets/images/stickers/1.png',
      requirement: StickerRequirement.free(),
    ),
    StickerDefinition(
      id: '2',
      assetPath: 'assets/images/stickers/2.png',
      requirement: StickerRequirement.free(),
    ),
    StickerDefinition(
      id: '3',
      assetPath: 'assets/images/stickers/3.png',
      requirement: StickerRequirement.free(),
    ),

    // ── Primeiros passos ─────────────────────────────────────────────────
    StickerDefinition(
      id: '4',
      assetPath: 'assets/images/stickers/4.png',
      requirement: StickerRequirement(StickerRequirementType.totalRuns, 1),
    ),
    StickerDefinition(
      id: '5',
      assetPath: 'assets/images/stickers/5.png',
      requirement: StickerRequirement(
        StickerRequirementType.totalDistanceKm,
        10,
      ),
    ),
    StickerDefinition(
      id: '6',
      assetPath: 'assets/images/stickers/6.png',
      requirement: StickerRequirement(StickerRequirementType.treesPlanted, 1),
    ),

    // ── Constância ───────────────────────────────────────────────────────
    StickerDefinition(
      id: '7',
      assetPath: 'assets/images/stickers/7.png',
      requirement: StickerRequirement(StickerRequirementType.streakDays, 3),
    ),
    StickerDefinition(
      id: '8',
      assetPath: 'assets/images/stickers/8.png',
      requirement: StickerRequirement(
        StickerRequirementType.singleRunDistanceKm,
        5,
      ),
    ),
    StickerDefinition(
      id: '9',
      assetPath: 'assets/images/stickers/9.png',
      requirement: StickerRequirement(
        StickerRequirementType.weeklyGoalWeeks,
        1,
      ),
    ),
    StickerDefinition(
      id: '10',
      assetPath: 'assets/images/stickers/10.png',
      requirement: StickerRequirement(StickerRequirementType.streakDays, 7),
    ),

    // ── Veteranos ────────────────────────────────────────────────────────
    StickerDefinition(
      id: '11',
      assetPath: 'assets/images/stickers/11.png',
      requirement: StickerRequirement(
        StickerRequirementType.totalDistanceKm,
        50,
      ),
    ),
    StickerDefinition(
      id: '12',
      assetPath: 'assets/images/stickers/12.png',
      requirement: StickerRequirement(StickerRequirementType.nightRuns, 3),
    ),
    StickerDefinition(
      id: '13',
      assetPath: 'assets/images/stickers/13.png',
      requirement: StickerRequirement(
        StickerRequirementType.exerciseVariety,
        3,
      ),
    ),
    StickerDefinition(
      id: '14',
      assetPath: 'assets/images/stickers/14.png',
      requirement: StickerRequirement(
        StickerRequirementType.totalDistanceKm,
        100,
      ),
    ),
  ];

  /// Adesivo padrão do app (avatar/marcador antes de qualquer escolha).
  static StickerDefinition get defaultSticker => all.first;

  static StickerDefinition? byId(String id) {
    for (final sticker in all) {
      if (sticker.id == id) return sticker;
    }
    return null;
  }

  static Iterable<StickerDefinition> get freeStickers =>
      all.where((sticker) => sticker.isFree);
}
