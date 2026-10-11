import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_tech/src/dashboard/technical_observability_page.dart';

TechnicalModuleAccess module(
  Set<String> permissions, {
  String moduleKey = 'core.catalog',
}) => TechnicalModuleAccess(
  moduleKey: moduleKey,
  name: 'Catalogue',
  description: null,
  groupCode: 'core',
  sortOrder: 1,
  isEnabled: true,
  maintenanceMode: false,
  version: null,
  healthStatus: 'unknown',
  lastHealthAt: null,
  accessLevelCode: 'tech_operator',
  permissionCodes: permissions,
);

TechnicalDiagnosticSnapshot diagnosticData() => TechnicalDiagnosticSnapshot(
  health: TechnicalModuleHealth(
    moduleKey: 'core.catalog',
    reportedStatus: 'degraded',
    effectiveStatus: 'degraded',
    lastReportAt: DateTime.utc(2026, 10, 11, 6),
    lastEvaluatedAt: DateTime.utc(2026, 10, 11, 6),
    summary: 'Private narrative not shown in the diagnostic workspace',
  ),
  probes: [
    const TechnicalHealthProbe(
      probeKey: 'state',
      name: 'Module control state',
      description: null,
      probeKind: 'control_state',
      staleAfterSeconds: 60,
      isRequired: true,
      isEnabled: true,
      currentStatus: 'degraded',
      currentSummary: 'Internal detail hidden',
      observedAt: null,
      isStale: true,
      canRun: true,
    ),
  ],
  dependencies: [
    const TechnicalModuleDependency(
      moduleKey: null,
      name: 'Do not reveal secret dependency',
      isVisible: false,
      dependencyType: 'required',
      failureEffect: 'down',
      description: null,
      isEnabled: null,
      maintenanceMode: null,
      reportedStatus: null,
      effectiveStatus: null,
      lastReportAt: null,
    ),
  ],
);

