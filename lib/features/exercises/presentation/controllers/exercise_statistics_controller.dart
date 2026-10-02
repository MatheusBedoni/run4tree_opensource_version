import 'package:flutter/material.dart';

import '../../../runs/domain/entities/run_session_entity.dart';

enum StatisticsPeriod { week, month, year, all }

class ChartDataPoint {
  final String label;
  final double value;
  final bool isCurrent; // To highlight the current day/month, etc. if needed

  const ChartDataPoint({
    required this.label,
    required this.value,
    this.isCurrent = false,
  });
}

class DetailedStatisticsSummary {
  final int activityCount;
  final double totalCalories;
  final int totalDurationSeconds;
  final double totalDistanceKm;
  final double avgPace;
  final double avgSpeed;
  final double elevationGain;
  final double elevationLoss;

  const DetailedStatisticsSummary({
    required this.activityCount,
    required this.totalCalories,
    required this.totalDurationSeconds,
    required this.totalDistanceKm,
    required this.avgPace,
    required this.avgSpeed,
    required this.elevationGain,
    required this.elevationLoss,
  });

  static const empty = DetailedStatisticsSummary(
    activityCount: 0,
    totalCalories: 0,
    totalDurationSeconds: 0,
    totalDistanceKm: 0,
    avgPace: 0,
    avgSpeed: 0,
    elevationGain: 0,
    elevationLoss: 0,
  );
}

class ExerciseStatisticsController extends ChangeNotifier {
  final List<RunSessionEntity> _allRuns;

  StatisticsPeriod _selectedPeriod = StatisticsPeriod.week;
  String? _selectedType;
  List<String> _availableTypes = [];

  DetailedStatisticsSummary _summary = DetailedStatisticsSummary.empty;
  List<ChartDataPoint> _distanceChartData = [];
  List<ChartDataPoint> _caloriesChartData = [];
  List<ChartDataPoint> _paceChartData = [];
  String _periodLabel = '';

  ExerciseStatisticsController(this._allRuns) {
    _availableTypes = _allRuns.map((r) => r.exerciseType).toSet().toList();
    _calculateStats();
  }

  StatisticsPeriod get selectedPeriod => _selectedPeriod;
  String? get selectedType => _selectedType;
  List<String> get availableTypes => _availableTypes;
  DetailedStatisticsSummary get summary => _summary;
  List<ChartDataPoint> get distanceChartData => _distanceChartData;
  List<ChartDataPoint> get caloriesChartData => _caloriesChartData;
  List<ChartDataPoint> get paceChartData => _paceChartData;
  String get periodLabel => _periodLabel;

  void setPeriod(StatisticsPeriod period) {
    if (_selectedPeriod != period) {
      _selectedPeriod = period;
      _calculateStats();
      notifyListeners();
    }
  }

  void setType(String? type) {
    if (_selectedType != type) {
      _selectedType = type;
      _calculateStats();
      notifyListeners();
    }
  }

