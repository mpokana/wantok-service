import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_app/src/home/client_account_tools.dart';
import 'package:wantok_ui/wantok_ui.dart';

Future<void> _show(
  WidgetTester tester,
  Future<List<SavedClientItem>> Function() loader, {
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 940);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: WantokTheme.light(),
      home: SavedItemsPage(loadSavedItems: loader),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  SavedClientItem provider() => const SavedClientItem(
    itemType: 'provider',
    entityId: 'cx1-qa-provider-readonly',
    title: 'Wantok QA Plumbing Services',
    subtitle: 'Specialist Services - Lae',
    imageUrl: null,
    createdAt: null,
  );

  for (final width in [390.0, 1240.0]) {
    testWidgets(
      'CX1 Saved shows previously saved provider read-only at $width',
      (tester) async {
        var reads = 0;
        await _show(tester, () async {
          reads++;
          return [provider()];
        }, width: width);
        expect(reads, 1);
        expect(find.text('Saved'), findsOneWidget);
        expect(find.text('Wantok QA Plumbing Services'), findsOneWidget);
        expect(find.byTooltip('Remove from saved'), findsOneWidget);
        expect(tester.takeException(), isNull);
        // No Save/Remove action is invoked: source data remains unchanged.
        expect(reads, 1);
      },
    );
  }

  testWidgets('CX1 Saved gracefully shows no existing bookmarks', (
    tester,
  ) async {
    await _show(tester, () async => []);
    expect(find.text('Nothing saved yet'), findsOneWidget);
    expect(find.byTooltip('Remove from saved'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CX1 Saved retries a failed read without mutating items', (
    tester,
  ) async {
    var attempts = 0;
    await _show(tester, () async {
      attempts++;
      if (attempts == 1) throw StateError('Simulated connectivity loss');
      return [provider()];
    });
    expect(find.text('Could not load saved items'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Wantok QA Plumbing Services'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
