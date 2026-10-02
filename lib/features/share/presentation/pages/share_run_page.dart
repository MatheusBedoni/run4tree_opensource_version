import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../exercises/presentation/utils/exercise_formatters.dart';
import '../../../runs/domain/entities/run_session_entity.dart';
import '../../../stickers/presentation/utils/sticker_labels.dart';
import '../../../stickers/presentation/widgets/sticker_avatar.dart';
import '../controllers/share_run_controller.dart';
import '../models/share_options.dart';
import '../utils/share_image_exporter.dart';
import '../widgets/checkerboard_painter.dart';
import '../widgets/route_shape_painter.dart';
import '../widgets/share_map_background.dart';
import '../widgets/share_run_card.dart';

/// Editor "Compartilhe seu progresso": o usuário escolhe formato (Stories ou
/// quadrado), fundo (mapa, foto ou cor) e um adesivo, e exporta a arte em PNG
/// pelo share sheet nativo — Instagram, WhatsApp, galeria etc.
class ShareRunPage extends StatefulWidget {
  final RunSessionEntity runSession;

  const ShareRunPage({super.key, required this.runSession});

  static Future<void> open(BuildContext context, RunSessionEntity runSession) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ShareRunPage(runSession: runSession),
      ),
    );
  }

  @override
  State<ShareRunPage> createState() => _ShareRunPageState();
}

class _ShareRunPageState extends State<ShareRunPage> {
  /// Largura final: 1080×1920 nos Stories e 1080×1080 no quadrado, as
  /// resoluções que o Instagram espera.
  static const double _exportWidth = 1080;
  static const Color _previewBackdrop = Color(0xFFE9EDF0);
  static const Color _idleBorder = Color(0xFFE0E0E0);

  late final ShareRunController _controller;
  late final ShareCardFonts _fonts;
  final _cardKey = GlobalKey();
  final _mapKey = GlobalKey<ShareMapBackgroundState>();
  final _shareButtonKey = GlobalKey();

  /// Foto do mapa posta por cima do GoogleMap só durante a exportação: a
  /// platform view não aparece na captura do `RepaintBoundary`.
  Uint8List? _mapSnapshot;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _fonts = ShareCardFonts.brand();
    _controller = ShareRunController(widget.runSession)..loadStickers();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ─── Exportação ────────────────────────────────────────────────────────────

