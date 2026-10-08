import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/home/category_information_page.dart';
import 'package:wantok_app/src/home/wantok_category_ui.dart';

void main() {
  testWidgets('Opt-in interest is scoped, explicit, and idempotent in UI', (
    tester,
  ) async {
    var submitted = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CategoryInformationPage(
          style: WantokCategoryStyles.beauty,
          description: 'Approved beauty services',
          categoryId: 'f0000000-0000-0000-0000-000000000001',
          loadInterest: (_) async => false,
          registerInterest: (slug) async {
            expect(slug, WantokCategoryStyles.beauty.slug);
            submitted++;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('category-verified-providers')),
      120,
    );
    expect(
      find.byKey(const ValueKey('category-verified-providers')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('category-provider-interest')),
      120,
    );
    expect(
      find.byKey(const ValueKey('category-provider-interest')),
      findsOneWidget,
    );
    expect(find.textContaining('not a provider application'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('category-provider-interest')));
    await tester.pumpAndSettle();
    expect(submitted, 1);
    expect(find.text('Interest recorded'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('category-provider-interest')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(submitted, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unlaunched category displays honest read-only state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: CategoryInformationPage(
          style: WantokCategoryStyles.health,
          description: 'Licensed healthcare discovery in Papua New Guinea.',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Health & Medical'), findsWidgets);
    expect(find.text('Provider listings coming soon'), findsOneWidget);
    expect(find.textContaining('No booking or payment'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(WantokCategoryPicture), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
