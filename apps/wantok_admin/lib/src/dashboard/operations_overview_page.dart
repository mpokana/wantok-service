import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

/// Read-only Operations snapshot. Supabase RLS and the app's admin auth gate
/// remain authoritative; no privileged keys or fixture records are used.
class OperationsSnapshot {
  const OperationsSnapshot({
    required this.pendingApplications,
    required this.pendingListings,
    required this.activeBookings,
    required this.recentAudits,
    required this.applications,
    required this.bookings,
    required this.audits,
  });
  final int pendingApplications;
  final int pendingListings;
  final int activeBookings;
  final int recentAudits;
  final List<Map<String, dynamic>> applications;
  final List<Map<String, dynamic>> bookings;
  final List<Map<String, dynamic>> audits;

  static Future<OperationsSnapshot> load() async {
    final db = WantokBackend.client;
    final pending =
        (await db
                .from('provider_applications')
                .select('id,company_name,service_type,status,created_at')
                .eq('status', 'pending')
                .order('created_at')
                .limit(100))
            .cast<Map<String, dynamic>>();
    final listings =
        (await db
                .from('provider_services')
                .select('id')
                .eq('status', 'pending_review')
                .limit(1000))
            .cast<Map<String, dynamic>>();
    final active =
        (await db
                .from('service_bookings')
                .select('id')
                .inFilter('status', [
                  'requested',
                  'quoted',
                  'accepted',
                  'confirmed',
                  'in_progress',
                ])
                .limit(1000))
            .cast<Map<String, dynamic>>();
    final bookings =
        (await db
                .from('service_bookings')
                .select(
                  'id,status,created_at,requested_amount,quoted_amount,final_amount,currency,service_categories(name)',
                )
                .order('created_at', ascending: false)
                .limit(8))
            .cast<Map<String, dynamic>>();
    final audits =
        (await db
                .from('audit_events')
                .select('id,action,entity_type,occurred_at')
                .order('occurred_at', ascending: false)
                .limit(8))
            .cast<Map<String, dynamic>>();
    return OperationsSnapshot(
      pendingApplications: pending.length,
      pendingListings: listings.length,
      activeBookings: active.length,
      recentAudits: audits.length,
      applications: pending.take(6).toList(growable: false),
      bookings: bookings,
      audits: audits,
    );
  }
}

/// Enterprise dashboard presentation at desktop, tablet and mobile widths.
/// All figures come from the authenticated database queries above. Planned
/// money/region modules have explicit blank gates, never invented K amounts.
class OperationsOverviewPage extends StatefulWidget {
  const OperationsOverviewPage({
    this.loader,
    this.onOpenProviders,
    this.onOpenListings,
    this.onOpenBookings,
    this.onOpenAudit,
    super.key,
  });
  final Future<OperationsSnapshot> Function()? loader;
  final VoidCallback? onOpenProviders;
  final VoidCallback? onOpenListings;
  final VoidCallback? onOpenBookings;
  final VoidCallback? onOpenAudit;
  @override
  State<OperationsOverviewPage> createState() => _OperationsOverviewPageState();
}

class _OperationsOverviewPageState extends State<OperationsOverviewPage> {
  late Future<OperationsSnapshot> _future;
  @override
  void initState() {
    super.initState();
    _future = (widget.loader ?? OperationsSnapshot.load)();
  }

  void _refresh() =>
      setState(() => _future = (widget.loader ?? OperationsSnapshot.load)());

