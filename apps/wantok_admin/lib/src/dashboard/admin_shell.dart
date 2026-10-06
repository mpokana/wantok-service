import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_auth/wantok_auth.dart';
import 'package:wantok_ui/wantok_ui.dart';

import 'resource_review_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({required this.roles, required this.email, super.key});

  final Set<String> roles;
  final String? email;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  static const _auth = WantokAuthService();

  int _index = 0;

  static const _destinations = [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Overview'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.how_to_reg_outlined),
      label: Text('Providers'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.storefront_outlined),
      label: Text('Listings'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.inventory_2_outlined),
      label: Text('Resources'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.receipt_long_outlined),
      label: Text('Bookings'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.history_outlined),
      label: Text('Audit'),
    ),
  ];

  static const _bottomDestinations = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      label: 'Overview',
    ),
    NavigationDestination(
      icon: Icon(Icons.how_to_reg_outlined),
      label: 'Providers',
    ),
    NavigationDestination(
      icon: Icon(Icons.storefront_outlined),
      label: 'Listings',
    ),
    NavigationDestination(
      icon: Icon(Icons.inventory_2_outlined),
      label: 'Resources',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      label: 'Bookings',
    ),
    NavigationDestination(icon: Icon(Icons.history_outlined), label: 'Audit'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _OverviewPage(),
      const _ProviderApplicationsPage(),
      const _ServiceReviewPage(),
      const ResourceReviewPage(),
      const _BookingsPage(),
      const _AuditPage(),
    ];

    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Wantok',
              style: TextStyle(
                color: WantokColors.primaryDark,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(width: 6),
            Text(
              'Admin',
              style: TextStyle(
                color: WantokColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          if (wide)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Center(
                child: Text(
                  widget.email ?? '',
                  style: const TextStyle(color: WantokColors.muted),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: _auth.signOut,
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  labelType: NavigationRailLabelType.all,
                  groupAlignment: -0.85,
                  onDestinationSelected: (value) {
                    setState(() => _index = value);
                  },
                  destinations: _destinations,
                ),
                const VerticalDivider(width: 1),
                Expanded(child: pages[_index]),
              ],
            )
          : pages[_index],
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) {
                setState(() => _index = value);
              },
              destinations: _bottomDestinations,
            ),
    );
  }
}

class _OverviewPage extends StatefulWidget {
  const _OverviewPage();

