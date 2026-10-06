import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_auth/wantok_auth.dart';
import 'package:wantok_ui/wantok_ui.dart';

import 'technical_access_page.dart';
import 'technical_configuration_page.dart';
import 'technical_health_page.dart';

class TechnicalShell extends StatefulWidget {
  const TechnicalShell({required this.email, super.key});

  final String? email;

  @override
  State<TechnicalShell> createState() => _TechnicalShellState();
}

class _TechnicalShellState extends State<TechnicalShell> {
  static const _repository = TechnicalControlRepository();

  late Future<List<TechnicalModuleAccess>> _future;
  String? _selectedModuleKey;
  String? _busyModuleKey;
  bool _showAccessManagement = false;

  @override
  void initState() {
    super.initState();
    _future = _repository.loadModules();
  }

  Future<void> _refresh() async {
    final next = _repository.loadModules();
    setState(() {
      _future = next;
    });
    await next;
  }

  Future<void> _setModuleState(
    TechnicalModuleAccess module, {
    bool? enabled,
    bool? maintenanceMode,
  }) async {
    if (_busyModuleKey != null) return;
    setState(() => _busyModuleKey = module.moduleKey);

    try {
      await _repository.setModuleState(
        moduleKey: module.moduleKey,
        enabled: enabled,
        maintenanceMode: maintenanceMode,
      );
      await _refresh();

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Updated ${module.name}.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _busyModuleKey = null);
    }
  }

  Future<bool> _confirmImpactAction(
    TechnicalModuleAccess module, {
    required String title,
    required String actionLabel,
    required String description,
  }) async {
    TechnicalModuleImpact impact;
    try {
      impact = await _repository.loadModuleImpact(module.moduleKey);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not load dependency impact. ${_friendlyError(error)}',
            ),
          ),
        );
      }
      return false;
    }

    if (!mounted) return false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(description),
              const SizedBox(height: 14),
              if (impact.impactedCount == 0)
                const Text(
                  'No dependent modules are registered.',
                  style: TextStyle(fontWeight: FontWeight.w800),
                )
              else ...[
                Text(
                  '${impact.impactedCount} dependent module(s) may be affected.',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                for (final item in impact.visibleImpacted.take(8))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: [
                        const Icon(Icons.account_tree_outlined, size: 17),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text('${item.name} — ${item.failureEffect}'),
                        ),
                      ],
                    ),
                  ),
                if (impact.visibleImpacted.length > 8)
                  Text(
                    '+ ${impact.visibleImpacted.length - 8} more visible module(s)',
                    style: const TextStyle(color: WantokColors.muted),
                  ),
                if (impact.hiddenImpactedCount > 0)
                  Text(
                    '${impact.hiddenImpactedCount} additional impacted module(s) are outside your visible technical scope.',
                    style: const TextStyle(color: WantokColors.muted),
                  ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Review Health & dependencies for the full technical context before proceeding.',
                style: TextStyle(color: WantokColors.muted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );

    return confirmed == true;
  }

  Future<void> _toggleEnabled(TechnicalModuleAccess module) async {
    if (module.isEnabled) {
      final confirmed = await _confirmImpactAction(
        module,
        title: 'Disable ${module.name}?',
        actionLabel: 'Disable module',
        description:
            'Disabling this module makes its effective health down and may '
            'degrade or stop dependent modules.',
      );
      if (!confirmed) return;
    }

    await _setModuleState(module, enabled: !module.isEnabled);
  }

  Future<void> _setMaintenance(TechnicalModuleAccess module, bool value) async {
    if (value) {
      final confirmed = await _confirmImpactAction(
        module,
        title: 'Put ${module.name} into maintenance?',
        actionLabel: 'Start maintenance',
        description:
            'Maintenance intentionally degrades this module and can affect '
            'services that depend on it.',
      );
      if (!confirmed) return;
    }

    await _setModuleState(module, maintenanceMode: value);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TechnicalModuleAccess>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Wantok Technical Control')),
            body: Center(
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
                          'Could not load technical modules',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _friendlyError(snapshot.error!),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final modules = snapshot.data ?? const <TechnicalModuleAccess>[];

        if (modules.isEmpty) {
          return Scaffold(
            appBar: _buildAppBar(),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'Your technical account is valid, but no service modules '
                  'are currently assigned to it.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final selected = _selectedModuleKey == null
            ? null
            : modules.cast<TechnicalModuleAccess?>().firstWhere(
                (module) => module?.moduleKey == _selectedModuleKey,
                orElse: () => null,
              );
        final manageableModules = modules
            .where((module) => module.hasPermission('module.permissions'))
            .toList(growable: false);

        final wide = MediaQuery.sizeOf(context).width >= 980;
        final content = _showAccessManagement && manageableModules.isNotEmpty
            ? TechnicalAccessPage(modules: manageableModules)
            : selected == null
            ? _OverviewPage(modules: modules)
            : _ModuleWorkspace(
                module: selected,
                busy: _busyModuleKey == selected.moduleKey,
                onToggleEnabled: () => _toggleEnabled(selected),
                onMaintenanceChanged: (value) =>
                    _setMaintenance(selected, value),
              );

        if (wide) {
          return Scaffold(
            appBar: _buildAppBar(),
            body: Row(
              children: [
                SizedBox(
                  width: 292,
                  child: _TechnicalSidebar(
                    modules: modules,
                    selectedModuleKey: _selectedModuleKey,
                    accessManagementSelected: _showAccessManagement,
                    onOverview: () {
                      setState(() {
                        _showAccessManagement = false;
                        _selectedModuleKey = null;
                      });
                    },
                    onAccessManagement: () {
                      setState(() {
                        _showAccessManagement = true;
                        _selectedModuleKey = null;
                      });
                    },
                    onModule: (key) {
                      setState(() {
                        _showAccessManagement = false;
                        _selectedModuleKey = key;
                      });
                    },
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(),
          drawer: Drawer(
            child: SafeArea(
              child: _TechnicalSidebar(
                modules: modules,
                selectedModuleKey: _selectedModuleKey,
                accessManagementSelected: _showAccessManagement,
                onOverview: () {
                  setState(() {
                    _showAccessManagement = false;
                    _selectedModuleKey = null;
                  });
                  Navigator.of(context).pop();
                },
                onAccessManagement: () {
                  setState(() {
                    _showAccessManagement = true;
                    _selectedModuleKey = null;
                  });
                  Navigator.of(context).pop();
                },
                onModule: (key) {
                  setState(() {
                    _showAccessManagement = false;
                    _selectedModuleKey = key;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
          body: content,
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.settings_input_component_outlined,
            color: WantokColors.primaryDark,
          ),
          SizedBox(width: 9),
          Text(
            'Wantok Technical Control',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
      actions: [
        if (widget.email != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              child: Text(
                widget.email!,
                style: const TextStyle(color: WantokColors.muted),
              ),
            ),
          ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: 'Sign out',
          onPressed: () => const WantokAuthService().signOut(),
          icon: const Icon(Icons.logout),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _TechnicalSidebar extends StatelessWidget {
  const _TechnicalSidebar({
    required this.modules,
    required this.selectedModuleKey,
    required this.accessManagementSelected,
    required this.onOverview,
    required this.onAccessManagement,
    required this.onModule,
  });

  final List<TechnicalModuleAccess> modules;
  final String? selectedModuleKey;
  final bool accessManagementSelected;
  final VoidCallback onOverview;
  final VoidCallback onAccessManagement;
  final ValueChanged<String> onModule;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<TechnicalModuleAccess>>{};
    for (final module in modules) {
      groups.putIfAbsent(module.groupCode, () => []).add(module);
    }
    final canManageAccess = modules.any(
      (module) => module.hasPermission('module.permissions'),
    );

    return Material(
      color: const Color(0xFFF8FAF9),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 24),
        children: [
          _SideTile(
            icon: Icons.dashboard_outlined,
            label: 'Overview',
            selected: selectedModuleKey == null && !accessManagementSelected,
            onTap: onOverview,
          ),
          if (canManageAccess)
            _SideTile(
              icon: Icons.manage_accounts_outlined,
              label: 'Technical access',
              selected: accessManagementSelected,
              onTap: onAccessManagement,
            ),
          const SizedBox(height: 12),
          for (final entry in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
              child: Text(
                _groupLabel(entry.key).toUpperCase(),
                style: const TextStyle(
                  color: WantokColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.9,
                ),
              ),
            ),
            for (final module in entry.value)
              _SideTile(
                icon: _moduleIcon(module.moduleKey),
                label: module.name,
                selected: selectedModuleKey == module.moduleKey,
                trailing: module.maintenanceMode
                    ? const Icon(
                        Icons.build_circle_outlined,
                        size: 16,
                        color: WantokColors.coral,
                      )
                    : !module.isEnabled
                    ? const Icon(
                        Icons.pause_circle_outline,
                        size: 16,
                        color: WantokColors.muted,
                      )
                    : null,
                onTap: () => onModule(module.moduleKey),
              ),
          ],
        ],
      ),
    );
  }
}

class _SideTile extends StatelessWidget {
  const _SideTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      selectedTileColor: const Color(0xFFDCEFE4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon, size: 21),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
          fontSize: 14,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _OverviewPage extends StatelessWidget {
  const _OverviewPage({required this.modules});

  final List<TechnicalModuleAccess> modules;

  @override
  Widget build(BuildContext context) {
    final enabled = modules.where((module) => module.isEnabled).length;
    final maintenance = modules
        .where((module) => module.maintenanceMode)
        .length;
    final platformAdmin = modules.any(
      (module) => module.accessLevelCode == 'tech_platform_admin',
    );

    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        Text(
          'Technical overview',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Only service modules within your effective technical scope are shown.',
          style: TextStyle(color: WantokColors.muted),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _MetricCard(
              icon: Icons.extension_outlined,
              value: '${modules.length}',
              label: 'Visible modules',
            ),
            _MetricCard(
              icon: Icons.check_circle_outline,
              value: '$enabled',
              label: 'Enabled',
            ),
            _MetricCard(
              icon: Icons.build_outlined,
              value: '$maintenance',
              label: 'Maintenance',
            ),
          ],
        ),
        if (platformAdmin) ...[
          const SizedBox(height: 20),
          const Card(
            color: Color(0xFFEAF5EF),
            child: ListTile(
              leading: Icon(
                Icons.security_outlined,
                color: WantokColors.primaryDark,
              ),
              title: Text(
                'Technical Platform Administrator',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                'You have cross-module technical authority. '
                'Operations administration remains a separate authority plane.',
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        Text(
          'Module scope',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width >= 1050
                ? 3
                : width >= 680
                ? 2
                : 1;
            final cardWidth = (width - ((columns - 1) * 12)) / columns;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: modules
                  .map(
                    (module) => SizedBox(
                      width: cardWidth,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _moduleIcon(module.moduleKey),
                                    color: WantokColors.primaryDark,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      module.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _accessLabel(module.accessLevelCode),
                                style: const TextStyle(
                                  color: WantokColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _StateSummary(module: module),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }
}

class _ModuleWorkspace extends StatelessWidget {
  const _ModuleWorkspace({
    required this.module,
    required this.busy,
    required this.onToggleEnabled,
    required this.onMaintenanceChanged,
  });

  final TechnicalModuleAccess module;
  final bool busy;
  final VoidCallback onToggleEnabled;
  final ValueChanged<bool> onMaintenanceChanged;

  @override
  Widget build(BuildContext context) {
    final canEnable = module.hasPermission(
      module.isEnabled ? 'module.disable' : 'module.enable',
    );
    final canMaintenance = module.hasPermission('module.maintenance');

    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFFE2F3E9),
              child: Icon(
                _moduleIcon(module.moduleKey),
                color: WantokColors.primaryDark,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.name,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    module.moduleKey,
                    style: const TextStyle(
                      color: WantokColors.muted,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (module.description != null) ...[
                    const SizedBox(height: 9),
                    Text(module.description!),
                  ],
                ],
              ),
            ),
            Chip(
              avatar: const Icon(Icons.admin_panel_settings_outlined, size: 17),
              label: Text(_accessLabel(module.accessLevelCode)),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Module state',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                _StateSummary(module: module),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (canEnable)
                      OutlinedButton.icon(
                        onPressed: busy ? null : onToggleEnabled,
                        icon: Icon(
                          module.isEnabled
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                        ),
                        label: Text(
                          module.isEnabled ? 'Disable module' : 'Enable module',
                        ),
                      ),
                    if (canMaintenance)
                      SizedBox(
                        width: 310,
                        child: SwitchListTile(
                          value: module.maintenanceMode,
                          onChanged: busy ? null : onMaintenanceChanged,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          title: const Text('Maintenance mode'),
                          subtitle: const Text(
                            'Use during controlled technical maintenance.',
                          ),
                        ),
                      ),
                  ],
                ),
                if (!canEnable && !canMaintenance)
                  const Text(
                    'Your access is read-only for module state.',
                    style: TextStyle(color: WantokColors.muted),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (module.hasPermission('module.view'))
          _CapabilityCard(
            icon: Icons.monitor_heart_outlined,
            title: 'Health & dependencies',
            description:
                'Review reported/effective health, registered probes, '
                'dependency impact and transition history.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => TechnicalHealthPage(module: module),
                ),
              );
            },
          ),
        if (module.hasPermission('module.view'))
          _CapabilityCard(
            icon: Icons.tune_outlined,
            title: 'Configuration',
            description: module.hasPermission('module.configure')
                ? 'Open and edit the versioned, typed configuration schema.'
                : 'Inspect the effective typed configuration in read-only mode.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) =>
                      TechnicalConfigurationPage(module: module),
                ),
              );
            },
          ),
        if (module.hasPermission('module.diagnostics'))
          const _CapabilityCard(
            icon: Icons.monitor_heart_outlined,
            title: 'Diagnostics',
            description: 'Diagnostic access is authorised. Richer diagnostic adapters belong to T2.4; health and dependency reporting is available separately.',
          ),
        if (module.hasPermission('module.logs'))
          const _CapabilityCard(
            icon: Icons.subject_outlined,
            title: 'Logs',
            description: 'Log access is authorised. Central log-source adapters are not yet connected.',
          ),
        if (module.hasPermission('module.jobs'))
          const _CapabilityCard(
            icon: Icons.work_history_outlined,
            title: 'Background jobs',
            description: 'Job operations are authorised. Queue/job providers will be connected per module.',
          ),
        if (module.hasPermission('module.integrations'))
          const _CapabilityCard(
            icon: Icons.hub_outlined,
            title: 'Integrations',
            description: 'Integration administration is authorised. Secret values will remain protected from ordinary UI display.',
          ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Effective permissions',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: module.permissionCodes
                      .map((permission) => Chip(label: Text(permission)))
                      .toList(growable: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CapabilityCard extends StatelessWidget {
  const _CapabilityCard({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: Icon(icon, color: WantokColors.primaryDark),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(description),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Icon(icon, color: WantokColors.primaryDark, size: 30),
              const SizedBox(width: 13),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(color: WantokColors.muted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateSummary extends StatelessWidget {
  const _StateSummary({required this.module});

  final TechnicalModuleAccess module;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatusChip(
          icon: module.isEnabled
              ? Icons.check_circle_outline
              : Icons.pause_circle_outline,
          label: module.isEnabled ? 'Enabled' : 'Disabled',
        ),
        if (module.maintenanceMode)
          const _StatusChip(
            icon: Icons.build_circle_outlined,
            label: 'Maintenance',
          ),
        _StatusChip(
          icon: Icons.monitor_heart_outlined,
          label: 'Effective health: ${module.healthStatus}',
        ),
        if (module.version != null)
          _StatusChip(icon: Icons.commit_outlined, label: 'v${module.version}'),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 17),
      label: Text(label),
    );
  }
}

String _groupLabel(String value) {
  return switch (value) {
    'core' => 'Core platform',
    'mobility' => 'Mobility',
    'hire' => 'Hire',
    'marketplace' => 'Marketplace',
    'places' => 'Places',
    'commerce' => 'Commerce',
    'logistics' => 'Logistics',
    'platform' => 'Platform services',
    _ => value.replaceAll('_', ' '),
  };
}

String _accessLabel(String value) {
  return switch (value) {
    'tech_platform_admin' => 'Platform Administrator',
    'tech_admin' => 'Technical Administrator',
    'tech_module_admin' => 'Module Administrator',
    'tech_support' => 'Technical Support',
    'tech_auditor' => 'Technical Auditor',
    _ => value.replaceAll('_', ' '),
  };
}

IconData _moduleIcon(String key) {
  if (key.startsWith('mobility.')) return Icons.directions_car_outlined;
  if (key.startsWith('hire.')) return Icons.key_outlined;
  if (key.startsWith('commerce.')) return Icons.storefront_outlined;
  if (key.startsWith('marketplace.')) return Icons.handyman_outlined;
  if (key.startsWith('places.')) return Icons.location_city_outlined;

  return switch (key) {
    'core.identity' => Icons.manage_accounts_outlined,
    'core.account' => Icons.account_circle_outlined,
    'core.catalog' => Icons.category_outlined,
    'core.messaging' => Icons.chat_bubble_outline,
    'events' => Icons.event_outlined,
    'delivery' => Icons.local_shipping_outlined,
    'errands' => Icons.shopping_bag_outlined,
    'payments' => Icons.account_balance_wallet_outlined,
    'notifications' => Icons.notifications_outlined,
    'audit' => Icons.history_outlined,
    _ => Icons.extension_outlined,
  };
}

String _friendlyError(Object error) {
  return error
      .toString()
      .replaceFirst('StateError: ', '')
      .replaceFirst('PostgrestException(message: ', '');
}
