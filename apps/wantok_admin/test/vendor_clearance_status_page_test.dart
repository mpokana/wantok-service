import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_admin/src/dashboard/vendor_clearance_status_page.dart';

void main() {
  for (final width in [390.0, 900.0, 1440.0]) {
    testWidgets('Clearance monitoring renders at ${width.toInt()}px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: VendorClearanceStatusPage(
            loadStatus: () async => [
              {
                'provider_id': 'sample-provider',
                'display_name': 'Synthetic Vendor',
                'expires_at': '2026-11-22T00:00:00Z',
                'revoked_at': null,
              },
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Clearance & Safety Controls'), findsOneWidget);
      expect(find.text('Synthetic Vendor'), findsOneWidget);
      expect(find.text('Emergency revoke & pause services'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
