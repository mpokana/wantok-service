import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/home/smoke_data.dart';

void main() {
  test('All smoke identifiers are namespaced, unique and disposable', () {
    final ids = <String>{};
    for (final scene in SmokeScene.values) {
      for (final record in SmokeCatalogue.recordsFor(scene)) {
        expect(record.id, startsWith('${WantokSmokeData.namespace}_'));
        expect(ids.add(record.id), isTrue, reason: record.id);
      }
    }
    expect(ids.length, greaterThanOrEqualTo(10));
  });

  testWidgets('Every smoke card carries a small s and reveals its ID', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SmokePreviewSection(
              scene: SmokeScene.food,
              heading: 'Sample restaurants',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sample restaurants'), findsOneWidget);
    expect(find.byType(SmokeMarker), findsNWidgets(SmokeCatalogue.food.length + 1));
    expect(find.text('s'), findsNWidgets(SmokeCatalogue.food.length + 1));
    expect(
      find.byKey(const ValueKey('SMOKE_20261008_FOOD_001')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('SMOKE_20261008_FOOD_001')));
    await tester.pumpAndSettle();
    expect(find.textContaining('SMOKE_20261008_FOOD_001'), findsOneWidget);
    expect(find.textContaining('cannot submit a real action'), findsOneWidget);
  });
}
