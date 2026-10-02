import 'package:flutter/foundation.dart';

import '../../domain/entities/sticker_entity.dart';
import '../../domain/usecases/get_stickers_usecase.dart';
import '../../domain/usecases/select_sticker_avatar_usecase.dart';
import '../../domain/usecases/sync_sticker_unlocks_usecase.dart';

/// Estado da coleção de adesivos: catálogo com progresso, avatar selecionado e
/// a fila de desbloqueios ainda não celebrados.
class StickerController extends ChangeNotifier {
  final GetStickersUseCase _getStickersUseCase;
  final SyncStickerUnlocksUseCase _syncStickerUnlocksUseCase;
  final SelectStickerAvatarUseCase _selectStickerAvatarUseCase;

  StickerController(
    this._getStickersUseCase,
    this._syncStickerUnlocksUseCase,
    this._selectStickerAvatarUseCase,
  );

  List<StickerEntity> _stickers = const [];
  List<StickerEntity> _pendingCelebrations = const [];
  bool _isLoading = false;
  bool _hasLoadError = false;

  List<StickerEntity> get stickers => _stickers;

  /// Adesivos recém-desbloqueados que ainda não foram exibidos ao usuário.
  List<StickerEntity> get pendingCelebrations => _pendingCelebrations;

  bool get isLoading => _isLoading;
  bool get hasLoadError => _hasLoadError;

  int get unlockedCount => _stickers.where((s) => s.isUnlocked).length;

  int get totalCount => _stickers.length;

  StickerEntity? get selectedSticker {
    for (final sticker in _stickers) {
      if (sticker.isSelected) return sticker;
    }
    for (final sticker in _stickers) {
      if (sticker.isUnlocked) return sticker;
    }
    return _stickers.isEmpty ? null : _stickers.first;
  }

  /// Carrega o catálogo, avaliando antes se algo novo foi conquistado.
  Future<void> load({bool syncUnlocks = true}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (syncUnlocks) {
        final unlocked = await _syncStickerUnlocksUseCase();
        if (unlocked.isNotEmpty) {
          _pendingCelebrations = [..._pendingCelebrations, ...unlocked];
        }
      }
      _stickers = await _getStickersUseCase();
      _hasLoadError = false;
    } catch (e) {
      _hasLoadError = true;
      debugPrint('StickerController.load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Escolhe o adesivo como avatar do perfil e marcador do mapa.
  Future<void> selectSticker(String stickerId) async {
    try {
      await _selectStickerAvatarUseCase(stickerId);
      _stickers = await _getStickersUseCase();
      notifyListeners();
    } catch (e) {
      debugPrint('StickerController.selectSticker error: $e');
    }
  }

  /// Remove um desbloqueio da fila depois de exibir a celebração.
  void consumeCelebration(StickerEntity sticker) {
    _pendingCelebrations = _pendingCelebrations
        .where((pending) => pending.id != sticker.id)
        .toList();
  }

  void clearCelebrations() {
    _pendingCelebrations = const [];
  }
}
