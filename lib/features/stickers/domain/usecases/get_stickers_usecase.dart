import '../entities/sticker_entity.dart';
import '../repositories/sticker_repository.dart';

/// Retorna o catálogo completo de adesivos com o progresso do usuário.
class GetStickersUseCase {
  final StickerRepository _repository;

  const GetStickersUseCase(this._repository);

  Future<List<StickerEntity>> call() => _repository.getStickers();
}
