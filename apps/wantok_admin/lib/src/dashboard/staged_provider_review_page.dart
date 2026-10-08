import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

import 'staged_verification_checklist_page.dart';

/// Preliminary intake triage. No approval, verification or listing action.
class StagedProviderReviewPage extends StatefulWidget {
  const StagedProviderReviewPage({super.key});

  @override
  State<StagedProviderReviewPage> createState() =>
      _StagedProviderReviewPageState();
}

class _StagedProviderReviewPageState extends State<StagedProviderReviewPage> {
  late Future<List<Map<String, dynamic>>> _future;
  String? _busy;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await WantokBackend.client
        .from('staged_provider_applications')
        .select(
          'id, user_id, applicant_name, applicant_kind, coverage_province, '
          'coverage_town, service_summary, submitted_at, status, '
          'service_categories(name, slug)',
        )
        .order('submitted_at', ascending: false)
        .limit(100);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      /* FutureBuilder shows retry. */
    }
  }

  Future<void> _triage(String id, String next) async {
    if (_busy != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          next == 'in_review'
              ? 'Mark for review?'
              : 'Decline preliminary request?',
        ),
        content: Text(
          next == 'in_review'
              ? 'This only flags the request for manual checks. It does not approve the provider or activate a listing.'
              : 'The request will be declined, without changing any existing provider permission.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = id);
    try {
      await WantokBackend.client.rpc(
        'triage_staged_provider_application',
        params: {'p_application_id': id, 'p_decision': next},
      );
      await _refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not update preliminary review status. Please retry.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Preliminary provider applications'),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
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
              label: const Text('Could not load applications — Retry'),
            ),
          );
        }
        final rows = snapshot.data ?? const <Map<String, dynamic>>[];
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: const Color(0xFFEAF4FF),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        color: WantokColors.primary,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Preliminary intake only. Review or decline requests. '
                          'Verification, licence checks, publishing, provider roles, '
                          'bookings and payments are not available here.',
                          style: TextStyle(height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('No preliminary applications yet.'),
                  ),
                )
              else
                for (final row in rows)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row['applicant_name']?.toString() ?? 'Applicant',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (row['service_categories'] as Map?)?['name']
                                    ?.toString() ??
                                'Catalogue category',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${row['coverage_town'] ?? ''} • ${row['coverage_province'] ?? ''} '
                            '• ${row['applicant_kind'] ?? ''}',
                            style: const TextStyle(color: WantokColors.muted),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            row['service_summary']?.toString() ?? '',
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Status: ${row['status']}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (row['status'] == 'in_review') ...[
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              key: ValueKey(
                                'review-application-checks-${row['id']}',
                              ),
                              icon: const Icon(Icons.fact_check_outlined),
                              label: const Text('Open verification checklist'),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      StagedVerificationChecklistPage(
                                        applicationId: row['id'] as String,
                                        applicantName:
                                            row['applicant_name']?.toString() ??
                                            'Applicant',
                                      ),
                                ),
                              ),
                            ),
                          ],
                          if (row['status'] == 'submitted') ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                FilledButton.icon(
                                  onPressed: _busy == null
                                      ? () => _triage(
                                          row['id'] as String,
                                          'in_review',
                                        )
                                      : null,
                                  icon: const Icon(Icons.fact_check_outlined),
                                  label: const Text('Mark for review'),
                                ),
                                OutlinedButton(
                                  onPressed: _busy == null
                                      ? () => _triage(
                                          row['id'] as String,
                                          'declined',
                                        )
                                      : null,
                                  child: const Text('Decline'),
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
        );
      },
    ),
  );
}
