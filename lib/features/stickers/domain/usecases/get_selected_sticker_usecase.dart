import '../entities/sticker_entity.dart';
import '../repositories/sticker_repository.dart';

/// Retorna o adesivo em uso como avatar/marcador do mapa.
class GetSelectedStickerUseCase {
  final StickerRepository _repository;

  const GetSelectedStickerUseCase(this._repository);

  Future<StickerEntity> call() => _repository.getSelectedSticker();
}
