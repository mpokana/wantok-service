import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

class ResourceReviewPage extends StatefulWidget {
  const ResourceReviewPage({super.key});

  @override
  State<ResourceReviewPage> createState() => _ResourceReviewPageState();
}

class _ResourceReviewPageState extends State<ResourceReviewPage> {
  late Future<List<Map<String, dynamic>>> _future;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await WantokBackend.client
        .from('provider_resources')
        .select(
          'id, provider_id, category_id, resource_type, name, description, capacity, address_text, status, created_at, service_categories(name, slug), provider_profiles(display_name)',
        )
        .eq('status', 'pending_review')
        .order('created_at');

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  Future<void> _review(String id, String status) async {
    setState(() => _busyId = id);
    try {
      await WantokBackend.client.rpc(
        'admin_set_provider_resource_status',
        params: {'p_resource_id': id, 'p_status': status},
      );
      _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resource review failed: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resource review',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Approve vehicles, boats, venues and other physical resources before clients can reserve them.',
                      style: TextStyle(color: WantokColors.muted),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: WantokColors.coral,
                              size: 42,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Could not load resource reviews.',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: WantokColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final rows =
                    snapshot.data ?? const <Map<String, dynamic>>[];
                if (rows.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 52,
                          color: WantokColors.primary,
                        ),
                        SizedBox(height: 12),
                        Text('No resources are waiting for review.'),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    final id = row['id'] as String;
                    final busy = _busyId == id;
                    final category = _asMap(row['service_categories']);
                    final provider = _asMap(row['provider_profiles']);

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runSpacing: 12,
                          spacing: 18,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 650),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    row['name'] as String? ?? 'Resource',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${category['name'] ?? 'Service'} • ${row['resource_type'] ?? 'resource'}',
                                  ),
                                  if (provider['display_name'] != null)
                                    Text(
                                      'Provider: ${provider['display_name']}',
                                    ),
                                  if (row['capacity'] != null)
                                    Text('Capacity: ${row['capacity']}'),
                                  if (row['address_text'] != null)
                                    Text(
                                      'Location: ${row['address_text']}',
                                    ),
                                  if (row['description'] != null) ...[
                                    const SizedBox(height: 5),
                                    Text(
                                      row['description'].toString(),
                                      style: const TextStyle(
                                        color: WantokColors.muted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton(
                                  onPressed: busy
                                      ? null
                                      : () => _review(id, 'rejected'),
                                  child: const Text('Reject'),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: busy
                                      ? null
                                      : () => _review(id, 'active'),
                                  child: Text(
                                    busy ? 'Working...' : 'Approve',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}
