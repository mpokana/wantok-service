import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

/// T2.4 foundation: only trusted, module-scoped read RPCs are used here.
/// No raw server log lines, credentials, arbitrary job payloads or commands.
enum TechnicalObservabilitySection { diagnostics, logs, jobs }

class TechnicalDiagnosticSnapshot {
  const TechnicalDiagnosticSnapshot({
    required this.health,
    required this.probes,
    required this.dependencies,
  });

  final TechnicalModuleHealth health;
  final List<TechnicalHealthProbe> probes;
  final List<TechnicalModuleDependency> dependencies;
}

typedef DiagnosticLoader = Future<TechnicalDiagnosticSnapshot> Function(
  String moduleKey,
);
typedef TransitionLoader = Future<List<TechnicalHealthHistoryEntry>> Function(
  String moduleKey,
);
typedef QueueLoader = Future<TechnicalQueueSnapshot> Function(String moduleKey);

class TechnicalObservabilityPage extends StatefulWidget {
  const TechnicalObservabilityPage({
    super.key,
    required this.module,
    required this.section,
    this.loadDiagnostics,
    this.loadTransitions,
    this.loadQueue,
  });

  final TechnicalModuleAccess module;
  final TechnicalObservabilitySection section;
  final DiagnosticLoader? loadDiagnostics;
  final TransitionLoader? loadTransitions;
  final QueueLoader? loadQueue;

  @override
  State<TechnicalObservabilityPage> createState() =>
      _TechnicalObservabilityPageState();
}

