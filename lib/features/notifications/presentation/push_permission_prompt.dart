import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/database/app_flags_repository.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Momento em que o app pede a permissão — muda só o texto de apoio.
enum PushPromptReason {
  /// Acabou de entrar num desafio em grupo.
  joinedGroup,

  /// Acabou de terminar um exercício.
  finishedExercise,
}

/// Pede a permissão de notificação **depois** de um momento que dá sentido a
/// ela, e não no primeiro segundo do app: quem acabou de entrar num grupo ou
/// de se exercitar entende por que vale receber o aviso.
///
/// Explica antes de abrir o diálogo do sistema e só pergunta uma vez por
/// instalação — inclusive para quem recusou.
Future<void> maybeAskForPushPermission(
  BuildContext context, {
  required PushPromptReason reason,
  AppFlagsRepository? flagsRepository,
}) async {
  final push = PushNotificationService.instance;
  if (!push.isInitialized || push.hasPermission) return;

  final flags = flagsRepository ?? AppFlagsRepository();
  if (await flags.isSet(AppFlagsRepository.pushPermissionAsked)) return;
  if (!context.mounted) return;

  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => _PushPermissionDialog(reason: reason),
  );
  // Marca mesmo se recusar: insistir a cada corrida seria abusivo.
  await flags.set(AppFlagsRepository.pushPermissionAsked);
  if (accepted != true) return;

  await push.requestPermission();
}

class _PushPermissionDialog extends StatelessWidget {
  const _PushPermissionDialog({required this.reason});

  final PushPromptReason reason;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final body = switch (reason) {
      PushPromptReason.joinedGroup => l10n.pushPromptBodyGroup,
      PushPromptReason.finishedExercise => l10n.pushPromptBodyExercise,
    };

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.accentOrange, AppColors.progressGreen],
              ),
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.bell,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.pushPromptTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.progressGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.pushPromptAccept,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                l10n.pushPromptLater,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
