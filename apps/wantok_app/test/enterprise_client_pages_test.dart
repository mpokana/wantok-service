import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/home/activity_page.dart';
import 'package:wantok_app/src/home/enterprise_services_catalogue.dart';
import 'package:wantok_app/src/home/explore_page.dart';
import 'package:wantok_app/src/home/messages_page.dart';
import 'package:wantok_app/src/home/responsive_client_canvas.dart';
import 'package:wantok_app/src/home/reference_services_gallery.dart';
import 'package:wantok_app/src/home/wantok_pay_preview_page.dart';

Future<void> showClient(
  WidgetTester tester,
  Widget page,
  double width, {
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width, 980);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(body: ResponsiveClientCanvas(child: page)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('desktop Services cards remain compact within centred canvas', (
    tester,
  ) async {
    await showClient(
      tester,
      EnterpriseServicesCatalogue(onCategory: (_) {}, onAllServices: () {}),
      1800,
    );
    expect(
      find.byKey(const ValueKey('client-responsive-canvas')),
      findsOneWidget,
    );
    final card = find.byKey(
      ValueKey(
        'enterprise-category-${ReferenceServiceCategories.items.first.title}',
      ),
    );
    expect(card, findsWidgets);
    expect(tester.getSize(card.first).width, lessThan(255));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'desktop Explore provides locally bundled inspiration, not offers',
    (tester) async {
      await showClient(tester, const ExplorePage(), 1600);
      expect(
        find.byKey(const ValueKey('explore-inspiration-grid')),
        findsOneWidget,
      );
      expect(find.text('Coast & water'), findsOneWidget);
      expect(find.text('Communities & events'), findsOneWidget);
      expect(find.text('People & skills'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('phone Explore retains scrollable discovery', (tester) async {
    await showClient(tester, const ExplorePage(), 390, scale: 1.2);
    expect(
      find.byKey(const ValueKey('client-responsive-canvas')),
      findsNothing,
    );
    expect(find.text('Explore'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop Track is readable with no invented reservations', (
    tester,
  ) async {
    await showClient(
      tester,
      ActivityPage(
        loadReservations: () async => const <Map<String, dynamic>>[],
      ),
      1560,
    );
    expect(
      find.byKey(const ValueKey('track-enterprise-header')),
      findsOneWidget,
    );
    expect(find.text('No requests or reservations yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop Inbox retains separate service/support counts', (
    tester,
  ) async {
    await showClient(
      tester,
      MessagesPage(
        loadThreads: () async => const <Map<String, dynamic>>[],
        loadSupportRequests: () async => const <Map<String, dynamic>>[],
      ),
      1560,
    );
    expect(
      find.byKey(const ValueKey('inbox-enterprise-header')),
      findsOneWidget,
    );
    expect(find.text('No service conversations yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop Wallet remains K0 preview with disabled payment rails', (
    tester,
  ) async {
    await showClient(tester, const WantokPayPreviewPage(embedded: true), 1600);
    expect(find.text('K0.00'), findsOneWidget);
    expect(find.textContaining('payment rails are not active'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