  @override
  Widget build(BuildContext context) => FutureBuilder<OperationsSnapshot>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: WantokColors.coral,
                    size: 40,
                  ),
                  const SizedBox(height: 9),
                  const Text('Operations data unavailable'),
                  const SizedBox(height: 10),
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  TextButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      final data = snapshot.data!;
      return LayoutBuilder(
        builder: (context, area) {
          final desktop = area.maxWidth >= 1030;
          final tablet = area.maxWidth >= 630;
          final pad = desktop ? 24.0 : 16.0;
          final contentWidth = area.maxWidth - pad * 2;
          final gap = 12.0;
          final metricWidth =
              (contentWidth -
                  gap *
                      (desktop
                          ? 3
                          : tablet
                          ? 1
                          : 0)) /
              (desktop
                  ? 4
                  : tablet
                  ? 2
                  : 1);
          return ListView(
            key: const ValueKey('operations-overview'),
            padding: EdgeInsets.all(pad),
            children: [
              Container(
                key: const ValueKey('operations-hero'),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06412E), Color(0xFF086B4B)],
                  ),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 18,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WANTOK OPERATIONS',
                          style: TextStyle(
                            color: WantokColors.gold,
                            letterSpacing: 1.6,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Operations overview',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Service activity and review queues across Wantok Services',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: _refresh,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 17),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _metric(
                    metricWidth,
                    'Pending applications',
                    data.pendingApplications,
                    Icons.how_to_reg_rounded,
                    widget.onOpenProviders,
                  ),
                  _metric(
                    metricWidth,
                    'Listings to review',
                    data.pendingListings,
                    Icons.storefront_rounded,
                    widget.onOpenListings,
                  ),
                  _metric(
                    metricWidth,
                    'Active bookings',
                    data.activeBookings,
                    Icons.receipt_long_rounded,
                    widget.onOpenBookings,
                  ),
                  _metric(
                    metricWidth,
                    'Recent audit events',
                    data.recentAudits,
                    Icons.shield_outlined,
                    widget.onOpenAudit,
                  ),
                ],
              ),
              const SizedBox(height: 17),
              if (tablet)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _panel(
                        'Bookings by category',
                        'Based on the latest loaded bookings · not total platform volume',
                        _categories(data.bookings),
                        widget.onOpenBookings,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _panel(
                        'Regional activity',
                        'Awaiting authorised regional aggregate data',
                        const _PlannedPanel(
                          icon: Icons.map_outlined,
                          message:
                              'Regional coverage reporting is not configured.',
                        ),
                        null,
                      ),
                    ),
                  ],
                )
              else ...[
                _panel(
                  'Bookings by category',
                  'Latest loaded booking sample',
                  _categories(data.bookings),
                  widget.onOpenBookings,
                ),
                const SizedBox(height: 12),
                _panel(
                  'Regional activity',
                  'Reporting not configured',
                  const _PlannedPanel(
                    icon: Icons.map_outlined,
                    message: 'Regional coverage reporting is not configured.',
                  ),
                  null,
                ),
              ],
              const SizedBox(height: 12),
              if (tablet)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _panel(
                        'Provider approvals',
                        'Pending real applications · review in Providers',
                        _queue(data.applications),
                        widget.onOpenProviders,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _panel(
                        'Recent bookings',
                        'Read-only live booking records',
                        _bookings(data.bookings),
                        widget.onOpenBookings,
                      ),
                    ),
                  ],
                )
              else ...[
                _panel(
                  'Provider approvals',
                  'Pending real applications',
                  _queue(data.applications),
                  widget.onOpenProviders,
                ),
                const SizedBox(height: 12),
                _panel(
                  'Recent bookings',
                  'Read-only live booking records',
                  _bookings(data.bookings),
                  widget.onOpenBookings,
                ),
              ],
              const SizedBox(height: 12),
              if (tablet)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _panel(
                        'Operational audit trail',
                        'Latest recorded events',
                        _audit(data.audits),
                        widget.onOpenAudit,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _panel(
                        'Payments & wallet',
                        'Planned · transaction processing disabled',
                        const _PlannedPanel(
                          icon: Icons.account_balance_wallet_outlined,
                          message:
                              'Payment volume, settlement analytics and '
                              'transaction reports are not active.',
                        ),
                        null,
                      ),
                    ),
                  ],
                )
              else ...[
                _panel(
                  'Operational audit trail',
                  'Latest recorded events',
                  _audit(data.audits),
                  widget.onOpenAudit,
                ),
                const SizedBox(height: 12),
                _panel(
                  'Payments & wallet',
                  'Not yet activated',
                  const _PlannedPanel(
                    icon: Icons.lock_outline,
                    message: 'Transactions and settlements are not active.',
                  ),
                  null,
                ),
              ],
            ],
          );
        },
      );
    },
  );

  Widget _metric(
    double width,
    String label,
    int value,
    IconData icon,
    VoidCallback? onTap,
  ) => SizedBox(
    width: width,
    child: Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        key: ValueKey('operations-metric-$label'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: const Color(0xFFDDF2E6),
                child: Icon(icon, color: WantokColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value.toString(),
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 2,
                      style: const TextStyle(
                        color: WantokColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right_rounded, size: 17),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _panel(
    String title,
    String subtitle,
    Widget contents,
    VoidCallback? more,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (more != null)
                  TextButton(onPressed: more, child: const Text('View all')),
              ],
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: WantokColors.muted),
            ),
            const SizedBox(height: 11),
            contents,
          ],
        ),
      ),
    );
  }

  Widget _categories(List<Map<String, dynamic>> rows) {
    final counts = <String, int>{};
    for (final row in rows) {
      final cat = row['service_categories'];
      final name = cat is Map ? (cat['name']?.toString() ?? 'Other') : 'Other';
      counts[name] = (counts[name] ?? 0) + 1;
    }
    if (counts.isEmpty) {
      return const Text(
        'No recent bookings.',
        style: TextStyle(color: WantokColors.muted),
      );
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      children: [
        for (final e in entries.take(6))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    e.key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: LinearProgressIndicator(
                    minHeight: 9,
                    borderRadius: BorderRadius.circular(6),
                    value: e.value / rows.length,
                    backgroundColor: const Color(0xFFE5EFE9),
                    color: WantokColors.primary,
                  ),
                ),
                const SizedBox(width: 7),
                SizedBox(width: 18, child: Text(e.value.toString())),
              ],
            ),
          ),
      ],
    );
  }

  Widget _queue(List<Map<String, dynamic>> rows) => _recordList(
    rows,
    Icons.how_to_reg_outlined,
    (row) => (row['company_name']?.toString().trim().isNotEmpty ?? false)
        ? row['company_name'].toString()
        : 'Individual applicant',
    (row) => row['service_type']?.toString() ?? 'Application',
    'No pending applications.',
  );
  Widget _bookings(List<Map<String, dynamic>> rows) => _recordList(
    rows,
    Icons.receipt_long_outlined,
    (row) =>
        ((row['service_categories'] is Map)
            ? (row['service_categories'] as Map)['name']?.toString()
            : null) ??
        'Service booking',
    (row) => row['status']?.toString() ?? 'Unknown',
    'No recent bookings.',
  );
  Widget _audit(List<Map<String, dynamic>> rows) => _recordList(
    rows,
    Icons.shield_outlined,
    (row) => row['action']?.toString() ?? 'Event',
    (row) => row['entity_type']?.toString() ?? 'Audit event',
    'No recent audit records.',
  );

  Widget _recordList(
    List<Map<String, dynamic>> rows,
    IconData icon,
    String Function(Map<String, dynamic>) title,
    String Function(Map<String, dynamic>) subtitle,
    String empty,
  ) {
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(empty, style: const TextStyle(color: WantokColors.muted)),
      );
    }
    return Column(
      children: [
        for (final row in rows.take(6))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFE4F3EA),
                  child: Icon(icon, size: 17, color: WantokColors.primary),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title(row),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        subtitle(row),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: WantokColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PlannedPanel extends StatelessWidget {
  const _PlannedPanel({required this.icon, required this.message});
  final IconData icon;
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(
      children: [
        Icon(icon, color: WantokColors.muted, size: 29),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: WantokColors.muted, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