  Future<void> _share() async {
    if (_isExporting) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final caption = _caption(l10n);
    final origin = _shareOrigin();

    setState(() => _isExporting = true);
    try {
      if (_controller.backgroundKind == ShareBackgroundKind.map) {
        final snapshot = await _mapKey.currentState?.takeSnapshot();
        if (snapshot != null && mounted) {
          await precacheImage(MemoryImage(snapshot), context);
          if (mounted) setState(() => _mapSnapshot = snapshot);
        }
      }
      // Sem isso, uma fonte ainda baixando sairia como a fonte padrão.
      await GoogleFonts.pendingFonts();
      await WidgetsBinding.instance.endOfFrame;

      final file = await ShareImageExporter.capture(
        _cardKey,
        targetWidth: _exportWidth,
      );
      await Share.shareXFiles(
        [file],
        text: caption,
        sharePositionOrigin: origin,
      );
    } catch (e) {
      debugPrint('ShareRunPage._share error: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.shareRunExportError),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _mapSnapshot = null;
        });
      }
    }
  }

  /// Legenda que acompanha a imagem nos apps que aceitam texto (WhatsApp,
  /// X...). O Instagram ignora e usa só a imagem.
  String _caption(AppLocalizations l10n) {
    final run = widget.runSession;
    final summary = l10n.runCompletedShareSummary(
      run.calories.toStringAsFixed(0),
      run.distanceKm.toStringAsFixed(2),
      formatStopwatchDuration(run.durationSeconds),
      labelForExerciseType(context, run.exerciseType),
      formatPace(run.pace),
      run.averageSpeed.toStringAsFixed(1),
    );
    return '$summary\n\n${l10n.shareRunCaptionFooter}';
  }

  /// Âncora do popover de compartilhamento no iPad.
  Rect? _shareOrigin() {
    final box = _shareButtonKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  // ─── Ações ─────────────────────────────────────────────────────────────────

  Future<void> _addPhoto() async {
    final l10n = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.shareRunPhotoCamera),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.shareRunPhotoGallery),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final ok = await _controller.pickPhoto(source);
    if (!ok && mounted) _showMessage(l10n.shareRunPhotoError);
  }

  void _onTabTap(ShareEditorTab tab, AppLocalizations l10n) {
    if (tab == ShareEditorTab.map && !_controller.hasRoute) {
      _showMessage(l10n.shareRunNoRoute);
      return;
    }
    _controller.selectTab(tab);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  // ─── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          l10n.shareRunTitle.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFormatSelector(l10n),
              Expanded(child: _buildPreview()),
              _buildTabBar(l10n),
              _buildOptions(l10n),
              _buildShareBar(l10n),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFormatSelector(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          _FormatChip(
            label: l10n.shareRunFormatStory,
            selected: _controller.format == ShareFormat.story,
            onTap: () => _controller.selectFormat(ShareFormat.story),
          ),
          const SizedBox(width: 12),
          _FormatChip(
            label: l10n.shareRunFormatSquare,
            selected: _controller.format == ShareFormat.square,
            onTap: () => _controller.selectFormat(ShareFormat.square),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final aspectRatio = _controller.format.aspectRatio;

    return ColoredBox(
      color: _previewBackdrop,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const margin = 16.0;
          var width = constraints.maxWidth - margin * 2;
          var height = width / aspectRatio;
          final maxHeight = constraints.maxHeight - margin * 2;
          if (height > maxHeight) {
            height = maxHeight;
            width = height * aspectRatio;
          }
          if (width <= 0 || height <= 0) return const SizedBox.shrink();

          return Center(
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_controller.isTransparent)
                    const CustomPaint(painter: CheckerboardPainter()),
                  RepaintBoundary(
                    key: _cardKey,
                    child: ShareRunCard(
                      run: widget.runSession,
                      background: _buildBackground(),
                      routePoints: _controller.routePoints,
                      showRouteShape:
                          _controller.backgroundKind != ShareBackgroundKind.map,
                      transparent: _controller.isTransparent,
                      stickerAssetPath: _controller.sticker?.assetPath,
                      stickerOrigin: _controller.stickerOrigin,
                      onStickerMoved: _controller.moveSticker,
                      fonts: _fonts,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackground() {
    switch (_controller.backgroundKind) {
      case ShareBackgroundKind.map:
        return Stack(
          fit: StackFit.expand,
          children: [
            ShareMapBackground(
              key: _mapKey,
              points: _controller.routePoints,
              style: _controller.mapStyle,
              format: _controller.format,
            ),
            if (_mapSnapshot != null)
              Image.memory(
                _mapSnapshot!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
          ],
        );
      case ShareBackgroundKind.photo:
        return Image(
          image: _controller.photo.image,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => DecoratedBox(
            decoration: BoxDecoration(
              gradient: ShareColorStyle.forest.gradient,
            ),
          ),
        );
      case ShareBackgroundKind.color:
        final gradient = _controller.colorStyle.gradient;
        if (gradient == null) return const SizedBox.expand();
        return DecoratedBox(decoration: BoxDecoration(gradient: gradient));
    }
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    final showStickerHint =
        _controller.activeTab == ShareEditorTab.sticker &&
        _controller.sticker != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          for (final tab in ShareEditorTab.values) ...[
            _TabButton(
              icon: _iconForTab(tab),
              label: _labelForTab(l10n, tab),
              selected: _controller.activeTab == tab,
              enabled: tab != ShareEditorTab.map || _controller.hasRoute,
              onTap: () => _onTabTap(tab, l10n),
            ),
            const SizedBox(width: 12),
          ],
          if (showStickerHint)
            Expanded(
              child: Text(
                l10n.shareRunStickerHint,
                textAlign: TextAlign.end,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOptions(AppLocalizations l10n) {
    final tiles = switch (_controller.activeTab) {
      ShareEditorTab.photo => _photoTiles(l10n),
      ShareEditorTab.map => _mapTiles(l10n),
      ShareEditorTab.color => _colorTiles(l10n),
      ShareEditorTab.sticker => _stickerTiles(l10n),
    };

    return SizedBox(
      height: 100,
      child: ListView.separated(
        key: PageStorageKey(_controller.activeTab),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tiles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, index) => tiles[index],
      ),
    );
  }

  List<Widget> _photoTiles(AppLocalizations l10n) {
    final isPhotoBackground =
        _controller.backgroundKind == ShareBackgroundKind.photo;
    return [
      _OptionTile(
        label: l10n.shareRunPhotoAdd,
        selected: false,
        onTap: _addPhoto,
        child: const ColoredBox(
          color: Color(0xFFF5F5F5),
          child: Center(
            child: Icon(
              Icons.add_a_photo_outlined,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
      for (final photo in _controller.photos)
        _OptionTile(
          selected: isPhotoBackground && _controller.photo == photo,
          onTap: () => _controller.selectPhoto(photo),
          child: Image(
            image: ResizeImage(photo.image, width: 240),
            fit: BoxFit.cover,
          ),
        ),
    ];
  }

  List<Widget> _mapTiles(AppLocalizations l10n) {
    final isMapBackground =
        _controller.backgroundKind == ShareBackgroundKind.map;
    return [
      for (final style in ShareMapStyle.values)
        _OptionTile(
          label: _labelForMapStyle(l10n, style),
          selected: isMapBackground && _controller.mapStyle == style,
          onTap: () => _controller.selectMapStyle(style),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: style.swatch,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox.expand(
                child: CustomPaint(
                  painter: RouteShapePainter(
                    points: _controller.routePoints,
                    color: style.routeColor,
                  ),
                ),
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _colorTiles(AppLocalizations l10n) {
    final isColorBackground =
        _controller.backgroundKind == ShareBackgroundKind.color;
    return [
      for (final style in ShareColorStyle.values)
        _OptionTile(
          label: _labelForColorStyle(l10n, style),
          selected: isColorBackground && _controller.colorStyle == style,
          onTap: () => _controller.selectColorStyle(style),
          child: style.gradient == null
              ? const SizedBox.expand(
                  child: CustomPaint(painter: CheckerboardPainter(cellSize: 8)),
                )
              : DecoratedBox(
                  decoration: BoxDecoration(gradient: style.gradient),
                ),
        ),
    ];
  }

  List<Widget> _stickerTiles(AppLocalizations l10n) {
    return [
      _OptionTile(
        label: l10n.shareRunStickerNone,
        selected: _controller.sticker == null,
        onTap: () => _controller.selectSticker(null),
        child: const ColoredBox(
          color: Color(0xFFF5F5F5),
          child: Center(
            child: Icon(Icons.block_rounded, color: AppColors.textSecondary),
          ),
        ),
      ),
      for (final sticker in _controller.stickers)
        _OptionTile(
          label: stickerName(l10n, sticker.definition),
          selected: _controller.sticker?.id == sticker.id,
          onTap: () => _controller.selectSticker(sticker),
          child: Center(
            child: StickerAvatar(
              assetPath: sticker.assetPath,
              size: 58,
              borderWidth: 0,
              showShadow: false,
            ),
          ),
        ),
    ];
  }

  Widget _buildShareBar(AppLocalizations l10n) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.paddingOf(context).bottom + 12,
      ),
      child: ElevatedButton.icon(
        key: _shareButtonKey,
        onPressed: _isExporting ? null : _share,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.progressGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.progressGreen.withValues(
            alpha: 0.6,
          ),
          disabledForegroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: _isExporting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.share_rounded),
        label: Text(
          l10n.runCompletedShareButton,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            fontFamily: _fonts.display,
          ),
        ),
      ),
    );
  }

  // ─── Rótulos ───────────────────────────────────────────────────────────────

  IconData _iconForTab(ShareEditorTab tab) {
    switch (tab) {
      case ShareEditorTab.photo:
        return Icons.image_outlined;
      case ShareEditorTab.map:
        return Icons.map_outlined;
      case ShareEditorTab.color:
        return Icons.palette_outlined;
      case ShareEditorTab.sticker:
        return Icons.emoji_emotions_outlined;
    }
  }

  String _labelForTab(AppLocalizations l10n, ShareEditorTab tab) {
    switch (tab) {
      case ShareEditorTab.photo:
        return l10n.shareRunTabPhoto;
      case ShareEditorTab.map:
        return l10n.shareRunTabMap;
      case ShareEditorTab.color:
        return l10n.shareRunTabColor;
      case ShareEditorTab.sticker:
        return l10n.shareRunTabSticker;
    }
  }

  String _labelForMapStyle(AppLocalizations l10n, ShareMapStyle style) {
    switch (style) {
      case ShareMapStyle.light:
        return l10n.shareRunMapLight;
      case ShareMapStyle.satellite:
        return l10n.shareRunMapSatellite;
      case ShareMapStyle.dark:
        return l10n.shareRunMapDark;
      case ShareMapStyle.cartoon:
        return l10n.shareRunMapCartoon;
    }
  }

  String _labelForColorStyle(AppLocalizations l10n, ShareColorStyle style) {
    switch (style) {
      case ShareColorStyle.forest:
        return l10n.shareRunColorForest;
      case ShareColorStyle.sunrise:
        return l10n.shareRunColorSunrise;
      case ShareColorStyle.night:
        return l10n.shareRunColorNight;
      case ShareColorStyle.transparent:
        return l10n.shareRunColorTransparent;
    }
  }
}

class _FormatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FormatChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.textPrimary : const Color(0xFFBDBDBD),
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 1.6,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _TabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: selected,
        enabled: enabled,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              border: Border.all(
                color: selected
                    ? AppColors.textPrimary
                    : _ShareRunPageState._idleBorder,
                width: selected ? 2 : 1,
              ),
            ),
            child: Icon(
              icon,
              size: 26,
              color: enabled ? AppColors.textPrimary : const Color(0xFFBDBDBD),
            ),
          ),
        ),
      ),
    );
  }
}

/// Miniatura de uma opção de fundo ou adesivo, com moldura escura quando
/// selecionada (como no adidas Running).
class _OptionTile extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final String? label;

  const _OptionTile({
    required this.selected,
    required this.onTap,
    required this.child,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selected
                        ? AppColors.textPrimary
                        : _ShareRunPageState._idleBorder,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: ClipRect(child: child),
              ),
              if (label != null) ...[
                const SizedBox(height: 4),
                Text(
                  label!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
