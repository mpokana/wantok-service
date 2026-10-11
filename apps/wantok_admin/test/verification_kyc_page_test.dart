import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_admin/src/dashboard/verification_kyc_page.dart';

void main() {
  const fixture = VerificationKycSnapshot(
    providers: [
      {'display_name': 'Verified provider', 'verification_status': 'verified'},
      {'display_name': 'Pending provider', 'verification_status': 'pending'},
      {'display_name': 'Rejected provider', 'verification_status': 'rejected'},
    ],
    staged: [
      {
        'applicant_name': 'Staged applicant',
        'status': 'submitted',
        'coverage_province': 'Central',
      },
    ],
  );
  for (final width in [390.0, 900.0, 1440.0]) {
    testWidgets('Verification & KYC safely renders at ${width.toInt()}px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 960);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerificationKycPage(loader: () async => fixture),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Verification & KYC'), findsOneWidget);
      expect(find.text('Preliminary onboarding checks'), findsOneWidget);
      expect(find.textContaining('Staged applicant'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