void main() {
  Future<void> mount(
    WidgetTester tester, {
    required double width,
    required TechnicalModuleAccess access,
    required TechnicalObservabilitySection section,
    DiagnosticLoader? diagnostics,
    TransitionLoader? transitions,
    QueueLoader? queue,
  }) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: TechnicalObservabilityPage(
          module: access,
          section: section,
          loadDiagnostics: diagnostics,
          loadTransitions: transitions,
          loadQueue: queue,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final width in [390.0, 1200.0]) {
    testWidgets(
      'diagnostics shows real adapter fields with no commands at $width',
      (tester) async {
        var reads = 0;
        await mount(
          tester,
          width: width,
          access: module({'module.view', 'module.diagnostics'}),
          section: TechnicalObservabilitySection.diagnostics,
          diagnostics: (key) async {
            reads++;
            expect(key, 'core.catalog');
            return diagnosticData();
          },
        );
        expect(find.textContaining('Effective: degraded'), findsOneWidget);
        expect(find.text('Module control state'), findsOneWidget);
        expect(find.text('Restricted dependency'), findsOneWidget);
        expect(find.text('Do not reveal secret dependency'), findsNothing);
        expect(find.text('Run'), findsNothing);
        expect(find.text('Retry job'), findsNothing);
        expect(reads, 1);
        await tester.tap(find.byKey(const ValueKey('t24-refresh')));
        await tester.pumpAndSettle();
        expect(reads, 2);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('missing capability fails closed, never calls loaders', (
    tester,
  ) async {
    var reads = 0;
    await mount(
      tester,
      width: 390,
      access: module({'module.view'}),
      section: TechnicalObservabilitySection.diagnostics,
      diagnostics: (_) async {
        reads++;
        return diagnosticData();
      },
    );
    expect(find.textContaining('not assigned'), findsOneWidget);
    expect(find.byKey(const ValueKey('t24-refresh')), findsNothing);
    expect(reads, 0);
  });

  testWidgets('read-only logs are bounded health history, not arbitrary logs', (
    tester,
  ) async {
    var reads = 0;
    await mount(
      tester,
      width: 1200,
      access: module({'module.view', 'module.logs'}),
      section: TechnicalObservabilitySection.logs,
      transitions: (key) async {
        reads++;
        expect(key, 'core.catalog');
        return List.generate(
          36,
          (i) => TechnicalHealthHistoryEntry(
            id: i,
            previousReportedStatus: 'unknown',
            reportedStatus: 'healthy',
            previousEffectiveStatus: 'unknown',
            effectiveStatus: 'healthy',
            transitionReason: 'state_update',
            sourceProbeKey: 'state',
            summary: 'Sensitive summary not shown',
            observedAt: null,
            recordedAt: DateTime.utc(2026, 10, 11),
          ),
        );
      },
    );
    expect(find.textContaining('maximum 30'), findsOneWidget);
    expect(
      find.textContaining('Central application, security and container logs'),
      findsOneWidget,
    );
    expect(find.textContaining('Sensitive summary not shown'), findsNothing);
    expect(reads, 1);
    await tester.tap(find.byKey(const ValueKey('t24-refresh')));
    await tester.pumpAndSettle();
    expect(reads, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('jobs never imply queue activity or offer execution', (
    tester,
  ) async {
    await mount(
      tester,
      width: 390,
      access: module({'module.view', 'module.jobs'}),
      section: TechnicalObservabilitySection.jobs,
    );
    expect(find.textContaining('No background queue adapter'), findsOneWidget);
    expect(
      find.textContaining('zero jobs must not be inferred'),
      findsOneWidget,
    );
    expect(find.text('Run'), findsNothing);
    expect(find.byKey(const ValueKey('t24-refresh')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  TechnicalQueueSnapshot snapshot({
    int total = 6,
    int pending = 2,
    int processing = 1,
    int sent = 2,
    int failed = 1,
    int cancelled = 0,
  }) => TechnicalQueueSnapshot(
    moduleKey: 'core.messaging',
    adapterKey: 'notification_outbox_status',
    observedAt: DateTime.utc(2026, 10, 11, 7),
    lastActivityAt: DateTime.utc(2026, 10, 11, 6),
    total: total,
    pending: pending,
    processing: processing,
    sent: sent,
    failed: failed,
    cancelled: cancelled,
  );

  for (final width in [390.0, 1200.0]) {
    testWidgets('messaging queue displays genuine source statuses at $width', (
      tester,
    ) async {
      var reads = 0;
      await mount(
        tester,
        width: width,
        access: module({
          'module.view',
          'module.jobs',
        }, moduleKey: 'core.messaging'),
        section: TechnicalObservabilitySection.jobs,
        queue: (key) async {
          reads++;
          expect(key, 'core.messaging');
          return snapshot();
        },
      );
      expect(find.text('Pending: 2'), findsOneWidget);
      expect(find.text('Processing status: 1'), findsOneWidget);
      expect(find.text('Failed: 1'), findsOneWidget);
      expect(find.byKey(const ValueKey('t24-queue-total')), findsOneWidget);
      expect(
        find.textContaining('NOT confirmed worker activity'),
        findsOneWidget,
      );
      expect(find.textContaining('No recipient identifiers'), findsOneWidget);
      expect(find.text('Retry job'), findsNothing);
      expect(reads, 1);
      await tester.tap(find.byKey(const ValueKey('t24-refresh')));
      await tester.pumpAndSettle();
      expect(reads, 2);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('empty Messaging outbox is distinct from disconnected adapter', (
    tester,
  ) async {
    await mount(
      tester,
      width: 390,
      access: module({
        'module.view',
        'module.jobs',
      }, moduleKey: 'core.messaging'),
      section: TechnicalObservabilitySection.jobs,
      queue: (_) async =>
          snapshot(total: 0, pending: 0, processing: 0, sent: 0, failed: 0),
    );
    expect(find.textContaining('contains no records'), findsOneWidget);
    expect(find.textContaining('No background queue adapter'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('non-Messaging module never invokes Messaging queue loader', (
    tester,
  ) async {
    var reads = 0;
    await mount(
      tester,
      width: 390,
      access: module({'module.view', 'module.jobs'}),
      section: TechnicalObservabilitySection.jobs,
      queue: (_) async {
        reads++;
        return snapshot();
      },
    );
    expect(find.textContaining('No background queue adapter'), findsOneWidget);
    expect(reads, 0);
    expect(find.byKey(const ValueKey('t24-refresh')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('module.jobs without view cannot read Messaging queue', (
    tester,
  ) async {
    var reads = 0;
    await mount(
      tester,
      width: 390,
      access: module({'module.jobs'}, moduleKey: 'core.messaging'),
      section: TechnicalObservabilitySection.jobs,
      queue: (_) async {
        reads++;
        return snapshot();
      },
    );
    expect(find.textContaining('not assigned'), findsOneWidget);
    expect(reads, 0);
    expect(tester.takeException(), isNull);
  });

  test('queue model rejects impossible totals and negative counts', () {
    final valid = {
      'module_key': 'core.messaging',
      'adapter_key': 'notification_outbox_status',
      'observed_at': '2026-10-11T07:00:00Z',
      'last_activity_at': null,
      'total': 1,
      'pending': 1,
      'processing': 0,
      'sent': 0,
      'failed': 0,
      'cancelled': 0,
    };
    expect(TechnicalQueueSnapshot.fromMap(valid).total, 1);
    expect(
      () => TechnicalQueueSnapshot.fromMap({...valid, 'total': 99}),
      throwsStateError,
    );
    expect(
      () => TechnicalQueueSnapshot.fromMap({...valid, 'pending': -1}),
      throwsStateError,
    );
    expect(
      () =>
          TechnicalQueueSnapshot.fromMap({...valid, 'module_key': 'payments'}),
      throwsStateError,
    );
  });

  testWidgets(
    'transient diagnostic read error retries without exposing exception',
    (tester) async {
      var attempts = 0;
      await mount(
        tester,
        width: 390,
        access: module({'module.view', 'module.diagnostics'}),
        section: TechnicalObservabilitySection.diagnostics,
        diagnostics: (_) async {
          attempts++;
          if (attempts == 1) throw StateError('sensitive backend information');
          return diagnosticData();
        },
      );
      expect(find.textContaining('Technical data unavailable'), findsOneWidget);
      expect(
        find.textContaining('sensitive backend information'),
        findsNothing,
      );
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(find.textContaining('Effective: degraded'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
