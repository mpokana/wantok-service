import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_core/wantok_core.dart';
import 'package:wantok_ui/wantok_ui.dart';
import 'package:wantok_app/src/home/activity_page.dart';
import 'package:wantok_app/src/home/client_home.dart';
import 'package:wantok_app/src/home/services_hub_page.dart';
import 'package:wantok_app/src/services/commerce_browse_page.dart';
import 'package:wantok_app/src/services/commerce_orders_page.dart';
import 'package:wantok_app/src/services/event_browse_page.dart';
import 'package:wantok_app/src/services/event_registrations_page.dart';
import 'package:wantok_app/src/services/open_request_page.dart';
import 'package:wantok_app/src/services/reservation_browse_page.dart';
import 'package:wantok_app/src/services/water_transport_page.dart';
import 'package:wantok_app/src/services/water_trip_bookings_page.dart';

Future<void> showPage(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(430, 1000);
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
  final destinations = <String, Type>{
    'vehicle-hire': ReservationBrowsePage,
    'boat-hire': ReservationBrowsePage,
    'venue-booking': ReservationBrowsePage,
    'boat-ship-rides': WaterTransportPage,
    'events': EventBrowsePage,
    'food': CommerceBrowsePage,
    'groceries': CommerceBrowsePage,
    'delivery': OpenRequestPage,
    'errands': OpenRequestPage,
    'specialist-services': OpenRequestPage,
    'general-labour': OpenRequestPage,
  };
  for (final entry in destinations.entries) {
    testWidgets('Services opens ${entry.key} and returns to discovery', (
      tester,
    ) async {
      final category = WantokServiceCategory(
        id: entry.key,
        slug: entry.key,
        name: 'Selected service',
        vertical: 'test',
        bookingMode: 'test',
      );
      await showPage(
        tester,
        ServicesHubPage(loadServices: () async => [category]),
      );
      final tile = find.byKey(ValueKey('catalogue-category-${entry.key}'));
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(find.byType(entry.value), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(ServicesHubPage), findsOneWidget);
    });
  }

  testWidgets('Home food entry uses the commerce journey and returns', (
    tester,
  ) async {
    const category = WantokServiceCategory(
      id: 'food',
      slug: 'food',
      name: 'Food',
      vertical: 'commerce',
      bookingMode: 'commerce',
    );
    await showPage(tester, ClientHome(loadServices: () async => [category]));
    final foodTile = find.byKey(const ValueKey('home-category-food'));
    await tester.ensureVisible(foodTile);
    await tester.tap(foodTile);
    await tester.pumpAndSettle();
    expect(find.byType(CommerceBrowsePage), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(ClientHome), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final (page, title, emptyTitle) in <(Widget, String, String)>[
    (
      const EventBrowsePage(),
      'Could not load events',
      'No upcoming events yet',
    ),
    (
      const WaterTransportPage(),
      'Could not load departures',
      'No scheduled departures available',
    ),
    (
      const CommerceOrdersPage(),
      'Could not load your orders',
      'No commerce orders yet',
    ),
    (
      const EventRegistrationsPage(),
      'Could not load your event registrations',
      'No event registrations yet',
    ),
    (
      const WaterTripBookingsPage(),
      'Could not load your water trips',
      'No water-trip bookings yet',
    ),
  ]) {
    testWidgets('$title remains retryable and is not an empty state', (
      tester,
    ) async {
      await showPage(tester, page);
      expect(find.text(title), findsOneWidget);
      expect(find.text(emptyTitle), findsNothing);
      for (var attempt = 0; attempt < 2; attempt++) {
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        expect(find.text(title), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  }

  for (final (label, destination) in <(String, Type)>[
    ('Food & shop orders', CommerceOrdersPage),
    ('Event registrations', EventRegistrationsPage),
    ('Water trips', WaterTripBookingsPage),
  ]) {
    testWidgets('Track opens $label even when requests cannot load', (
      tester,
    ) async {
      await showPage(tester, const ActivityPage());
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.byType(destination), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(ActivityPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
