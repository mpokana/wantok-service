import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_app/src/home/activity_page.dart';
import 'package:wantok_app/src/home/client_account_tools.dart';
import 'package:wantok_app/src/home/messages_page.dart';
import 'package:wantok_ui/wantok_ui.dart';

class _RoutePushObserver extends NavigatorObserver {
  int pushes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes++;
    super.didPush(route, previousRoute);
  }
}

void main() {
  Future<void> assertReadOnlyRefreshKeepsCurrentRoute(
    WidgetTester tester, {
    required Widget page,
    required String actionKey,
    required double width,
  }) async {
    tester.view.physicalSize = Size(width, 930);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final observer = _RoutePushObserver();
    await tester.pumpWidget(
      MaterialApp(
        theme: WantokTheme.light(),
        navigatorObservers: [observer],
        home: Scaffold(body: page),
      ),
    );
    await tester.pumpAndSettle();

    final before = observer.pushes;
    final refresh = find.byKey(ValueKey(actionKey));
    expect(refresh, findsOneWidget);
    expect(tester.getSize(refresh).height, greaterThanOrEqualTo(44));

    await tester.tapAt(tester.getCenter(refresh));
    await tester.pumpAndSettle();

    expect(observer.pushes, before,
        reason: 'Refreshing must not push vendor onboarding or any other route');
    expect(refresh, findsOneWidget);
    expect(tester.takeException(), isNull);
  }

  for (final width in [320.0, 1440.0]) {
    testWidgets('CX1 Saved refresh does not navigate at $width px',
        (tester) async {
      var reads = 0;
      await assertReadOnlyRefreshKeepsCurrentRoute(
        tester,
        width: width,
        actionKey: 'cx1-saved-refresh',
        page: SavedItemsPage(
          loadSavedItems: () async {
            reads++;
            return <SavedClientItem>[];
          },
        ),
      );
      expect(reads, 2);
      expect(find.text('Nothing saved yet'), findsOneWidget);
    });

    testWidgets('CX1 Inbox refresh does not navigate at $width px',
        (tester) async {
      var reads = 0;
      await assertReadOnlyRefreshKeepsCurrentRoute(
        tester,
        width: width,
        actionKey: 'cx1-inbox-refresh',
        page: MessagesPage(
          loadThreads: () async {
            reads++;
            return <Map<String, dynamic>>[];
          },
          loadSupportRequests: () async => <Map<String, dynamic>>[],
        ),
      );
      expect(reads, 2);
      expect(find.text('No service conversations yet'), findsOneWidget);
    });

    testWidgets('CX1 Track refresh does not navigate at $width px',
        (tester) async {
      var reads = 0;
      await assertReadOnlyRefreshKeepsCurrentRoute(
        tester,
        width: width,
        actionKey: 'cx1-track-refresh',
        page: ActivityPage(
          loadReservations: () async {
            reads++;
            return <Map<String, dynamic>>[];
          },
        ),
      );
      expect(reads, 2);
      expect(find.text('No requests or reservations yet'), findsOneWidget);
    });
  }
}
