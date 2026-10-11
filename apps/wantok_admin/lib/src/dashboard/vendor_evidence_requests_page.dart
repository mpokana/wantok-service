import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

/// Metadata-only evidence request dashboard.
/// NO document uploads, downloads, preview, clearance or activation.
class VendorEvidenceRequestsPage extends StatefulWidget {
  const VendorEvidenceRequestsPage({
    super.key,
    required this.caseId,
    required this.applicantName,
    this.loadRequests,
  });
  final String caseId, applicantName;
  final Future<(List<Map<String, dynamic>>, List<Map<String, dynamic>>)>
  Function()?
  loadRequests;
  @override
  State<VendorEvidenceRequestsPage> createState() =>
      _VendorEvidenceRequestsPageState();
}

class _VendorEvidenceRequestsPageState
    extends State<VendorEvidenceRequestsPage> {
  late Future<(List<Map<String, dynamic>>, List<Map<String, dynamic>>)>
  _future = _load();
  String? _busy;
  Future<(List<Map<String, dynamic>>, List<Map<String, dynamic>>)>
  _load() async {
    if (widget.loadRequests != null) return widget.loadRequests!();
    final db = WantokBackend.client;
    final checks = await db
        .from('vendor_verification_checks')
        .select('id,requirement_label,requirement_key')
        .eq('case_id', widget.caseId)
        .order('requirement_key');
    final requests = await db
        .from('vendor_evidence_requests')
        .select('id,check_id,requirement_note,status,requested_at,expires_at')
        .eq('case_id', widget.caseId)
        .order('requested_at', ascending: false);
    return (
      (checks as List).map((v) => Map<String, dynamic>.from(v as Map)).toList(),
      (requests as List)
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList(),
    );
  }

  void _refresh() => setState(() => _future = _load());
  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<String?> _reasonDialog(String title) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Describe what evidence is needed, not personal ID or '
              'tax numbers. Files cannot be submitted or viewed yet. '
              'No approval is granted by this request.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Reason (15–500 characters)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Record request'),
          ),
        ],
      ),
    );
    final value = controller.text.trim();
    controller.dispose();
    if (confirmed != true) return null;
    if (value.length < 15 || value.length > 500) {
      _notice('A 15–500 character explanation is required.');
      return null;
    }
    return value;
  }

  Future<void> _request(String checkId) async {
    if (_busy != null) return;
    final reason = await _reasonDialog('Record a document requirement');
    if (reason == null) return;
    setState(() => _busy = checkId);
    try {
      await WantokBackend.client.rpc(
        'request_vendor_evidence',
        params: {'p_check_id': checkId, 'p_note': reason},
      );
      _refresh();
    } catch (error) {
      if (mounted) _notice('Request failed: $error');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _cancel(String requestId) async {
    if (_busy != null) return;
    final reason = await _reasonDialog('Cancel evidence requirement');
    if (reason == null) return;
    setState(() => _busy = requestId);
    try {
      await WantokBackend.client.rpc(
        'cancel_vendor_evidence_request',
        params: {'p_request_id': requestId, 'p_reason': reason},
      );
      _refresh();
    } catch (error) {
      if (mounted) _notice('Cancellation failed: $error');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Evidence Requirements'),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child:
            FutureBuilder<
              (List<Map<String, dynamic>>, List<Map<String, dynamic>>)
            >(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.refresh),
                      onPressed: _refresh,
                      label: const Text('Cannot load requests. Retry'),
                    ),
                  );
                }
                final checks = snapshot.data!.$1, requests = snapshot.data!.$2;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: WantokColors.primaryDark,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EVIDENCE REQUEST REGISTER · NO UPLOAD',
                            style: TextStyle(
                              color: WantokColors.gold,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            widget.applicantName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Case: ${widget.caseId}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.lock_outline, color: Colors.orange),
                        title: Text(
                          'Document intake and KYC approval are disabled',
                        ),
                        subtitle: Text(
                          'Only metadata requests are recorded. The privacy '
                          'notice is a draft, not consent to upload. Do not send personal '
                          'documents through email, chat or these forms.',
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'Checklist requirements',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    for (final check in checks)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                check['requirement_label']?.toString() ??
                                    'Check',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 9),
                              OutlinedButton(
                                onPressed: _busy == null
                                    ? () => _request(check['id'].toString())
                                    : null,
                                child: const Text(
                                  'Request evidence (metadata)',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      'Request history (${requests.length})',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    for (final request in requests)
                      Card(
                        child: ListTile(
                          title: Text(
                            request['requirement_note']?.toString() ??
                                'Requirement',
                          ),
                          subtitle: Text(
                            'Status: ${request['status']}'
                            '\nExpires: ${request['expires_at']}'
                            '\nRequested: ${request['requested_at']}',
                          ),
                          isThreeLine: true,
                          trailing:
                              const {
                                'requested',
                                'acknowledged',
                              }.contains(request['status'])
                              ? TextButton(
                                  onPressed: _busy == null
                                      ? () => _cancel(request['id'].toString())
                                      : null,
                                  child: const Text('Cancel'),
                                )
                              : null,
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
