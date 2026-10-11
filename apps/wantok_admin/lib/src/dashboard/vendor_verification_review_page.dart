import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

import 'vendor_evidence_requests_page.dart';

/// Operational two-person checklist review, never identity certification.
/// No sensitive documents, media, or full ID numbers are accepted here.
class VendorVerificationReviewPage extends StatefulWidget {
  const VendorVerificationReviewPage({
    super.key,
    required this.caseId,
    required this.applicantName,
    this.loadChecks,
    this.loadEvents,
    this.recordAction,
    this.canRecordReviews = true,
    this.canModifyEvidence = true,
  });
  final bool canRecordReviews;
  final bool canModifyEvidence;
  final String caseId;
  final String applicantName;
  final Future<List<Map<String, dynamic>>> Function(String caseId)? loadChecks;
  final Future<List<Map<String, dynamic>>> Function(String caseId)? loadEvents;
  final Future<void> Function(String checkId, String action, String rationale)?
  recordAction;

  @override
  State<VendorVerificationReviewPage> createState() =>
      _VendorVerificationReviewPageState();
}

class _VendorVerificationReviewPageState
    extends State<VendorVerificationReviewPage> {
  late Future<List<Map<String, dynamic>>> _checks = _load();
  late Future<List<Map<String, dynamic>>> _events = _loadEvents();
  String? _busyId;

  Future<List<Map<String, dynamic>>> _load() async {
    if (widget.loadChecks != null) return widget.loadChecks!(widget.caseId);
    final rows = await WantokBackend.client
        .from('vendor_verification_checks')
        .select(
          'id,requirement_key,requirement_label,requirement_scope,'
          'state,first_reviewer,second_reviewer,updated_at',
        )
        .eq('case_id', widget.caseId)
        .order('requirement_key');
    return (rows as List)
        .map((x) => Map<String, dynamic>.from(x as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> _loadEvents() async {
    if (widget.loadEvents != null) return widget.loadEvents!(widget.caseId);
    final rows = await WantokBackend.client
        .from('vendor_verification_check_events')
        .select('action,actor_id,occurred_at,prior_state,next_state,rationale')
        .eq('case_id', widget.caseId)
        .order('occurred_at', ascending: false)
        .limit(60);
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  void _refresh() => setState(() {
    _checks = _load();
    _events = _loadEvents();
  });

  Future<void> _act(String id, String action) async {
    if (_busyId != null) return;
    final reason = TextEditingController();
    final answer = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(switch (action) {
          'start' => 'Start this review step?',
          'followup' => 'Record a follow-up requirement?',
          'record_first' => 'Record first procedural review?',
          _ => 'Record independent second procedural review?',
        }),
        content: SizedBox(
          width: 490,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This is a procedural review record, not verification '
                'that an ID, business, licence or permit is genuine. '
                'Do not enter full ID, passport, licence, tax or bank '
                'numbers here. Final clearance and activation remain disabled.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reason,
                maxLength: 1000,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Rationale (15–1000 characters)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Record audit event'),
          ),
        ],
      ),
    );
    final rationale = reason.text.trim();
    reason.dispose();
    if (answer != true) return;
    if (rationale.length < 15 || rationale.length > 1000) {
      _notice('A rationale of 15–1000 characters is required.');
      return;
    }
    setState(() => _busyId = id);
    try {
      if (widget.recordAction != null) {
        await widget.recordAction!(id, action, rationale);
      } else {
        await WantokBackend.client.rpc(
          'record_vendor_verification_review',
          params: {
            'p_check_id': id,
            'p_action': action,
            'p_rationale': rationale,
          },
        );
      }
      _refresh();
      if (mounted) _notice('Review event recorded.');
    } catch (error) {
      if (mounted) _notice('Review was not recorded: $error');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _notice(String value) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Verification Review Tasks'),
      actions: [
        IconButton(
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh review tasks',
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _checks,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: TextButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Cannot read review tasks. Retry'),
                ),
              );
            }
            final rows = snapshot.data ?? [];
            final second = rows
                .where((r) => r['state'] == 'second_review_recorded')
                .length;
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TRUST & COMPLIANCE · PRELIMINARY WORKFLOW',
                        style: TextStyle(
                          color: WantokColors.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.applicantName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 23,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Case ${widget.caseId}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    key: const ValueKey('vendor-evidence-register'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => VendorEvidenceRequestsPage(
                          caseId: widget.caseId,
                          applicantName: widget.applicantName,
                          canModifyRequests: widget.canModifyEvidence,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('Evidence request register (no uploads)'),
                  ),
                ),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.lock_outline, color: Colors.orange),
                    title: Text(
                      'Evidence intake and final activation are not enabled',
                    ),
                    subtitle: Text(
                      'Two staff members may record independent procedural '
                      'checks. This is NOT a validated KYC outcome or clearance to operate. '
                      'Full identity documents are not accepted on this screen.',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    '$second of ${rows.length} steps have independent '
                    'second review records.',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (rows.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text('No verification tasks yet'),
                      subtitle: Text(
                        'Refresh after the application is received.',
                      ),
                    ),
                  ),
                for (final row in rows) _taskCard(row),
                const SizedBox(height: 12),
                const Text(
                  'Verification review audit trail',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _events,
                  builder: (context, history) {
                    if (history.connectionState != ConnectionState.done) {
                      return const LinearProgressIndicator();
                    }
                    if (history.hasError) {
                      return const Text('Review audit history is unavailable.');
                    }
                    final events = history.data ?? [];
                    if (events.isEmpty) {
                      return const Text('No procedural reviews recorded yet.');
                    }
                    return Column(
                      children: [
                        for (final event in events)
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.history),
                              title: Text(
                                event['action']?.toString().replaceAll(
                                      '_',
                                      ' ',
                                    ) ??
                                    'Review action',
                              ),
                              subtitle: Text(
                                'Officer: ${event['actor_id']} · ${event['occurred_at']}'
                                '\n${event['rationale'] ?? ''}',
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    ),
  );

  Widget _taskCard(Map<String, dynamic> item) {
    final status = item['state']?.toString() ?? 'pending';
    final id = item['id']?.toString() ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 9,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  item['requirement_label']?.toString() ?? 'Verification task',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Chip(label: Text(status.replaceAll('_', ' '))),
              ],
            ),
            Text(
              item['requirement_scope']?.toString() ?? '',
              style: const TextStyle(fontSize: 12, color: WantokColors.muted),
            ),
            const SizedBox(height: 7),
            if (item['first_reviewer'] != null)
              const Text(
                'First procedural review recorded',
                style: TextStyle(fontSize: 12),
              ),
            if (item['second_reviewer'] != null)
              const Text(
                'Independent second procedural review recorded',
                style: TextStyle(fontSize: 12),
              ),
            const SizedBox(height: 9),
            Wrap(
              spacing: 9,
              runSpacing: 8,
              children: [
                if (widget.canRecordReviews &&
                    (status == 'pending' || status == 'needs_followup'))
                  OutlinedButton(
                    key: ValueKey('review-start-$id'),
                    onPressed: _busyId == null ? () => _act(id, 'start') : null,
                    child: const Text('Start review'),
                  ),
                if (widget.canRecordReviews &&
                    (status == 'pending' || status == 'in_review'))
                  OutlinedButton(
                    onPressed: _busyId == null
                        ? () => _act(id, 'followup')
                        : null,
                    child: const Text('Needs follow-up'),
                  ),
                if (widget.canRecordReviews && status == 'in_review')
                  FilledButton(
                    key: ValueKey('review-first-$id'),
                    onPressed: _busyId == null
                        ? () => _act(id, 'record_first')
                        : null,
                    child: const Text('Record first review'),
                  ),
                if (widget.canRecordReviews &&
                    status == 'first_review_recorded')
                  FilledButton(
                    key: ValueKey('review-second-$id'),
                    onPressed: _busyId == null
                        ? () => _act(id, 'record_second')
                        : null,
                    child: const Text('Independent second review'),
                  ),
                if (status == 'second_review_recorded')
                  const Text(
                    'Procedural review recorded · no activation issued',
                    style: TextStyle(fontSize: 12, color: WantokColors.muted),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
