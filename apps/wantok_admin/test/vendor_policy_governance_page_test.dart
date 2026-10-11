import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_admin/src/dashboard/vendor_policy_governance_page.dart';

void main() {
  final fixture = <Map<String, dynamic>>[
    {
      'id': 'new-policy',
      'country_code': 'PG',
      'region_code': 'PG-MPL',
      'category_scope': 'transport',
      'revision': 1,
      'notice_title': 'Internal transport onboarding proposal',
      'notice_body': 'A proposed policy notice for internal staff review only.',
      'collection_purpose': 'To evaluate proposed document requirements.',
      'legal_basis_notes': 'External legal evaluation is not yet available.',
      'retention_days': 180,
      'evidence_requirements': ['Driver licence', 'Vehicle registration'],
      'created_by': 'another-staff',
      'state': 'submitted',
    },
    {
      'id': 'older-policy',
      'country_code': 'PG',
      'region_code': null,
      'category_scope': 'trades',
      'revision': 1,
      'notice_title': 'Internal trade provider privacy proposal',
      'notice_body': 'A prior text requiring corrections before publication.',
      'collection_purpose': 'Review business identity and insurance.',
      'legal_basis_notes': 'Still awaiting lawyer approval and validation.',
      'retention_days': 90,
      'evidence_requirements': ['Proof of address'],
      'created_by': 'test-officer',
      'state': 'revision_requested',
      'reviewer_notes': 'Explain data minimization',
    },
  ];
  for (final width in [390.0, 900.0, 1440.0]) {
    testWidgets('Governance draft queue fits ${width.toInt()}px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: VendorPolicyGovernancePage(
            loadPolicies: () async => fixture,
            loadMyDuties: () async => [
              {
                'duty': 'policy_author',
                'country_code': 'PG',
                'region_code': null,
                'category_scope': 'trades',
              },
              {
                'duty': 'policy_reviewer',
                'country_code': 'PG',
                'region_code': 'PG-MPL',
                'category_scope': 'transport',
              },
            ],
            userIdOverride: 'test-officer',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Compliance Policy Proposals'), findsOneWidget);
      expect(
        find.textContaining('Country-specific policy drafts'),
        findsOneWidget,
      );
      expect(find.textContaining('Not a legal approval'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('policy-revise-older-policy')),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      expect(
        find.byKey(const ValueKey('policy-revise-older-policy')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('policy-review-new-policy')),
        -180,
        scrollable: find.byType(Scrollable).last,
      );
      expect(
        find.byKey(const ValueKey('policy-review-new-policy')),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Preview proposal').first);
      await tester.tap(find.text('Preview proposal').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('UNPUBLISHED'), findsWidgets);
      expect(find.textContaining('Legal basis proposed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Scoped staff without duties cannot author or review',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: VendorPolicyGovernancePage(
        loadPolicies: () async => fixture,
        loadMyDuties: () async => [],
        userIdOverride: 'test-officer',
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Read-only jurisdiction access'), findsOneWidget);
    expect(find.byKey(const ValueKey('policy-preview-button')), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Preview proposal').last,
      150,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byKey(const ValueKey('policy-review-new-policy')), findsNothing);
    expect(find.byKey(const ValueKey('policy-revise-older-policy')), findsNothing);
    expect(find.text('Preview proposal'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
