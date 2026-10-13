import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/home/activity_page.dart';
import 'package:wantok_ui/wantok_ui.dart';

void main() {
  for (final width in [320.0, 390.0, 800.0, 1024.0, 1440.0]) {
    testWidgets('CX1 Track Refresh remains readable at ${width}px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 930);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var reloads = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: WantokTheme.light(),
          home: Scaffold(
            body: ActivityPage(
              loadReservations: () async {
                reloads++;
                return <Map<String, dynamic>>[];
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final findRefresh = find.byKey(const ValueKey('cx1-track-refresh'));
      final hero = find.byKey(const ValueKey('track-enterprise-header'));
      expect(hero, findsOneWidget);
      expect(reloads, 1);
      if (width < 1200) {
        expect(findRefresh, findsNothing);
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 440));
      } else {
        expect(findRefresh, findsOneWidget);
        final button = tester.widget<TextButton>(findRefresh);
        final foreground = button.style!.foregroundColor!.resolve(
          <WidgetState>{},
        );
        final background = button.style!.backgroundColor!.resolve(
          <WidgetState>{},
        );
        expect(foreground, Colors.white);
        expect(background, const Color(0xFF096B4B));
        expect(
          1.05 / (background!.computeLuminance() + 0.05),
          greaterThanOrEqualTo(4.5),
        );
        expect(tester.getSize(findRefresh).height, greaterThanOrEqualTo(44));
        await tester.tapAt(tester.getCenter(findRefresh));
      }
      await tester.pumpAndSettle();
      expect(reloads, 2);
      expect(tester.takeException(), isNull);
    });
  }
}
