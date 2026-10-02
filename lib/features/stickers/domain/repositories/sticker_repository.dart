import '../entities/sticker_entity.dart';

/// Contrato do domínio para a coleção de adesivos.
abstract class StickerRepository {
  /// Catálogo completo já cruzado com o progresso do usuário, na ordem de
  /// exibição definida em `StickerCatalog.all`.
  Future<List<StickerEntity>> getStickers();

  /// Reavalia todos os requisitos e persiste os adesivos recém-conquistados.
  ///
  /// Retorna **apenas os que foram desbloqueados agora** — a UI usa essa lista
  /// para exibir a celebração. Chamar repetidamente é seguro: o que já estava
  /// desbloqueado nunca volta na lista.
  Future<List<StickerEntity>> syncUnlocks();

  /// Adesivo em uso como avatar/marcador. Cai no primeiro adesivo livre
  /// quando o usuário ainda não escolheu nenhum.
  Future<StickerEntity> getSelectedSticker();

  /// Define o adesivo do avatar. Ignora ids bloqueados ou inexistentes.
  Future<void> selectSticker(String stickerId);
}
