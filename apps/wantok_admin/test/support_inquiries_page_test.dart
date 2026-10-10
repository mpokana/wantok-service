import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_admin/src/dashboard/support_inquiries_page.dart';

const requests = <Map<String, dynamic>>[
  {
    'id': 'request-1',
    'summary': 'QA request, no operational help needed',
    'status': 'open',
    'created_at': '2026-10-10T06:00:00Z',
    'resolution_note': null,
  },
  {
    'id': 'request-2',
    'summary': 'Completed QA support enquiry',
    'status': 'resolved',
    'created_at': '2026-10-09T06:00:00Z',
    'resolution_note': 'Test follow-up completed',
  },
];

Future<void> pump(
  WidgetTester tester, {
  required double width,
  Future<List<Map<String, dynamic>>> Function()? loader,
}) async {
  tester.view.physicalSize = Size(width, 920);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SupportInquiriesPage(
          loadRequests: loader ?? () async => requests,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [390.0, 850.0, 1440.0]) {
    testWidgets('CX1I staff queue readable at ${width.toInt()}px', (
      tester,
    ) async {
      await pump(tester, width: width);
      expect(find.byKey(const ValueKey('cx1-support-queue')), findsOneWidget);
      expect(find.text('Support & Inquiries'), findsOneWidget);
      expect(find.textContaining('2 recent requests'), findsOneWidget);
      expect(find.textContaining('1 open or assigned'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('support-request-request-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('support-request-request-2')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('status filter is read-only and retains backend results', (
    tester,
  ) async {
    var calls = 0;
    await pump(
      tester,
      width: 1440,
      loader: () async {
        calls++;
        return requests;
      },
    );
    expect(calls, 1);
    await tester.tap(find.byKey(const ValueKey('support-status-resolved')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('support-request-request-1')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('support-request-request-2')),
      findsOneWidget,
    );
    expect(
      calls,
      1,
      reason: 'Client-side filter must not mutate or refetch the database',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('all status chips filter existing requests locally', (
    tester,
  ) async {
    var reads = 0;
    await pump(
      tester,
      width: 1440,
      loader: () async {
        reads++;
        return requests;
      },
    );
    for (final status in ['open', 'assigned', 'resolved', 'closed', 'all']) {
      await tester.tap(find.byKey(ValueKey('support-status-$status')));
      await tester.pumpAndSettle();
      final showOpen = status == 'open' || status == 'all';
      final showResolved = status == 'resolved' || status == 'all';
      expect(
        find.byKey(const ValueKey('support-request-request-1')),
        showOpen ? findsOneWidget : findsNothing,
      );
      expect(
        find.byKey(const ValueKey('support-request-request-2')),
        showResolved ? findsOneWidget : findsNothing,
      );
      if (status == 'assigned' || status == 'closed') {
        expect(find.text('No requests match this filter.'), findsOneWidget);
      }
    }
    expect(reads, 1, reason: 'Filtering must not issue additional DB reads');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Refresh reloads the queue without changing request status', (
    tester,
  ) async {
    var reads = 0;
    await pump(
      tester,
      width: 1440,
      loader: () async {
        reads++;
        return reads == 1 ? requests : [requests.first];
      },
    );
    expect(reads, 1);
    expect(find.textContaining('2 recent requests'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Refresh'));
    await tester.pumpAndSettle();
    expect(reads, 2);
    expect(find.textContaining('1 recent request'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('support-request-request-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('support-request-request-2')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Retry recovers safely after a failed support load', (
    tester,
  ) async {
    var reads = 0;
    await pump(
      tester,
      width: 390,
      loader: () async {
        reads++;
        if (reads == 1) throw StateError('Disconnected');
        return [requests.first];
      },
    );
    expect(find.text('Could not load support requests'), findsOneWidget);
    await tester.tap(find.byTooltip('Retry support queue'));
    await tester.pumpAndSettle();
    expect(reads, 2);
    expect(
      find.byKey(const ValueKey('support-request-request-1')),
      findsOneWidget,
    );
    expect(find.text('Could not load support requests'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('support load failure displays retryable safe error', (
    tester,
  ) async {
    await pump(
      tester,
      width: 390,
      loader: () async => throw StateError('Disconnected'),
    );
    expect(find.text('Could not load support requests'), findsOneWidget);
    expect(find.byTooltip('Retry support queue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
