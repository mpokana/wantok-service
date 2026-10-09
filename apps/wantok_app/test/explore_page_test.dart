import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/home/explore_page.dart';
import 'package:wantok_app/src/home/reference_services_gallery.dart';
import 'package:wantok_app/src/home/smoke_data.dart';

void main() {
  Future<void> pumpExplore(
    WidgetTester tester, {
    VoidCallback? onServices,
  }) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ExplorePage(onBrowseServices: onServices)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Explore is a separate usable destination with service action', (
    tester,
  ) async {
    var browses = 0;
    await pumpExplore(tester, onServices: () => browses++);
    expect(find.byKey(const ValueKey('wantok-explore-page')), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.textContaining('Discover PNG and beyond'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('explore-browse-services')));
    expect(browses, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'twelve marked design previews appear on Explore only in opt-in dev mode',
    (tester) async {
      await pumpExplore(tester);
      expect(
        find.byKey(const ValueKey('explore-reference-samples')),
        WantokSmokeData.enabled ? findsOneWidget : findsNothing,
      );
      expect(
        find.byKey(const ValueKey('reference-scene-foodListing')),
        WantokSmokeData.enabled ? findsOneWidget : findsNothing,
      );
      if (WantokSmokeData.enabled) {
        expect(find.text('Reference screen samples'), findsOneWidget);
        expect(ReferenceScreenGallery.items.length, 12);
        expect(
          find.byKey(const ValueKey('reference-scene-signIn')),
          findsOneWidget,
        );
      } else {
        expect(find.text('Explore more of PNG'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );
}
