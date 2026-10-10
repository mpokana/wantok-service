import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_core/wantok_core.dart';
import 'package:wantok_ui/wantok_ui.dart';
import 'package:wantok_app/src/home/client_home.dart';
import 'package:wantok_app/src/home/home_shell.dart';

const _services = [
  WantokServiceCategory(
    id: 'a',
    slug: 'taxi-ride',
    name: 'Taxi',
    vertical: 'mobility',
    bookingMode: 'on_demand',
  ),
  WantokServiceCategory(
    id: 'b',
    slug: 'food',
    name: 'Food',
    vertical: 'commerce',
    bookingMode: 'commerce',
  ),
  WantokServiceCategory(
    id: 'c',
    slug: 'groceries',
    name: 'Groceries',
    vertical: 'commerce',
    bookingMode: 'commerce',
  ),
  WantokServiceCategory(
    id: 'd',
    slug: 'specialist-services',
    name: 'Specialists',
    vertical: 'marketplace',
    bookingMode: 'quote',
  ),
];

Future<void> _display(WidgetTester tester, Widget page, double width) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: WantokTheme.light(),
      home: Scaffold(body: page),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('desktop Home replaces stretched three-column tiles', (
    tester,
  ) async {
    await _display(
      tester,
      ClientHome(loadServices: () async => _services),
      1600,
    );
    expect(
      find.byKey(const ValueKey('enterprise-home-category-grid')),
      findsOneWidget,
    );
    final first = find.byKey(const ValueKey('home-category-taxi-ride'));
    expect(first, findsOneWidget);
    expect(tester.getSize(first).width, lessThan(215));
    expect(find.text('Popular categories'), findsOneWidget);
    expect(find.text('Services for everyday life'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet shows usable multi-column category tiles', (
    tester,
  ) async {
    await _display(
      tester,
      ClientHome(loadServices: () async => _services),
      900,
    );
    expect(
      find.byKey(const ValueKey('enterprise-home-category-grid')),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('home-category-food'))).width,
      lessThan(220),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('handheld retains native gesture category grid', (tester) async {
    await _display(
      tester,
      ClientHome(loadServices: () async => _services),
      390,
    );
    expect(
      find.byKey(const ValueKey('enterprise-home-category-grid')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('adaptive-category-gesture-surface')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop shell moves navigation to the top bar', (tester) async {
    await _display(
      tester,
      const HomeShell(roles: {'customer'}, email: null),
      1500,
    );
    for (final label in ['Home', 'Services', 'Explore', 'Track', 'Wallet']) {
      expect(find.byKey(ValueKey('wantok-desktop-nav-$label')), findsOneWidget);
      expect(find.byKey(ValueKey('wantok-nav-$label')), findsNothing);
    }
    await tester.tap(find.byKey(const ValueKey('wantok-desktop-nav-Services')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('wantok-desktop-nav-Services')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
