import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_admin/src/dashboard/vendor_intake_queue_page.dart';
import 'package:wantok_admin/src/dashboard/vendor_verification_review_page.dart';
import 'package:wantok_admin/src/dashboard/vendor_evidence_requests_page.dart';

void main() {
  final caseFixture = <Map<String, dynamic>>[
    {
      'id': 'case-scope-only',
      'applicant_kind': 'individual',
      'display_name': 'Synthetic vendor',
      'country_code': 'PG',
      'region': 'Morobe',
      'locality': 'Lae',
      'street_address': 'Synthetic street only',
      'contact_email': 'local@example.test',
      'contact_phone': '+67570000000',
      'applicant_identity_type': 'other',
      'identity_last_four': null,
      'service_metadata': <String, dynamic>{},
      'service_categories': {'name': 'Home Services', 'slug': 'home-services'},
      'service_summary': 'Synthetic plumbing service metadata only',
      'status': 'submitted',
    },
  ];
  testWidgets('Evidence-only officer sees local case without triage buttons', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: VendorIntakeQueuePage(
          canTriage: false,
          canReviewChecks: false,
          canRequestEvidence: true,
          loadCases: () async => caseFixture,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Synthetic vendor'), findsOneWidget);
    expect(find.text('Begin review'), findsNothing);
    expect(find.text('Request information'), findsNothing);
    expect(find.text('Decline'), findsNothing);
    expect(
      find.byKey(const ValueKey('verification-tasks-case-scope-only')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Evidence-only officer cannot see procedural review actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: VendorVerificationReviewPage(
          caseId: 'scoped-case',
          applicantName: 'Synthetic vendor',
          canRecordReviews: false,
          canModifyEvidence: true,
          loadChecks: (_) async => [
            {
              'id': 'check-scope',
              'requirement_label': 'Review valid operating address',
              'requirement_scope': 'baseline',
              'state': 'pending',
            },
          ],
          loadEvents: (_) async => [],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Review valid operating address'), findsOneWidget);
    expect(find.text('Start review'), findsNothing);
    expect(find.text('Needs follow-up'), findsNothing);
    expect(find.text('Record first review'), findsNothing);
    expect(
      find.byKey(const ValueKey('vendor-evidence-register')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Case reviewer sees evidence history without request controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: VendorEvidenceRequestsPage(
          caseId: 'scoped-case',
          applicantName: 'Synthetic vendor',
          canModifyRequests: false,
          loadRequests: () async => (
            <Map<String, dynamic>>[
              {
                'id': 'check-1',
                'requirement_key': 'identity_check',
                'requirement_label': 'Identity review requirements',
              },
            ],
            <Map<String, dynamic>>[
              {
                'id': 'request-1',
                'check_id': 'check-1',
                'requirement_note': 'Synthetic document request, no uploads',
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
    expect(find.text('Identity review requirements'), findsOneWidget);
    expect(find.text('Request evidence (metadata)'), findsNothing);
    expect(find.text('Cancel'), findsNothing);
    expect(
      find.textContaining('Document intake and KYC approval'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
