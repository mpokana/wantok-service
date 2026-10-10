import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/phone_preview/phone_preview_app.dart';
import 'package:wantok_app/src/home/client_home.dart';
import 'package:wantok_app/src/home/services_hub_page.dart';
import 'package:wantok_app/src/home/activity_page.dart';
import 'package:wantok_app/src/home/wantok_pay_preview_page.dart';
import 'package:wantok_app/src/home/smoke_data.dart';

void main() {
  Future<void> showPhone(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 870);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const WantokPhonePreviewApp());
    await tester.pumpAndSettle();
  }

  testWidgets(
    'offline HONOR uses the REAL emulator Home and Services widgets',
    (tester) async {
      await showPhone(tester, 390);
      expect(
        find.byKey(const ValueKey('phone-preview-warning')),
        findsOneWidget,
      );
      expect(find.textContaining('OFFLINE DEMONSTRATION'), findsOneWidget);
      expect(find.byType(ClientHome), findsOneWidget);
      expect(find.byType(ServicesHubPage, skipOffstage: false), findsOneWidget);
      expect(find.byType(ActivityPage, skipOffstage: false), findsOneWidget);
      expect(
        find.byType(WantokPayPreviewPage, skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('What do you need today?'), findsOneWidget);
      expect(find.text('Popular categories'), findsOneWidget);
      expect(find.text('Sign in'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Services keeps the original full photo-category entrance', (
    tester,
  ) async {
    await showPhone(tester, 390);
    await tester.tap(find.byIcon(Icons.grid_view_outlined).last);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reference-services-landing')),
      findsOneWidget,
    );
    expect(find.text('Services'), findsWidgets);
    expect(
      find.byKey(const ValueKey('reference-services-search')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('reference-all-services')));
    await tester.pumpAndSettle();
    expect(find.text('Browse services'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Explore preserves the approved twelve photographic samples', (
    tester,
  ) async {
    await showPhone(tester, 390);
    await tester.tap(find.byIcon(Icons.explore_outlined).last);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Discover PNG and beyond — places, local experiences and services.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('explore-reference-samples')),
      WantokSmokeData.enabled ? findsOneWidget : findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Track and Wallet render real surfaces without live operations', (
    tester,
  ) async {
    await showPhone(tester, 360);
    await tester.tap(find.byIcon(Icons.route_outlined).last);
    await tester.pumpAndSettle();
    if (WantokSmokeData.enabled) {
      expect(find.text('Sample booking timeline'), findsOneWidget);
    } else {
      expect(find.text('No requests or reservations yet'), findsOneWidget);
    }
    expect(
      find.textContaining('Demonstration booking timeline'),
      findsOneWidget,
    );
    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined).last);
    await tester.pumpAndSettle();
    expect(find.text('Wantok Wallet preview'), findsOneWidget);
    expect(
      find.textContaining('payment rails are not active yet'),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Inbox and applicant/vendor simulator do not require a backend', (
    tester,
  ) async {
    await showPhone(tester, 390);
    await tester.tap(find.byTooltip('Inbox'));
    await tester.pumpAndSettle();
    expect(find.text('Inbox · SAMPLE'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Account and profile'));
    await tester.pumpAndSettle();
    expect(find.text('My Settings'), findsOneWidget);
    expect(find.text('Vendor'), findsOneWidget);
    await tester.tap(find.text('Vendor'));
    await tester.pumpAndSettle();
    expect(find.text('Approved vendor dashboard · SAMPLE'), findsOneWidget);
    await tester.tap(find.text('Applicant view'));
    await tester.pumpAndSettle();
    expect(find.text('Become a Wantok Vendor'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('full Home scenic footer opens full Explore', (tester) async {
    await showPhone(tester, 390);
    final scenic = find.text('Explore PNG and beyond');
    await tester.dragUntilVisible(
      scenic,
      find.byType(ListView).first,
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    await tester.tap(scenic);
    await tester.pumpAndSettle();
    expect(find.text('Explore'), findsWidgets);
    expect(
      find.text(
        'Discover PNG and beyond — places, local experiences and services.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
