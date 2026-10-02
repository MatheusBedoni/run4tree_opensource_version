import '../repositories/sticker_repository.dart';

/// Define qual adesivo desbloqueado será o avatar do perfil e o marcador do
/// usuário no mapa.
class SelectStickerAvatarUseCase {
  final StickerRepository _repository;

  const SelectStickerAvatarUseCase(this._repository);

  Future<void> call(String stickerId) => _repository.selectSticker(stickerId);
}
