import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_tech/src/dashboard/technical_observability_page.dart';

TechnicalModuleAccess _module(Set<String> permissionCodes) =>
    TechnicalModuleAccess(
      moduleKey: 'core.catalog',
      name: 'Catalogue',
      description: null,
      groupCode: 'core',
      sortOrder: 0,
      isEnabled: true,
      maintenanceMode: false,
      version: null,
      healthStatus: 'unknown',
      lastHealthAt: null,
      accessLevelCode: 'tech_auditor',
      permissionCodes: permissionCodes,
    );

final _readiness = TechnicalCentralLogReadiness(
  moduleKey: 'core.catalog',
  registeredSourceContracts: 2,
  observedAt: DateTime.utc(2026, 10, 12),
);

void main() {
  for (final width in [390.0, 1200.0]) {
    testWidgets('central source contract remains unconnected at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 930);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var transitionReads = 0;
      var registryReads = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: TechnicalObservabilityPage(
            module: _module({'module.view', 'module.logs'}),
            section: TechnicalObservabilitySection.logs,
            loadTransitions: (key) async {
              expect(key, 'core.catalog');
              transitionReads++;
              return <TechnicalHealthHistoryEntry>[];
            },
            loadCentralReadiness: (key) async {
              expect(key, 'core.catalog');
              registryReads++;
              return _readiness;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Central log collectors: not connected'),
        findsOneWidget,
      );
      expect(
        find.textContaining('2 source contract(s) registered'),
        findsOneWidget,
      );
      expect(find.textContaining('No verified collector'), findsOneWidget);
      expect(find.text('Run job'), findsNothing);
      expect(registryReads, 1);
      expect(transitionReads, 1);
      await tester.tap(find.byKey(const ValueKey('t24-refresh')));
      await tester.pumpAndSettle();
      expect(registryReads, 2);
      expect(transitionReads, 2);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('missing module.logs stops both reads', (tester) async {
    var reads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: TechnicalObservabilityPage(
          module: _module({'module.view'}),
          section: TechnicalObservabilitySection.logs,
          loadTransitions: (_) async {
            reads++;
            return <TechnicalHealthHistoryEntry>[];
          },
          loadCentralReadiness: (_) async {
            reads++;
            return _readiness;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(reads, 0);
    expect(find.textContaining('not assigned'), findsOneWidget);
    expect(find.text('Central log collectors: not connected'), findsNothing);
  });

  test('typed response only accepts unconnected server-verified shape', () {
    Map<String, dynamic> record() => <String, dynamic>{
      'module_key': 'core.catalog',
      'registered_source_contracts': 0,
      'observed_at': '2026-10-12T01:02:03Z',
      'connection_state': 'not_connected',
      'collector_verified': false,
      'central_logs_available': false,
      'source_health': 'unknown',
    };
    expect(
      TechnicalCentralLogReadiness.fromMap(record()).registeredSourceContracts,
      0,
    );
    for (final altered in <Map<String, dynamic>>[
      {...record(), 'connection_state': 'connected'},
      {...record(), 'collector_verified': true},
      {...record(), 'central_logs_available': true},
      {...record(), 'registered_source_contracts': -1},
      {...record(), 'provenance_ticket': 'SEC-SECRET'},
      {...record(), 'observed_at': 'invalid'},
    ]) {
      expect(
        () => TechnicalCentralLogReadiness.fromMap(altered),
        throwsStateError,
      );
    }
  });
}
