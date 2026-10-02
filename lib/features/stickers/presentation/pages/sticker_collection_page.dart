import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../controllers/sticker_controller.dart';
import '../utils/sticker_labels.dart';
import '../widgets/sticker_avatar.dart';
import '../widgets/sticker_tile.dart';
import '../widgets/sticker_unlocked_dialog.dart';

/// Galeria de adesivos: mostra tudo que já foi conquistado, o que ainda está
/// bloqueado (com o requisito e o progresso) e permite escolher o avatar.
class StickerCollectionPage extends StatefulWidget {
  final StickerController controller;

  const StickerCollectionPage({super.key, required this.controller});

  @override
  State<StickerCollectionPage> createState() => _StickerCollectionPageState();
}

class _StickerCollectionPageState extends State<StickerCollectionPage> {
  @override
  void initState() {
    super.initState();
    // Reavalia as conquistas ao abrir e celebra o que estiver pendente.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.controller.load();
      if (mounted) await _showPendingCelebrations();
    });
  }

  /// Exibe o diálogo de desbloqueio para cada adesivo novo, um de cada vez.
  Future<void> _showPendingCelebrations() async {
    final pending = List.of(widget.controller.pendingCelebrations);
    for (final sticker in pending) {
      if (!mounted) return;
      final useAsAvatar = await showStickerUnlockedDialog(context, sticker);
      widget.controller.consumeCelebration(sticker);
      if (useAsAvatar) {
        await widget.controller.selectSticker(sticker.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          l10n.stickerCollectionTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;

          if (controller.isLoading && controller.stickers.isEmpty) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.accentOrange),
            );
          }

          if (controller.hasLoadError && controller.stickers.isEmpty) {
            return _buildError(l10n);
          }

          return SafeArea(
            top: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(l10n, controller)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.78,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final sticker = controller.stickers[index];
                      return StickerTile(
                        sticker: sticker,
                        onTap: () => controller.selectSticker(sticker.id),
                      );
                    }, childCount: controller.stickers.length),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, StickerController controller) {
    final selected = controller.selectedSticker;
    final unlocked = controller.unlockedCount;
    final total = controller.totalCount;
    final progress = total == 0 ? 0.0 : unlocked / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          StickerAvatar(assetPath: selected?.assetPath, size: 104),
          const SizedBox(height: 12),
          if (selected != null)
            Text(
              stickerName(l10n, selected.definition),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: AppColors.accentOrange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.stickerCollectionProgress(unlocked, total),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.progressTrack,
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.progressGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.stickerCollectionHint,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              l10n.stickerCollectionLoadError,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => widget.controller.load(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(l10n.commonRetryButton),
            ),
          ],
        ),
      ),
    );
  }
}
