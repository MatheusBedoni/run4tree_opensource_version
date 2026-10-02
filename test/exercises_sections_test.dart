import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_4_tree/features/exercises/domain/entities/exercise_stats.dart';
import 'package:run_4_tree/features/exercises/presentation/widgets/exercise_records_section.dart';
import 'package:run_4_tree/features/exercises/presentation/widgets/exercise_statistics_section.dart';
import 'package:run_4_tree/features/runs/domain/entities/run_session_entity.dart';
import 'package:run_4_tree/l10n/generated/app_localizations.dart';

RunSessionEntity _run({
  int id = 1,
  String exerciseType = 'run',
  double distanceKm = 8.4,
  int durationSeconds = 6357,
  double calories = 308,
  double pace = 5.4,
  double maxSpeed = 17.2,
  DateTime? createdAt,
}) {
  return RunSessionEntity(
    id: id,
    durationSeconds: durationSeconds,
    distanceKm: distanceKm,
    calories: calories,
    averageSpeed: 11.1,
    maxSpeed: maxSpeed,
    pace: pace,
    polyline: '[]',
    isNight: false,
    treesEarned: 1,
    exerciseType: exerciseType,
    createdAt: createdAt ?? DateTime.now(),
  );
}

Widget _host(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}

List<MonthlyStat> _months({bool withData = true}) {
  final now = DateTime(2026, 9);
  return List.generate(12, (i) {
    final month = DateTime(now.year, now.month - (11 - i));
    final isLast = i == 11;
    return MonthlyStat(
      month: month,
      distanceKm: withData && isLast ? 112.8 : 0,
      durationSeconds: withData && isLast ? 44640 : 0,
      activityCount: withData && isLast ? 14 : 0,
    );
  });
}

void main() {
  testWidgets('records section renders every record without overflow', (
    tester,
  ) async {
    final run = _run();
    final records = ExerciseRecordType.values
        .map((type) => ExerciseRecord(type: type, run: run))
        .toList();

    await tester.pumpWidget(
      _host(
        ExerciseRecordsSection(records: records, onRecordTap: (_) {}),
      ),
    );
    await tester.pumpAndSettle();

    // Um card por métrica, cada um com sua legenda e valor formatado.
    expect(find.text('Longest distance'), findsOneWidget);
    expect(find.text('Longest duration'), findsOneWidget);
    expect(find.text('Most kcal burned'), findsOneWidget);
    expect(find.text('01:45:57'), findsOneWidget);
    expect(find.text('308'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('records section shows the empty card with no records', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const ExerciseRecordsSection(records: [], onRecordTap: _noop)),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Finish your first activity to unlock records.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('statistics section renders chart, filters and totals', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        ExerciseStatisticsSection(
          monthlyStats: _months(),
          summary: const ExerciseSummary(
            activityCount: 14,
            totalDurationSeconds: 44640,
            totalDistanceKm: 112.8,
          ),
          availableTypes: const ['run', 'walk', 'bike'],
          selectedType: null,
          onFilterChanged: (_) {},
          runs: const [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ALL'), findsOneWidget);
    expect(find.text('WALK'), findsOneWidget);
    expect(find.text('DISTANCE (KM) - LAST 12 MONTHS'), findsOneWidget);
    // 14 activities, 12h24 duration, 112.8 km
    expect(find.text('14'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    expect(find.text('112.8'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('statistics section falls back to a message with no activity', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        ExerciseStatisticsSection(
          monthlyStats: _months(withData: false),
          summary: ExerciseSummary.empty,
          availableTypes: const ['run'],
          selectedType: null,
          onFilterChanged: _noop,
          runs: const [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No activities recorded in this period.'),
      findsOneWidget,
    );
    // Um único tipo registrado não justifica os chips de filtro.
    expect(find.text('ALL'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

void _noop(Object? _) {}
