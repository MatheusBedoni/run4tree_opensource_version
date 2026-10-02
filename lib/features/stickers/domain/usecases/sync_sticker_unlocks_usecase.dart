import '../entities/sticker_entity.dart';
import '../repositories/sticker_repository.dart';

/// Reavalia as conquistas e persiste os adesivos recém-desbloqueados,
/// devolvendo só os novos — a UI usa o retorno para celebrar.
///
/// Deve ser chamado sempre que o progresso muda: ao terminar uma atividade,
/// ao plantar uma árvore e ao abrir a coleção.
class SyncStickerUnlocksUseCase {
  final StickerRepository _repository;

  const SyncStickerUnlocksUseCase(this._repository);

  Future<List<StickerEntity>> call() => _repository.syncUnlocks();
}
