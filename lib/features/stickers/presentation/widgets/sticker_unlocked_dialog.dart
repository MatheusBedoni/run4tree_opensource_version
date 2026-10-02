import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/sticker_entity.dart';
import '../utils/sticker_labels.dart';
import 'sticker_avatar.dart';

/// Celebração de um adesivo recém-conquistado.
///
/// Retorna `true` quando o usuário decide usá-lo como avatar.
Future<bool> showStickerUnlockedDialog(
  BuildContext context,
  StickerEntity sticker,
) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => StickerUnlockedDialog(sticker: sticker),
  );
  return result ?? false;
}

class StickerUnlockedDialog extends StatefulWidget {
  final StickerEntity sticker;

  const StickerUnlockedDialog({super.key, required this.sticker});

  @override
  State<StickerUnlockedDialog> createState() => _StickerUnlockedDialogState();
}

class _StickerUnlockedDialogState extends State<StickerUnlockedDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..forward();
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scale,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.accentOrange.withValues(alpha: 0.28),
                          AppColors.accentOrange.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  StickerAvatar(assetPath: widget.sticker.assetPath, size: 116),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.stickerUnlockedTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.stickerUnlockedSubtitle(
                stickerName(l10n, widget.sticker.definition),
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              stickerRequirementLabel(l10n, widget.sticker.requirement),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  l10n.stickerUnlockedUseButton,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                l10n.stickerUnlockedCloseButton,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
