import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/home/client_refresh_policy.dart';
import 'package:wantok_app/src/vendor/vendor_evidence_inbox_page.dart';

void main() {
  for (final width in [320.0, 390.0, 800.0, 1024.0, 1199.0, 1200.0, 1440.0]) {
    testWidgets('Adaptive refresh desktop threshold at $width px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 980);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Text(
              ClientRefreshPolicy.showDesktopButton(context)
                  ? 'desktop'
                  : 'pull',
            ),
          ),
        ),
      );
      expect(find.text(width >= 1200 ? 'desktop' : 'pull'), findsOneWidget);
    });
  }

  for (final width in [320.0, 800.0, 1024.0, 1440.0]) {
    testWidgets(
      'Vendor evidence metadata pull remains read-only at $width px',
      (tester) async {
        tester.view.physicalSize = Size(width, 990);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var metadataReads = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: VendorEvidenceInboxPage(
              loadRequests: () async {
                metadataReads++;
                return <Map<String, dynamic>>[];
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(metadataReads, 1);
        expect(find.text('No evidence requests'), findsOneWidget);
        final refresh = find.byTooltip('Refresh requests');
        if (width < 1200) {
          expect(refresh, findsNothing);
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, 450),
          );
        } else {
          expect(refresh, findsOneWidget);
          await tester.tap(refresh);
        }
        await tester.pumpAndSettle();
        expect(metadataReads, 2);
        expect(find.text('No evidence requests'), findsOneWidget);
        expect(find.textContaining('No document upload'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
