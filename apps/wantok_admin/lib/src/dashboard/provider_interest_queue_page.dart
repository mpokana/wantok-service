import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

/// Read-only pre-onboarding signals. A registered interest cannot be approved
/// or promoted to a provider application through this screen.
class ProviderInterestQueuePage extends StatefulWidget {
  const ProviderInterestQueuePage({super.key});

  @override
  State<ProviderInterestQueuePage> createState() =>
      _ProviderInterestQueuePageState();
}

class _ProviderInterestQueuePageState extends State<ProviderInterestQueuePage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await WantokBackend.client
        .from('provider_category_interests')
        .select(
          'id, user_id, created_at, status, service_categories(name,slug)',
        )
        .order('created_at', ascending: false)
        .limit(100);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      /* Error card remains retryable. */
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Provider interest queue')),
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
              label: const Text('Unable to load interests — Retry'),
            ),
          );
        }
        final rows = snapshot.data ?? const <Map<String, dynamic>>[];
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Card(
                color: const Color(0xFFEAF4FF),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: WantokColors.primary,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Pre-onboarding expressions of interest only. '
                          'No identity/licence verification, provider approval, '
                          'listing publication, payments or bookings are enabled.',
                          style: TextStyle(height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${rows.length} most recent interests',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No provider interest registrations yet.'),
                )
              else
                for (final row in rows)
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.pending_actions_outlined,
                        color: WantokColors.primary,
                      ),
                      title: Text(
                        ((row['service_categories'] as Map?)?['name'] ??
                                'Category')
                            .toString(),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        'Received ${row['created_at']?.toString().split('T').first ?? ''} '
                        '• account …${row['user_id']?.toString().substring(0, 8) ?? 'unknown'}',
                      ),
                      trailing: const Text(
                        'Interest only',
                        style: TextStyle(color: WantokColors.muted),
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
