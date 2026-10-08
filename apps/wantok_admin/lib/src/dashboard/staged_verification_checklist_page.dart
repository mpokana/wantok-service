import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

import 'staged_evidence_planning_section.dart';

/// Early-stage administrative checks ONLY. Never grants provider verification.
class StagedVerificationChecklistPage extends StatefulWidget {
  const StagedVerificationChecklistPage({
    super.key,
    required this.applicationId,
    required this.applicantName,
    this.loadChecks,
    this.loadAudit,
    this.loadEvidencePlans,
    this.planEvidenceCheck,
    this.cancelEvidencePlan,
    this.updateCheck,
  });

  final String applicationId;
  final String applicantName;
  final Future<List<Map<String, dynamic>>> Function(String)? loadChecks;
  final Future<List<Map<String, dynamic>>> Function(String)? loadAudit;
  final Future<List<Map<String, dynamic>>> Function(String)? loadEvidencePlans;
  final Future<void> Function(String)? planEvidenceCheck;
  final Future<void> Function(String)? cancelEvidencePlan;
  final Future<void> Function(String, String)? updateCheck;

  @override
  State<StagedVerificationChecklistPage> createState() =>
      _StagedVerificationChecklistPageState();
}

class _StagedVerificationChecklistPageState
    extends State<StagedVerificationChecklistPage> {
  late Future<List<Map<String, dynamic>>> _future;
  late Future<List<Map<String, dynamic>>> _auditFuture;
  String? _busy;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _auditFuture = _loadAudit();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    if (widget.loadChecks != null) {
      return widget.loadChecks!(widget.applicationId);
    }
    final rows = await WantokBackend.client
        .from('staged_verification_checks')
        .select(
          'id, requirement_index, requirement_label, review_status, last_reviewed_at',
        )
        .eq('application_id', widget.applicationId)
        .order('requirement_index');
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> _loadAudit() async {
    if (widget.loadAudit != null) {
      return widget.loadAudit!(widget.applicationId);
    }
    final rows = await WantokBackend.client
        .from('staged_verification_audit')
        .select('previous_status, next_status, reviewed_at')
        .eq('application_id', widget.applicationId)
        .order('reviewed_at', ascending: false)
        .limit(30);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> _refresh() async {
    final next = _load();
    final audit = _loadAudit();
    setState(() {
      _future = next;
      _auditFuture = audit;
    });
    try {
      await Future.wait<dynamic>([next, audit]);
    } catch (_) {
      /* FutureBuilder offers retry */
    }
  }

  Future<void> _change(String checkId, String nextStatus) async {
    if (_busy != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update preliminary review?'),
        content: const Text(
          'This records checklist progress only. It does not verify credentials, '
          'approve the applicant, activate provider status, publish listings or enable payments. '
          'Do not enter or attach personal identity documents here.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Record status'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = checkId);
    try {
      if (widget.updateCheck != null) {
        await widget.updateCheck!(checkId, nextStatus);
      } else {
        await WantokBackend.client.rpc(
          'update_staged_verification_check',
          params: {'p_check_id': checkId, 'p_status': nextStatus},
        );
      }
      await _refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review status could not be saved. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  String _statusLabel(String status) => switch (status) {
    'under_review' => 'Under review',
    'needs_followup' => 'Needs follow-up',
    _ => 'Pending',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Preliminary verification checks')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
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
              label: const Text('Unable to load — Retry'),
            ),
          );
        }
        final checks = snapshot.data ?? const <Map<String, dynamic>>[];
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                widget.applicantName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Card(
                color: const Color(0xFFEAF4FF),
                elevation: 0,
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline, color: WantokColors.primary),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No identity files or licence documents are collected here. '
                          'Checklist statuses are preliminary, audited and do not constitute approval. '
                          'Final provider verification and activation remain disabled.',
                          style: TextStyle(height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (checks.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No checklist items are available for this application.',
                  ),
                )
              else
                for (final check in checks)
                  Card(
                    key: ValueKey('review-check-${check['requirement_index']}'),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            check['requirement_label']?.toString() ??
                                'Requirement',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Status: ${_statusLabel(check['review_status']?.toString() ?? 'pending')}',
                            style: const TextStyle(color: WantokColors.muted),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              OutlinedButton(
                                onPressed: _busy == null
                                    ? () => _change(
                                        check['id'] as String,
                                        'under_review',
                                      )
                                    : null,
                                child: const Text('Under review'),
                              ),
                              OutlinedButton(
                                onPressed: _busy == null
                                    ? () => _change(
                                        check['id'] as String,
                                        'needs_followup',
                                      )
                                    : null,
                                child: const Text('Needs follow-up'),
                              ),
                              TextButton(
                                onPressed: _busy == null
                                    ? () => _change(
                                        check['id'] as String,
                                        'pending',
                                      )
                                    : null,
                                child: const Text('Reset pending'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: 18),
              StagedEvidencePlanningSection(
                applicationId: widget.applicationId,
                checks: checks,
                loadPlans: widget.loadEvidencePlans,
                planCheck: widget.planEvidenceCheck,
                cancelPlan: widget.cancelEvidencePlan,
              ),
              const SizedBox(height: 18),
              const Text(
                'Review activity',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _auditFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const LinearProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return const Text(
                      'Review history is currently unavailable.',
                    );
                  }
                  final events =
                      snapshot.data ?? const <Map<String, dynamic>>[];
                  if (events.isEmpty) {
                    return const Text('No review changes recorded.');
                  }
                  return Column(
                    children: [
                      for (final event in events)
                        ListTile(
                          leading: const Icon(
                            Icons.history_rounded,
                            color: WantokColors.primary,
                          ),
                          title: Text(
                            '${_statusLabel(event['previous_status']?.toString() ?? 'pending')} → '
                            '${_statusLabel(event['next_status']?.toString() ?? 'pending')}',
                          ),
                          subtitle: Text(
                            event['reviewed_at']?.toString() ?? '',
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}
