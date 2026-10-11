import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

import 'vendor_verification_review_page.dart';

/// Preliminary review queue. Identity clearance and final approval do not
/// occur here. All decisions pass through the scoped, audited database RPC.
class VendorIntakeQueuePage extends StatefulWidget {
  const VendorIntakeQueuePage({
    super.key,
    this.canTriage = true,
    this.canReviewChecks = true,
    this.canRequestEvidence = true,
    this.loadCases,
  });
  final Future<List<Map<String, dynamic>>> Function()? loadCases;
  final bool canTriage;
  final bool canReviewChecks;
  final bool canRequestEvidence;
  @override
  State<VendorIntakeQueuePage> createState() => _VendorIntakeQueuePageState();
}

class _VendorIntakeQueuePageState extends State<VendorIntakeQueuePage> {
  Future<List<Map<String, dynamic>>>? _future;
  String _status = 'open';
  String? _busy;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<List<Map<String, dynamic>>> _load() async {
    if (widget.loadCases != null) return widget.loadCases!();
    final rows = await WantokBackend.client
        .from('vendor_intake_cases')
        .select(
          'id,applicant_kind,display_name,country_code,region,locality,'
          'street_address,contact_email,contact_phone,applicant_identity_type,'
          'identity_last_four,business_registration,tax_reference_last_four,'
          'service_summary,service_metadata,status,submitted_at,assigned_reviewer,'
          'service_categories(name,slug)',
        )
        .order('submitted_at', ascending: false)
        .limit(200);
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  bool _show(Map<String, dynamic> row) => switch (_status) {
    'open' => row['status'] != 'declined',
    'declined' => row['status'] == 'declined',
    _ => row['status'] == _status,
  };
  Future<void> _history(String id) async {
    try {
      final rows = await WantokBackend.client
          .from('vendor_intake_events')
          .select(
            'event_type,previous_status,next_status,reason,recorded_at,actor_id',
          )
          .eq('case_id', id)
          .order('recorded_at');
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Application audit history'),
          content: SizedBox(
            width: 560,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final row in rows)
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: Text('${row['event_type']} → ${row['next_status']}'),
                    subtitle: Text(
                      '${row['recorded_at']} · reviewer ${row['actor_id']}'
                      '\n${row['reason'] ?? 'No reason recorded'}',
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) _message('Could not read case history: $error');
    }
  }

  Future<void> _review(String id, String action) async {
    if (_busy != null) return;
    final needsReason = action != 'start_review';
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(switch (action) {
          'start_review' => 'Begin preliminary review?',
          'request_information' => 'Request more information?',
          _ => 'Decline the application?',
        }),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This records a staff decision and audit event only. '
              'It never grants KYC clearance, driver rights or active listings.',
            ),
            if (needsReason) ...[
              const SizedBox(height: 13),
              TextField(
                controller: reason,
                maxLines: 3,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Reason (minimum 10 characters)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Record action'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      reason.dispose();
      return;
    }
    final text = reason.text.trim();
    reason.dispose();
    if (needsReason && text.length < 10) {
      _message('Please provide a meaningful review reason.');
      return;
    }
    setState(() => _busy = id);
    try {
      await WantokBackend.client.rpc(
        'triage_vendor_intake_case',
        params: {
          'p_case_id': id,
          'p_action': action,
          'p_reason': needsReason ? text : null,
        },
      );
      _reload();
    } catch (error) {
      if (mounted) _message('Case could not be updated: $error');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _message(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Vendor Applications & Review')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: TextButton.icon(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    'Access or loading failed — Retry: ${snapshot.error}',
                  ),
                ),
              );
            }
            final rows = (snapshot.data ?? []).where(_show).toList();
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
                        'OPERATIONS · PROVIDER LIFECYCLE',
                        style: TextStyle(
                          color: WantokColors.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Review applications, do not auto-activate',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Assign work, request evidence through approved channels, '
                        'and preserve a traceable decision history.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.gpp_maybe_outlined,
                      color: Colors.orange,
                    ),
                    title: Text(
                      'Final KYC and provider activation are not available here',
                    ),
                    subtitle: Text(
                      'Full ID and tax documents must use a dedicated '
                      'encrypted evidence workflow with restricted access. '
                      'Submitting or triaging a case is not verification.',
                    ),
                  ),
                ),
                Wrap(
                  spacing: 9,
                  children: [
                    for (final option in const [
                      'open',
                      'submitted',
                      'in_review',
                      'needs_information',
                      'declined',
                    ])
                      ChoiceChip(
                        label: Text(option.replaceAll('_', ' ')),
                        selected: _status == option,
                        onSelected: (_) => setState(() => _status = option),
                      ),
                    IconButton(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh queue',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (rows.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text('No applications in this queue'),
                      subtitle: Text(
                        'Vendor submissions will appear here after sign-in and successful intake.',
                      ),
                    ),
                  ),
                for (final row in rows) _caseCard(row),
              ],
            );
          },
        ),
      ),
    ),
  );

  Widget _caseCard(Map<String, dynamic> row) {
    final category = Map<String, dynamic>.from(
      row['service_categories'] as Map? ?? {},
    );
    final metadata = Map<String, dynamic>.from(
      row['service_metadata'] as Map? ?? {},
    );
    final id = row['id'].toString(), status = row['status'].toString();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 7,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  row['display_name']?.toString() ?? 'Applicant',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Chip(label: Text(status.replaceAll('_', ' '))),
                Chip(
                  label: Text(row['applicant_kind']?.toString() ?? 'unknown'),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text('Reference: $id', style: const TextStyle(fontSize: 11)),
            const Divider(),
            Text('Category: ${category['name'] ?? 'Unknown'}'),
            Text(
              'Country: ${row['country_code']} · ${row['region']} · ${row['locality']}',
            ),
            Text('Address: ${row['street_address']}'),
            Text('Contact: ${row['contact_email']} · ${row['contact_phone']}'),
            Text(
              'Identity type: ${row['applicant_identity_type']} · '
              'Last four: ${row['identity_last_four'] ?? 'Not supplied'}',
            ),
            if (row['applicant_kind'] == 'business') ...[
              Text(
                'Company registration: ${row['business_registration'] ?? 'Not supplied'}',
              ),
              Text(
                'TIN last four: ${row['tax_reference_last_four'] ?? 'Not supplied'}',
              ),
            ],
            const SizedBox(height: 5),
            Text('Services: ${row['service_summary']}', maxLines: 5),
            for (final item in metadata.entries)
              Text(
                '${item.key.replaceAll('_', ' ')}: ${item.value}',
                style: const TextStyle(fontSize: 12),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 9,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _history(id),
                  icon: const Icon(Icons.history),
                  label: const Text('Audit trail'),
                ),
                OutlinedButton.icon(
                  key: ValueKey('verification-tasks-$id'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => VendorVerificationReviewPage(
                        caseId: id,
                        applicantName:
                            row['display_name']?.toString() ?? 'Applicant',
                        canRecordReviews: widget.canReviewChecks,
                        canModifyEvidence: widget.canRequestEvidence,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Verification review tasks'),
                ),
                if (widget.canTriage && status == 'submitted')
                  FilledButton.icon(
                    onPressed: _busy == null
                        ? () => _review(id, 'start_review')
                        : null,
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Begin review'),
                  ),
                if (widget.canTriage &&
                    (status == 'submitted' || status == 'in_review'))
                  OutlinedButton(
                    onPressed: _busy == null
                        ? () => _review(id, 'request_information')
                        : null,
                    child: const Text('Request information'),
                  ),
                if (widget.canTriage && status != 'declined')
                  TextButton(
                    onPressed: _busy == null
                        ? () => _review(id, 'decline')
                        : null,
                    child: const Text('Decline'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
