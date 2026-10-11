import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/vendor/vendor_evidence_inbox_page.dart';

void main() {
  for (final width in [390.0, 900.0]) {
    testWidgets('Applicant evidence inbox safely fits ${width.toInt()}px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: VendorEvidenceInboxPage(
            checkReadiness: (_) async => {
              'request_id': 'test',
              'status': 'requested',
              'upload_allowed': false,
              'reviewer_access_allowed': false,
              'identity_verified': false,
            },
            loadRequests: () async => [
              {
                'id': 'test',
                'case_id': 'case1',
                'requirement_note': 'Driving licence requirement',
                'status': 'requested',
                'expires_at': '2099-01-01T00:00:00Z',
              },
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('My evidence requirements'), findsOneWidget);
      expect(find.text('Driving licence requirement'), findsOneWidget);
      expect(find.textContaining('No document upload'), findsOneWidget);
      expect(find.text('Acknowledge receipt'), findsOneWidget);
      expect(find.text('Check secure upload status'), findsOneWidget);
      await tester.tap(find.text('Check secure upload status'));
      await tester.pumpAndSettle();
      expect(find.text('Secure upload is not yet available'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
