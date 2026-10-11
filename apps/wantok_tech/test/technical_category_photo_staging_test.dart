import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_tech/src/dashboard/technical_category_manager_page.dart';

void main() {
  const category = ManagedServiceCategory(
    id: 'e0000000-0000-0000-0000-000000000001',
    slug: 'it-electronics',
    name: 'Electronics & IT',
    vertical: 'people',
    bookingMode: 'information',
    isActive: false,
    showOnHome: false,
    showInServices: false,
    sortOrder: 230,
    updatedAt: '2026-10-11T00:00:00Z',
  );
  // Synthetic one-pixel image, never uploaded to a server.
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/lZkAAAAASUVORK5CYII=',
  );

  Future<CategoryPickedPicture> fakeImage(String name, Uint8List bytes) async =>
      (name: name, bytes: bytes);

  Future<void> openEditor(
    WidgetTester tester, {
    required Future<CategoryPickedPicture?> Function() picker,
    required Future<String> Function({
      required String slug,
      required String extension,
      required Uint8List bytes,
    })
    upload,
    required Future<void> Function(
      Map<String, dynamic>,
      ManagedServiceCategory?,
    )
    save,
  }) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: TechnicalCategoryManagerPage(
          loadCategories: () async => [category],
          pickCategoryPicture: picker,
          uploadCategoryPicture: upload,
          saveCategory: save,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit Electronics & IT'));
    await tester.pumpAndSettle();
    expect(find.text('Edit category'), findsOneWidget);
  }

  Future<void> selectPicture(WidgetTester tester) async {
    final action = find.text('Choose category picture');
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Cancel after selecting photo makes zero storage or database writes',
    (tester) async {
      var uploads = 0;
      var saves = 0;
      await openEditor(
        tester,
        picker: () => fakeImage('safe.png', png),
        upload: ({required slug, required extension, required bytes}) async {
          uploads++;
          return 'categories/it-electronics/cardImage/test.png';
        },
        save: (fields, existing) async {
          saves++;
        },
      );
      await selectPicture(tester);
      expect(
        find.byKey(const ValueKey('category-picture-staged')),
        findsOneWidget,
      );
      expect(uploads, 0);
      expect(saves, 0);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Edit category'), findsNothing);
      expect(uploads, 0);
      expect(saves, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Save uploads exactly once and persists image path to existing draft',
    (tester) async {
      var uploads = 0;
      var saves = 0;
      Map<String, dynamic>? savedFields;
      ManagedServiceCategory? edited;
      await openEditor(
        tester,
        picker: () => fakeImage('safe.PNG', png),
        upload: ({required slug, required extension, required bytes}) async {
          uploads++;
          expect(slug, 'it-electronics');
          expect(extension, 'png');
          expect(bytes, png);
          return 'categories/it-electronics/cardImage/test.png';
        },
        save: (fields, existing) async {
          saves++;
          savedFields = Map<String, dynamic>.of(fields);
          edited = existing;
        },
      );
      await selectPicture(tester);
      expect(uploads, 0);
      expect(saves, 0);
      await tester.ensureVisible(find.text('Save category'));
      await tester.tap(find.text('Save category'));
      await tester.pumpAndSettle();
      expect(uploads, 1);
      expect(saves, 1);
      expect(edited?.id, category.id);
      expect(
        savedFields?['image_path'],
        'categories/it-electronics/cardImage/test.png',
      );
      expect(savedFields?['is_active'], false);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Unsupported extension does not stage, upload or save', (
    tester,
  ) async {
    var uploads = 0;
    var saves = 0;
    await openEditor(
      tester,
      picker: () => fakeImage('invalid.svg', png),
      upload: ({required slug, required extension, required bytes}) async {
        uploads++;
        return 'unexpected';
      },
      save: (fields, existing) async {
        saves++;
      },
    );
    await selectPicture(tester);
    expect(find.text('Choose JPG, PNG or WebP.'), findsOneWidget);
    expect(find.byKey(const ValueKey('category-picture-staged')), findsNothing);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(uploads, 0);
    expect(saves, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Spoofed PNG signature is rejected before storage access', (
    tester,
  ) async {
    var uploads = 0;
    await openEditor(
      tester,
      picker: () => fakeImage('fake.png', Uint8List.fromList([1, 2, 3])),
      upload: ({required slug, required extension, required bytes}) async {
        uploads++;
        return 'unexpected';
      },
      save: (fields, existing) async {},
    );
    await selectPicture(tester);
    expect(
      find.text('The picture does not match its image type.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('category-picture-staged')), findsNothing);
    expect(uploads, 0);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
