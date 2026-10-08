import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/home/reference_services_gallery.dart';
import 'package:wantok_app/src/home/smoke_data.dart';

void main() {
  test('Reference includes exactly twelve screenshot-aligned categories', () {
    expect(ReferenceServiceCategories.items.length, 12);
    expect(
      ReferenceServiceCategories.items
          .map((item) => item.title.replaceAll('\n', ' '))
          .toList(),
      [
        'Taxi & Transport',
        'Food & Restaurants',
        'Groceries & Essentials',
        'Shopping & Retail',
        'Home Services',
        'Beauty & Wellness',
        'Health & Medical',
        'Travel & Flights',
        'Events & Tickets',
        'Professional Services',
        'Automotive',
        'More',
      ],
    );
    expect(ReferenceScreenGallery.items.length, 12);
    expect(
      ReferenceScreenGallery.items.map((screen) => screen.scene).toSet().length,
      12,
    );
  });

  Future<void> pumpLanding(
    WidgetTester tester, {
    required ValueChanged<ReferenceCategorySpec> onCategory,
    required VoidCallback onAll,
  }) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReferenceServicesLanding(
            onCategory: onCategory,
            onAllServices: onAll,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Reference category grid opens matching icon category and All Services',
    (tester) async {
      ReferenceCategorySpec? selected;
      var allServices = false;
      await pumpLanding(
        tester,
        onCategory: (item) => selected = item,
        onAll: () => allServices = true,
      );

      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('All Services'), findsOneWidget);
      expect(find.byType(GridView), findsWidgets);
      expect(find.byIcon(Icons.local_taxi_rounded), findsWidgets);
      expect(find.byIcon(Icons.restaurant_rounded), findsWidgets);
      expect(find.byIcon(Icons.shopping_basket_rounded), findsWidgets);
      await tester.tap(
        find.byKey(const ValueKey('reference-category-Food &\nRestaurants')),
      );
      await tester.pumpAndSettle();
      expect(selected?.slug, 'food');
      await tester.tap(find.byKey(const ValueKey('reference-all-services')));
      expect(allServices, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Reference sample gallery is clearly opt-in', (tester) async {
    await pumpLanding(tester, onCategory: (_) {}, onAll: () {});
    expect(
      find.byKey(const ValueKey('reference-scene-foodListing')),
      WantokSmokeData.enabled ? findsOneWidget : findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
