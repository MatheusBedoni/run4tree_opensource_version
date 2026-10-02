import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../runs/domain/entities/run_session_entity.dart';
import '../controllers/exercise_statistics_controller.dart';
import '../utils/exercise_formatters.dart';

class ExerciseDetailedStatisticsPage extends StatefulWidget {
  final List<RunSessionEntity> runs;

  const ExerciseDetailedStatisticsPage({super.key, required this.runs});

  @override
  State<ExerciseDetailedStatisticsPage> createState() =>
      _ExerciseDetailedStatisticsPageState();
}

class _ExerciseDetailedStatisticsPageState
    extends State<ExerciseDetailedStatisticsPage> {
  late final ExerciseStatisticsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ExerciseStatisticsController(widget.runs);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.exercisesStatisticsTitle.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            fontSize: 16,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTabs(),
                const SizedBox(height: 16),
                _buildFilterChips(l10n),
                const SizedBox(height: 16),
                _buildPeriodSelector(),
                const SizedBox(height: 32),
                _buildSummarySection(l10n, locale),
                const SizedBox(height: 40),
                _buildGenericChartSection(
                  title: 'DISTÂNCIA',
                  totalValue: NumberFormat(
                    '0.0',
                    locale,
                  ).format(_controller.summary.totalDistanceKm),
                  unit: 'KM',
                  chartData: _controller.distanceChartData,
                  locale: locale,
                ),
                const SizedBox(height: 40),
                _buildGenericChartSection(
                  title: 'CALORIAS',
                  totalValue: _controller.summary.totalCalories.toStringAsFixed(
                    0,
                  ),
                  unit: 'KCAL',
                  chartData: _controller.caloriesChartData,
                  locale: locale,
                ),
                const SizedBox(height: 40),
                _buildGenericChartSection(
                  title: 'RITMO MÉDIO',
                  totalValue: _formatPace(_controller.summary.avgPace),
                  unit: 'MIN/KM',
                  chartData: _controller.paceChartData,
                  locale: locale,
                  isPace: true,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatPace(double decimalPace) {
    if (decimalPace == 0) return '00:00';
    final int paceMinutes = decimalPace.floor();
    final int paceSeconds = ((decimalPace - paceMinutes) * 60).round();
    return '${paceMinutes.toString().padLeft(2, '0')}:${paceSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildTabButton('SEMANA', StatisticsPeriod.week),
          const SizedBox(width: 8),
          _buildTabButton('MÊS', StatisticsPeriod.month),
          const SizedBox(width: 8),
          _buildTabButton('ANO', StatisticsPeriod.year),
          const SizedBox(width: 8),
          _buildTabButton('TUDO', StatisticsPeriod.all),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, StatisticsPeriod period) {
    final isSelected = _controller.selectedPeriod == period;
    return GestureDetector(
      onTap: () => _controller.setPeriod(period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.transparent : AppColors.cardWhite,
          border: Border.all(
            color: isSelected ? AppColors.textPrimary : AppColors.progressTrack,
            width: isSelected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(4), // Square-ish like the image
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(AppLocalizations l10n) {
    if (_controller.availableTypes.length < 2) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _FilterChip(
            label: l10n.exercisesFilterAll,
            selected: _controller.selectedType == null,
            onTap: () => _controller.setType(null),
          ),
          for (final type in _controller.availableTypes) ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: labelForExerciseType(context, type),
              selected: _controller.selectedType == type,
              onTap: () => _controller.setType(type),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textPrimary, width: 1.0),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Período selecionado', // Simplified from "Semana selecionada"
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _controller.periodLabel,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(AppLocalizations l10n, String locale) {
    final summary = _controller.summary;

    // Formatting
    final hours = summary.totalDurationSeconds ~/ 3600;
    final minutes = (summary.totalDurationSeconds % 3600) ~/ 60;
    final durationStr = hours > 0
        ? '$hours h ${minutes.toString().padLeft(2, '0')} min'
        : '$minutes min';

    final int paceMinutes = summary.avgPace.floor();
    final int paceSeconds = ((summary.avgPace - paceMinutes) * 60).round();
    final paceStr =
        '${paceMinutes.toString().padLeft(2, '0')}:${paceSeconds.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RESUMO',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.flash_on_outlined,
                  value: summary.activityCount.toString(),
                  label: 'ATIVIDADES',
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.local_fire_department_outlined,
                  value: summary.totalCalories.toStringAsFixed(0),
                  unit: 'KCAL',
                  label: 'CALORIAS',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.timer_outlined,
                  value: durationStr,
                  label: 'DURAÇÃO',
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.place_outlined,
                  value: NumberFormat(
                    '0.0',
                    locale,
                  ).format(summary.totalDistanceKm),
                  unit: 'KM',
                  label: 'DISTÂNCIA',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.speed_outlined, // Replace with appropriate icon
                  value: paceStr,
                  unit: 'MIN/KM',
                  label: 'RITMO MED.',
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.directions_run_outlined,
                  value: NumberFormat('0.0', locale).format(
                    summary.avgSpeed,
                  ), // Using max speed for now from logic
                  unit: 'KM/H',
                  label: 'VELOCIDADE MED.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.terrain_outlined,
                  value: summary.elevationGain.toStringAsFixed(0),
                  unit: 'M',
                  label: 'GANHO DE ELEV.',
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.trending_down_outlined,
                  value: summary.elevationLoss.toStringAsFixed(0),
                  unit: 'M',
                  label: 'PERDA DE ELEV.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String value,
    String? unit,
    required String label,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 28, color: AppColors.textPrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (unit != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenericChartSection({
    required String title,
    required String totalValue,
    required String unit,
    required List<ChartDataPoint> chartData,
    required String locale,
    bool isPace = false,
  }) {
    final maxValue = chartData.fold<double>(
      0,
      (max, data) => data.value > max ? data.value : max,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Chart Header
          Row(
            children: [
              Container(width: 4, height: 36, color: AppColors.primaryLight),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$totalValue $unit',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _controller.periodLabel,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Bar Chart
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Y-axis labels
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      unit,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      isPace
                          ? _formatPace(maxValue)
                          : NumberFormat('0', locale).format(maxValue),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      isPace
                          ? _formatPace(maxValue / 2)
                          : NumberFormat('0', locale).format(maxValue / 2),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    const Text(
                      '0',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                // Bars
                Expanded(
                  child: Stack(
                    children: [
                      // Grid lines
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(height: 14), // Offset for 'KM'
                          _buildGridLine(),
                          _buildGridLine(),
                          _buildGridLine(),
                        ],
                      ),
                      // Bars container
                      Padding(
                        padding: const EdgeInsets.only(top: 14, bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: chartData.map((data) {
                            final hasValue = data.value > 0;
                            final ratio = maxValue > 0
                                ? data.value / maxValue
                                : 0.0;
                            final barHeight = hasValue
                                ? (150 * ratio).clamp(4.0, 150.0)
                                : 0.0;

                            return Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (hasValue)
                                    Container(
                                      height: barHeight,
                                      width:
                                          _controller.selectedPeriod ==
                                              StatisticsPeriod.month
                                          ? 4
                                          : 12,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(2),
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // X-axis labels
          Row(
            children: [
              const SizedBox(width: 24), // Offset for Y-axis
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: chartData.map((data) {
                    return Expanded(
                      child: Text(
                        data.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridLine() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        color: AppColors.progressTrack,
        border: Border(
          bottom: BorderSide(
            color: AppColors.progressTrack,
            width: 1,
            style: BorderStyle
                .solid, // Use simple solid line or CustomPaint for dashed
          ),
        ),
      ),
    );
  }
}

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
