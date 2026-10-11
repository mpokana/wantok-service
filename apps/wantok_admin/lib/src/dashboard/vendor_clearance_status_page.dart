import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

/// View issued clearances and revoke unsafe ones.
/// Issuance, document reading and KYC certification are NOT provided.
class VendorClearanceStatusPage extends StatefulWidget {
  const VendorClearanceStatusPage({
    super.key,
    this.loadStatus,
    this.canRevoke = true,
  });
  final Future<List<Map<String, dynamic>>> Function()? loadStatus;
  final bool canRevoke;
  @override
  State<VendorClearanceStatusPage> createState() =>
      _VendorClearanceStatusPageState();
}

class _VendorClearanceStatusPageState extends State<VendorClearanceStatusPage> {
  late Future<List<Map<String, dynamic>>> _future = _load();
  String? _busy;
  Future<List<Map<String, dynamic>>> _load() async {
    if (widget.loadStatus != null) return widget.loadStatus!();
    final data = await WantokBackend.client.rpc('list_vendor_clearance_status');
    return (data as List)
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList();
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _revoke(String providerId, String displayName) async {
    if (_busy != null) return;
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text('Suspend all active services for $displayName?'),
        content: SizedBox(
          width: 470,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This is an emergency safety action. It revokes an '
                'existing clearance, pauses all current active service listings '
                'for this provider and records your decision. It cannot be '
                'undone by clicking this button again.',
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                maxLines: 3,
                maxLength: 1000,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Reason (15–1000 characters)',
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
            child: const Text('Confirm revocation'),
          ),
        ],
      ),
    );
    final reason = controller.text.trim();
    controller.dispose();
    if (confirmed != true) return;
    if (reason.length < 15 || reason.length > 1000) {
      _notice('Please provide a 15–1000 character reason.');
      return;
    }
    setState(() => _busy = providerId);
    try {
      final count = await WantokBackend.client.rpc(
        'revoke_vendor_activation_clearance',
        params: {'p_provider_id': providerId, 'p_reason': reason},
      );
      _refresh();
      if (mounted) _notice('Clearance revoked. $count active services paused.');
    } catch (error) {
      if (mounted) _notice('Revocation failed: $error');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Clearance & Safety Controls'),
      actions: [
        IconButton(
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh clearances',
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
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
                  label: const Text('Cannot load clearance status. Retry'),
                ),
              );
            }
            final rows = snapshot.data ?? [];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: WantokColors.primaryDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OPERATIONS · TRUST & SAFETY',
                        style: TextStyle(
                          color: WantokColors.gold,
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Clearance monitoring',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.warning_amber_outlined,
                      color: Colors.orange,
                    ),
                    title: Text('No new clearance issuance in this release'),
                    subtitle: Text(
                      'This screen only shows the existing clearance '
                      'register and offers emergency revocation. '
                      'Automatic expiry maintenance is not scheduled yet.',
                    ),
                  ),
                ),
                if (rows.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text('No clearance records currently available'),
                      subtitle: Text(
                        'All new onboarding approvals remain gated.',
                      ),
                    ),
                  ),
                for (final row in rows)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row['display_name']?.toString() ?? 'Provider',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Provider ID: ${row['provider_id']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Expires: ${row['expires_at']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (row['revoked_at'] != null)
                            Text(
                              'Revoked: ${row['revoked_at']}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          if (widget.canRevoke &&
                              row['revoked_at'] == null) ...[
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _busy == null
                                  ? () => _revoke(
                                      row['provider_id'].toString(),
                                      row['display_name']?.toString() ??
                                          'Provider',
                                    )
                                  : null,
                              icon: const Icon(Icons.gpp_bad_outlined),
                              label: const Text(
                                'Emergency revoke & pause services',
                              ),
                            ),
                          ],
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