  void _calculateStats() {
    final now = DateTime.now();

    final runsByType = _selectedType == null
        ? _allRuns
        : _allRuns.where((r) => r.exerciseType == _selectedType).toList();

    List<RunSessionEntity> filteredRuns = [];

    switch (_selectedPeriod) {
      case StatisticsPeriod.week:
        final int currentDay = now.weekday;
        final DateTime startOfWeek = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: currentDay - 1));
        final DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));

        filteredRuns = runsByType
            .where(
              (r) =>
                  r.createdAt.isAfter(startOfWeek) &&
                  r.createdAt.isBefore(endOfWeek),
            )
            .toList();
        _periodLabel = 'Semana Atual';
        _generateWeekCharts(filteredRuns, startOfWeek);
        break;

      case StatisticsPeriod.month:
        final DateTime startOfMonth = DateTime(now.year, now.month, 1);
        final DateTime endOfMonth = DateTime(now.year, now.month + 1, 1);

        filteredRuns = runsByType
            .where(
              (r) =>
                  r.createdAt.isAfter(startOfMonth) &&
                  r.createdAt.isBefore(endOfMonth),
            )
            .toList();
        _periodLabel = 'Mês Atual';
        _generateMonthCharts(filteredRuns, startOfMonth);
        break;

      case StatisticsPeriod.year:
        final DateTime startOfYear = DateTime(now.year, 1, 1);
        final DateTime endOfYear = DateTime(now.year + 1, 1, 1);

        filteredRuns = runsByType
            .where(
              (r) =>
                  r.createdAt.isAfter(startOfYear) &&
                  r.createdAt.isBefore(endOfYear),
            )
            .toList();
        _periodLabel = '${now.year}';
        _generateYearCharts(filteredRuns, startOfYear);
        break;

      case StatisticsPeriod.all:
        filteredRuns = runsByType;
        _periodLabel = 'Desde o Início';
        _generateAllCharts(filteredRuns);
        break;
    }

    _calculateSummary(filteredRuns);
  }

  void _calculateSummary(List<RunSessionEntity> runs) {
    if (runs.isEmpty) {
      _summary = DetailedStatisticsSummary.empty;
      return;
    }

    int count = runs.length;
    double calories = 0;
    int duration = 0;
    double distance = 0;
    double paceSum = 0;
    double speedSum = 0;

    for (final run in runs) {
      calories += run.calories;
      duration += run.durationSeconds;
      distance += run.distanceKm;
      paceSum += run.pace;
      speedSum += run.averageSpeed;
    }

    _summary = DetailedStatisticsSummary(
      activityCount: count,
      totalCalories: calories,
      totalDurationSeconds: duration,
      totalDistanceKm: distance,
      avgPace: paceSum / count,
      avgSpeed: speedSum / count,
      elevationGain: 0,
      elevationLoss: 0,
    );
  }

  void _generateWeekCharts(List<RunSessionEntity> runs, DateTime startOfWeek) {
    _distanceChartData = _buildWeekData(
      runs,
      startOfWeek,
      (r) => r.distanceKm,
      false,
    );
    _caloriesChartData = _buildWeekData(
      runs,
      startOfWeek,
      (r) => r.calories,
      false,
    );
    _paceChartData = _buildWeekData(runs, startOfWeek, (r) => r.pace, true);
  }

  void _generateMonthCharts(
    List<RunSessionEntity> runs,
    DateTime startOfMonth,
  ) {
    _distanceChartData = _buildMonthData(
      runs,
      startOfMonth,
      (r) => r.distanceKm,
      false,
    );
    _caloriesChartData = _buildMonthData(
      runs,
      startOfMonth,
      (r) => r.calories,
      false,
    );
    _paceChartData = _buildMonthData(runs, startOfMonth, (r) => r.pace, true);
  }

  void _generateYearCharts(List<RunSessionEntity> runs, DateTime startOfYear) {
    _distanceChartData = _buildYearData(
      runs,
      startOfYear,
      (r) => r.distanceKm,
      false,
    );
    _caloriesChartData = _buildYearData(
      runs,
      startOfYear,
      (r) => r.calories,
      false,
    );
    _paceChartData = _buildYearData(runs, startOfYear, (r) => r.pace, true);
  }

  void _generateAllCharts(List<RunSessionEntity> runs) {
    _distanceChartData = _buildAllData(runs, (r) => r.distanceKm, false);
    _caloriesChartData = _buildAllData(runs, (r) => r.calories, false);
    _paceChartData = _buildAllData(runs, (r) => r.pace, true);
  }

  List<ChartDataPoint> _buildWeekData(
    List<RunSessionEntity> runs,
    DateTime startOfWeek,
    double Function(RunSessionEntity) selector,
    bool isAvg,
  ) {
    final Map<int, double> values = {};
    final Map<int, int> counts = {};
    for (int i = 0; i < 7; i++) {
      values[i] = 0.0;
      counts[i] = 0;
    }

    for (final run in runs) {
      int dayIndex = run.createdAt.difference(startOfWeek).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        values[dayIndex] = (values[dayIndex] ?? 0) + selector(run);
        counts[dayIndex] = (counts[dayIndex] ?? 0) + 1;
      }
    }

    const labels = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];
    return List.generate(7, (index) {
      double val = values[index] ?? 0.0;
      int count = counts[index] ?? 0;
      if (isAvg && count > 0) val = val / count;
      return ChartDataPoint(label: labels[index], value: val);
    });
  }

  List<ChartDataPoint> _buildMonthData(
    List<RunSessionEntity> runs,
    DateTime startOfMonth,
    double Function(RunSessionEntity) selector,
    bool isAvg,
  ) {
    final int daysInMonth = DateTime(
      startOfMonth.year,
      startOfMonth.month + 1,
      0,
    ).day;
    final Map<int, double> values = {};
    final Map<int, int> counts = {};
    for (int i = 0; i < daysInMonth; i++) {
      values[i] = 0.0;
      counts[i] = 0;
    }

    for (final run in runs) {
      int dayIndex = run.createdAt.day - 1;
      if (dayIndex >= 0 && dayIndex < daysInMonth) {
        values[dayIndex] = (values[dayIndex] ?? 0) + selector(run);
        counts[dayIndex] = (counts[dayIndex] ?? 0) + 1;
      }
    }

    return List.generate(daysInMonth, (index) {
      String label = (index == 0 || index == daysInMonth - 1 || index % 5 == 4)
          ? '${index + 1}'
          : '';
      double val = values[index] ?? 0.0;
      int count = counts[index] ?? 0;
      if (isAvg && count > 0) val = val / count;
      return ChartDataPoint(label: label, value: val);
    });
  }

  List<ChartDataPoint> _buildYearData(
    List<RunSessionEntity> runs,
    DateTime startOfYear,
    double Function(RunSessionEntity) selector,
    bool isAvg,
  ) {
    final Map<int, double> values = {};
    final Map<int, int> counts = {};
    for (int i = 0; i < 12; i++) {
      values[i] = 0.0;
      counts[i] = 0;
    }

    for (final run in runs) {
      int monthIndex = run.createdAt.month - 1;
      values[monthIndex] = (values[monthIndex] ?? 0) + selector(run);
      counts[monthIndex] = (counts[monthIndex] ?? 0) + 1;
    }

    const labels = [
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez',
    ];
    return List.generate(12, (index) {
      double val = values[index] ?? 0.0;
      int count = counts[index] ?? 0;
      if (isAvg && count > 0) val = val / count;
      return ChartDataPoint(label: labels[index], value: val);
    });
  }

  List<ChartDataPoint> _buildAllData(
    List<RunSessionEntity> runs,
    double Function(RunSessionEntity) selector,
    bool isAvg,
  ) {
    if (runs.isEmpty) return [];

    final sortedRuns = List<RunSessionEntity>.from(runs)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final int startYear = sortedRuns.first.createdAt.year;
    final int endYear = sortedRuns.last.createdAt.year;

    final Map<int, double> values = {};
    final Map<int, int> counts = {};
    for (int i = startYear; i <= endYear; i++) {
      values[i] = 0.0;
      counts[i] = 0;
    }

    for (final run in runs) {
      int year = run.createdAt.year;
      values[year] = (values[year] ?? 0) + selector(run);
      counts[year] = (counts[year] ?? 0) + 1;
    }

    return List.generate(endYear - startYear + 1, (index) {
      int year = startYear + index;
      double val = values[year] ?? 0.0;
      int count = counts[year] ?? 0;
      if (isAvg && count > 0) val = val / count;
      return ChartDataPoint(label: '$year', value: val);
    });
  }
}
