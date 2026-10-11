import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';

/// Real, redacted module-level Technical change history, not central logs.
/// The PostgreSQL adapter requires module.view + module.logs.
typedef TechnicalActivityLoader = Future<List<TechnicalActivityEvent>> Function(
  String moduleKey,
);

class TechnicalActivityPage extends StatefulWidget {
  const TechnicalActivityPage({
    super.key,
    required this.module,
    this.loadActivity,
  });

  final TechnicalModuleAccess module;
  final TechnicalActivityLoader? loadActivity;

  @override
  State<TechnicalActivityPage> createState() => _TechnicalActivityPageState();
}

class _TechnicalActivityPageState extends State<TechnicalActivityPage> {
  static const _repository = TechnicalControlRepository();
  Future<List<TechnicalActivityEvent>>? _future;

  bool get _allowed =>
      widget.module.hasPermission('module.view') &&
      widget.module.hasPermission('module.logs');

  Future<List<TechnicalActivityEvent>> _load() =>
      (widget.loadActivity ?? _repository.loadModuleActivity)(
        widget.module.moduleKey,
      );

  void _refresh() {
    if (!_allowed) return;
    final next = _load();
    setState(() {
      _future = next;
    });
  }

  @override
  void initState() {
    super.initState();
    if (_allowed) _future = _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('${widget.module.name} · Technical activity'),
      actions: [
        if (_allowed)
          IconButton(
            key: const ValueKey('t24-activity-refresh'),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh technical activity',
            onPressed: _refresh,
          ),
      ],
    ),
    body: !_allowed
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Technical activity access is not assigned to your account.',
              ),
            ),
          )
        : FutureBuilder<List<TechnicalActivityEvent>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 36),
                      const SizedBox(height: 12),
                      const Text(
                        'Technical activity unavailable. No changes were made.',
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _refresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              final events = (snapshot.data ?? const <TechnicalActivityEvent>[])
                  .take(30)
                  .toList(growable: false);
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 950),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Read-only · Actual Technical Control changes for '
                            'this module only. Source: restricted audit_events '
                            'actions. Actor names, access targets, raw metadata, '
                            'request identifiers and customer events are hidden. '
                            'This is not an application/container log feed.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Recent technical changes (${events.length}, maximum 30)',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (events.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(18),
                            child: Text(
                              'No eligible technical changes were returned. '
                              'This does not prove an absence of other events.',
                            ),
                          ),
                        ),
                      for (final e in events)
                        Card(
                          child: ListTile(
                            key: ValueKey('t24-activity-${e.id}'),
                            leading: const Icon(Icons.manage_history_outlined),
                            title: Text(_label(e.actionCode)),
                            subtitle: Text(
                              'Recorded UTC: '
                              '${e.occurredAt.toUtc().toIso8601String()}',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
  );

  String _label(String code) => switch (code) {
    'technical_module_state_changed' => 'Module state changed',
    'technical_module_configuration_changed' => 'Configuration changed',
    'technical_module_access_granted' => 'Technical access granted',
    'technical_module_access_revoked' => 'Technical access revoked',
    _ => 'Approved technical event',
  };
}
