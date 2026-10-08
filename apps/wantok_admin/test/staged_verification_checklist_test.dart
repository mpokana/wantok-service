import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_admin/src/dashboard/staged_verification_checklist_page.dart';

void main() {
  testWidgets(
    'Admin checklist only records preliminary states after confirmation',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var nextStatus = 'pending';
      var changes = 0;
      Future<List<Map<String, dynamic>>> load(String _) async => [
        {
          'id': 'check-one',
          'requirement_index': 1,
          'requirement_label': 'Trade description and coverage area',
          'review_status': nextStatus,
        },
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: StagedVerificationChecklistPage(
            applicationId: 'app-one',
            applicantName: 'Example Applicant',
            loadChecks: load,
            loadEvidencePlans: (_) async => const [],
            loadAudit: (_) async => nextStatus == 'pending'
                ? []
                : [
                    {
                      'previous_status': 'pending',
                      'next_status': nextStatus,
                      'reviewed_at': '2026-10-08T23:00:00',
                    },
                  ],
            updateCheck: (id, status) async {
              expect(id, 'check-one');
              nextStatus = status;
              changes++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Trade description and coverage area'), findsNWidgets(2));
      expect(find.text('Status: Pending'), findsOneWidget);
      expect(find.textContaining('approve the applicant'), findsNothing);
      expect(find.text('Approve'), findsNothing);

      await tester.tap(find.text('Needs follow-up'));
      await tester.pumpAndSettle();
      expect(find.text('Record status'), findsOneWidget);
      expect(changes, 0);
      await tester.tap(find.text('Record status'));
      await tester.pumpAndSettle();
      expect(changes, 1);
      expect(find.text('Status: Needs follow-up'), findsOneWidget);
      expect(find.text('Pending → Needs follow-up'), findsOneWidget);
      expect(find.text('Approve'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
