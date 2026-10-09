import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/home/adaptive_category_grid.dart';

void main() {
  int columns(WidgetTester tester, String key) {
    final grid = tester.widget<GridView>(find.byKey(ValueKey(key)));
    return (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
        .crossAxisCount;
  }

  Future<void> render(
    WidgetTester tester,
    double width,
    ValueNotifier<int?> density,
  ) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AdaptiveGridDensityScope(
              density: density,
              child: Column(
                children: [
                  for (final name in ['firstGrid', 'secondGrid'])
                    AdaptiveCategoryGrid(
                      gridKey: ValueKey(name),
                      itemCount: 6,
                      tileHeight: 110,
                      itemBuilder: (context, index) => ColoredBox(
                        color: Colors.green,
                        child: Text('Tile $index'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('width adapts automatically to 2 or 3 columns', (tester) async {
    final density = ValueNotifier<int?>(null);
    addTearDown(density.dispose);
    await render(tester, 390, density);
    expect(columns(tester, 'firstGrid'), 2);
    expect(columns(tester, 'secondGrid'), 2);
    await render(tester, 540, density);
    expect(columns(tester, 'firstGrid'), 3);
    expect(columns(tester, 'secondGrid'), 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pinch switches 2 / 3 globally without changing card contents', (
    tester,
  ) async {
    final density = ValueNotifier<int?>(null);
    addTearDown(density.dispose);
    await render(tester, 390, density);
    final center =
        tester.getTopLeft(find.byKey(const ValueKey('firstGrid'))) +
        const Offset(190, 65);

    // Two-finger pinch IN switches the shared view to three columns.
    var a = await tester.createGesture(pointer: 11);
    var b = await tester.createGesture(pointer: 12);
    await a.down(center + const Offset(-50, 0));
    await b.down(center + const Offset(50, 0));
    await a.moveTo(center + const Offset(-18, 0));
    await b.moveTo(center + const Offset(18, 0));
    await tester.pumpAndSettle();
    expect(columns(tester, 'firstGrid'), 3);
    expect(columns(tester, 'secondGrid'), 3);
    await a.up();
    await b.up();

    // Two-finger spread OUT switches back to larger two-column cards.
    a = await tester.createGesture(pointer: 13);
    b = await tester.createGesture(pointer: 14);
    await a.down(center + const Offset(-24, 0));
    await b.down(center + const Offset(24, 0));
    await a.moveTo(center + const Offset(-77, 0));
    await b.moveTo(center + const Offset(77, 0));
    await tester.pumpAndSettle();
    expect(columns(tester, 'firstGrid'), 2);
    expect(columns(tester, 'secondGrid'), 2);
    expect(find.text('Tile 0'), findsNWidgets(2));
    await a.up();
    await b.up();
    expect(tester.takeException(), isNull);
  });
}
