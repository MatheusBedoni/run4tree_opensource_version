import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../runs/domain/entities/run_session_entity.dart';
import '../../domain/entities/exercise_stats.dart';
import '../utils/exercise_formatters.dart';
import 'exercise_section_header.dart';

/// Seção "Recordes": lista horizontal com a melhor marca do usuário em cada
/// métrica, no mesmo formato dos cards de destaque do app (círculo com ícone,
/// valor em evidência e legenda).
class ExerciseRecordsSection extends StatelessWidget {
  final List<ExerciseRecord> records;
  final ValueChanged<RunSessionEntity> onRecordTap;

  const ExerciseRecordsSection({
    super.key,
    required this.records,
    required this.onRecordTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (records.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _EmptyRecordsCard(
              message: l10n.exercisesRecordsEmptyMessage,
            ),
          )
        else
          SizedBox(
            height: 236,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: records.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final record = records[index];
                return _RecordCard(
                  record: record,
                  onTap: () => onRecordTap(record.run),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ─── Cards ───────────────────────────────────────────────────────────────────

class _RecordCard extends StatelessWidget {
  final ExerciseRecord record;
  final VoidCallback onTap;

  const _RecordCard({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final value = recordValue(context, record);
    final unit = recordUnit(context, record.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 156,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              labelForExerciseType(
                context,
                record.run.exerciseType,
              ).toUpperCase(),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 14),
            _RecordBadge(type: record.type),
            const SizedBox(height: 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (unit != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      unit.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              recordLabel(context, record.type),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Círculo escuro com o ícone da métrica, no espírito das medalhas do app.
class _RecordBadge extends StatelessWidget {
  final ExerciseRecordType type;

  const _RecordBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryDark,
        border: Border.all(color: AppColors.progressTrack, width: 4),
      ),
      child: Icon(recordIcon(type), color: AppColors.accentOrange, size: 32),
    );
  }
}

class _RecordRow extends StatelessWidget {
  final ExerciseRecord record;
  final VoidCallback onTap;

  const _RecordRow({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unit = recordUnit(context, record.type);
    final value = recordValue(context, record);

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.progressTrack,
        ),
        child: Icon(recordIcon(record.type), color: AppColors.primaryDark),
      ),
      title: Text(
        recordLabel(context, record.type),
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        labelForExerciseType(context, record.run.exerciseType),
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: Text(
        unit == null ? value : '$value $unit',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _EmptyRecordsCard extends StatelessWidget {
  final String message;

  const _EmptyRecordsCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: AppColors.textSecondary,
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Apresentação por métrica ────────────────────────────────────────────────

IconData recordIcon(ExerciseRecordType type) {
  switch (type) {
    case ExerciseRecordType.longestDistance:
      return Icons.route_rounded;
    case ExerciseRecordType.longestDuration:
      return Icons.hourglass_bottom_rounded;
    case ExerciseRecordType.mostCalories:
      return Icons.local_fire_department_rounded;
    case ExerciseRecordType.bestPace:
      return Icons.speed_rounded;
    case ExerciseRecordType.topSpeed:
      return Icons.bolt_rounded;
  }
}

String recordLabel(BuildContext context, ExerciseRecordType type) {
  final l10n = AppLocalizations.of(context)!;
  switch (type) {
    case ExerciseRecordType.longestDistance:
      return l10n.exercisesRecordLongestDistance;
    case ExerciseRecordType.longestDuration:
      return l10n.exercisesRecordLongestDuration;
    case ExerciseRecordType.mostCalories:
      return l10n.exercisesRecordMostCalories;
    case ExerciseRecordType.bestPace:
      return l10n.exercisesRecordBestPace;
    case ExerciseRecordType.topSpeed:
      return l10n.exercisesRecordTopSpeed;
  }
}

String? recordUnit(BuildContext context, ExerciseRecordType type) {
  final l10n = AppLocalizations.of(context)!;
  switch (type) {
    case ExerciseRecordType.longestDistance:
      return l10n.exercisesUnitKm;
    case ExerciseRecordType.longestDuration:
      return null;
    case ExerciseRecordType.mostCalories:
      return l10n.exercisesKcalUnit;
    case ExerciseRecordType.bestPace:
      return l10n.exercisesUnitPerKm;
    case ExerciseRecordType.topSpeed:
      return l10n.exercisesUnitKmh;
  }
}

String recordValue(BuildContext context, ExerciseRecord record) {
  final locale = Localizations.localeOf(context).toString();
  switch (record.type) {
    case ExerciseRecordType.longestDistance:
      return NumberFormat('0.00', locale).format(record.run.distanceKm);
    case ExerciseRecordType.longestDuration:
      return formatClockDuration(record.run.durationSeconds);
    case ExerciseRecordType.mostCalories:
      return NumberFormat('0', locale).format(record.run.calories);
    case ExerciseRecordType.bestPace:
      return formatPace(record.run.pace);
    case ExerciseRecordType.topSpeed:
      return NumberFormat('0.0', locale).format(record.run.maxSpeed);
  }
}
