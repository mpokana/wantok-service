import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_tech/src/dashboard/technical_activity_page.dart';

TechnicalModuleAccess access(Set<String> permissions) => TechnicalModuleAccess(
  moduleKey: 'core.catalog',
  name: 'Service Catalogue',
  description: null,
  groupCode: 'core',
  sortOrder: 1,
  isEnabled: true,
  maintenanceMode: false,
  version: null,
  healthStatus: 'healthy',
  lastHealthAt: null,
  accessLevelCode: 'tech_auditor',
  permissionCodes: permissions,
);

Future<void> mountActivity(
  WidgetTester tester, {
  required double width,
  required TechnicalModuleAccess module,
  TechnicalActivityLoader? loader,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: TechnicalActivityPage(module: module, loadActivity: loader),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TechnicalActivityEvent event(int id, String action) => TechnicalActivityEvent(
    id: id,
    occurredAt: DateTime.utc(2026, 10, 12, 1, 20),
    actionCode: action,
  );

  for (final width in [390.0, 1200.0]) {
    testWidgets(
      'safe activity labels and bounded read-only refresh at $width',
      (tester) async {
        var reads = 0;
        await mountActivity(
          tester,
          width: width,
          module: access({'module.view', 'module.logs'}),
          loader: (moduleKey) async {
            expect(moduleKey, 'core.catalog');
            reads++;
            return [
              event(1, 'technical_module_state_changed'),
              event(2, 'technical_module_configuration_changed'),
              event(3, 'technical_module_access_granted'),
              event(4, 'technical_module_access_revoked'),
            ];
          },
        );
        expect(find.text('Module state changed'), findsOneWidget);
        expect(find.text('Configuration changed'), findsOneWidget);
        expect(find.text('Technical access granted'), findsOneWidget);
        expect(find.text('Technical access revoked'), findsOneWidget);
        expect(
          find.textContaining('Actual Technical Control changes'),
          findsOneWidget,
        );
        expect(find.textContaining('Actor names'), findsOneWidget);
        expect(find.text('Run'), findsNothing);
        expect(find.text('Cancel job'), findsNothing);
        expect(reads, 1);
        await tester.tap(find.byKey(const ValueKey('t24-activity-refresh')));
        await tester.pumpAndSettle();
        expect(reads, 2);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('missing logs permission makes no read call', (tester) async {
    var reads = 0;
    await mountActivity(
      tester,
      width: 390,
      module: access({'module.view'}),
      loader: (_) async {
        reads++;
        return [event(1, 'technical_module_state_changed')];
      },
    );
    expect(find.textContaining('not assigned'), findsOneWidget);
    expect(find.byKey(const ValueKey('t24-activity-refresh')), findsNothing);
    expect(reads, 0);
  });

  testWidgets('empty history is not interpreted as no platform events', (
    tester,
  ) async {
    await mountActivity(
      tester,
      width: 390,
      module: access({'module.view', 'module.logs'}),
      loader: (_) async => const [],
    );
    expect(find.textContaining('does not prove an absence'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed read redacts backend error and Retry works', (
    tester,
  ) async {
    var attempts = 0;
    await mountActivity(
      tester,
      width: 390,
      module: access({'module.view', 'module.logs'}),
      loader: (_) async {
        attempts++;
        if (attempts == 1) {
          throw StateError('DB SECRET: do not display');
        }
        return [event(7, 'technical_module_state_changed')];
      },
    );
    expect(
      find.textContaining('Technical activity unavailable'),
      findsOneWidget,
    );
    expect(find.textContaining('DB SECRET'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Module state changed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('typed activity model rejects unsafe/unexpected server fields', () {
    final valid = {
      'id': 1,
      'occurred_at': '2026-10-12T01:20:00Z',
      'action_code': 'technical_module_access_revoked',
    };
    final item = TechnicalActivityEvent.fromMap(valid);
    expect(item.id, 1);
    expect(item.actionCode, 'technical_module_access_revoked');
    expect(
      () => TechnicalActivityEvent.fromMap({
        ...valid,
        'action_code': 'operational_case_approved',
      }),
      throwsStateError,
    );
    expect(
      () => TechnicalActivityEvent.fromMap({...valid, 'id': -1}),
      throwsStateError,
    );
    expect(
      () => TechnicalActivityEvent.fromMap({...valid, 'occurred_at': null}),
      throwsStateError,
    );
  });
}
