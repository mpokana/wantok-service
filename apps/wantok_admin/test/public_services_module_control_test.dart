import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_admin/src/dashboard/public_services_module_control_page.dart';

void main() {
  testWidgets(
    'module admin switch requires confirmation and saves only approved changes',
    (tester) async {
      bool persisted = true;
      var writes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PublicServicesModuleControlPage(
              loadEnabled: () async => persisted,
              saveEnabled: (enabled) async {
                writes++;
                persisted = enabled;
                return persisted;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('admin-public-services-toggle')),
        findsOneWidget,
      );
      expect(find.textContaining('Enabled — visible'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('admin-public-services-toggle')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Disable Public Services?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(writes, 0);

      await tester.tap(
        find.byKey(const ValueKey('admin-public-services-toggle')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Disable').last);
      await tester.pumpAndSettle();

      expect(writes, 1);
      expect(persisted, isFalse);
      expect(find.textContaining('Disabled — hidden'), findsOneWidget);
    },
  );

  testWidgets('module switch presents safe unavailable state when load fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PublicServicesModuleControlPage(
            loadEnabled: () async => throw StateError('offline'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Unable to load'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('admin-public-services-toggle')),
      findsNothing,
    );
  });
}
