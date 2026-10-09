import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/home/enterprise_services_catalogue.dart';
import 'package:wantok_app/src/home/reference_services_gallery.dart';

void main() {
  for (final width in [840.0, 1440.0]) {
    testWidgets('photographic Services catalogue works at ${width.toInt()}px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 960);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      ReferenceCategorySpec? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnterpriseServicesCatalogue(
              onCategory: (spec) => selected = spec,
              onAllServices: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('All Services'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('enterprise-services-catalogue')),
        findsOneWidget,
      );
      expect(find.text('Browse by category'), findsOneWidget);
      expect(
        find.byKey(
          ValueKey(
            'enterprise-category-${ReferenceServiceCategories.items.first.title}',
          ),
        ),
        findsWidgets,
        reason: 'Taxi tile must be visible',
      );
      expect(tester.takeException(), isNull);
      await tester.tap(
        find.byKey(
          ValueKey(
            'enterprise-category-${ReferenceServiceCategories.items.first.title}',
          ),
        ),
      );
      expect(selected, isNotNull);
    });
  }

  testWidgets('filters show selected category, and search handles no match', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EnterpriseServicesCatalogue(
            onCategory: (_) {},
            onAllServices: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('enterprise-filter-Food')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        ValueKey(
          'enterprise-category-${ReferenceServiceCategories.items[1].title}',
        ),
      ),
      findsWidgets,
    );
    expect(find.byKey(ValueKey('enterprise-category-Delivery')), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('enterprise-services-search')),
      'zzzz-no-services',
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No matching categories. Try another search.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
