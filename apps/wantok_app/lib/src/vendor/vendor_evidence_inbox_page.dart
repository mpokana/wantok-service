import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

/// Applicants only see their own metadata via database RLS.
/// No uploader or consent-approval control is intentionally exposed.
class VendorEvidenceInboxPage extends StatefulWidget {
  const VendorEvidenceInboxPage({
    super.key,
    this.loadRequests,
    this.checkReadiness,
  });
  final Future<List<Map<String, dynamic>>> Function()? loadRequests;
  final Future<Map<String, dynamic>> Function(String requestId)? checkReadiness;
  @override
  State<VendorEvidenceInboxPage> createState() =>
      _VendorEvidenceInboxPageState();
}

class _VendorEvidenceInboxPageState extends State<VendorEvidenceInboxPage> {
  late Future<List<Map<String, dynamic>>> _future = _load();
  String? _busy;
  Future<List<Map<String, dynamic>>> _load() async {
    if (widget.loadRequests != null) return widget.loadRequests!();
    final data = await WantokBackend.client
        .from('vendor_evidence_requests')
        .select(
          'id,case_id,requirement_note,status,notice_version,'
          'requested_at,expires_at',
        )
        .order('requested_at', ascending: false)
        .limit(100);
    return (data as List)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();
  }

  void _refresh() => setState(() => _future = _load());
  void _notice(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  Future<void> _respond(String id, String action) async {
    if (_busy != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(
          action == 'acknowledged'
              ? 'Acknowledge evidence requirement?'
              : 'Withdraw this request?',
        ),
        content: const Text(
          'This only records that you received a request. '
          'It is NOT consent to upload sensitive documents, nor does '
          'it prove your identity or approve your account. No uploads '
          'are available until a separately approved secure process exists.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Record response'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = id);
    try {
      await WantokBackend.client.rpc(
        'respond_vendor_evidence_request',
        params: {'p_request_id': id, 'p_action': action},
      );
      _refresh();
    } catch (error) {
      if (mounted) _notice('Unable to record response: $error');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _checkReadiness(String requestId) async {
    if (_busy != null) return;
    setState(() => _busy = requestId);
    try {
      final Map<String, dynamic> state;
      if (widget.checkReadiness != null) {
        state = await widget.checkReadiness!(requestId);
      } else {
        final response = await WantokBackend.client.rpc(
          'vendor_evidence_preflight',
          params: {'p_request_id': requestId},
        );
        state = Map<String, dynamic>.from(response as Map);
      }
      if (!mounted) return;
      // This preview contains no upload widget or endpoint, even if a remote
      // service unexpectedly changes its policy.
      if (state['upload_allowed'] != false ||
          state['reviewer_access_allowed'] != false ||
          state['identity_verified'] != false) {
        _notice('Upload status unavailable. Please contact Wantok support.');
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Secure upload is not yet available'),
          content: Text(
            'Your request status: ${state['status'] ?? 'pending'}. '
            'The approved privacy notice, secure gateway and document '
            'verification process are not enabled. '
            'Do not submit personal documents by chat or email.',
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
      if (mounted) _notice('Unable to check upload availability.');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('My evidence requirements'),
      actions: [
        IconButton(
          onPressed: _refresh,
          tooltip: 'Refresh requests',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
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
                  label: const Text('Could not load evidence requests. Retry'),
                ),
              );
            }
            final rows = snapshot.data ?? [];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(19),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: WantokColors.primaryDark,
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PRIVATE VENDOR CASE RECORD',
                        style: TextStyle(
                          fontSize: 11,
                          color: WantokColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Your verification requests',
                        style: TextStyle(
                          fontSize: 23,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.shield_outlined, color: Colors.orange),
                    title: Text('No document upload or identity approval yet'),
                    subtitle: Text(
                      'This is a requirement register only. '
                      'The notice shown is a draft, not approved consent. '
                      'Do not send NID, passports, licences, tax records or '
                      'bank information by email or chat.',
                    ),
                  ),
                ),
                if (rows.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text('No evidence requests'),
                      subtitle: Text(
                        'Staff requests will appear here after review.',
                      ),
                    ),
                  ),
                for (final req in rows)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req['requirement_note']?.toString() ??
                                'Evidence requirement',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Status: ${req['status']} · Case: ${req['case_id']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Expires: ${req['expires_at']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            key: ValueKey('evidence-preflight-${req['id']}'),
                            onPressed: _busy == null
                                ? () => _checkReadiness(req['id'].toString())
                                : null,
                            icon: const Icon(Icons.lock_outline),
                            label: const Text('Check secure upload status'),
                          ),
                          const SizedBox(height: 8),
                          if (DateTime.tryParse(
                                req['expires_at']?.toString() ?? '',
                              )?.isAfter(DateTime.now()) ??
                              false)
                            Wrap(
                              spacing: 8,
                              children: [
                                if (req['status'] == 'requested')
                                  OutlinedButton(
                                    onPressed: _busy == null
                                        ? () => _respond(
                                            req['id'].toString(),
                                            'acknowledged',
                                          )
                                        : null,
                                    child: const Text('Acknowledge receipt'),
                                  ),
                                if (const {
                                  'requested',
                                  'acknowledged',
                                }.contains(req['status']))
                                  TextButton(
                                    onPressed: _busy == null
                                        ? () => _respond(
                                            req['id'].toString(),
                                            'withdrawn',
                                          )
                                        : null,
                                    child: const Text('Withdraw request'),
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
