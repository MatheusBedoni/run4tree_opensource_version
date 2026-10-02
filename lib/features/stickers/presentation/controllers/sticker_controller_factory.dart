import '../../data/repositories/sticker_repository_impl.dart';
import '../../domain/usecases/get_stickers_usecase.dart';
import '../../domain/usecases/select_sticker_avatar_usecase.dart';
import '../../domain/usecases/sync_sticker_unlocks_usecase.dart';
import 'sticker_controller.dart';

/// Monta a cadeia repositório → casos de uso → controller.
///
/// Existe para o perfil e a home não repetirem a mesma fiação; quando o app
/// adotar um injetor de dependências, é o único ponto a trocar.
StickerController createStickerController() {
  final repository = StickerRepositoryImpl();
  return StickerController(
    GetStickersUseCase(repository),
    SyncStickerUnlocksUseCase(repository),
    SelectStickerAvatarUseCase(repository),
  );
}
