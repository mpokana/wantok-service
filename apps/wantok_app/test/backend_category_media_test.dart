import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/home/wantok_category_ui.dart';

/// Read-only media coverage for the 23 distinct backend service_categories
/// recorded on 11 Oct 2026, including those that are currently inactive.
/// Never enable a category simply because it has a photograph.
void main() {
  const databaseSlugs = <String>[
    'taxi-ride',
    'vehicle-hire',
    'boat-hire',
    'boat-ship-rides',
    'specialist-services',
    'general-labour',
    'venue-booking',
    'events',
    'delivery',
    'errands',
    'food',
    'groceries',
    'shopping-retail',
    'home-services',
    'beauty-wellness',
    'health-medical',
    'travel-flights',
    'education-training',
    'financial-services',
    'public-services',
    'bus-coach',
    'accommodation',
    'flights',
  ];

  test('All backend category slugs have their own canonical photo style', () {
    final styles = WantokCategoryStyles.backendCatalogue;
    expect(styles.length, databaseSlugs.length);
    expect(styles.map((style) => style.slug), unorderedEquals(databaseSlugs));
    final photos = <String>{};
    for (final slug in databaseSlugs) {
      final style = WantokCategoryStyles.bySlug(slug);
      expect(
        style.slug,
        slug,
        reason: 'Unknown category must not fall to More',
      );
      expect(style.photoAsset, isNotNull, reason: slug);
      expect(
        photos.add(style.photoAsset!),
        isTrue,
        reason: 'Category photo reused for $slug',
      );
    }
    expect(
      WantokCategoryStyles.bySlug('flights').photoAsset,
      'packages/wantok_ui/assets/images/categories/category_flights.webp',
    );
    expect(
      WantokCategoryStyles.bySlug('bus-coach').photoAsset,
      'packages/wantok_ui/assets/images/categories/category_bus_coach.webp',
    );
    expect(
      WantokCategoryStyles.bySlug('travel-flights').photoAsset,
      isNot(WantokCategoryStyles.bySlug('flights').photoAsset),
    );
  });

  test(
    'All bundled backend category photo bytes exist and are unique',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final signatures = <String>{};
      for (final style in WantokCategoryStyles.backendCatalogue) {
        final data = await rootBundle.load(style.photoAsset!);
        expect(data.lengthInBytes, greaterThan(1500), reason: style.slug);
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        expect(
          signatures.add(base64Encode(bytes)),
          isTrue,
          reason: 'Duplicate photo bytes for ${style.slug}',
        );
      }
    },
  );

  testWidgets('Bus and Flights render different offline pictures', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: 150,
                height: 180,
                child: WantokCategoryTile(
                  style: WantokCategoryStyles.busCoach,
                  onTap: () {},
                ),
              ),
              SizedBox(
                width: 150,
                height: 180,
                child: WantokCategoryTile(
                  style: WantokCategoryStyles.flights,
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
        const AssetImage('packages/wantok_ui/assets/images/categories/category_bus_coach.webp'),
      ),
      findsOneWidget,
    );
    expect(
      find.image(
        const AssetImage('packages/wantok_ui/assets/images/categories/category_flights.webp'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
