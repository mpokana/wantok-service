import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/home/screenshot_service_tiles.dart';
import 'package:wantok_app/src/home/reference_services_gallery.dart';
import 'package:wantok_app/src/home/wantok_category_ui.dart';

void main() {
  final categories = ScreenshotServiceArt.items.entries.toList();

  for (final width in [320.0, 390.0, 700.0]) {
    testWidgets(
      'Services caption is text-only with one full photo at $width px',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        for (final entry in categories) {
          var taps = 0;
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: width <= 390 ? (width - 36) / 2 : 205,
                    height: 169,
                    child: ScreenshotServicesCard(
                      art: entry.value,
                      onTap: () => taps++,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final photos = find.byType(WantokCategoryPicture);
          expect(photos, findsOneWidget, reason: entry.key);
          expect(
            tester.widget<WantokCategoryPicture>(photos).mediaSlot,
            'cardImage',
            reason: 'Only the large category photograph should remain.',
          );
          expect(find.text(entry.value.title), findsOneWidget);
          expect(find.text(entry.value.subtitle), findsOneWidget);
          expect(tester.takeException(), isNull, reason: entry.key);
          await tester.tap(find.byType(ScreenshotServicesCard));
          expect(taps, 1, reason: entry.key);
        }
      },
    );
  }

  for (final width in [320.0, 390.0]) {
    testWidgets(
      'Single-photo captions tolerate 150% text scaling at $width px',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        for (final entry in categories) {
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 900),
                  textScaler: const TextScaler.linear(1.5),
                ),
                child: Scaffold(
                  body: Center(
                    child: SizedBox(
                      width: (width - 36) / 2,
                      height: 213,
                      child: ScreenshotServicesCard(
                        art: entry.value,
                        onTap: () {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.byType(WantokCategoryPicture),
            findsOneWidget,
            reason: entry.key,
          );
          expect(tester.takeException(), isNull, reason: entry.key);
        }
      },
    );
  }

  testWidgets(
    '320px actual Services landing keeps two-column single-photo cards',
    (tester) async {
      tester.view.physicalSize = const Size(320, 811);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var opened = '';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReferenceServicesLanding(
              onCategory: (category) => opened = category.slug ?? '',
              onAllServices: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final taxiCategory = ReferenceServiceCategories.items.firstWhere(
        (category) => category.slug == 'taxi-ride',
      );
      final taxi = find.byKey(
        ValueKey('reference-category-${taxiCategory.title}'),
      );
      expect(taxi, findsOneWidget);
      expect(
        find.descendant(of: taxi, matching: find.byType(WantokCategoryPicture)),
        findsOneWidget,
      );
      expect(find.text('Taxi / Transport'), findsOneWidget);
      await tester.tap(taxi);
      expect(opened, 'taxi-ride');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Home category tile retains its own compact photo identity', (
    tester,
  ) async {
    final art = ScreenshotServiceArt.items['taxi-ride']!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 150,
            height: 130,
            child: ScreenshotHomeTile(art: art, onTap: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final image = tester.widget<WantokCategoryPicture>(
      find.byType(WantokCategoryPicture),
    );
    expect(image.mediaSlot, 'homeIcon');
    expect(tester.takeException(), isNull);
  });
}
