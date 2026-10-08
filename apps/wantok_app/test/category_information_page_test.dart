import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/home/category_information_page.dart';
import 'package:wantok_app/src/home/wantok_category_ui.dart';

void main() {
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
