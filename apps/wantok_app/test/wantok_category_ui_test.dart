import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/home/wantok_category_ui.dart';
import 'package:wantok_app/src/home/reference_services_gallery.dart';

void main() {
  test('Nineteen catalogue entries share the category style registry', () {
    final styles = WantokCategoryStyles.reference;
    expect(styles.length, 19);
    final photos = styles
        .map((style) => style.photoAsset)
        .whereType<String>()
        .toList(growable: false);
    // No two visible categories may silently share one photo.
    expect(photos.toSet().length, photos.length);
    expect(ReferenceServiceCategories.items.length, styles.length);
    for (var i = 0; i < styles.length; i++) {
      final category = ReferenceServiceCategories.items[i];
      expect(category.style, same(styles[i]));
      expect(category.icon, styles[i].icon);
      expect(category.colour, styles[i].accent);
      expect(category.surface, styles[i].surface);
      expect(category.style.photoAsset, styles[i].photoAsset);
      if (styles[i].photoAsset == null) {
        // A meaningful icon illustration is preferable to an unrelated photo.
        expect(styles[i].icon, isNotNull);
      } else {
        expect(styles[i].photoAsset, startsWith('assets/images/'));
        expect(
          styles[i].photoAsset,
          anyOf(endsWith('.webp'), endsWith('.png')),
        );
      }
    }
  });

  test('Missing category photographs use their own relevant icons', () {
    expect(WantokCategoryStyles.education.photoAsset, isNull);
    expect(WantokCategoryStyles.education.icon, Icons.school_rounded);
    expect(WantokCategoryStyles.labour.photoAsset, isNull);
    expect(WantokCategoryStyles.labour.icon, Icons.handyman_rounded);
    expect(WantokCategoryStyles.financial.photoAsset, isNull);
    expect(WantokCategoryStyles.financial.icon, Icons.payments_rounded);
    expect(WantokCategoryStyles.hotels.photoAsset, isNull);
    expect(WantokCategoryStyles.hotels.icon, Icons.hotel_rounded);
    expect(WantokCategoryStyles.errands.photoAsset, isNull);
    expect(WantokCategoryStyles.boatHire.photoAsset, isNull);
    expect(
      WantokCategoryStyles.professional.photoAsset,
      'assets/images/categories/category_professional.webp',
    );
    expect(
      WantokCategoryStyles.home.photoAsset,
      'assets/images/categories/category_home_services.webp',
    );
  });

  testWidgets('Education and Labour tiles render different illustrated icons', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: 146,
                height: 160,
                child: WantokCategoryTile(
                  style: WantokCategoryStyles.education,
                  onTap: () {},
                ),
              ),
              SizedBox(
                width: 146,
                height: 160,
                child: WantokCategoryTile(
                  style: WantokCategoryStyles.labour,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.school_rounded), findsOneWidget);
    expect(find.byIcon(Icons.handyman_rounded), findsOneWidget);
    expect(
      find.image(
        const AssetImage('assets/images/categories/category_professional.webp'),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
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
