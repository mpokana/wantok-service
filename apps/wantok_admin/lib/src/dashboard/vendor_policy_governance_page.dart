import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

/// International vendor policy drafting only.
/// This screen cannot publish a policy, accept private documents or issue KYC.
class VendorPolicyGovernancePage extends StatefulWidget {
  const VendorPolicyGovernancePage({
    super.key,
    this.loadPolicies,
    this.loadMyDuties,
    this.createDraft,
    this.reviseDraft,
    this.userIdOverride,
    this.submitDraft,
    this.reviewDraft,
  });
  final Future<List<Map<String, dynamic>>> Function()? loadPolicies;
  final Future<List<Map<String, dynamic>>> Function()? loadMyDuties;
  final Future<void> Function(Map<String, dynamic>)? createDraft;
  final Future<void> Function(String, Map<String, dynamic>)? reviseDraft;
  final String? userIdOverride;
  final Future<void> Function(String)? submitDraft;
  final Future<void> Function(String, String, String)? reviewDraft;
  @override
  State<VendorPolicyGovernancePage> createState() =>
      _VendorPolicyGovernancePageState();
}

class _VendorPolicyGovernancePageState
    extends State<VendorPolicyGovernancePage> {
  List<Map<String, dynamic>> _duties = [];
  late Future<List<Map<String, dynamic>>> _future = _load();
  String? _busy;
  String _filter = 'all';
  final _country = TextEditingController(text: 'PG');
  final _region = TextEditingController();
  final _title = TextEditingController();
  final _notice = TextEditingController();
  final _purpose = TextEditingController();
  final _legal = TextEditingController();
  final _retention = TextEditingController(text: '180');
  final _requirements = TextEditingController();
  String _scope = 'all';
  String? _revisingPolicyId;
  final _formKey = GlobalKey<FormState>();
  @override
  void dispose() {
    for (final x in [
      _country,
      _region,
      _title,
      _notice,
      _purpose,
      _legal,
      _retention,
      _requirements,
    ]) {
      x.dispose();
    }
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    if (widget.loadPolicies != null) {
      // Test-only loaders also inject duties; production always uses server RLS.
      _duties = await (widget.loadMyDuties?.call() ?? Future.value([]));
      return widget.loadPolicies!();
    }
    final grants = await WantokBackend.client
        .from('operations_duty_grants')
        .select('duty,country_code,region_code,category_scope,'
            'issued_at,expires_at,revoked_at');
    _duties = (grants as List)
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList();
    final rows = await WantokBackend.client
        .from('vendor_policy_drafts')
        .select(
          'id,country_code,region_code,category_scope,revision,notice_title,'
          'notice_body,collection_purpose,legal_basis_notes,retention_days,'
          'evidence_requirements,state,created_by,reviewer_id,reviewer_notes,'
          'replaces_policy_id,'
          'submitted_at,reviewed_at,created_at',
        )
        .order('created_at', ascending: false)
        .limit(150);
    return (rows as List)
        .map((x) => Map<String, dynamic>.from(x as Map))
        .toList();
  }

  bool _hasDuty(String duty, String country, String? region, String category) {
    final now = DateTime.now().toUtc();
    return _duties.any((grant) {
      final expiry = DateTime.tryParse(grant['expires_at']?.toString() ?? '');
      final issued = DateTime.tryParse(grant['issued_at']?.toString() ?? '');
      return grant['duty'] == duty &&
          grant['country_code'] == country &&
          grant['revoked_at'] == null &&
          (issued == null || !issued.toUtc().isAfter(now)) &&
          (expiry == null || expiry.toUtc().isAfter(now)) &&
          (grant['region_code'] == null || grant['region_code'] == region) &&
          (grant['category_scope'] == 'all' ||
              grant['category_scope'] == category);
    });
  }

  bool get _canAuthor => _duties.any((grant) {
    final country = grant['country_code']?.toString() ?? '';
    return _hasDuty('policy_author', country,
        grant['region_code']?.toString(),
        grant['category_scope']?.toString() ?? 'all');
  });

  void _refresh() => setState(() => _future = _load());
  void _noticeMessage(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  String? _check(String? value, int min, int max) {
    final n = value?.trim().length ?? 0;
    if (n < min || n > max) return 'Enter $min–$max characters';
    return null;
  }

  Widget _entry(
    String label,
    TextEditingController controller, {
    int min = 5,
    int max = 150,
    int lines = 1,
    bool readOnly = false,
  }) => TextFormField(
    controller: controller,
    readOnly: readOnly,
    maxLines: lines,
    maxLength: max,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      alignLabelWithHint: lines > 1,
      contentPadding: const EdgeInsets.all(12),
    ),
    validator: (text) => _check(text, min, max),
  );
  Future<void> _create() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _noticeMessage('Complete the draft fields before previewing.');
      return;
    }
    final country = _country.text.trim().toUpperCase();
    final region = _region.text.trim().toUpperCase();
    final requirements = _requirements.text
        .split(RegExp(r'[\n,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final days = int.tryParse(_retention.text.trim());
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(country) ||
        (region.isNotEmpty &&
            (!RegExp(r'^[A-Z]{2}-[A-Z0-9]{1,6}$').hasMatch(region) ||
                !region.startsWith('$country-'))) ||
        days == null ||
        days < 1 ||
        days > 3650 ||
        requirements.isEmpty ||
        requirements.length > 16 ||
        requirements.any((s) => s.length < 5 || s.length > 120)) {
      _noticeMessage(
        'Check ISO country/region, retention (1–3650 days), '
        'and up to 16 clear evidence requirement names.',
      );
      return;
    }
    final payload = <String, dynamic>{
      'p_country_code': country,
      'p_region_code': region.isEmpty ? null : region,
      'p_category_scope': _scope,
      'p_notice_title': _title.text.trim(),
      'p_notice_body': _notice.text.trim(),
      'p_collection_purpose': _purpose.text.trim(),
      'p_legal_basis_notes': _legal.text.trim(),
      'p_retention_days': days,
      'p_evidence_requirements': requirements,
    };
    // The preview is mandatory and explicitly states there is no publication.
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Preview unpublished policy proposal'),
        content: SizedBox(
          width: 610,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'INTERNAL DRAFT · NO LEGAL APPROVAL',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$country ${region.isEmpty ? '(all regions)' : region}'
                  ' · ${_scope.toUpperCase()}',
                ),
                Text('Retention proposal: $days days'),
                const SizedBox(height: 10),
                Text(
                  _title.text.trim(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                Text(_notice.text.trim()),
                const SizedBox(height: 8),
                const Text(
                  'Processing purpose',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(_purpose.text.trim()),
                const SizedBox(height: 8),
                const Text(
                  'Proposed legal basis (unverified)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(_legal.text.trim()),
                const SizedBox(height: 8),
                const Text(
                  'Evidence requirements',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                for (final item in requirements) Text('• $item'),
                const SizedBox(height: 12),
                const Text(
                  'Saving only creates an internal draft. It does not '
                  'publish a notice, authorise document uploads, set retention '
                  'schedules or approve applicants.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Go back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Save draft only'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    setState(() => _busy = 'create');
    try {
      if (_revisingPolicyId != null) {
        final oldId = _revisingPolicyId!;
        final revisionPayload = Map<String, dynamic>.from(payload)
          ..remove('p_country_code')
          ..remove('p_region_code')
          ..remove('p_category_scope');
        if (widget.reviseDraft != null) {
          await widget.reviseDraft!(oldId, revisionPayload);
        } else {
          await WantokBackend.client.rpc(
            'revise_vendor_policy_draft',
            params: {'p_prior_id': oldId, ...revisionPayload},
          );
        }
        if (mounted) setState(() => _revisingPolicyId = null);
      } else if (widget.createDraft != null) {
        await widget.createDraft!(payload);
      } else {
        await WantokBackend.client.rpc(
          'create_vendor_policy_draft',
          params: payload,
        );
      }
      _refresh();
      if (mounted) {
        _noticeMessage('Unpublished draft recorded for internal review.');
      }
    } catch (error) {
      if (mounted) _noticeMessage('Draft was not saved: $error');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _submit(String id) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Submit draft for independent review?'),
        content: const Text(
          'The author may not perform the review. '
          'An internal review never grants legal approval or publishes '
          'this policy to applicants.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Submit proposal'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    setState(() => _busy = id);
    try {
      if (widget.submitDraft != null) {
        await widget.submitDraft!(id);
      } else {
        await WantokBackend.client.rpc(
          'submit_vendor_policy_draft',
          params: {'p_policy_id': id},
        );
      }
      _refresh();
    } catch (error) {
      if (mounted) _noticeMessage('Submission refused: $error');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _review(String id) async {
    final controller = TextEditingController();
    String decision = 'revision_requested';
    final confirmed = await showDialog<(String, String)>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (ctx, refresh) => AlertDialog(
          title: const Text('Independent policy review'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Only a different administrator may review. '
                  'This is administrative review, NOT a legal opinion, '
                  'approval to collect evidence or permission to publish.',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: decision,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Decision',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'revision_requested',
                      child: Text('Request revision'),
                    ),
                    DropdownMenuItem(
                      value: 'internal_review_complete',
                      child: Text('Internal review complete (non-operative)'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) refresh(() => decision = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  maxLength: 1500,
                  decoration: const InputDecoration(
                    labelText: 'Reviewer rationale (20–1500 characters)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialog, (decision, controller.text.trim())),
              child: const Text('Record internal decision'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (confirmed == null) return;
    if (confirmed.$2.length < 20 || confirmed.$2.length > 1500) {
      _noticeMessage('Provide a 20–1500 character rationale.');
      return;
    }
    setState(() => _busy = id);
    try {
      if (widget.reviewDraft != null) {
        await widget.reviewDraft!(id, confirmed.$1, confirmed.$2);
      } else {
        await WantokBackend.client.rpc(
          'review_vendor_policy_draft',
          params: {
            'p_policy_id': id,
            'p_decision': confirmed.$1,
            'p_notes': confirmed.$2,
          },
        );
      }
      _refresh();
    } catch (error) {
      if (mounted) _noticeMessage('Review refused: $error');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _showHistory(String policyId) async {
    try {
      final data = await WantokBackend.client
          .from('vendor_policy_events')
          .select(
            'event_type,actor_id,prior_state,next_state,notes,recorded_at',
          )
          .eq('policy_id', policyId)
          .order('recorded_at');
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Immutable policy decision trail'),
          content: SizedBox(
            width: 580,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final event in data)
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(
                      event['event_type']?.toString().replaceAll('_', ' ') ??
                          'Audit event',
                    ),
                    subtitle: Text(
                      'Officer: ${event['actor_id']}'
                      '\n${event['recorded_at']}'
                      '\n${event['notes'] ?? 'No additional rationale'}',
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) _noticeMessage('Audit trail unavailable: $error');
    }
  }

  void _editRevision(Map<String, dynamic> row) {
    final requirements = (row['evidence_requirements'] as List? ?? [])
        .map((x) => x.toString())
        .join(', ');
    setState(() {
      _revisingPolicyId = row['id'].toString();
      _country.text = row['country_code']?.toString() ?? 'PG';
      _region.text = row['region_code']?.toString() ?? '';
      _scope = row['category_scope']?.toString() ?? 'all';
      _title.text = row['notice_title']?.toString() ?? '';
      _notice.text = row['notice_body']?.toString() ?? '';
      _purpose.text = row['collection_purpose']?.toString() ?? '';
      _legal.text = row['legal_basis_notes']?.toString() ?? '';
      _retention.text = row['retention_days']?.toString() ?? '180';
      _requirements.text = requirements;
    });
    _noticeMessage(
      'Revise the proposal above, preview every change, '
      'and save it as a new numbered draft. The prior record is retained.',
    );
  }

  void _view(Map<String, dynamic> row) {
    showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(row['notice_title']?.toString() ?? 'Policy draft'),
        content: SizedBox(
          width: 630,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'UNPUBLISHED · NOT LEGALLY APPROVED',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${row['country_code']} · ${row['region_code'] ?? 'All regions'}'
                  ' · ${row['category_scope']} · ${row['retention_days']} days',
                ),
                const SizedBox(height: 10),
                Text(row['notice_body']?.toString() ?? ''),
                const SizedBox(height: 10),
                const Text(
                  'Purpose',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(row['collection_purpose']?.toString() ?? ''),
                const SizedBox(height: 8),
                const Text(
                  'Legal basis proposed (unverified)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(row['legal_basis_notes']?.toString() ?? ''),
                const SizedBox(height: 8),
                const Text(
                  'Proposed document categories',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                for (final item
                    in (row['evidence_requirements'] as List? ?? []))
                  Text('• $item'),
                if (row['reviewer_notes'] != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Reviewer comments',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(row['reviewer_notes'].toString()),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Compliance Policy Proposals'),
      actions: [
        IconButton(
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh governance queue',
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: TextButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Policy access unavailable. Retry'),
                ),
              );
            }
            final data = (snapshot.data ?? [])
                .where((r) => _filter == 'all' || r['state'] == _filter)
                .toList();
            final current =
                widget.userIdOverride ??
                (widget.loadPolicies != null
                    ? null
                    : WantokBackend.client.auth.currentUser?.id);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF003F2D), Color(0xFF087350)],
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TRUST & COMPLIANCE · JURISDICTION GOVERNANCE',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          color: WantokColors.gold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Country-specific policy drafts',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 23,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Proposal → mandatory preview → independent internal review. '
                        'No publication or document ingestion rights.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.lock_outline, color: Colors.orange),
                    title: Text(
                      'Not a legal approval or consent-management service',
                    ),
                    subtitle: Text(
                      'Lawful basis, notice approval, regulator validation, '
                      'retention implementation and real user consent must be '
                      'independently assessed before any policy becomes effective.',
                    ),
                  ),
                ),
                if (_canAuthor) ExpansionTile(
                  key: ValueKey(
                    'policy-create-expansion-${_revisingPolicyId ?? 'new'}',
                  ),
                  initiallyExpanded: data.isEmpty || _revisingPolicyId != null,
                  title: Text(
                    _revisingPolicyId == null
                        ? 'Prepare a new internal draft'
                        : 'Prepare revised draft (old decision preserved)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            LayoutBuilder(
                              builder: (context, limits) => Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  SizedBox(
                                    width: limits.maxWidth >= 650
                                        ? (limits.maxWidth - 12) / 2
                                        : limits.maxWidth,
                                    child: _entry(
                                      'Country (ISO 3166-1 alpha-2)',
                                      _country,
                                      min: 2,
                                      max: 2,
                                      readOnly: _revisingPolicyId != null,
                                    ),
                                  ),
                                  SizedBox(
                                    width: limits.maxWidth >= 650
                                        ? (limits.maxWidth - 12) / 2
                                        : limits.maxWidth,
                                    child: TextFormField(
                                      controller: _region,
                                      readOnly: _revisingPolicyId != null,
                                      maxLength: 9,
                                      decoration: const InputDecoration(
                                        labelText:
                                            'State / province code (optional)',
                                        hintText: 'PG-MPL',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 9),
                            DropdownButtonFormField<String>(
                              initialValue: _scope,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Service scope',
                                border: OutlineInputBorder(),
                              ),
                              items:
                                  const [
                                        'all',
                                        'transport',
                                        'food',
                                        'trades',
                                        'equipment',
                                        'accommodation',
                                        'other',
                                      ]
                                      .map(
                                        (x) => DropdownMenuItem(
                                          value: x,
                                          child: Text(x),
                                        ),
                                      )
                                      .toList(),
                              onChanged: _revisingPolicyId == null
                                  ? (v) {
                                      if (v != null) setState(() => _scope = v);
                                    }
                                  : null,
                            ),
                            const SizedBox(height: 9),
                            _entry(
                              'Proposed notice title',
                              _title,
                              min: 12,
                              max: 150,
                            ),
                            const SizedBox(height: 9),
                            _entry(
                              'Proposed privacy notice (unapproved)',
                              _notice,
                              min: 80,
                              max: 5000,
                              lines: 4,
                            ),
                            const SizedBox(height: 9),
                            _entry(
                              'Purpose limitation and intended data use',
                              _purpose,
                              min: 30,
                              max: 1500,
                              lines: 3,
                            ),
                            const SizedBox(height: 9),
                            _entry(
                              'Proposed legal basis and outstanding research',
                              _legal,
                              min: 30,
                              max: 1500,
                              lines: 3,
                            ),
                            const SizedBox(height: 9),
                            _entry(
                              'Proposed retention (days)',
                              _retention,
                              min: 1,
                              max: 4,
                            ),
                            const SizedBox(height: 9),
                            _entry(
                              'Proposed evidence categories (comma-separated)',
                              _requirements,
                              min: 5,
                              max: 1500,
                              lines: 3,
                            ),
                            const SizedBox(height: 9),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FilledButton.icon(
                                key: const ValueKey('policy-preview-button'),
                                onPressed: _busy == null ? _create : null,
                                icon: const Icon(Icons.preview_outlined),
                                label: const Text(
                                  'Preview before saving draft',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (!_canAuthor)
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.admin_panel_settings_outlined),
                      title: Text('Read-only jurisdiction access'),
                      subtitle: Text(
                        'Draft authoring requires an explicit, unexpired '
                        'policy_author assignment for the selected country, '
                        'province and service category.',
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final filter in const [
                      'all',
                      'draft',
                      'submitted',
                      'revision_requested',
                      'internal_review_complete',
                    ])
                      ChoiceChip(
                        label: Text(filter.replaceAll('_', ' ')),
                        selected: _filter == filter,
                        onSelected: (_) => setState(() => _filter = filter),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (data.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text('No policy proposals in this queue'),
                      subtitle: Text(
                        'Create an unpublished draft using the form above.',
                      ),
                    ),
                  ),
                for (final row in data)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 9,
                            runSpacing: 5,
                            children: [
                              Text(
                                row['notice_title']?.toString() ??
                                    'Draft policy',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              Chip(
                                label: Text('Revision ${row['revision'] ?? 1}'),
                              ),
                              Chip(
                                label: Text(
                                  row['state']?.toString().replaceAll(
                                        '_',
                                        ' ',
                                      ) ??
                                      'draft',
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${row['country_code']}'
                            ' · ${row['region_code'] ?? 'All regions'}'
                            ' · ${row['category_scope']}'
                            ' · ${row['retention_days']} days',
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Unpublished · pending external legal clearance',
                            style: TextStyle(
                              color: WantokColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: () => _view(row),
                                child: const Text('Preview proposal'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _showHistory(row['id'].toString()),
                                icon: const Icon(Icons.history),
                                label: const Text('Audit trail'),
                              ),
                              if (row['state'] == 'draft' &&
                                  current == row['created_by'] &&
                                  _hasDuty('policy_author',
                                    row['country_code']?.toString() ?? '',
                                    row['region_code']?.toString(),
                                    row['category_scope']?.toString() ?? 'all'))
                                OutlinedButton(
                                  key: ValueKey('policy-submit-${row['id']}'),
                                  onPressed: _busy == null
                                      ? () => _submit(row['id'].toString())
                                      : null,
                                  child: const Text(
                                    'Submit to independent reviewer',
                                  ),
                                ),
                              if (row['state'] == 'revision_requested' &&
                                  current == row['created_by'] &&
                                  _hasDuty('policy_author',
                                    row['country_code']?.toString() ?? '',
                                    row['region_code']?.toString(),
                                    row['category_scope']?.toString() ?? 'all'))
                                OutlinedButton.icon(
                                  key: ValueKey('policy-revise-${row['id']}'),
                                  onPressed: () => _editRevision(row),
                                  icon: const Icon(Icons.edit_note),
                                  label: const Text(
                                    'Prepare numbered revision',
                                  ),
                                ),
                              if (row['state'] == 'submitted' &&
                                  _hasDuty('policy_reviewer',
                                    row['country_code']?.toString() ?? '',
                                    row['region_code']?.toString(),
                                    row['category_scope']?.toString() ?? 'all'))
                                FilledButton(
                                  key: ValueKey('policy-review-${row['id']}'),
                                  onPressed:
                                      _busy == null &&
                                          current != row['created_by']
                                      ? () => _review(row['id'].toString())
                                      : null,
                                  child: const Text('Record internal review'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
