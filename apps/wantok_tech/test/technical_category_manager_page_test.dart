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
    testWidgets('category editor loads inactive drafts at $width px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: TechnicalCategoryManagerPage(
            loadCategories: () async {
              calls++;
              return [example];
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Service category management'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('category-it-electronics')),
        findsOneWidget,
      );
      expect(find.text('Draft'), findsOneWidget);
      expect(find.text('Home Off'), findsOneWidget);
      expect(calls, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('new category dialog defaults inactive and cancel is safe', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: TechnicalCategoryManagerPage(
          loadCategories: () async => [example],
        ),
      ),
    );
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

  testWidgets('uses the SAME Taxi and Public Services photographs as Client', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ManagedServiceCategory category(String slug, String name, int index) =>
        ManagedServiceCategory(
          id: 'e0000000-0000-0000-0000-${index.toString().padLeft(12, '0')}',
          slug: slug,
          name: name,
          vertical: 'people',
          bookingMode: 'information',
          isActive: true,
          showOnHome: true,
          showInServices: true,
          sortOrder: index,
          updatedAt: '2026-10-11T00:00:00Z',
        );
    await tester.pumpWidget(
      MaterialApp(
        home: TechnicalCategoryManagerPage(
          loadCategories: () async => [
            category('taxi-ride', 'Taxi / Ride', 1),
            category('public-services', 'Public Services', 2),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.image(
        const AssetImage(
          'packages/wantok_ui/assets/images/categories/category_taxi.webp',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.image(
        const AssetImage(
          'packages/wantok_ui/assets/images/reference/services_public_photo.jpg',
        ),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
