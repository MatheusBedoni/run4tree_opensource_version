import 'sticker_definition.dart';
import 'sticker_requirement.dart';
import 'sticker_stats.dart';

/// Um adesivo do catálogo já cruzado com o estado do usuário: se está
/// desbloqueado, se é o avatar em uso e o quanto falta para conquistá-lo.
class StickerEntity {
  final StickerDefinition definition;

  /// Quando foi desbloqueado — `null` enquanto estiver bloqueado.
  final DateTime? unlockedAt;

  /// Se é o adesivo escolhido como avatar/marcador do mapa.
  final bool isSelected;

  /// Progresso rumo ao desbloqueio, de 0.0 a 1.0.
  final double progress;

  /// Valor atual do usuário na métrica exigida (ex: 7.4 de 10 km).
  final double currentValue;

  const StickerEntity({
    required this.definition,
    required this.unlockedAt,
    required this.isSelected,
    required this.progress,
    required this.currentValue,
  });

  /// Monta a entidade a partir das métricas do usuário.
  factory StickerEntity.from({
    required StickerDefinition definition,
    required StickerStats stats,
    DateTime? unlockedAt,
    bool isSelected = false,
  }) {
    return StickerEntity(
      definition: definition,
      unlockedAt: unlockedAt,
      isSelected: isSelected,
      progress: definition.requirement.progress(stats),
      currentValue: definition.requirement.currentValue(stats),
    );
  }

  String get id => definition.id;

  String get assetPath => definition.assetPath;

  StickerRequirement get requirement => definition.requirement;

  bool get isUnlocked => unlockedAt != null;

  StickerEntity copyWith({DateTime? unlockedAt, bool? isSelected}) {
    return StickerEntity(
      definition: definition,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isSelected: isSelected ?? this.isSelected,
      progress: progress,
      currentValue: currentValue,
    );
  }
}
