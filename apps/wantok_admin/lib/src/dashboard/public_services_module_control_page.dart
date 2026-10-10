import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

/// Operations-only visibility control. All writes are protected again by
/// Supabase RBAC in admin_set_public_services_enabled(), and audited there.
class PublicServicesModuleControlPage extends StatefulWidget {
  const PublicServicesModuleControlPage({
    this.loadEnabled,
    this.saveEnabled,
    super.key,
  });

  final Future<bool> Function()? loadEnabled;
  final Future<bool> Function(bool enabled)? saveEnabled;

  @override
  State<PublicServicesModuleControlPage> createState() =>
      _PublicServicesModuleControlPageState();
}

class _PublicServicesModuleControlPageState
    extends State<PublicServicesModuleControlPage> {
  late Future<bool> _status;
  bool _saving = false;

  Future<bool> _load() async {
    if (widget.loadEnabled case final injected?) return injected();
    final rows = await WantokBackend.client
        .from('service_categories')
        .select('is_active')
        .eq('slug', 'public-services')
        .limit(1);
    if (rows.isEmpty) {
      throw StateError('Public Services is not installed in the database.');
    }
    return rows.first['is_active'] as bool;
  }

  Future<bool> _save(bool enabled) async {
    if (widget.saveEnabled case final injected?) return injected(enabled);
    final result = await WantokBackend.client.rpc(
      'admin_set_public_services_enabled',
      params: {'p_enabled': enabled},
    );
    return result == true;
  }

  @override
  void initState() {
    super.initState();
    _status = _load();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _status = _load();
    });
  }

  Future<void> _toggle(bool enabled) async {
    if (_saving) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          enabled ? 'Enable Public Services?' : 'Disable Public Services?',
        ),
        content: Text(
          enabled
              ? 'The Public Services tile will appear on Home and Services after clients refresh.'
              : 'The Public Services tile will disappear from Home and Services after clients refresh. Other services are unaffected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(enabled ? 'Enable' : 'Disable'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() => _saving = true);
    try {
      final actual = await _save(enabled);
      if (!mounted) return;
      setState(() {
        _status = Future<bool>.value(actual);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            actual ? 'Public Services enabled.' : 'Public Services disabled.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not change Public Services: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    key: const ValueKey('admin-module-controls'),
    padding: const EdgeInsets.all(20),
    children: [
      Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modules',
                  style: TextStyle(
                    color: WantokColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 25,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Control which information modules appear to Wantok customers.',
                  style: TextStyle(color: WantokColors.muted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh module settings',
            onPressed: _saving ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FutureBuilder<bool>(
            future: _status,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const ListTile(
                  title: Text('Public Services'),
                  subtitle: Text('Loading module status...'),
                  trailing: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              if (snapshot.hasError) {
                return ListTile(
                  title: const Text('Public Services'),
                  subtitle: Text('Unable to load: ${snapshot.error}'),
                  trailing: IconButton(
                    tooltip: 'Retry module status',
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                );
              }
              final enabled = snapshot.data == true;
              return SwitchListTile.adaptive(
                key: const ValueKey('admin-public-services-toggle'),
                value: enabled,
                onChanged: _saving ? null : _toggle,
                secondary: const Icon(
                  Icons.account_balance_rounded,
                  color: WantokColors.primaryDark,
                  size: 34,
                ),
                title: const Text(
                  'Public Services',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  enabled
                      ? 'Enabled — visible on Home and Services'
                      : 'Disabled — hidden from Home and Services',
                ),
              );
            },
          ),
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Public Services is a directory module. This switch does not authorise '
        'emergency dispatch, government transactions, provider verification or payments. '
        'Changes are restricted to administrators and recorded in the audit log.',
        style: TextStyle(color: WantokColors.muted, fontSize: 12),
      ),
    ],
  );
}
