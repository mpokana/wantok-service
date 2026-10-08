import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/home/reference_scene_details.dart';
import 'package:wantok_app/src/home/smoke_data.dart';

void main() {
  Future<void> show(WidgetTester tester, String scene) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ReferenceSceneDetails(scene: scene),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Food listing renders four labelled example restaurants', (
    tester,
  ) async {
    await show(tester, 'foodListing');
    expect(find.text('Sample restaurants'), findsOneWidget);
    expect(find.text('The Waterfront'), findsOneWidget);
    expect(find.text('Trukai Haus'), findsOneWidget);
    expect(find.text('Café Melanesia'), findsOneWidget);
    expect(find.text('The Noodle Place'), findsOneWidget);
    expect(find.byType(SmokeMarker), findsAtLeastNWidgets(5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Taxi tier interaction is local and request stays disabled', (
    tester,
  ) async {
    await show(tester, 'taxi');
    await tester.tap(find.byKey(const ValueKey('sample-vehicle-1')));
    await tester.pumpAndSettle();
    expect(find.text('Comfort'), findsOneWidget);
    expect(find.textContaining('Request Taxi'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Travel example includes route and an inactive search', (
    tester,
  ) async {
    await show(tester, 'travel');
    expect(find.text('Port Moresby (POM)'), findsOneWidget);
    expect(find.text('Brisbane (BNE)'), findsOneWidget);
    expect(find.textContaining('Search Flights'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Account example is explicitly not the signed-in user', (
    tester,
  ) async {
    await show(tester, 'account');
    expect(find.text('Sample account'), findsOneWidget);
    expect(find.text('Not the signed-in user'), findsOneWidget);
    expect(find.text('Wallet & Payments'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
