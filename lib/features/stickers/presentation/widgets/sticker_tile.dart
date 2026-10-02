import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/sticker_entity.dart';
import '../utils/sticker_labels.dart';

/// Filtro que deixa a arte em tons de cinza enquanto o adesivo está bloqueado —
/// o desenho continua visível (o usuário vê o que pode ganhar), mas apagado.
const ColorFilter _greyscale = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
]);

/// Card de um adesivo dentro da coleção.
class StickerTile extends StatelessWidget {
  final StickerEntity sticker;

  /// Chamado ao tocar num adesivo desbloqueado (define o avatar).
  final VoidCallback onTap;

  const StickerTile({super.key, required this.sticker, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isUnlocked = sticker.isUnlocked;
    final isSelected = sticker.isSelected;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: isUnlocked ? onTap : null,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primaryLight : Colors.transparent,
              width: 2,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildArt(isUnlocked, isSelected),
              const SizedBox(height: 10),
              Text(
                stickerName(l10n, sticker.definition),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: isUnlocked
                    ? _buildUnlockedFooter(l10n, isSelected)
                    : _buildLockedFooter(l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArt(bool isUnlocked, bool isSelected) {
    final image = ClipOval(
      child: Image.asset(
        sticker.assetPath,
        width: 76,
        height: 76,
        fit: BoxFit.cover,
      ),
    );

    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked ? Colors.white : AppColors.background,
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: AppColors.primaryLight.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isUnlocked
                  ? image
                  : Opacity(
                      opacity: 0.45,
                      child: ColorFiltered(
                        colorFilter: _greyscale,
                        child: image,
                      ),
                    ),
            ),
          ),
          if (!isUnlocked)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          if (isSelected)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUnlockedFooter(AppLocalizations l10n, bool isSelected) {
    if (isSelected) {
      return Align(
        alignment: Alignment.topCenter,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.progressTrack,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            l10n.stickerCollectionInUse,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: Text(
        l10n.stickerCollectionUseButton,
        textAlign: TextAlign.center,
        maxLines: 2,
        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildLockedFooter(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          stickerRequirementLabel(l10n, sticker.requirement),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            height: 1.25,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: sticker.progress,
            minHeight: 5,
            backgroundColor: AppColors.progressTrack,
            valueColor: const AlwaysStoppedAnimation(AppColors.accentOrange),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          stickerProgressLabel(l10n, sticker),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
