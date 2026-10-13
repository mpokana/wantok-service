import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/home/activity_page.dart';
import 'package:wantok_ui/wantok_ui.dart';

void main() {
  for (final width in [320.0, 390.0, 1440.0]) {
    testWidgets('CX1 Track Refresh remains readable at ${width}px', (tester) async {
      tester.view.physicalSize = Size(width, 930);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var reloads = 0;
      await tester.pumpWidget(MaterialApp(
        theme: WantokTheme.light(),
        home: Scaffold(
          body: ActivityPage(
            loadReservations: () async {
              reloads++;
              return <Map<String, dynamic>>[];
            },
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final findRefresh = find.byKey(const ValueKey('cx1-track-refresh'));
      expect(findRefresh, findsOneWidget);
      final button = tester.widget<TextButton>(findRefresh);
      final foreground = button.style!.foregroundColor!.resolve(<WidgetState>{});
      final background = button.style!.backgroundColor!.resolve(<WidgetState>{});
      expect(foreground, Colors.white);
      expect(background, const Color(0xFF096B4B));
      final contrastRatio = (1.05) / (background!.computeLuminance() + 0.05);
      expect(contrastRatio, greaterThanOrEqualTo(4.5));
      expect(tester.getSize(findRefresh).height, greaterThanOrEqualTo(44));

      final hero = find.byKey(const ValueKey('track-enterprise-header'));
      expect(hero, findsOneWidget);
      if (width < 600) {
        // The mobile refresh action must never cover the green hero title.
        expect(
          tester.getTopLeft(findRefresh).dy,
          greaterThanOrEqualTo(tester.getBottomLeft(hero).dy),
          reason: 'Refresh must appear below the Track header on phones.',
        );
        expect(
          tester.getTopRight(findRefresh).dx,
          lessThanOrEqualTo(width),
          reason: 'Refresh must stay inside the phone viewport.',
        );
      }

      expect(reloads, 1);
      await tester.tapAt(tester.getCenter(findRefresh));
      await tester.pumpAndSettle();
      expect(reloads, 2);
      expect(tester.takeException(), isNull);
    });
  }
}
