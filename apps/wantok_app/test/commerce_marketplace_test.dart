import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/services/commerce_browse_page.dart';
import 'package:wantok_core/wantok_core.dart';
import 'package:wantok_ui/wantok_ui.dart';

void main() {
  const food = WantokServiceCategory(
    id: 'food',
    slug: 'food',
    name: 'Food',
    vertical: 'commerce',
    bookingMode: 'commerce',
  );
  const groceries = WantokServiceCategory(
    id: 'groceries',
    slug: 'groceries',
    name: 'Groceries / Shops',
    vertical: 'commerce',
    bookingMode: 'commerce',
  );

  Future<void> show(WidgetTester tester, CommerceBrowsePage page) async {
    tester.view.physicalSize = const Size(390, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: WantokTheme.light(), home: page),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('empty commerce market stays truthful and service-first', (
    tester,
  ) async {
    await show(
      tester,
      CommerceBrowsePage(
        category: groceries,
        loadStores: (_) async => const <Map<String, dynamic>>[],
      ),
    );

    expect(find.text('DELIVERY OR PICKUP'), findsOneWidget);
    expect(
      find.text('Choose your address or pickup option at checkout'),
      findsOneWidget,
    );
    expect(find.text('Local shops. Everyday needs.'), findsOneWidget);
    expect(find.text('No approved shops in this market yet'), findsOneWidget);
    expect(find.text('Top rated'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('populated commerce market shows approved vendor discovery', (
    tester,
  ) async {
    final stores = <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'store-1',
        'title': 'Wantok Fresh Market',
        'description': 'Fresh local food and produce',
        'service_address': 'Lae',
        'metadata': <String, dynamic>{},
        'provider_profiles': <String, dynamic>{
          'display_name': 'Wantok Fresh',
          'rating_average': 4.8,
          'rating_count': 32,
        },
      },
      <String, dynamic>{
        'id': 'store-2',
        'title': 'Island Kitchen',
        'description': 'Local meals',
        'service_address': 'Lae',
        'metadata': <String, dynamic>{},
        'provider_profiles': <String, dynamic>{
          'display_name': 'Island Kitchen',
          'rating_average': 4.5,
          'rating_count': 11,
        },
      },
    ];

    await show(
      tester,
      CommerceBrowsePage(category: food, loadStores: (_) async => stores),
    );

    expect(find.text('Featured food vendors'), findsOneWidget);
    expect(find.text('2 approved Wantok vendors available.'), findsNWidgets(2));
    expect(find.text('Browse all food vendors'), findsOneWidget);
    expect(find.text('Wantok Fresh Market'), findsWidgets);
    expect(find.text('Island Kitchen'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
