import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_admin/src/dashboard/operations_sidebar.dart';

void main() {
  testWidgets('Operations menu exposes verification and services', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    int? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 245,
            child: OperationsSidebar(
              selected: 0,
              onSelect: (index) => tapped = index,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Verification & KYC'), findsOneWidget);
    expect(find.text('Services & Categories'), findsOneWidget);
    await tester.ensureVisible(find.text('Verification & KYC'));
    await tester.tap(find.text('Verification & KYC'));
    expect(tapped, 8);
    await tester.ensureVisible(find.text('Services & Categories'));
    await tester.tap(find.text('Services & Categories'));
    expect(tapped, 2);
    expect(tester.takeException(), isNull);
  });
}
