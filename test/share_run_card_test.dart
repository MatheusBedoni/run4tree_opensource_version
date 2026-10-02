import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_4_tree/features/runs/domain/entities/run_session_entity.dart';
import 'package:run_4_tree/features/share/presentation/models/share_options.dart';
import 'package:run_4_tree/features/share/presentation/utils/route_points.dart';
import 'package:run_4_tree/features/share/presentation/utils/share_route_camera.dart';
import 'package:run_4_tree/features/share/presentation/widgets/share_run_card.dart';
import 'package:run_4_tree/features/stickers/presentation/widgets/sticker_avatar.dart';
import 'package:run_4_tree/l10n/generated/app_localizations.dart';

const _route =
    '[[2.8195,-60.6714],[2.8210,-60.6800],[2.8230,-60.6900],[2.8260,-60.7000]]';

RunSessionEntity _run({String exerciseType = 'run', int treesEarned = 2}) {
  return RunSessionEntity(
    id: 1,
    durationSeconds: 4609,
    distanceKm: 12.53,
    calories: 640,
    averageSpeed: 9.8,
    maxSpeed: 21.3,
    pace: 5.4,
    polyline: _route,
    isNight: false,
    treesEarned: treesEarned,
    exerciseType: exerciseType,
    createdAt: DateTime(2026, 9, 11, 7, 30),
  );
}

Widget _host(Widget card, Size size) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: SizedBox(width: size.width, height: size.height, child: card),
      ),
    ),
  );
}

void main() {
  final points = decodeRoutePoints(_route);

  group('ShareRunCard', () {
    for (final format in ShareFormat.values) {
      testWidgets('renders the ${format.name} layout without overflow', (
        tester,
      ) async {
        const width = 270.0;
        await tester.pumpWidget(
          _host(
            ShareRunCard(
              run: _run(),
              background: const ColoredBox(color: Colors.teal),
              routePoints: points,
            ),
            Size(width, width / format.aspectRatio),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('12.53 KM'), findsOneWidget);
        expect(find.text('01:16:49'), findsOneWidget);
        expect(find.text('05:24 /KM'), findsOneWidget);
        expect(find.text('+2 seeds for real trees'), findsOneWidget);
      });
    }

    testWidgets('shows average speed instead of pace for bike rides', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ShareRunCard(
            run: _run(exerciseType: 'bike', treesEarned: 0),
            background: const ColoredBox(color: Colors.teal),
          ),
          const Size(270, 480),
        ),
      );

      expect(find.text('9.8 KM/H'), findsOneWidget);
      expect(find.text('05:24 /KM'), findsNothing);
      expect(find.text('Moving for a greener planet'), findsOneWidget);
    });

    testWidgets('dragging the sticker moves it and stays inside the card', (
      tester,
    ) async {
      var origin = ShareRunCard.defaultStickerOrigin;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => _host(
            ShareRunCard(
              run: _run(),
              background: const ColoredBox(color: Colors.teal),
              stickerAssetPath: 'assets/images/stickers/1.png',
              stickerOrigin: origin,
              onStickerMoved: (value) => setState(() => origin = value),
            ),
            const Size(270, 480),
          ),
        ),
      );

      await tester.drag(find.byType(StickerAvatar), const Offset(54, 0));
      await tester.pump();
      expect(origin.dx, greaterThan(ShareRunCard.defaultStickerOrigin.dx + 0.1));
      expect(origin.dy, closeTo(ShareRunCard.defaultStickerOrigin.dy, 0.001));

      await tester.drag(find.byType(StickerAvatar), const Offset(-1000, -1000));
      await tester.pump();
      expect(origin, Offset.zero);
    });
  });

  group('shareRouteCamera', () {
    test('centers the route horizontally and lifts it above the stats', () {
      final camera = shareRouteCamera(
        points: points,
        viewport: const Size(270, 480),
        format: ShareFormat.story,
      );

      expect(camera.target.longitude, closeTo((-60.6714 - 60.7000) / 2, 1e-9));
      expect(camera.target.latitude, lessThan((2.8195 + 2.8260) / 2));
      expect(camera.zoom, inInclusiveRange(2, 19));
    });

    test('zooms out for a longer route', () {
      final longRoute = decodeRoutePoints(
        '[[2.70,-60.60],[2.80,-60.70],[2.95,-60.85],[3.10,-61.00]]',
      );
      final short = shareRouteCamera(
        points: points,
        viewport: const Size(270, 480),
        format: ShareFormat.story,
      );
      final long = shareRouteCamera(
        points: longRoute,
        viewport: const Size(270, 480),
        format: ShareFormat.story,
      );

      expect(long.zoom, lessThan(short.zoom));
    });

    test('keeps a finite zoom for a single point', () {
      final camera = shareRouteCamera(
        points: [points.first],
        viewport: const Size(270, 270),
        format: ShareFormat.square,
      );

      expect(camera.zoom.isFinite, isTrue);
    });
  });

  group('decodeRoutePoints', () {
    test('parses the stored polyline', () {
      expect(points, hasLength(4));
      expect(points.first.latitude, 2.8195);
      expect(points.first.longitude, -60.6714);
    });

    test('returns an empty route for missing or corrupted data', () {
      expect(decodeRoutePoints(''), isEmpty);
      expect(decodeRoutePoints('not json'), isEmpty);
      expect(decodeRoutePoints('[[1]]'), isEmpty);
    });
  });
}
