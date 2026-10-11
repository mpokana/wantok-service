import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/vendor/vendor_enterprise_application_page.dart';

void main() {
  final categories = <Map<String, dynamic>>[
    {'id': '1', 'name': 'Taxi / Transport', 'slug': 'taxi-ride'},
    {'id': '2', 'name': 'Food', 'slug': 'food'},
    {'id': '3', 'name': 'Home Services', 'slug': 'home-services'},
  ];
  for (final width in [390.0, 900.0]) {
    testWidgets('Vendor application has responsive entry steps at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: VendorEnterpriseApplicationPage(
            loadCategories: () async => categories,
            submitForReview: (payload) async => 'case-one',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Applicant & category'), findsOneWidget);
      expect(find.byKey(const ValueKey('vendor-kind')), findsOneWidget);
      expect(find.byKey(const ValueKey('vendor-category')), findsOneWidget);
      expect(find.text('Become a Wantok vendor'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
