import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/home/activity_page.dart';
import 'package:wantok_app/src/home/adaptive_category_grid.dart';

void main() {
  final shortcuts = <String>[
    'Taxi rides',
    'Food & shop orders',
    'Event registrations',
    'Water trips',
  ];

  int columns(WidgetTester tester) {
    final grid = tester.widget<GridView>(
      find.byKey(const ValueKey('track-journey-shortcut-grid')),
    );
    return (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
        .crossAxisCount;
  }

  Future<void> showTrack(
    WidgetTester tester,
    double width, {
    ValueNotifier<int?>? density,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveGridDensityScope(
            density: density ?? ValueNotifier<int?>(null),
            child: ActivityPage(
              loadReservations: () async => <Map<String, dynamic>>[],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final (width, expected) in <(double, int)>[
    (320, 2),
    (390, 2),
    (540, 3),
    (800, 3),
    (1024, 3),
  ]) {
    testWidgets(
      'Track shortcuts $width px: $expected columns, equal tap cards',
      (tester) async {
        final shared = ValueNotifier<int?>(null);
        addTearDown(shared.dispose);
        await showTrack(tester, width, density: shared);
        expect(columns(tester), expected);
        for (var i = 0; i < shortcuts.length; i++) {
          expect(find.text(shortcuts[i]), findsOneWidget);
          final target = find.byKey(ValueKey('track-journey-shortcut-$i'));
          expect(target, findsOneWidget);
          expect(tester.widget<InkWell>(target).onTap, isNotNull);
          final rect = tester.getRect(target);
          expect(rect.height, greaterThanOrEqualTo(80));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(width));
        }
        expect(find.text('No requests or reservations yet'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Track pinch in/out changes 2/3 like Home without navigation', (
    tester,
  ) async {
    final shared = ValueNotifier<int?>(null);
    addTearDown(shared.dispose);
    await showTrack(tester, 320, density: shared);
    expect(columns(tester), 2);
    final origin = tester.getTopLeft(
      find.byKey(const ValueKey('track-journey-shortcut-grid')),
    );
    final centre = origin + const Offset(140, 48);

    // Two-finger pinch inward fits three smaller, equal-sized cards.
    var left = await tester.createGesture(pointer: 41);
    var right = await tester.createGesture(pointer: 42);
    await left.down(centre + const Offset(-45, 0));
    await right.down(centre + const Offset(45, 0));
    await left.moveTo(centre + const Offset(-15, 0));
    await right.moveTo(centre + const Offset(15, 0));
    await tester.pumpAndSettle();
    expect(columns(tester), 3);
    expect(shared.value, 3);
    await left.up();
    await right.up();

    // Reverse spread restores two larger cards and the same destinations.
    left = await tester.createGesture(pointer: 43);
    right = await tester.createGesture(pointer: 44);
    await left.down(centre + const Offset(-25, 0));
    await right.down(centre + const Offset(25, 0));
    await left.moveTo(centre + const Offset(-75, 0));
    await right.moveTo(centre + const Offset(75, 0));
    await tester.pumpAndSettle();
    expect(columns(tester), 2);
    expect(shared.value, 2);
    for (final label in shortcuts) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('No requests or reservations yet'), findsOneWidget);
    await left.up();
    await right.up();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Desktop 1440 px preserves original compact shortcut buttons', (
    tester,
  ) async {
    await showTrack(tester, 1440);
    expect(
      find.byKey(const ValueKey('track-journey-shortcut-grid')),
      findsNothing,
    );
    for (final label in shortcuts) {
      expect(find.widgetWithText(OutlinedButton, label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
