import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_tech/src/dashboard/technical_observability_page.dart';

TechnicalModuleAccess module(Set<String> permissions) => TechnicalModuleAccess(
  moduleKey: 'core.catalog',
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
      access: module({'module.jobs'}),
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
