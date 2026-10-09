import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/phone_preview/phone_preview_app.dart';
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

  testWidgets('phone preview is visibly offline with no sign-in', (
    tester,
  ) async {
    await showPhone(tester, 390);
    expect(find.byKey(const ValueKey('phone-preview-warning')), findsOneWidget);
    expect(find.textContaining('OFFLINE PREVIEW'), findsOneWidget);
    expect(find.text('Discover local services'), findsOneWidget);
    expect(find.text('Services for everyday life'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Services'), findsWidgets);
    expect(find.text('Explore'), findsWidgets);
    expect(find.text('Track'), findsOneWidget);
    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Explore keeps the approved photo gallery gated', (tester) async {
    await showPhone(tester, 390);
    await tester.tap(find.byIcon(Icons.explore_outlined).first);
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

  testWidgets('Track and Wallet clearly deny live operations at phone width', (
    tester,
  ) async {
    await showPhone(tester, 320);
    await tester.tap(find.byIcon(Icons.route_outlined));
    await tester.pumpAndSettle();
    expect(find.textContaining('approved staging connection'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('No balance, top-up or money movement'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Inbox unavailable in preview'));
    await tester.pump();
    expect(find.textContaining('no live account or service'), findsOneWidget);
    await tester.tap(find.byTooltip('Account and profile'));
    await tester.pumpAndSettle();
    expect(find.text('My Settings'), findsOneWidget);
    expect(find.text('Vendor'), findsOneWidget);
    await tester.tap(find.text('Vendor'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Nothing is active in this offline preview'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('scenic card remains at bottom of Home and opens Explore', (
    tester,
  ) async {
    await showPhone(tester, 390);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('phone-preview-scenic-card')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('phone-preview-explore')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Discover PNG and beyond — places, local experiences and services.',
      ),
      findsOneWidget,
    );
  });
}
