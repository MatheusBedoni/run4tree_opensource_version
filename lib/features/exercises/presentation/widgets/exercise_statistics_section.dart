import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/exercise_stats.dart';
import '../utils/exercise_formatters.dart';
import 'exercise_section_header.dart';
import '../pages/exercise_detailed_statistics_page.dart';
import '../../../runs/domain/entities/run_session_entity.dart';

/// Seção "Estatísticas": filtro por modalidade, gráfico de distância dos
/// últimos meses e os totais consolidados do período.
class ExerciseStatisticsSection extends StatelessWidget {
  final List<MonthlyStat> monthlyStats;
  final ExerciseSummary summary;

  /// Modalidades com atividade registrada, usadas para montar os chips.
  final List<String> availableTypes;

  /// Modalidade selecionada (`null` = todas).
  final String? selectedType;
  final ValueChanged<String?> onFilterChanged;

  final List<RunSessionEntity> runs;

  const ExerciseStatisticsSection({
    super.key,
    required this.monthlyStats,
    required this.summary,
    required this.availableTypes,
    required this.selectedType,
    required this.onFilterChanged,
    required this.runs,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ExerciseSectionHeader(
            title: l10n.exercisesStatisticsTitle,
            onMoreTap: summary.activityCount == 0
                ? null
                : () => _openMonthlyBreakdown(context),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterChips(context, l10n),
                const SizedBox(height: 20),
                Text(
                  l10n
                      .exercisesChartDistanceTitle(monthlyStats.length)
                      .toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                _MonthlyDistanceChart(monthlyStats: monthlyStats),
                const SizedBox(height: 20),
                const Divider(height: 1, color: AppColors.progressTrack),
                const SizedBox(height: 18),
                _buildSummaryRow(context, l10n),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context, AppLocalizations l10n) {
    // Só faz sentido oferecer o filtro quando há mais de uma modalidade.
    if (availableTypes.length < 2) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: l10n.exercisesFilterAll,
            selected: selectedType == null,
            onTap: () => onFilterChanged(null),
          ),
          for (final type in availableTypes) ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: labelForExerciseType(context, type),
              selected: selectedType == type,
              onTap: () => onFilterChanged(type),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, AppLocalizations l10n) {
    final locale = Localizations.localeOf(context).toString();
    final hours = summary.totalDurationSeconds ~/ 3600;
    final minutes = (summary.totalDurationSeconds % 3600) ~/ 60;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _SummaryStat(
            label: l10n.exercisesSummaryActivities,
            segments: [_StatSegment('${summary.activityCount}')],
          ),
        ),
        Expanded(
          child: _SummaryStat(
            label: l10n.exercisesSummaryDuration,
            segments: [
              if (hours > 0) _StatSegment('$hours', l10n.exercisesUnitHour),
              _StatSegment('$minutes', l10n.exercisesUnitMinute),
            ],
          ),
        ),
        Expanded(
          child: _SummaryStat(
            label: l10n.exercisesSummaryDistance,
            segments: [
              _StatSegment(
                NumberFormat('0.0', locale).format(summary.totalDistanceKm),
                l10n.exercisesUnitKm,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openMonthlyBreakdown(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseDetailedStatisticsPage(runs: runs),
      ),
    );
  }
}

// ─── Gráfico ─────────────────────────────────────────────────────────────────

/// Gráfico de barras da distância mensal, desenhado apenas com widgets para
/// não adicionar dependência de biblioteca de charts.
class _MonthlyDistanceChart extends StatelessWidget {
  static const double _maxBarHeight = 110;

  final List<MonthlyStat> monthlyStats;

  const _MonthlyDistanceChart({required this.monthlyStats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    final maxDistance = monthlyStats.fold<double>(
      0,
      (max, month) => month.distanceKm > max ? month.distanceKm : max,
    );

    if (maxDistance <= 0) {
      return SizedBox(
        height: _maxBarHeight + 32,
        child: Center(
          child: Text(
            l10n.exercisesStatsEmptyMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: monthlyStats.map((month) {
        final hasValue = month.distanceKm > 0;
        // Barras com valor recebem uma altura mínima para continuarem
        // visíveis mesmo quando muito menores que o pico do período.
        final ratio = month.distanceKm / maxDistance;
        final barHeight = hasValue
            ? (_maxBarHeight * ratio).clamp(6.0, _maxBarHeight)
            : 2.0;

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  NumberFormat('0', locale).format(month.distanceKm),
                  style: TextStyle(
                    color: hasValue
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: hasValue ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: barHeight,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: hasValue
                      ? AppColors.primaryLight
                      : AppColors.progressTrack,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _monthInitial(month.month, locale),
                style: TextStyle(
                  color: hasValue
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: hasValue ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _monthInitial(DateTime month, String locale) {
    final name = DateFormat('MMM', locale).format(month);
    return name.isEmpty ? '' : name.substring(0, 1).toUpperCase();
  }
}

// ─── Peças auxiliares ────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.progressTrack : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primaryDark : AppColors.progressTrack,
            width: selected ? 1.6 : 1.4,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: selected ? AppColors.primaryDark : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

/// Um número do rodapé de estatísticas, opcionalmente quebrado em partes
/// (ex: `12 h 24 min`), com o valor em destaque e a unidade discreta.
class _StatSegment {
  final String value;
  final String? unit;

  const _StatSegment(this.value, [this.unit]);
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final List<_StatSegment> segments;

  const _SummaryStat({required this.label, required this.segments});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              for (final segment in segments) ...[
                Text(
                  segment.value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (segment.unit != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 3, right: 6),
                    child: Text(
                      segment.unit!.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}
