import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_tech/src/dashboard/technical_local_ports_page.dart';

void main() {
  test('port registry records exactly the agreed EAGLT02 addresses', () {
    expect(localWantokApplications.map((entry) => entry.port).toList(), [
      3000,
      3100,
      3200,
      3300,
      3400,
    ]);
    expect(
      localWantokApplications.map((entry) => entry.uri.toString()).toList(),
      [
        'http://127.0.0.1:3000/',
        'http://127.0.0.1:3100/',
        'http://127.0.0.1:3200/',
        'http://127.0.0.1:3300/',
        'http://127.0.0.1:3400/',
      ],
    );
    expect(
      localWantokApplications
          .where((entry) => entry.environment == 'Staging preview')
          .length,
      2,
    );
  });

  for (final width in [390.0, 1200.0]) {
    testWidgets('local applications fit ${width.toInt()}px', (tester) async {
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final opened = <Uri>[];
      await tester.pumpWidget(
        MaterialApp(
          home: TechnicalLocalPortsPage(
            openUrl: (uri) async {
              opened.add(uri);
              return true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Local applications & ports'), findsOneWidget);
      expect(find.textContaining('EAGLT02'), findsWidgets);
      expect(find.byKey(const ValueKey('local-port-3000')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('open-local-port-3000')),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('open-local-port-3000')));
      await tester.pumpAndSettle();
      expect(opened.single.toString(), 'http://127.0.0.1:3000/');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('staging link is openable with no configuration writes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final opened = <Uri>[];
    await tester.pumpWidget(
      MaterialApp(
        home: TechnicalLocalPortsPage(
          openUrl: (uri) async {
            opened.add(uri);
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('open-local-port-3400')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('open-local-port-3400')));
    await tester.pumpAndSettle();
    expect(opened.single.toString(), 'http://127.0.0.1:3400/');
    expect(tester.takeException(), isNull);
  });
}
