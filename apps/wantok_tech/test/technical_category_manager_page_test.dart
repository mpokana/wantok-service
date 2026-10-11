import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_tech/src/dashboard/technical_category_manager_page.dart';

void main() {
  final example = ManagedServiceCategory(
    id: 'e0000000-0000-0000-0000-000000000001',
    slug: 'it-electronics',
    name: 'Electronics & IT',
    vertical: 'people',
    bookingMode: 'information',
    isActive: false,
    showOnHome: false,
    showInServices: false,
    sortOrder: 230,
    updatedAt: '2026-10-11T00:00:00Z',
  );

  for (final width in [390.0, 1240.0]) {
    testWidgets('category editor loads inactive drafts at $width px', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var calls = 0;
      await tester.pumpWidget(MaterialApp(
        home: TechnicalCategoryManagerPage(
          loadCategories: () async {
            calls++;
            return [example];
          },
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Category management'), findsOneWidget);
      expect(find.byKey(const ValueKey('category-it-electronics')), findsOneWidget);
      expect(find.textContaining('Inactive'), findsOneWidget);
      expect(find.textContaining('Home No'), findsOneWidget);
      expect(calls, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('new category dialog defaults inactive and cancel is safe', (tester) async {
    tester.view.physicalSize = const Size(1280, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: TechnicalCategoryManagerPage(
      loadCategories: () async => [example],
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();
    expect(find.text('Enabled / active'), findsOneWidget);
    expect(find.text('Show on Home'), findsOneWidget);
    expect(find.text('Show in Services'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Add category'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
