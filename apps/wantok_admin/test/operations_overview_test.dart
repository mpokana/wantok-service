import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_admin/src/dashboard/operations_overview_page.dart';

void main() {
  const snapshot = OperationsSnapshot(
    pendingApplications: 2,
    pendingListings: 1,
    activeBookings: 3,
    recentAudits: 4,
    applications: [
      {
        'id': 'SMOKE_TEST_1',
        'company_name': 'Test-only provider',
        'service_type': 'specialist-services',
        'status': 'pending',
      },
    ],
    bookings: [
      {
        'id': 'SMOKE_TEST_BOOKING',
        'status': 'completed',
        'service_categories': {'name': 'Specialist Services'},
      },
    ],
    audits: [
      {'id': 'SMOKE_TEST_AUDIT', 'action': 'test_event', 'entity_type': 'test'},
    ],
  );

  for (final width in [390.0, 900.0, 1440.0]) {
    testWidgets(
      'operations overview renders at ${width.toInt()}px without overflow',
      (tester) async {
        tester.view.physicalSize = Size(width, 960);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OperationsOverviewPage(loader: () async => snapshot),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Operations overview'), findsOneWidget);
        expect(find.text('Pending applications'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Provider approvals'),
          330,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Provider approvals'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Payments & wallet'),
          330,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Payments & wallet'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('overview links navigate to existing administration sections', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var openedProviders = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OperationsOverviewPage(
            loader: () async => snapshot,
            onOpenProviders: () => openedProviders = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('operations-metric-Pending applications')),
    );
    expect(openedProviders, isTrue);
    expect(tester.takeException(), isNull);
  });
}
