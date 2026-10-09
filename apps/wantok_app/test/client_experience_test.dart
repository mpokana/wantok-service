import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_core/wantok_core.dart';
import 'package:wantok_ui/wantok_ui.dart';
import 'package:wantok_app/src/home/client_home.dart';
import 'package:wantok_app/src/home/home_shell.dart';
import 'package:wantok_app/src/home/services_hub_page.dart';
import 'package:wantok_app/src/home/wantok_pay_preview_page.dart';

const services = [
  WantokServiceCategory(
    id: '1',
    slug: 'food',
    name: 'Food',
    vertical: 'commerce',
    bookingMode: 'commerce',
  ),
  WantokServiceCategory(
    id: '2',
    slug: 'groceries',
    name: 'Groceries',
    vertical: 'commerce',
    bookingMode: 'commerce',
  ),
  WantokServiceCategory(
    id: '3',
    slug: 'taxi-ride',
    name: 'Taxi',
    vertical: 'mobility',
    bookingMode: 'on_demand',
  ),
  WantokServiceCategory(
    id: '4',
    slug: 'specialist-services',
    name: 'Specialists',
    vertical: 'marketplace',
    bookingMode: 'quote',
  ),
];

const recommendations = [
  ClientServiceRecommendation(
    categoryId: '1',
    categorySlug: 'food',
    categoryName: 'Food',
    reason: 'Saved by you',
    score: 60,
    distanceKm: 1.2,
  ),
];

const places = [
  ClientServicePlace(
    province: 'Morobe Province',
    town: 'Lae',
    categoryIds: ['1', '3'],
    categoryNames: ['Food', 'Taxi'],
    listingCount: 3,
    eventCount: 0,
    routeCount: 1,
  ),
];

