import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_app/src/home/staged_provider_application_page.dart';

void main() {
  testWidgets(
    'Applicant sees read-only checklist status without approval actions',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var loaded = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: StagedProviderApplicationPage(
            categoryId: 'cat-one',
            categorySlug: 'home-services',
            categoryName: 'Home Services',
            requirements: const ['Trade description'],
            loadApplication: (_) async => {
              'id': 'app-one',
              'status': 'in_review',
              'applicant_name': 'Example Applicant',
            },
            loadEvidencePlans: (_) async => [
              {'check_id': 'check-one', 'state': 'planned'},
            ],
            loadChecks: (id) async {
              expect(id, 'app-one');
              loaded++;
              return [
                {
                  'requirement_index': 1,
                  'requirement_label': 'Trade description and coverage area',
                  'review_status': 'needs_followup',
                },
              ];
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(loaded, greaterThan(0));
      expect(find.text('Preliminary checklist progress'), findsOneWidget);
      expect(find.text('Needs follow-up'), findsOneWidget);
      expect(find.text('Future evidence planning only'), findsOneWidget);
      expect(
        find.textContaining('Do not email, message or send'),
        findsOneWidget,
      );
      expect(find.text('Trade description and coverage area'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      expect(
        find.byKey(const ValueKey('submit-staged-application')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Preliminary intake only collects minimal details and never approves',
    (tester) async {
      tester.view.physicalSize = const Size(390, 2800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var submitted = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: StagedProviderApplicationPage(
            categoryId: 'c0000000-0000-0000-0000-000000000001',
            categorySlug: 'home-services',
            categoryName: 'Home Services',
            requirements: const ['Trade description', 'Future identity review'],
            loadApplication: (_) async => null,
            submitApplication:
                (category, name, kind, province, town, summary) async {
                  expect(category, 'home-services');
                  expect(name, 'Test Home Repair');
                  expect(kind, 'individual');
                  expect(province, 'Morobe');
                  expect(summary, 'Repairs and maintenance in Lae');
                  submitted++;
                },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('not approval'), findsOneWidget);
      expect(find.text('Future verification checklist'), findsOneWidget);

      final name = find.byKey(const ValueKey('staged-applicant-name'));
      await tester.ensureVisible(name);
      await tester.enterText(name, 'Test Home Repair');
      final province = find.byKey(const ValueKey('staged-applicant-province'));
      await tester.ensureVisible(province);
      await tester.enterText(province, 'Morobe');
      final summary = find.byKey(const ValueKey('staged-applicant-summary'));
      await tester.ensureVisible(summary);
      await tester.enterText(summary, 'Repairs and maintenance in Lae');
      final submit = find.byKey(const ValueKey('submit-staged-application'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(submitted, 1);
      expect(find.textContaining('Application: submitted'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('submit-staged-application')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
