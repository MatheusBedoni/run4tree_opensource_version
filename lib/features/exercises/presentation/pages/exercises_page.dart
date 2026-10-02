import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../profile/data/repositories/profile_repository_impl.dart';
import '../../../profile/domain/entities/profile_entity.dart';
import '../../../profile/domain/usecases/get_profile_usecase.dart';
import '../../../runs/data/datasources/run_session_local_datasource_impl.dart';
import '../../../runs/data/repositories/run_session_repository_impl.dart';
import '../../../runs/domain/entities/run_session_entity.dart';
import '../../../runs/domain/usecases/delete_run_usecase.dart';
import '../../../runs/domain/usecases/get_all_runs_usecase.dart';
import '../../../share/presentation/pages/share_run_page.dart';
import '../controllers/exercises_controller.dart';
import '../utils/exercise_formatters.dart';
import '../widgets/exercise_records_section.dart';
import '../widgets/exercise_section_header.dart';
import '../widgets/exercise_statistics_section.dart';
import 'exercise_details_page.dart';

class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  late final ExercisesController _controller;

  @override
  void initState() {
    super.initState();

    // Drift: instancia a cadeia datasource → repository → usecases
    final db = AppDatabase.instance;
    final runDataSource = RunSessionLocalDataSourceImpl(db);
    final runRepository = RunSessionRepositoryImpl(runDataSource);
    _controller = ExercisesController(
      GetAllRunsUseCase(runRepository),
      DeleteRunUseCase(runRepository),
      GetProfileUseCase(ProfileRepositoryImpl()),
    );
    _controller.loadRuns();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openRunDetails(RunSessionEntity run) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExerciseDetailsPage(runSession: run)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.homeNavProgress,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (_controller.isLoading && _controller.runs.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryDark),
              );
            }

            if (_controller.hasLoadError && _controller.runs.isEmpty) {
              return _buildErrorState(
                AppLocalizations.of(context)!.exercisesLoadErrorMessage,
              );
            }

            return RefreshIndicator(
              color: AppColors.primaryDark,
              onRefresh: _controller.refreshRuns,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 8, bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _buildSections(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Monta a pilha de seções da página. Sem nenhuma atividade registrada,
  /// recordes e estatísticas não teriam o que mostrar — nesse caso só a meta
  /// semanal e o estado vazio aparecem.
  List<Widget> _buildSections() {
    final profile = _controller.profile;
    final hasRuns = _controller.runs.isNotEmpty;

    return [
      if (profile != null) ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildWeeklyGoalCard(profile),
        ),
        const SizedBox(height: 28),
      ],
      if (!hasRuns)
        _buildEmptyState()
      else ...[
        ExerciseRecordsSection(
          records: _controller.records,
          onRecordTap: _openRunDetails,
        ),
        const SizedBox(height: 28),
        ExerciseStatisticsSection(
          monthlyStats: _controller.monthlyStats,
          summary: _controller.summary,
          availableTypes: _controller.availableExerciseTypes,
          selectedType: _controller.statsFilter,
          onFilterChanged: _controller.selectStatsFilter,
          runs: _controller.runs,
        ),
        const SizedBox(height: 28),
        _buildRunHistorySection(),
      ],
    ];
  }

  Widget _buildWeeklyGoalCard(ProfileEntity profile) {
    final progress = profile.weeklyGoalProgress;
    final reachedGoal = progress >= 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
                Icons.flag_rounded,
                color: AppColors.primaryDark,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.fieldLabelWeeklyGoal,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                AppLocalizations.of(context)!.weeklyGoalProgressLabel(
                  profile.weeklyDistanceKm.toStringAsFixed(1),
                  profile.weeklyGoalKm.toStringAsFixed(1),
                ),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: reachedGoal
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.progressTrack,
              valueColor: AlwaysStoppedAnimation(
                reachedGoal ? AppColors.progressGreen : AppColors.primaryLight,
              ),
            ),
          ),
          if (reachedGoal) ...[
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context)!.profileGoalCompletedMessage,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRunHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ExerciseSectionHeader(
            title: AppLocalizations.of(context)!.exercisesHistoryTitle,
          ),
        ),
        const SizedBox(height: 14),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _controller.runs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildRunCard(_controller.runs[index]);
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.directions_run_rounded,
            size: 56,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.exercisesEmptyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.exercisesEmptySubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _controller.refreshRuns,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.commonRetryButton,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRunCard(RunSessionEntity run) {
    return Dismissible(
      key: ValueKey(run.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        if (run.id != null) _controller.deleteRun(run.id!);
      },
      child: GestureDetector(
        onTap: () => _openRunDetails(run),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.progressTrack,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconForExerciseType(run.exerciseType),
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labelForExerciseType(context, run.exerciseType),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(run.createdAt),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildRunMetric(
                          Icons.route_rounded,
                          '${run.distanceKm.toStringAsFixed(2)} km',
                        ),
                        const SizedBox(width: 16),
                        _buildRunMetric(
                          Icons.timer_rounded,
                          formatCompactDuration(run.durationSeconds),
                        ),
                        const SizedBox(width: 16),
                        _buildRunMetric(
                          Icons.local_fire_department_rounded,
                          '${run.calories.toStringAsFixed(0)} ${AppLocalizations.of(context)!.exercisesKcalUnit}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded, size: 20),
                color: AppColors.textSecondary,
                tooltip: AppLocalizations.of(context)!.runCompletedShareButton,
                onPressed: () => ShareRunPage.open(context, run),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRunMetric(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    final datePart = DateFormat('d MMM', locale).format(date);
    final timePart = DateFormat.Hm(locale).format(date);
    return '$datePart • $timePart';
  }
}
