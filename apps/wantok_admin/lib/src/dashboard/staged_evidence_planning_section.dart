import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

/// Review planning ONLY. This widget does not upload, scan or approve evidence.
class StagedEvidencePlanningSection extends StatefulWidget {
  const StagedEvidencePlanningSection({
    super.key,
    required this.applicationId,
    required this.checks,
    this.loadPlans,
    this.planCheck,
    this.cancelPlan,
  });

  final String applicationId;
  final List<Map<String, dynamic>> checks;
  final Future<List<Map<String, dynamic>>> Function(String)? loadPlans;
  final Future<void> Function(String)? planCheck;
  final Future<void> Function(String)? cancelPlan;

  @override
  State<StagedEvidencePlanningSection> createState() =>
      _StagedEvidencePlanningSectionState();
}

class _StagedEvidencePlanningSectionState
    extends State<StagedEvidencePlanningSection> {
  late Future<List<Map<String, dynamic>>> _plans;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _plans = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    if (widget.loadPlans != null) {
      return widget.loadPlans!(widget.applicationId);
    }
    final rows = await WantokBackend.client
        .from('staged_evidence_requirements')
        .select('check_id, state, planned_at')
        .eq('application_id', widget.applicationId);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> _refresh() async {
    final updated = _load();
    setState(() => _plans = updated);
    try {
      await updated;
    } catch (_) {
      // FutureBuilder shows the error without enabling a dangerous fallback.
    }
  }

  Future<void> _change(String checkId, {required bool cancel}) async {
    if (_busyId != null) return;
    final agreed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          cancel
              ? 'Cancel future evidence planning?'
              : 'Record future evidence requirement?',
        ),
        content: const Text(
          'This is an internal planning marker only. Secure uploads, '
          'document requests, notifications, malware scanning and final '
          'provider approval are NOT active. Do not ask applicants to send '
          'identity, licence or financial documents through other channels.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm planning'),
          ),
        ],
      ),
    );
    if (agreed != true || !mounted) return;

    setState(() => _busyId = checkId);
    try {
      if (cancel) {
        if (widget.cancelPlan != null) {
          await widget.cancelPlan!(checkId);
        } else {
          await WantokBackend.client.rpc(
            'cancel_staged_evidence_requirement',
            params: {'p_check_id': checkId},
          );
        }
      } else {
        if (widget.planCheck != null) {
          await widget.planCheck!(checkId);
        } else {
          await WantokBackend.client.rpc(
            'plan_staged_evidence_requirement',
            params: {'p_check_id': checkId},
          );
        }
      }
      await _refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The planning change could not be recorded.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _plans,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: LinearProgressIndicator());
      }
      if (snapshot.hasError) {
        return TextButton.icon(
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Unable to load evidence planning — Retry'),
        );
      }

      final plans = {
        for (final item in snapshot.data ?? const <Map<String, dynamic>>[])
          item['check_id']?.toString() ?? '': item['state']?.toString() ?? '',
      };
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Evidence planning',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Card(
            color: Color(0xFFFFF3E5),
            elevation: 0,
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline, color: WantokColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Planning only — secure document upload is disabled. '
                      'Do not request documents by email or messaging. '
                      'No scanned or verified files are stored.',
                      style: TextStyle(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          for (final check in widget.checks) ...[
            Builder(
              builder: (context) {
                final checkId = check['id']?.toString() ?? '';
                final state = plans[checkId];
                return Card(
                  key: ValueKey('evidence-plan-$checkId'),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          check['requirement_label']?.toString() ??
                              'Requirement',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          state == 'planned'
                              ? 'Planning recorded — upload unavailable'
                              : state == 'cancelled'
                              ? 'Planning cancelled'
                              : 'No document requirement planned',
                          style: const TextStyle(color: WantokColors.muted),
                        ),
                        const SizedBox(height: 7),
                        if (state == null && checkId.isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: _busyId == null
                                ? () => _change(checkId, cancel: false)
                                : null,
                            icon: const Icon(Icons.fact_check_outlined),
                            label: const Text('Plan future evidence'),
                          )
                        else if (state == 'planned')
                          TextButton.icon(
                            onPressed: _busyId == null
                                ? () => _change(checkId, cancel: true)
                                : null,
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Cancel planning'),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      );
    },
  );
}
