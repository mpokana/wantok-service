import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

class TechnicalHealthPage extends StatefulWidget {
  const TechnicalHealthPage({required this.module, super.key});

  final TechnicalModuleAccess module;

  @override
  State<TechnicalHealthPage> createState() => _TechnicalHealthPageState();
}

class _TechnicalHealthPageState extends State<TechnicalHealthPage> {
  static const _repository = TechnicalControlRepository();

  late Future<_HealthBundle> _future;
  String? _busyProbeKey;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_HealthBundle> _load() async {
    final health = await _repository.loadModuleHealth(widget.module.moduleKey);
    final probes = await _repository.loadModuleHealthProbes(
      widget.module.moduleKey,
    );
    final dependencies = await _repository.loadModuleDependencies(
      widget.module.moduleKey,
    );
    final impact = await _repository.loadModuleImpact(widget.module.moduleKey);
    final history = await _repository.loadModuleHealthHistory(
      widget.module.moduleKey,
    );

    return _HealthBundle(
      health: health,
      probes: probes,
      dependencies: dependencies,
      impact: impact,
      history: history,
    );
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _future = next;
    });
    await next;
  }

  Future<void> _runProbe(TechnicalHealthProbe probe) async {
    if (_busyProbeKey != null) return;

    setState(() => _busyProbeKey = probe.probeKey);
    try {
      await _repository.runModuleHealthProbe(
        moduleKey: widget.module.moduleKey,
        probeKey: probe.probeKey,
      );
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${probe.name} completed.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _busyProbeKey = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.module.name} health',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_HealthBundle>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(error: snapshot.error!, onRetry: _refresh);
          }

          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _HealthSummaryCard(module: widget.module, health: data.health),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Dependencies',
                subtitle: 'Required dependencies can take this module down. Optional dependencies degrade it.',
                child: data.dependencies.isEmpty
                    ? const Text(
                        'No module dependencies are registered.',
                        style: TextStyle(color: WantokColors.muted),
                      )
                    : Column(
                        children: data.dependencies
                            .map(
                              (dependency) =>
                                  _DependencyRow(dependency: dependency),
                            )
                            .toList(growable: false),
                      ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Health probes & reporters',
                subtitle: 'Reported health comes from registered probes. Running a probe never executes arbitrary SQL or shell commands.',
                child: Column(
                  children: data.probes
                      .map(
                        (probe) => _ProbeRow(
                          probe: probe,
                          busy: _busyProbeKey == probe.probeKey,
                          onRun:
                              probe.canRun &&
                                  probe.isBuiltInRunnable &&
                                  _busyProbeKey == null
                              ? () => _runProbe(probe)
                              : null,
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: 14),
              _ImpactCard(impact: data.impact),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Health history',
                subtitle:
                    'Only reported/effective status transitions are recorded.',
                child: data.history.isEmpty
                    ? const Text(
                        'No health transitions have been recorded.',
                        style: TextStyle(color: WantokColors.muted),
                      )
                    : Column(
                        children: data.history
                            .map((entry) => _HistoryRow(entry: entry))
                            .toList(growable: false),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HealthBundle {
  const _HealthBundle({
    required this.health,
    required this.probes,
    required this.dependencies,
    required this.impact,
    required this.history,
  });

  final TechnicalModuleHealth health;
  final List<TechnicalHealthProbe> probes;
  final List<TechnicalModuleDependency> dependencies;
  final TechnicalModuleImpact impact;
  final List<TechnicalHealthHistoryEntry> history;
}

class _HealthSummaryCard extends StatelessWidget {
  const _HealthSummaryCard({required this.module, required this.health});

  final TechnicalModuleAccess module;
  final TechnicalModuleHealth health;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF8FAF9),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.monitor_heart_outlined,
                  color: WantokColors.primaryDark,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Module health',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                _HealthChip(
                  status: health.effectiveStatus,
                  prefix: 'Effective',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HealthChip(status: health.reportedStatus, prefix: 'Reported'),
                _StateChip(
                  icon: module.isEnabled
                      ? Icons.check_circle_outline
                      : Icons.pause_circle_outline,
                  label: module.isEnabled ? 'Enabled' : 'Disabled',
                ),
                if (module.maintenanceMode)
                  const _StateChip(
                    icon: Icons.build_circle_outlined,
                    label: 'Maintenance',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              health.summary ?? 'No health summary is available.',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              health.lastReportAt == null
                  ? 'No health report timestamp.'
                  : 'Last report: ${_dateLabel(health.lastReportAt!)}',
              style: const TextStyle(color: WantokColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            const Text(
              'Reported health reflects registered probes. Effective health also includes module state and transitive dependency impact.',
              style: TextStyle(color: WantokColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: WantokColors.muted)),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _DependencyRow extends StatelessWidget {
  const _DependencyRow({required this.dependency});

  final TechnicalModuleDependency dependency;

  @override
  Widget build(BuildContext context) {
    if (!dependency.isVisible) {
      return const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.lock_outline),
        title: Text(
          'Restricted dependency',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          'A dependency exists outside your visible technical scope.',
        ),
      );
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        dependency.failureEffect == 'down'
            ? Icons.link_off_outlined
            : Icons.link_outlined,
        color: dependency.failureEffect == 'down'
            ? WantokColors.coral
            : WantokColors.primaryDark,
      ),
      title: Text(
        dependency.name ?? dependency.moduleKey ?? 'Dependency',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${dependency.dependencyType} • failure effect: ${dependency.failureEffect}'
        '${dependency.maintenanceMode == true ? ' • maintenance' : ''}',
      ),
      trailing: dependency.effectiveStatus == null
          ? null
          : _HealthChip(status: dependency.effectiveStatus!),
    );
  }
}

class _ProbeRow extends StatelessWidget {
  const _ProbeRow({
    required this.probe,
    required this.busy,
    required this.onRun,
  });

  final TechnicalHealthProbe probe;
  final bool busy;
  final VoidCallback? onRun;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        probe.isStale ? Icons.schedule_outlined : Icons.sensors_outlined,
        color: probe.isStale ? WantokColors.coral : WantokColors.primaryDark,
      ),
      title: Text(
        probe.name,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        [
          probe.probeKind.replaceAll('_', ' '),
          if (probe.isRequired) 'required',
          if (probe.isStale) 'stale',
          if (probe.currentSummary != null) probe.currentSummary!,
        ].join(' • '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HealthChip(status: probe.currentStatus),
          if (onRun != null) ...[
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: busy ? null : onRun,
              icon: busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Run'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  const _ImpactCard({required this.impact});

  final TechnicalModuleImpact impact;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Dependent-module impact',
      subtitle: 'Shown before disable or maintenance actions so technical staff can assess blast radius.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            impact.impactedCount == 0
                ? 'No dependent modules are registered.'
                : '${impact.impactedCount} module(s) may be affected.',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          if (impact.hiddenImpactedCount > 0) ...[
            const SizedBox(height: 5),
            Text(
              '${impact.hiddenImpactedCount} impacted module(s) are outside your visible technical scope.',
              style: const TextStyle(color: WantokColors.muted),
            ),
          ],
          if (impact.visibleImpacted.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...impact.visibleImpacted.map(
              (item) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.account_tree_outlined),
                title: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  'Depth ${item.depth} • possible effect: ${item.failureEffect}',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final TechnicalHealthHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _HealthDot(status: entry.effectiveStatus),
      title: Row(
        children: [
          _HealthChip(status: entry.effectiveStatus, prefix: 'Effective'),
          const SizedBox(width: 7),
          _HealthChip(status: entry.reportedStatus, prefix: 'Reported'),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(
          '${entry.summary ?? entry.transitionReason}\n'
          '${entry.transitionReason} • ${_dateLabel(entry.recordedAt)}',
        ),
      ),
    );
  }
}

class _HealthChip extends StatelessWidget {
  const _HealthChip({required this.status, this.prefix});

  final String status;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    final color = _healthColor(status);
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(_healthIcon(status), size: 16, color: color),
      label: Text(
        prefix == null ? status : '$prefix: $status',
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _HealthDot extends StatelessWidget {
  const _HealthDot({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 15,
      backgroundColor: _healthColor(status).withValues(alpha: 0.12),
      child: Icon(_healthIcon(status), size: 17, color: _healthColor(status)),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: WantokColors.coral,
                  size: 52,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Could not load module health',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(_friendlyError(error), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _healthColor(String status) => switch (status) {
  'healthy' => WantokColors.primaryDark,
  'degraded' => const Color(0xFFB36A00),
  'down' => WantokColors.coral,
  _ => WantokColors.muted,
};

IconData _healthIcon(String status) => switch (status) {
  'healthy' => Icons.check_circle_outline,
  'degraded' => Icons.warning_amber_rounded,
  'down' => Icons.error_outline,
  _ => Icons.help_outline,
};

String _dateLabel(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}

String _friendlyError(Object error) {
  return error.toString().replaceFirst('PostgrestException(message: ', '');
}
