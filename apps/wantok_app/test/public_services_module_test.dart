import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/home/client_home.dart';
import 'package:wantok_app/src/home/public_services_page.dart';
import 'package:wantok_app/src/home/reference_services_gallery.dart';
import 'package:wantok_app/src/home/services_hub_page.dart';
import 'package:wantok_core/wantok_core.dart';

const publicCategory = WantokServiceCategory(
  id: 'public-test',
  slug: 'public-services',
  name: 'Public Services',
  vertical: 'other',
  bookingMode: 'information',
);
const inactivePublicCategory = WantokServiceCategory(
  id: 'public-disabled-test',
  slug: 'public-services',
  name: 'Public Services',
  vertical: 'other',
  bookingMode: 'information',
  isActive: false,
);
const taxiCategory = WantokServiceCategory(
  id: 'taxi-test',
  slug: 'taxi-ride',
  name: 'Taxi / Transport',
  vertical: 'mobility',
  bookingMode: 'on_demand',
);

Future<void> pumpModule(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: page)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Public Services remains hidden while disabled on Home', (
    tester,
  ) async {
    await pumpModule(
      tester,
      ClientHome(
        loadServices: () async => [taxiCategory, inactivePublicCategory],
        loadTopProviders: () async => [],
      ),
    );
    expect(
      find.byKey(const ValueKey('home-category-public-services')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('home-category-taxi-ride')), findsWidgets);
  });

  testWidgets('Public Services Home tile opens its own page', (tester) async {
    await pumpModule(
      tester,
      ClientHome(
        loadServices: () async => [taxiCategory, publicCategory],
        loadTopProviders: () async => [],
      ),
    );
    final tile = find.byKey(const ValueKey('home-category-public-services'));
    await tester.scrollUntilVisible(
      tile,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('public-services-page')), findsOneWidget);
    expect(find.text('Public Services Categories'), findsOneWidget);
  });

  testWidgets('Services category visibility follows its active flag', (
    tester,
  ) async {
    await pumpModule(
      tester,
      ServicesHubPage(
        demoMode: true,
        loadServices: () async => [taxiCategory, inactivePublicCategory],
      ),
    );
    expect(
      find.byKey(const ValueKey('reference-category-Public\nServices')),
      findsNothing,
    );
  });

  testWidgets('Services tile opens the dedicated Public Services module', (
    tester,
  ) async {
    await pumpModule(
      tester,
      ServicesHubPage(
        demoMode: true,
        loadServices: () async => [taxiCategory, publicCategory],
      ),
    );
    final tile = find.byKey(
      const ValueKey('reference-category-Public\nServices'),
    );
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('public-services-page')), findsOneWidget);
  });

  testWidgets('Public service category tiles open information pages', (
    tester,
  ) async {
    await pumpModule(tester, const PublicServicesPage());
    expect(find.text('Emergency & Safety'), findsWidgets);
    expect(find.text('Health Services'), findsWidgets);
    await tester.ensureVisible(
      find.byKey(const ValueKey('public-area-Emergency & Safety')),
    );
    await tester.tap(
      find.byKey(const ValueKey('public-area-Emergency & Safety')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('public-area-page-Emergency & Safety')),
      findsOneWidget,
    );
    expect(find.text('Police'), findsOneWidget);
    expect(find.textContaining('verified'), findsWidgets);
  });

  testWidgets('Static reference category hides Public Services by default', (
    tester,
  ) async {
    await pumpModule(
      tester,
      ReferenceServicesLanding(onCategory: (_) {}, onAllServices: () {}),
    );
    expect(
      find.byKey(const ValueKey('reference-category-Public\nServices')),
      findsNothing,
    );
  });
}
