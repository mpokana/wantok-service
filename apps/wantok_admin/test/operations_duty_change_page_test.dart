import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_admin/src/dashboard/operations_duty_change_page.dart';

void main() {
  final request = <String, dynamic>{
    'id': 'request-1',
    'action': 'grant',
    'staff_user_id': 'subject-uuid',
    'duty': 'case_reviewer',
    'country_code': 'PG',
    'region_code': 'PG-MPL',
    'category_scope': 'trades',
    'status': 'pending',
    'proposed_by': 'requester-user',
    'proposed_reason': 'Verified bounded Morobe trade staff assignment',
  };
  Map<String, dynamic> authority(String role) => {
    'authority': role,
    'country_code': 'PG',
    'issued_at': '2026-01-01T00:00:00Z',
    'revoked_at': null,
  };

  for (final width in [390.0, 900.0, 1440.0]) {
    testWidgets('Staff without provisioning authority is read-only at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1250);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: OperationsDutyChangePage(
            currentUserIdOverride: 'plain-employee',
            loadData: () async =>
                (<Map<String, dynamic>>[], <Map<String, dynamic>>[request]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Staff Duty Authorisation'), findsOneWidget);
      expect(
        find.text('No current duty-provisioning authority'),
        findsOneWidget,
      );
      expect(find.text('Request change · PG'), findsNothing);
      expect(find.text('Approve independently'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Requester cannot approve their own pending assignment', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: OperationsDutyChangePage(
          currentUserIdOverride: 'requester-user',
          loadData: () async => (
            <Map<String, dynamic>>[
              authority('requester'),
              authority('approver'),
            ],
            <Map<String, dynamic>>[request],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Request change · PG'), findsOneWidget);
    expect(find.text('Approve independently'), findsNothing);
    await tester.tap(find.text('Request change · PG'));
    await tester.pumpAndSettle();
    expect(find.text('Request staff duty change'), findsOneWidget);
    expect(find.text('Submit for independent review'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Independent approver requires a reason and confirmation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var decisions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: OperationsDutyChangePage(
          currentUserIdOverride: 'independent-approver',
          loadData: () async => (
            <Map<String, dynamic>>[authority('approver')],
            <Map<String, dynamic>>[request],
          ),
          decideChange: (id, accepted, reason) async {
            expect(id, 'request-1');
            expect(accepted, isTrue);
            expect(reason.length, greaterThanOrEqualTo(30));
            decisions++;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Approve independently'), findsOneWidget);
    await tester.tap(find.text('Approve independently'));
    await tester.pumpAndSettle();
    expect(decisions, 0);
    expect(find.text('Independently approve change?'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Independent decision rationale'),
      'Independent review confirms this is a bounded staff permission.',
    );
    await tester.tap(find.text('Confirm approval'));
    await tester.pumpAndSettle();
    expect(decisions, 1);
    expect(tester.takeException(), isNull);
  });
}
