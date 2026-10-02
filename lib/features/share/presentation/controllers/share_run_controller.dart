import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../runs/domain/entities/run_session_entity.dart';
import '../../../stickers/domain/entities/sticker_entity.dart';
import '../../../stickers/presentation/controllers/sticker_controller.dart';
import '../../../stickers/presentation/controllers/sticker_controller_factory.dart';
import '../models/share_options.dart';
import '../utils/route_points.dart';
import '../widgets/share_run_card.dart';

/// Estado do editor de compartilhamento: formato, fundo, adesivo e posição.
///
/// A exportação fica na página porque depende da árvore de renderização.
class ShareRunController extends ChangeNotifier {
  final RunSessionEntity runSession;
  final List<LatLng> routePoints;
  final StickerController _stickerController;
  final ImagePicker _imagePicker;

  ShareRunController(
    this.runSession, {
    StickerController? stickerController,
    ImagePicker? imagePicker,
  }) : routePoints = decodeRoutePoints(runSession.polyline),
       _stickerController = stickerController ?? createStickerController(),
       _imagePicker = imagePicker ?? ImagePicker() {
    // Sem GPS não há mapa: a arte do app entra como fundo inicial.
    if (!hasRoute) {
      _backgroundKind = ShareBackgroundKind.photo;
      _activeTab = ShareEditorTab.photo;
    }
  }

  // ─── Estado ────────────────────────────────────────────────────────────────

  ShareFormat _format = ShareFormat.story;
  ShareEditorTab _activeTab = ShareEditorTab.map;
  ShareBackgroundKind _backgroundKind = ShareBackgroundKind.map;
  ShareMapStyle _mapStyle = ShareMapStyle.light;
  ShareColorStyle _colorStyle = ShareColorStyle.forest;
  final List<ShareCardPhoto> _pickedPhotos = [];
  ShareCardPhoto _photo = ShareCardPhoto.builtIn.first;
  List<StickerEntity> _stickers = const [];
  StickerEntity? _sticker;
  Offset _stickerOrigin = ShareRunCard.defaultStickerOrigin;
  bool _isDisposed = false;

  ShareFormat get format => _format;
  ShareEditorTab get activeTab => _activeTab;
  ShareBackgroundKind get backgroundKind => _backgroundKind;
  ShareMapStyle get mapStyle => _mapStyle;
  ShareColorStyle get colorStyle => _colorStyle;
  ShareCardPhoto get photo => _photo;

  /// Fotos escolhidas nesta sessão (mais recentes primeiro) e as artes do app.
  List<ShareCardPhoto> get photos => [
    ..._pickedPhotos,
    ...ShareCardPhoto.builtIn,
  ];

  /// Só os adesivos já conquistados podem ir para o card.
  List<StickerEntity> get stickers => _stickers;
  StickerEntity? get sticker => _sticker;
  Offset get stickerOrigin => _stickerOrigin;

  bool get hasRoute => routePoints.length >= 2;

  bool get isTransparent =>
      _backgroundKind == ShareBackgroundKind.color &&
      _colorStyle == ShareColorStyle.transparent;

  // ─── Ações ─────────────────────────────────────────────────────────────────

  void selectFormat(ShareFormat format) {
    if (_format == format) return;
    _format = format;
    notifyListeners();
  }

  void selectTab(ShareEditorTab tab) {
    if (tab == ShareEditorTab.map && !hasRoute) return;
    if (_activeTab == tab) return;
    _activeTab = tab;
    notifyListeners();
  }

  void selectMapStyle(ShareMapStyle style) {
    if (!hasRoute) return;
    _mapStyle = style;
    _backgroundKind = ShareBackgroundKind.map;
    notifyListeners();
  }

  void selectColorStyle(ShareColorStyle style) {
    _colorStyle = style;
    _backgroundKind = ShareBackgroundKind.color;
    notifyListeners();
  }

  void selectPhoto(ShareCardPhoto photo) {
    _photo = photo;
    _backgroundKind = ShareBackgroundKind.photo;
    notifyListeners();
  }

  /// `null` remove o adesivo do card.
  void selectSticker(StickerEntity? sticker) {
    _sticker = sticker;
    notifyListeners();
  }

  void moveSticker(Offset origin) {
    _stickerOrigin = origin;
    notifyListeners();
  }

  /// Abre a câmera ou a galeria e usa a foto como fundo.
  ///
  /// Retorna `false` só em caso de erro — cancelar a escolha não é falha.
  Future<bool> pickPhoto(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 2160,
        maxHeight: 2160,
        imageQuality: 92,
      );
      if (file == null || _isDisposed) return true;

      final photo = ShareCardPhoto.file(file.path);
      _pickedPhotos.insert(0, photo);
      selectPhoto(photo);
      return true;
    } catch (e) {
      debugPrint('ShareRunController.pickPhoto error: $e');
      return false;
    }
  }

  Future<void> loadStickers() async {
    await _stickerController.load(syncUnlocks: false);
    if (_isDisposed) return;
    _stickers = _stickerController.stickers
        .where((sticker) => sticker.isUnlocked)
        .toList();
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stickerController.dispose();
    super.dispose();
  }
}
