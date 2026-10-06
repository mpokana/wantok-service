import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

class TechnicalAccessPage extends StatefulWidget {
  const TechnicalAccessPage({required this.modules, super.key});

  final List<TechnicalModuleAccess> modules;

  @override
  State<TechnicalAccessPage> createState() => _TechnicalAccessPageState();
}

class _TechnicalAccessPageState extends State<TechnicalAccessPage> {
  static const _repository = TechnicalControlRepository();

  final _searchController = TextEditingController();

  late String _moduleKey;
  late Future<_AccessData> _future;
  List<TechnicalAccountCandidate> _searchResults = const [];
  bool _searching = false;
  bool _mutating = false;

  @override
  void initState() {
    super.initState();
    _moduleKey = widget.modules.first.moduleKey;
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant TechnicalAccessPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final valid = widget.modules.any(
      (module) => module.moduleKey == _moduleKey,
    );
    if (!valid && widget.modules.isNotEmpty) {
      _moduleKey = widget.modules.first.moduleKey;
      _future = _load();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  TechnicalModuleAccess get _selectedModule =>
      widget.modules.firstWhere((module) => module.moduleKey == _moduleKey);

  Future<_AccessData> _load() async {
    final results = await Future.wait<dynamic>([
      _repository.loadAssignableAccessLevels(_moduleKey),
      _repository.loadModuleStaff(_moduleKey),
    ]);

    return _AccessData(
      levels: results[0] as List<TechnicalAccessLevelOption>,
      staff: results[1] as List<TechnicalModuleStaff>,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  void _changeModule(String? value) {
    if (value == null || value == _moduleKey) return;
    setState(() {
      _moduleKey = value;
      _searchController.clear();
      _searchResults = const [];
      _future = _load();
    });
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.length < 2 || _searching) return;

    setState(() => _searching = true);
    try {
      final results = await _repository.searchTechnicalAccounts(
        moduleKey: _moduleKey,
        query: query,
      );
      if (mounted) setState(() => _searchResults = results);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _assignCandidate(
    TechnicalAccountCandidate candidate,
    List<TechnicalAccessLevelOption> levels,
  ) async {
    if (_mutating || candidate.isPlatformAdmin) return;

    final draft = await showDialog<_AccessDraft>(
      context: context,
      builder: (context) => _AccessAssignmentDialog(
        title: candidate.currentAccessLevelCode == null
            ? 'Assign technical access'
            : 'Change technical access',
        personName: candidate.fullName,
        levels: levels,
        initialLevelCode: candidate.currentAccessLevelCode,
      ),
    );
    if (draft == null) return;

    await _grant(
      userId: candidate.userId,
      personName: candidate.fullName,
      draft: draft,
    );
  }

  Future<void> _changeStaff(
    TechnicalModuleStaff staff,
    List<TechnicalAccessLevelOption> levels,
  ) async {
    if (_mutating) return;

    final available = levels.any((level) => level.code == staff.accessLevelCode)
        ? levels
        : [
            TechnicalAccessLevelOption(
              code: staff.accessLevelCode,
              name: staff.accessLevelName,
              description: null,
              rank: staff.accessRank,
            ),
            ...levels,
          ];

    final draft = await showDialog<_AccessDraft>(
      context: context,
      builder: (context) => _AccessAssignmentDialog(
        title: 'Change technical access',
        personName: staff.fullName,
        levels: available,
        initialLevelCode: staff.accessLevelCode,
        initialNotes: staff.notes,
      ),
    );
    if (draft == null) return;

    await _grant(
      userId: staff.userId,
      personName: staff.fullName,
      draft: draft,
    );
  }

  Future<void> _grant({
    required String userId,
    required String personName,
    required _AccessDraft draft,
  }) async {
    setState(() => _mutating = true);
    try {
      await _repository.grantModuleAccess(
        userId: userId,
        moduleKey: _moduleKey,
        accessLevelCode: draft.accessLevelCode,
        notes: draft.notes,
      );
      await _refresh();
      if (mounted) {
        setState(() => _searchResults = const []);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Updated technical access for $personName.')),
        );
      }
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _revoke(TechnicalModuleStaff staff) async {
    if (_mutating) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke module access?'),
        content: Text(
          '${staff.fullName} will lose technical access to '
          '${_selectedModule.name}. Other module assignments are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Revoke access'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _mutating = true);
    try {
      final revoked = await _repository.revokeModuleAccess(
        userId: staff.userId,
        moduleKey: _moduleKey,
      );
      await _refresh();
      if (mounted && revoked) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Revoked access for ${staff.fullName}.')),
        );
      }
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(_friendlyError(error))));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AccessData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
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
                        Icons.manage_accounts_outlined,
                        size: 48,
                        color: WantokColors.coral,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Could not load technical access management',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _friendlyError(snapshot.error!),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
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
          );
        }

        final data = snapshot.data!;
        final module = _selectedModule;

        return ListView(
          padding: const EdgeInsets.all(28),
          children: [
            Text(
              'Technical access',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Assign technical staff per module. Access to one service does '
              'not grant access to unrelated services.',
              style: TextStyle(color: WantokColors.muted),
            ),
            const SizedBox(height: 22),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: DropdownButtonFormField<String>(
                initialValue: _moduleKey,
                decoration: const InputDecoration(
                  labelText: 'Service module',
                  prefixIcon: Icon(Icons.extension_outlined),
                ),
                items: widget.modules
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.moduleKey,
                        child: Text(item.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: _mutating ? null : _changeModule,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              module.moduleKey,
              style: const TextStyle(
                color: WantokColors.muted,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 24),
            _CurrentStaffSection(
              staff: data.staff,
              mutating: _mutating,
              maxAssignableRank: data.levels
                  .map((level) => level.rank)
                  .reduce((left, right) => left > right ? left : right),
              onChange: (staff) => _changeStaff(staff, data.levels),
              onRevoke: _revoke,
            ),
            const SizedBox(height: 26),
            Text(
              'Add staff',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Search an existing Wantok account by name or email. '
              'At least 2 characters are required.',
              style: TextStyle(color: WantokColors.muted),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _search(),
                      decoration: const InputDecoration(
                        labelText: 'Name or email',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _searching || _mutating ? null : _search,
                    icon: _searching
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.search),
                    label: const Text('Search'),
                  ),
                ],
              ),
            ),
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 14),
              ..._searchResults.map(
                (candidate) => _SearchResultCard(
                  candidate: candidate,
                  disabled: _mutating,
                  assignableLevelCodes: data.levels
                      .map((level) => level.code)
                      .toSet(),
                  onAssign: () => _assignCandidate(candidate, data.levels),
                ),
              ),
            ],
            const SizedBox(height: 18),
            const Card(
              color: Color(0xFFF4F7F5),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.security_outlined,
                      color: WantokColors.primaryDark,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Technical Platform Administrators have global '
                        'technical authority and are intentionally not managed '
                        'as ordinary module assignments on this screen.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CurrentStaffSection extends StatelessWidget {
  const _CurrentStaffSection({
    required this.staff,
    required this.mutating,
    required this.maxAssignableRank,
    required this.onChange,
    required this.onRevoke,
  });

  final List<TechnicalModuleStaff> staff;
  final bool mutating;
  final int maxAssignableRank;
  final ValueChanged<TechnicalModuleStaff> onChange;
  final ValueChanged<TechnicalModuleStaff> onRevoke;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Current staff',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 8),
            Chip(label: Text('${staff.length}')),
          ],
        ),
        const SizedBox(height: 10),
        if (staff.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(22),
              child: Row(
                children: [
                  Icon(Icons.person_off_outlined, color: WantokColors.muted),
                  SizedBox(width: 10),
                  Text('No direct staff assignments for this module.'),
                ],
              ),
            ),
          )
        else
          ...staff.map(
            (person) => Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFE2F3E9),
                      child: Text(_initials(person.fullName)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            person.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            person.email ?? 'No email',
                            style: const TextStyle(color: WantokColors.muted),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 7,
                            runSpacing: 5,
                            children: [
                              Chip(
                                visualDensity: VisualDensity.compact,
                                label: Text(person.accessLevelName),
                              ),
                              if (person.grantedByName != null)
                                Text(
                                  'Granted by ${person.grantedByName}',
                                  style: const TextStyle(
                                    color: WantokColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          if (person.notes?.trim().isNotEmpty == true)
                            Text(
                              person.notes!,
                              style: const TextStyle(
                                color: WantokColors.muted,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (person.accessRank > maxAssignableRank)
                      const Tooltip(
                        message: 'Equal or higher technical authority',
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.lock_outline,
                            color: WantokColors.muted,
                          ),
                        ),
                      )
                    else
                      PopupMenuButton<String>(
                        enabled: !mutating,
                        onSelected: (value) {
                          if (value == 'change') onChange(person);
                          if (value == 'revoke') onRevoke(person);
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'change',
                            child: ListTile(
                              leading: Icon(Icons.manage_accounts_outlined),
                              title: Text('Change access'),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'revoke',
                            child: ListTile(
                              leading: Icon(Icons.person_remove_outlined),
                              title: Text('Revoke access'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.candidate,
    required this.disabled,
    required this.assignableLevelCodes,
    required this.onAssign,
  });

  final TechnicalAccountCandidate candidate;
  final bool disabled;
  final Set<String> assignableLevelCodes;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final currentCode = candidate.currentAccessLevelCode;
    final protectedAssignment =
        currentCode != null && !assignableLevelCodes.contains(currentCode);

    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(_initials(candidate.fullName))),
        title: Text(
          candidate.fullName,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(candidate.email ?? 'No email'),
        trailing: candidate.isPlatformAdmin
            ? const Chip(label: Text('Platform Administrator'))
            : protectedAssignment
            ? const Chip(
                avatar: Icon(Icons.lock_outline, size: 16),
                label: Text('Protected'),
              )
            : candidate.currentAccessLevelName != null
            ? OutlinedButton.icon(
                onPressed: disabled ? null : onAssign,
                icon: const Icon(Icons.edit_outlined),
                label: Text(candidate.currentAccessLevelName!),
              )
            : FilledButton.icon(
                onPressed: disabled ? null : onAssign,
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('Assign'),
              ),
      ),
    );
  }
}

class _AccessAssignmentDialog extends StatefulWidget {
  const _AccessAssignmentDialog({
    required this.title,
    required this.personName,
    required this.levels,
    this.initialLevelCode,
    this.initialNotes,
  });

  final String title;
  final String personName;
  final List<TechnicalAccessLevelOption> levels;
  final String? initialLevelCode;
  final String? initialNotes;

  @override
  State<_AccessAssignmentDialog> createState() =>
      _AccessAssignmentDialogState();
}

class _AccessAssignmentDialogState extends State<_AccessAssignmentDialog> {
  late String _levelCode;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _levelCode =
        widget.initialLevelCode != null &&
            widget.levels.any((level) => level.code == widget.initialLevelCode)
        ? widget.initialLevelCode!
        : widget.levels.first.code;
    _notes = TextEditingController(text: widget.initialNotes ?? '');
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.levels.firstWhere((item) => item.code == _levelCode);

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.personName,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _levelCode,
              decoration: const InputDecoration(
                labelText: 'Access level',
                prefixIcon: Icon(Icons.admin_panel_settings_outlined),
              ),
              items: widget.levels
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.code,
                      child: Text(item.name),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) setState(() => _levelCode = value);
              },
            ),
            if (level.description != null) ...[
              const SizedBox(height: 8),
              Text(
                level.description!,
                style: const TextStyle(color: WantokColors.muted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Access note (optional)',
                hintText: 'Reason or responsibility for this assignment',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            _AccessDraft(
              accessLevelCode: _levelCode,
              notes: _emptyToNull(_notes.text),
            ),
          ),
          child: const Text('Save access'),
        ),
      ],
    );
  }
}

class _AccessData {
  const _AccessData({required this.levels, required this.staff});

  final List<TechnicalAccessLevelOption> levels;
  final List<TechnicalModuleStaff> staff;
}

class _AccessDraft {
  const _AccessDraft({required this.accessLevelCode, required this.notes});

  final String accessLevelCode;
  final String? notes;
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'W';
  if (parts.length == 1) {
    return parts.first
        .substring(0, parts.first.length > 1 ? 2 : 1)
        .toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _friendlyError(Object error) {
  final raw = error.toString();
  final messageMatch = RegExp(r'message:\s*([^,\)]+)').firstMatch(raw);
  if (messageMatch != null) return messageMatch.group(1)!.trim();
  return raw.replaceFirst('StateError: ', '');
}
