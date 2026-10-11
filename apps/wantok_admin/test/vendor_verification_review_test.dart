import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_admin/src/dashboard/vendor_verification_review_page.dart';

void main() {
  final fixture = <Map<String, dynamic>>[
    {
      'id': 'first',
      'requirement_label': 'Identity review and contact',
      'requirement_scope': 'baseline',
      'state': 'pending',
    },
    {
      'id': 'second',
      'requirement_label': 'Business registration review',
      'requirement_scope': 'business',
      'state': 'first_review_recorded',
      'first_reviewer': 'first-officer',
    },
    {
      'id': 'completed',
      'requirement_label': 'Vehicle insurance check',
      'requirement_scope': 'category',
      'state': 'second_review_recorded',
      'first_reviewer': 'first-officer',
      'second_reviewer': 'independent-officer',
    },
  ];
  for (final width in [390.0, 900.0, 1440.0]) {
    testWidgets('Verification tasks render without overflow at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: VendorVerificationReviewPage(
            caseId: 'sample-id',
            applicantName: 'Sample Vendor',
            loadChecks: (_) async => fixture,
            loadEvents: (_) async => const [
              {
                'action': 'started',
                'actor_id': 'staff-1',
                'occurred_at': '2026-10-11T12:00:00',
                'rationale': 'Preliminary stage opened for review',
              },
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Verification Review Tasks'), findsOneWidget);
      expect(find.text('Sample Vendor'), findsOneWidget);
      expect(
        find.textContaining('Evidence intake and final activation'),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('review-second-second')),
      );
      expect(
        find.byKey(const ValueKey('review-second-second')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
