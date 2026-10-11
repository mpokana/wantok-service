import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/home/activity_page.dart';
import 'package:wantok_app/src/home/messages_page.dart';
import 'package:wantok_ui/wantok_ui.dart';

void main() {
  Future<void> showScreen(
    WidgetTester tester,
    Widget screen, {
    required double width,
  }) async {
    tester.view.physicalSize = Size(width, 930);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: WantokTheme.light(),
        home: Scaffold(body: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final width in [390.0, 1440.0]) {
    testWidgets('CX1 Inbox toolbar reload is read-only at $width px', (
      tester,
    ) async {
      var threadReads = 0;
      var supportReads = 0;
      await showScreen(
        tester,
        MessagesPage(
          loadThreads: () async {
            threadReads++;
            return <Map<String, dynamic>>[];
          },
          loadSupportRequests: () async {
            supportReads++;
            return <Map<String, dynamic>>[];
          },
        ),
        width: width,
      );
      expect(find.byTooltip('Refresh Inbox'), findsOneWidget);
      expect(find.text('No service conversations yet'), findsOneWidget);
      expect(threadReads, 1);
      expect(supportReads, 1);

      final targetCx1InboxRefresh = find.byKey(
        const ValueKey('cx1-inbox-refresh'),
      );
      expect(targetCx1InboxRefresh, findsOneWidget);
      expect(
        tester.getSize(targetCx1InboxRefresh).height,
        greaterThanOrEqualTo(44),
      );
      await tester.tapAt(tester.getCenter(targetCx1InboxRefresh));
      await tester.pumpAndSettle();
      expect(threadReads, 2);
      expect(supportReads, 2);
      expect(find.text('No service conversations yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CX1 Track toolbar reload is read-only at $width px', (
      tester,
    ) async {
      var reads = 0;
      await showScreen(
        tester,
        ActivityPage(
          loadReservations: () async {
            reads++;
            return <Map<String, dynamic>>[];
          },
        ),
        width: width,
      );
      expect(find.byTooltip('Refresh activity'), findsOneWidget);
      expect(find.text('No requests or reservations yet'), findsOneWidget);
      expect(reads, 1);

      final targetCx1TrackRefresh = find.byKey(
        const ValueKey('cx1-track-refresh'),
      );
      expect(targetCx1TrackRefresh, findsOneWidget);
      expect(
        tester.getSize(targetCx1TrackRefresh).height,
        greaterThanOrEqualTo(44),
      );
      await tester.tapAt(tester.getCenter(targetCx1TrackRefresh));
      await tester.pumpAndSettle();
      expect(reads, 2);
      expect(find.text('No requests or reservations yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'CX1 Inbox reload recovers service read while support stays available',
    (tester) async {
      var attempts = 0;
      await showScreen(
        tester,
        MessagesPage(
          loadThreads: () async {
            attempts++;
            if (attempts == 1) throw StateError('Temporary thread failure');
            return <Map<String, dynamic>>[];
          },
          loadSupportRequests: () async => <Map<String, dynamic>>[],
        ),
        width: 1240,
      );
      expect(find.text('Could not load service conversations'), findsOneWidget);
      final targetCx1InboxRefresh = find.byKey(
        const ValueKey('cx1-inbox-refresh'),
      );
      expect(targetCx1InboxRefresh, findsOneWidget);
      expect(
        tester.getSize(targetCx1InboxRefresh).height,
        greaterThanOrEqualTo(44),
      );
      await tester.tapAt(tester.getCenter(targetCx1InboxRefresh));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(find.text('No service conversations yet'), findsOneWidget);
      expect(find.text('Help & support (0)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('CX1 Track reload recovers failed read without booking writes', (
    tester,
  ) async {
    var attempts = 0;
    await showScreen(
      tester,
      ActivityPage(
        loadReservations: () async {
          attempts++;
          if (attempts == 1) throw StateError('Temporary activity failure');
          return <Map<String, dynamic>>[];
        },
      ),
      width: 1240,
    );
    expect(find.text('Could not load your activity'), findsOneWidget);
    final targetCx1TrackRefresh = find.byKey(
      const ValueKey('cx1-track-refresh'),
    );
    expect(targetCx1TrackRefresh, findsOneWidget);
    expect(
      tester.getSize(targetCx1TrackRefresh).height,
      greaterThanOrEqualTo(44),
    );
    await tester.tapAt(tester.getCenter(targetCx1TrackRefresh));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('No requests or reservations yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