Future<void> showPage(
  WidgetTester tester,
  Widget page, {
  double width = 390,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: WantokTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(body: page),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Home search and Agent perform their service actions', (
    tester,
  ) async {
    var searches = 0;
    var agentOpens = 0;
    await showPage(
      tester,
      ClientHome(
        loadServices: () async => [],
        onServicesTap: () => searches++,
        onAgentTap: () => agentOpens++,
      ),
    );
    await tester.tap(find.text('Search services, goods or providers'));
    await tester.tap(find.byTooltip('Ask Wantok'));
    expect(searches, 1);
    expect(agentOpens, 1);
    expect(find.text('Popular categories'), findsOneWidget);
    expect(find.text('Wantok Pay'), findsNothing);
    expect(find.text('Wantok AI Agent'), findsNothing);
    expect(
      find.text('No services available yet. Please check back soon.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('service family and search combine, clear restores catalogue', (
    tester,
  ) async {
    await showPage(tester, ServicesHubPage(loadServices: () async => services));
    expect(find.text('Move & travel'), findsOneWidget);
    expect(find.text('Food & shopping'), findsOneWidget);
    expect(find.text('People & skills'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Eat & shop'));
    await tester.pumpAndSettle();
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Taxi'), findsNothing);
    await tester.enterText(find.byType(TextField), 'taxi');
    await tester.pumpAndSettle();
    expect(find.text('No service matched'), findsOneWidget);
    await tester.ensureVisible(find.text('Clear filters'));
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('Taxi'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('See all opens the grouped Wantok service catalogue', (
    tester,
  ) async {
    await showPage(
      tester,
      ServicesHubPage(
        loadServices: () async => services,
        showMarketplaceLandingWhenInjected: true,
      ),
    );

    expect(find.text('Popular categories'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('See all').first);
    await tester.tap(find.text('See all').first);
    await tester.pumpAndSettle();

    expect(find.text('All Wantok Services'), findsOneWidget);
    expect(find.text('Move & travel'), findsWidgets);
    expect(find.text('Food & shopping'), findsWidgets);
    expect(find.text('People & skills'), findsWidgets);
    expect(find.text('Taxi'), findsWidgets);
    expect(find.text('Food'), findsWidgets);
    expect(find.text('Groceries'), findsWidgets);
    expect(find.text('Specialists'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'recommendations use injected real-signal results and hide while filtering',
    (tester) async {
      await showPage(
        tester,
        ServicesHubPage(
          loadServices: () async => services,
          loadRecommendations: () async => recommendations,
        ),
      );

      expect(find.text('Recommended for you'), findsOneWidget);
      expect(find.text('Saved by you'), findsOneWidget);
      expect(find.text('1.2 km away'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'taxi');
      await tester.pumpAndSettle();
      expect(find.text('Recommended for you'), findsNothing);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('Recommended for you'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Explore PNG uses covered places and opens available service types',
    (tester) async {
      await showPage(
        tester,
        ServicesHubPage(
          loadServices: () async => services,
          loadPlaces: () async => places,
        ),
      );

      expect(find.text('Explore PNG'), findsOneWidget);
      expect(find.text('Lae'), findsOneWidget);
      expect(find.text('Morobe Province'), findsOneWidget);

      await tester.tap(find.text('Lae'));
      await tester.pumpAndSettle();

      expect(find.text('Lae, Morobe Province'), findsOneWidget);
      expect(
        find.text('4 active coverage points across 2 service types.'),
        findsOneWidget,
      );
      expect(find.text('Food'), findsWidgets);
      expect(find.text('Taxi'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('catalogue failure has a safe error and working retry', (
    tester,
  ) async {
    var loads = 0;
    await showPage(
      tester,
      ServicesHubPage(
        loadServices: () async {
          if (++loads < 3) throw StateError('internal database detail');
          return services;
        },
      ),
    );
    expect(find.text('Could not load services'), findsOneWidget);
    expect(find.textContaining('internal database detail'), findsNothing);
    await tester.ensureVisible(find.text('Retry'));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Could not load services'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Food'), findsOneWidget);
    expect(loads, 3);
  });

  testWidgets('empty catalogue differs from unmatched search', (tester) async {
    await showPage(tester, ServicesHubPage(loadServices: () async => []));
    expect(find.text('No services available yet'), findsOneWidget);
    expect(find.text('No service matched'), findsNothing);
  });

  testWidgets('Services shows loading before a delayed catalogue resolves', (
    tester,
  ) async {
    final completer = Completer<List<WantokServiceCategory>>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ServicesHubPage(loadServices: () => completer.future),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.complete(services);
    await tester.pumpAndSettle();
    expect(find.text('Food'), findsOneWidget);
  });

  testWidgets(
    'five bottom tabs including Explore and header Inbox keep account navigation',
    (tester) async {
      await showPage(tester, const HomeShell(roles: {'customer'}, email: null));
      for (final tab in ['Home', 'Services', 'Explore', 'Track', 'Wallet']) {
        final navigation = find.byKey(ValueKey('wantok-nav-$tab'));
        expect(navigation, findsOneWidget);
        await tester.tap(navigation);
        await tester.pumpAndSettle();
        expect(
          tester.widget<Semantics>(navigation).properties.selected,
          isTrue,
        );
        expect(
          tester.widget<Semantics>(navigation).properties.onTap,
          isNotNull,
        );
        expect(tester.takeException(), isNull);
      }
      expect(find.byKey(const ValueKey('wantok-nav-Inbox')), findsNothing);
      await tester.tap(find.byTooltip('Inbox'));
      await tester.pumpAndSettle();
      expect(find.text('Inbox'), findsWidgets);
      expect(find.byKey(const ValueKey('wantok-nav-Wallet')), findsOneWidget);
      expect(find.byKey(const ValueKey('wantok-nav-Track')), findsOneWidget);
      expect(find.byKey(const ValueKey('wantok-nav-Explore')), findsOneWidget);
      expect(find.text('Technical access'), findsNothing);
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Account and profile'));
      await tester.pumpAndSettle();
      expect(find.text('Account and profile'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    },
  );

  testWidgets('Home scenic Explore card opens the new destination', (
    tester,
  ) async {
    var exploreOpens = 0;
    await showPage(
      tester,
      ClientHome(
        loadServices: () async => services,
        onExploreTap: () => exploreOpens++,
      ),
    );
    final card = find.text('Explore PNG and beyond');
    await tester.dragUntilVisible(
      card,
      find.byType(ListView).first,
      const Offset(0, -450),
    );
    await tester.pumpAndSettle();
    await tester.tap(card);
    expect(exploreOpens, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Wantok Agent is a compact discovery action', (tester) async {
    await showPage(tester, const HomeShell(roles: {'customer'}, email: null));
    expect(find.byTooltip('Ask Wantok'), findsOneWidget);
    expect(find.text('Wantok AI Agent'), findsNothing);

    await tester.tap(find.byTooltip('Ask Wantok'));
    await tester.pumpAndSettle();
    expect(find.text('Wantok Agent'), findsOneWidget);
    expect(find.text('Your Wantok guide'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('wantok-nav-Home')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Client/Vendor switch remains inside Account and grants no access',
    (tester) async {
      await showPage(tester, const HomeShell(roles: {'customer'}, email: null));

      await tester.tap(find.byTooltip('Account and profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Switch Client/Vendor mode'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vendor mode').last);
      await tester.pumpAndSettle();

      expect(find.text('Become a Wantok Vendor'), findsOneWidget);
      expect(find.text('Taxi Driver Console'), findsNothing);
      expect(find.text('Technical access'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Account and profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Switch Client/Vendor mode'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Client mode').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('wantok-nav-Home')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 390.0, 800.0]) {
    testWidgets('discovery fits width $width with enlarged text', (
      tester,
    ) async {
      await showPage(
        tester,
        ServicesHubPage(loadServices: () async => services),
        width: width,
        scale: 1.5,
      );
      expect(tester.takeException(), isNull);
      await showPage(
        tester,
        ClientHome(loadServices: () async => services, onAccountTap: () {}),
        width: width,
        scale: 1.5,
      );
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView).first, const Offset(0, -1200));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await showPage(
        tester,
        const HomeShell(roles: {'customer'}, email: null),
        width: width,
        scale: 1.5,
      );
      for (final tab in ['Home', 'Services', 'Explore', 'Track', 'Wallet']) {
        await tester.tap(find.byKey(ValueKey('wantok-nav-$tab')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('Wallet is Kina preview with no enabled transaction buttons', (
    tester,
  ) async {
    await showPage(
      tester,
      const WantokPayPreviewPage(embedded: true),
      width: 320,
    );
    expect(find.text('K0.00'), findsOneWidget);
    expect(
      find.text('Preview only - payment rails are not active yet.'),
      findsOneWidget,
    );
    await tester.dragUntilVisible(
      find.text('Google Pay'),
      find.byType(ListView).first,
      const Offset(0, -320),
    );
    await tester.pumpAndSettle();
    expect(find.text('Visa'), findsOneWidget);
    expect(find.text('Mastercard'), findsOneWidget);
    expect(find.text('Google Pay'), findsOneWidget);
    expect(find.text('PayPal'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
