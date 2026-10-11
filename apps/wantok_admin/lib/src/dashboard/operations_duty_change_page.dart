import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

/// Signed-in, country-scoped two-person duty requests. No service key,
/// bootstrap authority, identity documents or global admin inheritance.
class OperationsDutyChangePage extends StatefulWidget {
  const OperationsDutyChangePage({
    super.key,
    this.loadData,
    this.submitChange,
    this.decideChange,
    this.currentUserIdOverride,
  });

  final Future<(List<Map<String, dynamic>>, List<Map<String, dynamic>>)>
  Function()?
  loadData;
  final Future<void> Function(Map<String, dynamic> payload)? submitChange;
  final Future<void> Function(String requestId, bool accept, String reason)?
  decideChange;
  final String? currentUserIdOverride;

  @override
  State<OperationsDutyChangePage> createState() =>
      _OperationsDutyChangePageState();
}

class _OperationsDutyChangePageState extends State<OperationsDutyChangePage> {
  late Future<(List<Map<String, dynamic>>, List<Map<String, dynamic>>)>
  _future = _load();
  String? _busy;

  String? get _userId =>
      widget.currentUserIdOverride ?? WantokBackend.client.auth.currentUser?.id;

  Future<(List<Map<String, dynamic>>, List<Map<String, dynamic>>)>
  _load() async {
    if (widget.loadData != null) return widget.loadData!();
    final authorities = await WantokBackend.client
        .from('operations_provisioning_authorities')
        .select('authority,country_code,issued_at,revoked_at');
    final requests = await WantokBackend.client
        .from('operations_duty_change_requests')
        .select(
          'id,action,staff_user_id,duty,country_code,region_code,'
          'category_scope,status,proposed_by,proposed_at,proposed_reason',
        )
        .order('proposed_at', ascending: false)
        .limit(100);
    return (
      (authorities as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      (requests as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  void _notice(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _request(String countryCode) async {
    final user = TextEditingController();
    final country = TextEditingController(text: countryCode);
    final region = TextEditingController();
    final targetGrant = TextEditingController();
    final reason = TextEditingController();
    final days = TextEditingController(text: '90');
    var action = 'grant';
    var duty = 'case_reviewer';
    var category = 'trades';
    final formKey = GlobalKey<FormState>();
    final requested = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Request staff duty change'),
          content: SizedBox(
            width: 510,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'An independently authorised officer in this country '
                      'must approve. A request alone gives no permissions.',
                    ),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: action,
                      items: const [
                        DropdownMenuItem(value: 'grant', child: Text('Grant')),
                        DropdownMenuItem(
                          value: 'revoke',
                          child: Text('Revoke'),
                        ),
                      ],
                      onChanged: (v) => update(() => action = v ?? action),
                    ),
                    TextFormField(
                      controller: user,
                      decoration: const InputDecoration(
                        labelText: 'Staff user UUID',
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Staff identity is required'
                          : null,
                    ),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: duty,
                      items: const [
                        DropdownMenuItem(
                          value: 'policy_author',
                          child: Text('Policy author'),
                        ),
                        DropdownMenuItem(
                          value: 'policy_reviewer',
                          child: Text('Policy reviewer'),
                        ),
                        DropdownMenuItem(
                          value: 'case_reviewer',
                          child: Text('Case reviewer'),
                        ),
                        DropdownMenuItem(
                          value: 'evidence_officer',
                          child: Text('Evidence officer'),
                        ),
                        DropdownMenuItem(
                          value: 'safety_investigator',
                          child: Text('Safety investigator'),
                        ),
                        DropdownMenuItem(
                          value: 'final_approver',
                          child: Text(
                            'Final approver (not enabled for KYC)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      onChanged: (v) => update(() => duty = v ?? duty),
                    ),
                    TextFormField(
                      controller: country,
                      decoration: const InputDecoration(
                        labelText: 'Country ISO alpha-2',
                      ),
                      validator: (v) =>
                          RegExp(r'^[A-Z]{2}$').hasMatch((v ?? '').trim())
                          ? null
                          : 'Enter uppercase ISO alpha-2 country',
                    ),
                    TextFormField(
                      controller: region,
                      decoration: const InputDecoration(
                        labelText: 'Verified subdivision (optional)',
                        helperText: 'Only independently registered codes',
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: category,
                      items:
                          [
                                'all',
                                'transport',
                                'food',
                                'trades',
                                'equipment',
                                'accommodation',
                                'other',
                              ]
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                      onChanged: (v) => update(() => category = v ?? category),
                    ),
                    if (action == 'grant')
                      TextFormField(
                        controller: days,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Expiry in days (1–366)',
                        ),
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          return n == null || n < 1 || n > 366
                              ? 'Choose 1–366 days'
                              : null;
                        },
                      ),
                    if (action == 'revoke')
                      TextFormField(
                        controller: targetGrant,
                        decoration: const InputDecoration(
                          labelText: 'Exact existing grant UUID',
                        ),
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? 'Grant reference required'
                            : null,
                      ),
                    TextFormField(
                      controller: reason,
                      minLines: 2,
                      maxLines: 4,
                      maxLength: 1000,
                      decoration: const InputDecoration(
                        labelText: 'Verified business justification',
                      ),
                      validator: (v) => (v ?? '').trim().length < 30
                          ? 'At least 30 characters required'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                Navigator.pop(dialog, {
                  'p_action': action,
                  'p_staff': user.text.trim(),
                  'p_duty': duty,
                  'p_country': country.text.trim(),
                  'p_region': region.text.trim().isEmpty
                      ? null
                      : region.text.trim(),
                  'p_category': category,
                  'p_expires': action == 'grant'
                      ? DateTime.now()
                            .toUtc()
                            .add(Duration(days: int.parse(days.text.trim())))
                            .toIso8601String()
                      : null,
                  'p_target': action == 'revoke'
                      ? targetGrant.text.trim()
                      : null,
                  'p_reason': reason.text.trim(),
                });
              },
              child: const Text('Submit for independent review'),
            ),
          ],
        ),
      ),
    );
    // showDialog resolves when pop starts; allow its closing animation
    // to release field listeners before disposing the controllers.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    user.dispose();
    country.dispose();
    region.dispose();
    targetGrant.dispose();
    days.dispose();
    reason.dispose();
    if (requested == null) return;
    setState(() => _busy = 'request');
    try {
      if (widget.submitChange != null) {
        await widget.submitChange!(requested);
      } else {
        await WantokBackend.client.rpc(
          'request_operations_duty_change',
          params: requested,
        );
      }
      _notice('Request recorded; no duty has been granted yet.');
      _refresh();
    } catch (_) {
      _notice('Request rejected. Verify your scope and staff authority.');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _decide(String requestId, bool accept) async {
    if (_busy != null) return;
    var explanation = '';
    final formKey = GlobalKey<FormState>();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(
          accept ? 'Independently approve change?' : 'Reject change?',
        ),
        content: SizedBox(
          width: 460,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Confirm the verified jurisdiction, business reason, '
                    'employee identity and independent reviewer before deciding. '
                    'No KYC approval or provider activation follows.',
                  ),
                  TextFormField(
                    onChanged: (value) => explanation = value,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      labelText: 'Independent decision rationale',
                    ),
                    validator: (v) => (v ?? '').trim().length < 30
                        ? 'At least 30 characters required'
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(dialog, explanation.trim());
              }
            },
            child: Text(accept ? 'Confirm approval' : 'Confirm rejection'),
          ),
        ],
      ),
    );
    if (reason == null) return;
    setState(() => _busy = requestId);
    try {
      if (widget.decideChange != null) {
        await widget.decideChange!(requestId, accept, reason);
      } else {
        await WantokBackend.client.rpc(
          'decide_operations_duty_change',
          params: {
            'p_request': requestId,
            'p_accept': accept,
            'p_reason': reason,
          },
        );
      }
      _notice('Decision recorded in the staff-duty audit.');
      _refresh();
    } catch (_) {
      _notice('Decision denied. Independent authority is required.');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Staff Duty Authorisation'),
      actions: [
        IconButton(
          tooltip: 'Refresh staff duty requests',
          icon: const Icon(Icons.refresh),
          onPressed: _refresh,
        ),
      ],
    ),
    body:
        FutureBuilder<(List<Map<String, dynamic>>, List<Map<String, dynamic>>)>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: TextButton(
                  onPressed: _refresh,
                  child: const Text('Cannot load duty requests. Retry'),
                ),
              );
            }
            final authorities = snapshot.data!.$1;
            final requests = snapshot.data!.$2;
            final now = DateTime.now().toUtc();
            final active = authorities.where((entry) {
              final issued = DateTime.tryParse(
                entry['issued_at']?.toString() ?? '',
              )?.toUtc();
              return entry['revoked_at'] == null &&
                  issued != null &&
                  !issued.isAfter(now);
            }).toList();
            final requesterCountries = active
                .where((a) => a['authority'] == 'requester')
                .map((a) => a['country_code'].toString())
                .toSet();
            final approverCountries = active
                .where((a) => a['authority'] == 'approver')
                .map((a) => a['country_code'].toString())
                .toSet();
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: WantokColors.primaryDark,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OPERATIONS · DUAL CONTROL',
                            style: TextStyle(color: WantokColors.gold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Independent staff-duty authorisation',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Requester, approver and staff subject must be '
                            'different people. A request alone grants no access.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.lock_outline),
                        title: Text('No automatic administrator authority'),
                        subtitle: Text(
                          'Only the trusted server can register '
                          'initial provisioning authorities. This workspace '
                          'cannot issue final vendor or KYC approval.',
                        ),
                      ),
                    ),
                    if (requesterCountries.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          for (final country in requesterCountries)
                            FilledButton.icon(
                              key: ValueKey('duty-request-$country'),
                              onPressed: _busy == null
                                  ? () => _request(country)
                                  : null,
                              icon: const Icon(Icons.person_add_alt_1_outlined),
                              label: Text('Request change · $country'),
                            ),
                        ],
                      ),
                    ],
                    if (active.isEmpty)
                      const Card(
                        child: ListTile(
                          title: Text('No current duty-provisioning authority'),
                          subtitle: Text(
                            'Your account cannot request or '
                            'approve staff duties.',
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'Duty requests (${requests.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final request in requests)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${request['action']} · ${request['duty']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Scope: ${request['country_code']} / '
                                '${request['region_code'] ?? 'national'} / '
                                '${request['category_scope']}',
                              ),
                              Text('Staff: ${request['staff_user_id']}'),
                              Text('Status: ${request['status']}'),
                              Text(
                                request['proposed_reason']?.toString() ?? '',
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (request['status'] == 'pending' &&
                                  approverCountries.contains(
                                    request['country_code']?.toString(),
                                  ) &&
                                  request['proposed_by'] != _userId &&
                                  request['staff_user_id'] != _userId) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton(
                                      key: ValueKey(
                                        'duty-approve-${request['id']}',
                                      ),
                                      onPressed: _busy == null
                                          ? () => _decide(
                                              request['id'].toString(),
                                              true,
                                            )
                                          : null,
                                      child: const Text(
                                        'Approve independently',
                                      ),
                                    ),
                                    TextButton(
                                      key: ValueKey(
                                        'duty-reject-${request['id']}',
                                      ),
                                      onPressed: _busy == null
                                          ? () => _decide(
                                              request['id'].toString(),
                                              false,
                                            )
                                          : null,
                                      child: const Text('Reject'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
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
}