  @override
  State<_OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<_OverviewPage> {
  late Future<_AdminMetrics> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AdminMetrics> _load() async {
    final client = WantokBackend.client;

    final applications = await client
        .from('provider_applications')
        .select('id')
        .eq('status', 'pending');
    final services = await client
        .from('provider_services')
        .select('id')
        .eq('status', 'pending_review');
    final bookings = await client
        .from('service_bookings')
        .select('id')
        .inFilter('status', [
          'requested',
          'quoted',
          'accepted',
          'confirmed',
          'in_progress',
        ]);
    final audits = await client.from('audit_events').select('id').limit(100);

    return _AdminMetrics(
      providerApplications: (applications as List).length,
      serviceReviews: (services as List).length,
      activeBookings: (bookings as List).length,
      recentAudits: (audits as List).length,
    );
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return _AdminPageFrame(
      title: 'Operations overview',
      subtitle: 'Live platform workload from the Wantok backend.',
      action: IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
      child: FutureBuilder<_AdminMetrics>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorCard(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          final metrics = snapshot.data!;
          return Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _AdminMetricCard(
                label: 'Provider applications',
                value: metrics.providerApplications.toString(),
                icon: Icons.how_to_reg_outlined,
              ),
              _AdminMetricCard(
                label: 'Listings to review',
                value: metrics.serviceReviews.toString(),
                icon: Icons.storefront_outlined,
              ),
              _AdminMetricCard(
                label: 'Active bookings',
                value: metrics.activeBookings.toString(),
                icon: Icons.receipt_long_outlined,
              ),
              _AdminMetricCard(
                label: 'Recent audit records',
                value: metrics.recentAudits.toString(),
                icon: Icons.history_outlined,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProviderApplicationsPage extends StatefulWidget {
  const _ProviderApplicationsPage();

  @override
  State<_ProviderApplicationsPage> createState() =>
      _ProviderApplicationsPageState();
}

class _ProviderApplicationsPageState extends State<_ProviderApplicationsPage> {
  late Future<List<Map<String, dynamic>>> _future;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await WantokBackend.client
        .from('provider_applications')
        .select(
          'id, user_id, service_type, company_name, vehicle_plate, vehicle_make, vehicle_model, notes, status, created_at',
        )
        .eq('status', 'pending')
        .order('created_at');
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  Future<void> _review(String id, String decision) async {
    setState(() => _busyId = id);
    try {
      await WantokBackend.client.rpc(
        'review_provider_application',
        params: {'p_application_id': id, 'p_decision': decision},
      );
      _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Review failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AdminPageFrame(
      title: 'Provider applications',
      subtitle: 'Approve identity/business applications before vendor capabilities become available.',
      action: IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorCard(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          final rows = snapshot.data ?? const <Map<String, dynamic>>[];
          if (rows.isEmpty) {
            return const _EmptyState(
              icon: Icons.verified_outlined,
              message: 'No pending provider applications.',
            );
          }

          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final row = rows[index];
              final id = row['id'] as String;
              final busy = _busyId == id;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 12,
                    spacing: 18,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (row['company_name'] as String?)
                                          ?.trim()
                                          .isNotEmpty ==
                                      true
                                  ? row['company_name'] as String
                                  : 'Individual provider',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Service: ${row['service_type'] as String? ?? 'Unknown'}',
                            ),
                            if (row['vehicle_plate'] != null)
                              Text(
                                'Vehicle: ${row['vehicle_plate'] as String? ?? ''} ${row['vehicle_make'] as String? ?? ''} ${row['vehicle_model'] as String? ?? ''}',
                              ),
                            if (row['notes'] != null)
                              Text(
                                'Notes: ${row['notes']}',
                                style: const TextStyle(
                                  color: WantokColors.muted,
                                ),
                              ),
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
                                : () => _review(id, 'approved'),
                            child: Text(busy ? 'Working...' : 'Approve'),
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
    );
  }
}

class _ServiceReviewPage extends StatefulWidget {
  const _ServiceReviewPage();

  @override
  State<_ServiceReviewPage> createState() => _ServiceReviewPageState();
}

class _ServiceReviewPageState extends State<_ServiceReviewPage> {
  late Future<List<Map<String, dynamic>>> _future;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await WantokBackend.client
        .from('provider_services')
        .select(
          'id, provider_id, category_id, title, description, pricing_model, base_price, currency, status, created_at, service_categories(name)',
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
        'admin_set_provider_service_status',
        params: {'p_service_id': id, 'p_status': status},
      );
      _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Review failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AdminPageFrame(
      title: 'Service listing review',
      subtitle: 'Only approved vendor listings become discoverable to clients.',
      action: IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorCard(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          final rows = snapshot.data ?? const <Map<String, dynamic>>[];
          if (rows.isEmpty) {
            return const _EmptyState(
              icon: Icons.storefront_outlined,
              message: 'No service listings are waiting for review.',
            );
          }

          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final row = rows[index];
              final id = row['id'] as String;
              final busy = _busyId == id;
              final category =
                  row['service_categories'] as Map<String, dynamic>?;

              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    row['title'] as String? ?? 'Untitled service',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${category?['name'] as String? ?? 'Service'} • ${row['pricing_model'] as String? ?? 'pricing not set'}',
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: busy ? null : () => _review(id, 'rejected'),
                        child: const Text('Reject'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: busy ? null : () => _review(id, 'active'),
                        child: Text(busy ? 'Working...' : 'Approve'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _BookingsPage extends StatefulWidget {
  const _BookingsPage();

  @override
  State<_BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<_BookingsPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await WantokBackend.client
        .from('service_bookings')
        .select(
          'id, status, requested_amount, quoted_amount, final_amount, currency, created_at, service_categories(name)',
        )
        .order('created_at', ascending: false)
        .limit(100);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return _AdminPageFrame(
      title: 'Marketplace bookings',
      subtitle: 'Recent non-taxi bookings across Wantok Services.',
      action: IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorCard(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          final rows = snapshot.data ?? const <Map<String, dynamic>>[];
          if (rows.isEmpty) {
            return const _EmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'No marketplace bookings yet.',
            );
          }

          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final row = rows[index];
              final category =
                  row['service_categories'] as Map<String, dynamic>?;
              final amount =
                  row['final_amount'] ??
                  row['quoted_amount'] ??
                  row['requested_amount'];

              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.receipt_long_outlined),
                ),
                title: Text(category?['name'] as String? ?? 'Service booking'),
                subtitle: Text(
                  (row['status'] as String? ?? 'unknown').toUpperCase(),
                ),
                trailing: amount == null
                    ? null
                    : Text(
                        '${row['currency'] as String? ?? 'PGK'} $amount',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AuditPage extends StatefulWidget {
  const _AuditPage();

  @override
  State<_AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends State<_AuditPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await WantokBackend.client
        .from('audit_events')
        .select(
          'id, occurred_at, actor_user_id, action, entity_type, entity_id',
        )
        .order('occurred_at', ascending: false)
        .limit(100);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return _AdminPageFrame(
      title: 'Audit history',
      subtitle: 'Security and operational actions recorded by the backend.',
      action: IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorCard(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          final rows = snapshot.data ?? const <Map<String, dynamic>>[];
          if (rows.isEmpty) {
            return const _EmptyState(
              icon: Icons.history_outlined,
              message: 'No audit records yet.',
            );
          }

          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final row = rows[index];
              return ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: Text(row['action'] as String? ?? 'event'),
                subtitle: Text(
                  '${row['entity_type'] as String? ?? 'entity'} • ${row['occurred_at'] as String? ?? ''}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AdminPageFrame extends StatelessWidget {
  const _AdminPageFrame({
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: WantokColors.muted),
                    ),
                  ],
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 18),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _AdminMetricCard extends StatelessWidget {
  const _AdminMetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: WantokColors.primary),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: WantokColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
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
                  'Could not load this admin view.',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: WantokColors.muted),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: WantokColors.primary),
          const SizedBox(height: 12),
          Text(message),
        ],
      ),
    );
  }
}

class _AdminMetrics {
  const _AdminMetrics({
    required this.providerApplications,
    required this.serviceReviews,
    required this.activeBookings,
    required this.recentAudits,
  });

  final int providerApplications;
  final int serviceReviews;
  final int activeBookings;
  final int recentAudits;
}
