import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/home/messages_page.dart';

void main() {
  Future<List<Map<String, dynamic>>> serviceThreads() async => [
    <String, dynamic>{
      'thread_id': 'thread-1',
      'other_display_name': 'Wantok QA Plumbing Services',
      'category_name': 'Specialist Services',
      'booking_status': 'completed',
      'last_message': 'Thanks for using Wantok.',
      'unread_count': 1,
    },
  ];

  Future<List<Map<String, dynamic>>> supportRequests() async => [
    <String, dynamic>{
      'id': 'support-1',
      'summary': 'Need human follow-up for a service search.',
      'status': 'open',
      'created_at': '2026-10-07T08:58:47+10:00',
      'resolution_note': null,
    },
  ];

  Future<void> showInbox(
    WidgetTester tester, {
    Future<List<Map<String, dynamic>>> Function()? loadThreads,
    Future<List<Map<String, dynamic>>> Function()? loadSupport,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessagesPage(
            loadThreads: loadThreads ?? serviceThreads,
            loadSupportRequests: loadSupport ?? supportRequests,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('separates service conversations from owner support requests', (
    tester,
  ) async {
    await showInbox(tester);

    expect(find.text('Services (1)'), findsOneWidget);
    expect(find.text('Help & support (1)'), findsOneWidget);
    expect(find.text('Wantok QA Plumbing Services'), findsOneWidget);
    expect(
      find.text('Need human follow-up for a service search.'),
      findsNothing,
    );

    await tester.tap(find.text('Help & support (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Wantok help request'), findsOneWidget);
    expect(
      find.text('Need human follow-up for a service search.'),
      findsOneWidget,
    );
    expect(find.text('OPEN'), findsOneWidget);
  });

  testWidgets('support remains available when service conversations fail', (
    tester,
  ) async {
    await showInbox(
      tester,
      loadThreads: () async =>
          throw StateError('service messaging unavailable'),
    );

    expect(find.text('Could not load service conversations'), findsOneWidget);
    expect(find.text('Help & support (1)'), findsOneWidget);

    await tester.tap(find.text('Help & support (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Wantok help request'), findsOneWidget);
    expect(find.text('OPEN'), findsOneWidget);
    expect(find.text('Could not load service conversations'), findsNothing);
  });
}
