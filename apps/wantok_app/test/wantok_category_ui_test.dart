import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/home/wantok_category_ui.dart';
import 'package:wantok_app/src/home/reference_services_gallery.dart';

void main() {
  test('Nineteen catalogue entries share the category style registry', () {
    final styles = WantokCategoryStyles.reference;
    expect(styles.length, 19);
    expect(
      styles.map((style) => style.photoAsset).toSet().length,
      greaterThanOrEqualTo(12),
    );
    expect(ReferenceServiceCategories.items.length, styles.length);
    for (var i = 0; i < styles.length; i++) {
      final category = ReferenceServiceCategories.items[i];
      expect(category.style, same(styles[i]));
      expect(category.icon, styles[i].icon);
      expect(category.colour, styles[i].accent);
      expect(category.surface, styles[i].surface);
      expect(category.style.photoAsset, styles[i].photoAsset);
      if (styles[i] == WantokCategoryStyles.publicServices) {
        // The Public Services tile intentionally uses the approved gold icon.
        expect(styles[i].photoAsset, isNull);
      } else {
        expect(styles[i].photoAsset, startsWith('assets/images/'));
        expect(
          styles[i].photoAsset,
          anyOf(endsWith('.webp'), endsWith('.png')),
        );
      }
    }
  });

  test('Backend categories resolve the same identity throughout app', () {
    expect(
      WantokCategoryStyles.bySlug('taxi-ride'),
      same(WantokCategoryStyles.taxi),
    );
    expect(
      WantokCategoryStyles.bySlug('food'),
      same(WantokCategoryStyles.food),
    );
    expect(
      WantokCategoryStyles.bySlug('groceries'),
      same(WantokCategoryStyles.groceries),
    );
    expect(
      WantokCategoryStyles.bySlug('specialist-services'),
      same(WantokCategoryStyles.professional),
    );
    expect(
      WantokCategoryStyles.bySlug('vehicle-hire'),
      same(WantokCategoryStyles.automotive),
    );
    expect(
      WantokCategoryStyles.bySlug('events'),
      same(WantokCategoryStyles.events),
    );
    expect(
      WantokCategoryStyles.bySlug('delivery'),
      same(WantokCategoryStyles.delivery),
    );
    expect(
      WantokCategoryStyles.bySlug('boat-ship-rides'),
      same(WantokCategoryStyles.waterRides),
    );
    expect(
      WantokCategoryStyles.bySlug('venue-booking'),
      same(WantokCategoryStyles.venue),
    );
    expect(
      WantokCategoryStyles.bySlug('no-such-category'),
      same(WantokCategoryStyles.more),
    );
  });

  testWidgets(
    'Premium categories are tappable with stable icons and no overflows',
    (tester) async {
      var selected = '';
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                height: 155,
                width: 96,
                child: WantokCategoryTile(
                  key: const ValueKey('premium-food'),
                  style: WantokCategoryStyles.food,
                  onTap: () => selected = 'food',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  WantokCategoryStyles.food.photoAsset,
        ),
        findsOneWidget,
      );
      expect(find.text(WantokCategoryStyles.food.title), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('premium-food')));
      expect(selected, 'food');
    },
  );

  testWidgets('The same food photo appears in category tiles and headers', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              const WantokCategoryBadge(style: WantokCategoryStyles.food),
              const SizedBox(width: 10),
              SizedBox(
                width: 115,
                height: 153,
                child: WantokCategoryTile(
                  style: WantokCategoryStyles.food,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.image(
        const AssetImage('assets/images/categories/category_food.webp'),
      ),
      findsNWidgets(2),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Compact saved category preserves independent bookmark action', (
    tester,
  ) async {
    var navigation = 0;
    var saves = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 125,
            width: 105,
            child: WantokCategoryTile(
              style: WantokCategoryStyles.professional,
              compact: true,
              label: 'Specialists',
              saved: false,
              onSavedToggle: () => saves++,
              onTap: () => navigation++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Save category'));
    expect(saves, 1);
    expect(navigation, 0);
    expect(tester.takeException(), isNull);
  });
}