class _TechnicalObservabilityPageState
    extends State<TechnicalObservabilityPage> {
  static const _repository = TechnicalControlRepository();
  Future<Object>? _current;

  bool get _allowed => switch (widget.section) {
    TechnicalObservabilitySection.diagnostics =>
      widget.module.hasPermission('module.view') &&
          widget.module.hasPermission('module.diagnostics'),
    TechnicalObservabilitySection.logs =>
      widget.module.hasPermission('module.view') &&
          widget.module.hasPermission('module.logs'),
    TechnicalObservabilitySection.jobs =>
      widget.module.hasPermission('module.view') &&
          widget.module.hasPermission('module.jobs'),
  };

  String get _title => switch (widget.section) {
    TechnicalObservabilitySection.diagnostics => 'Diagnostics',
    TechnicalObservabilitySection.logs => 'Module logs',
    TechnicalObservabilitySection.jobs => 'Background jobs',
  };

  Future<TechnicalDiagnosticSnapshot> _readDiagnostics(String key) async {
    final results = await Future.wait<Object>([
      _repository.loadModuleHealth(key),
      _repository.loadModuleHealthProbes(key),
      _repository.loadModuleDependencies(key),
    ]);
    return TechnicalDiagnosticSnapshot(
      health: results[0] as TechnicalModuleHealth,
      probes: results[1] as List<TechnicalHealthProbe>,
      dependencies: results[2] as List<TechnicalModuleDependency>,
    );
  }

  Future<Object> _load() => switch (widget.section) {
    TechnicalObservabilitySection.diagnostics =>
      (widget.loadDiagnostics ?? _readDiagnostics)(widget.module.moduleKey),
    TechnicalObservabilitySection.logs =>
      (widget.loadTransitions ??
          (key) => _repository.loadModuleLogEvents(key, limit: 30))(
        widget.module.moduleKey,
      ),
    TechnicalObservabilitySection.jobs =>
      widget.module.moduleKey == 'core.messaging'
          ? (widget.loadQueue ?? _repository.loadMessagingQueueSnapshot)(
              widget.module.moduleKey,
            )
          : Future<Object>.value(const _NoQueueAdapter()),
  };

  void _refresh() {
    if (!_allowed) return;
    final next = _load();
    setState(() {
      _current = next;
    });
  }

  @override
  void initState() {
    super.initState();
    if (_allowed) _current = _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('${widget.module.name} · $_title'),
      actions: [
        if (_allowed &&
            (widget.section != TechnicalObservabilitySection.jobs ||
                widget.module.moduleKey == 'core.messaging'))
          IconButton(
            key: const ValueKey('t24-refresh'),
            tooltip: 'Refresh read-only view',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
      ],
    ),
    body: !_allowed
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'This module capability is not assigned to your technical account.',
              ),
            ),
          )
        : FutureBuilder<Object>(
            future: _current,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 40),
                        const SizedBox(height: 12),
                        const Text(
                          'Technical data unavailable. No changes were made.',
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: _refresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _InfoPanel(
                        icon: Icons.lock_outline,
                        text:
                            'Read-only · ${widget.module.moduleKey} · '
                            'Data is scoped to your existing technical access. '
                            'No job execution or configuration changes are available here.',
                      ),
                      const SizedBox(height: 14),
                      if (snapshot.data is TechnicalDiagnosticSnapshot)
                        _diagnostics(
                          snapshot.data! as TechnicalDiagnosticSnapshot,
                        ),
                      if (snapshot.data is List<TechnicalHealthHistoryEntry>)
                        _transitions(
                          snapshot.data! as List<TechnicalHealthHistoryEntry>,
                        ),
                      if (snapshot.data is TechnicalQueueSnapshot)
                        _queue(snapshot.data! as TechnicalQueueSnapshot),
                      if (snapshot.data is _NoQueueAdapter)
                        const _InfoPanel(
                          icon: Icons.hourglass_empty_outlined,
                          text:
                              'No background queue adapter is connected for this module. '
                              'Job counts, execution status, retries and controls are unavailable; '
                              'zero jobs must not be inferred.',
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
  );

  Widget _diagnostics(TechnicalDiagnosticSnapshot data) {
    final health = data.health;
    final observed =
        health.lastReportAt?.toUtc().toIso8601String() ?? 'not reported';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Health snapshot'),
        Card(
          child: ListTile(
            title: Text('Effective: ${health.effectiveStatus}'),
            subtitle: Text(
              'Reported: ${health.reportedStatus} · Last report UTC: $observed',
            ),
            trailing: const Icon(Icons.monitor_heart_outlined),
          ),
        ),
        const SizedBox(height: 12),
        _heading('Registered diagnostic probes (${data.probes.length})'),
        if (data.probes.isEmpty)
          const _InfoPanel(
            icon: Icons.info_outline,
            text:
                'No registered probes were returned. Health is not assumed OK.',
          ),
        for (final probe in data.probes)
          Card(
            child: ListTile(
              title: Text(probe.name),
              subtitle: Text(
                '${probe.probeKind} · '
                '${probe.isStale ? 'stale' : 'current'} · '
                '${probe.isEnabled ? 'enabled' : 'disabled'}',
              ),
              trailing: Text(probe.currentStatus),
            ),
          ),
        const SizedBox(height: 12),
        _heading('Dependencies (${data.dependencies.length})'),
        if (data.dependencies.isEmpty)
          const Text('No dependencies returned by the module adapter.'),
        for (final dependency in data.dependencies)
          Card(
            child: ListTile(
              title: Text(
                dependency.isVisible
                    ? (dependency.name ?? 'Visible dependency')
                    : 'Restricted dependency',
              ),
              subtitle: Text(
                dependency.isVisible
                    ? '${dependency.dependencyType} · '
                          '${dependency.effectiveStatus ?? 'unknown'}'
                    : 'Dependency details are outside your permitted scope.',
              ),
            ),
          ),
      ],
    );
  }

  Widget _queue(TechnicalQueueSnapshot data) {
    final observed = data.observedAt.toUtc().toIso8601String();
    final last = data.lastActivityAt?.toUtc().toIso8601String() ?? 'none';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InfoPanel(
          icon: Icons.mark_email_read_outlined,
          text:
              'Connected source: Messaging notification outbox status totals only. '
              'Processing means database status, NOT confirmed worker activity. '
              'Sent is a recorded status, NOT independent delivery proof. '
              'No recipient identifiers, messages, actions or retry controls are exposed.',
        ),
        const SizedBox(height: 14),
        _heading('Messaging notification queue'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Observed UTC: $observed'),
                Text('Last outbox update UTC: $last'),
                const SizedBox(height: 10),
                Text(
                  'Total records: ${data.total}',
                  key: const ValueKey('t24-queue-total'),
                ),
                Text('Pending: ${data.pending}'),
                Text('Processing status: ${data.processing}'),
                Text('Sent status: ${data.sent}'),
                Text('Failed: ${data.failed}'),
                Text('Cancelled: ${data.cancelled}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (data.total == 0)
          const Text('The outbox contains no records at the observation time.'),
      ],
    );
  }

  Widget _transitions(List<TechnicalHealthHistoryEntry> records) {
    // Existing module health transitions are NOT a general application log.
    // The adapter enforces a bounded 30-item server read.
    final entries = records.take(30).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InfoPanel(
          icon: Icons.subject_outlined,
          text:
              'Connected source: module health-transition history only. '
              'Central application, security and container logs are NOT connected. '
              'A missing event does not imply a healthy system.',
        ),
        const SizedBox(height: 14),
        _heading('Recent health transitions (${entries.length}, maximum 30)'),
        if (entries.isEmpty)
          const Text('No module health transitions were returned.'),
        for (final item in entries)
          Card(
            child: ListTile(
              title: Text(
                '${item.previousEffectiveStatus ?? 'unknown'} → '
                '${item.effectiveStatus}',
              ),
              subtitle: Text(
                '${item.transitionReason} · '
                '${item.recordedAt.toUtc().toIso8601String()} UTC',
              ),
              trailing: const Icon(Icons.history_outlined),
            ),
          ),
      ],
    );
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
    ),
  );
}

class _NoQueueAdapter {
  const _NoQueueAdapter();
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: WantokColors.primaryDark),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    ),
  );
}
