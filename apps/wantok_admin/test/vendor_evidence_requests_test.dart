import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_admin/src/dashboard/vendor_evidence_requests_page.dart';

void main() {
  for (final width in [390.0, 900.0, 1440.0]) {
    testWidgets('Evidence request register fits ${width.toInt()}px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: VendorEvidenceRequestsPage(
            caseId: 'sample-case',
            applicantName: 'Example Vendor',
            loadRequests: () async => (
              <Map<String, dynamic>>[
                {
                  'id': 'check1',
                  'requirement_label': 'Verify licence validity',
                  'requirement_key': 'driver_licence',
                },
              ],
              <Map<String, dynamic>>[
                {
                  'id': 'req1',
                  'requirement_note': 'Please provide a valid driving licence',
                  'status': 'requested',
                  'requested_at': '2026-10-11',
                  'expires_at': '2026-10-25',
                },
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Evidence Requirements'), findsOneWidget);
      expect(find.text('Example Vendor'), findsOneWidget);
      expect(
        find.textContaining('Document intake and KYC approval'),
        findsOneWidget,
      );
      expect(find.text('Request evidence (metadata)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
