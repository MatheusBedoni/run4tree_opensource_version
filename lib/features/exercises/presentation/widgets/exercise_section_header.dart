import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Cabeçalho das seções da ExercisesPage: título em caixa alta à esquerda e
/// um link "mais" opcional à direita.
class ExerciseSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMoreTap;

  const ExerciseSectionHeader({super.key, required this.title, this.onMoreTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ),
        if (onMoreTap != null)
          InkWell(
            onTap: onMoreTap,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                AppLocalizations.of(
                  context,
                )!.exercisesSectionMore.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
