import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_admin/src/dashboard/staged_evidence_planning_section.dart';

void main() {
  testWidgets('Evidence planning never offers uploads or provider approval', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? plannedState;
    var changes = 0;
    Future<List<Map<String, dynamic>>> load(String id) async {
      expect(id, 'application-one');
      if (plannedState == null) return [];
      return [
        {
          'check_id': 'check-one',
          'state': plannedState,
          'planned_at': '2026-10-09T01:00:00',
        },
      ];
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              StagedEvidencePlanningSection(
                applicationId: 'application-one',
                checks: const [
                  {
                    'id': 'check-one',
                    'requirement_label': 'Business identity review pending',
                  },
                ],
                loadPlans: load,
                planCheck: (id) async {
                  expect(id, 'check-one');
                  plannedState = 'planned';
                  changes++;
                },
                cancelPlan: (id) async {
                  expect(id, 'check-one');
                  plannedState = 'cancelled';
                  changes++;
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('secure document upload is disabled'),
      findsOneWidget,
    );
    expect(find.text('Plan future evidence'), findsOneWidget);
    expect(find.text('Upload'), findsNothing);
    expect(find.text('Approve'), findsNothing);
    await tester.tap(find.text('Plan future evidence'));
    await tester.pumpAndSettle();
    expect(changes, 0);
    expect(find.text('Confirm planning'), findsOneWidget);
    await tester.tap(find.text('Confirm planning'));
    await tester.pumpAndSettle();
    expect(changes, 1);
    expect(find.text('Planning recorded — upload unavailable'), findsOneWidget);
    await tester.tap(find.text('Cancel planning'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm planning'));
    await tester.pumpAndSettle();
    expect(changes, 2);
    expect(find.text('Planning cancelled'), findsOneWidget);
    expect(find.text('Plan future evidence'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
