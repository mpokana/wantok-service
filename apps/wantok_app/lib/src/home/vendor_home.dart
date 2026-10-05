import 'package:flutter/material.dart';
import 'package:wantok_ui/wantok_ui.dart';

class VendorHome extends StatelessWidget {
  const VendorHome({
    required this.hasVendorAccess,
    required this.onOpenJobs,
    required this.onOpenListings,
    super.key,
  });

  final bool hasVendorAccess;
  final VoidCallback onOpenJobs;
  final VoidCallback onOpenListings;

  @override
  Widget build(BuildContext context) {
    if (!hasVendorAccess) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Become a Wantok Vendor',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use the same account to earn by driving, delivering, hiring assets, hosting venues, selling food or offering professional and labour services.',
            style: TextStyle(color: WantokColors.muted),
          ),
          const SizedBox(height: 18),
          const _VendorBenefit(
            icon: Icons.verified_user_outlined,
            title: 'One verified provider profile',
            body: 'Identity and business verification are shared across your approved services.',
          ),
          const SizedBox(height: 10),
          const _VendorBenefit(
            icon: Icons.category_outlined,
            title: 'Multiple service capabilities',
            body: 'A single vendor can operate several approved services without creating new accounts.',
          ),
          const SizedBox(height: 10),
          const _VendorBenefit(
            icon: Icons.payments_outlined,
            title: 'Jobs, earnings and settlements',
            body: 'Quotes, bookings, work history and future payouts stay in one vendor workspace.',
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.how_to_reg_outlined),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 13),
              child: Text('Apply to become a vendor'),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Vendor dashboard',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            const Chip(
              avatar: Icon(Icons.verified_outlined, size: 17),
              label: Text('Provider'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Manage your services and work from the same Wantok account.',
          style: TextStyle(color: WantokColors.muted),
        ),
        const SizedBox(height: 18),
        const Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Open requests',
                value: 'Jobs',
                icon: Icons.work_outline,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Resources',
                value: 'Manage',
                icon: Icons.inventory_2_outlined,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Availability',
                value: 'Control',
                icon: Icons.event_available_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Quick actions',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        _ActionCard(
          icon: Icons.request_quote_outlined,
          title: 'Requests & jobs',
          body: 'Confirm reservation requests, send quotes and progress active work.',
          onTap: onOpenJobs,
        ),
        const SizedBox(height: 10),
        _ActionCard(
          icon: Icons.storefront_outlined,
          title: 'Services & resources',
          body: 'Manage listings, prices, vehicles, boats, venues and approval status.',
          onTap: onOpenListings,
        ),
        const SizedBox(height: 10),
        _ActionCard(
          icon: Icons.calendar_month_outlined,
          title: 'Availability',
          body: 'Block unavailable resource time. Recurring schedules are enforced by the backend.',
          onTap: onOpenListings,
        ),
        const SizedBox(height: 10),
        const _ActionCard(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Earnings & settlements',
          body: 'Payment and settlement records will be connected in a later platform phase.',
        ),
      ],
    );
  }
}

class _VendorBenefit extends StatelessWidget {
  const _VendorBenefit({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE7F4ED),
          child: Icon(icon, color: WantokColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(body),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: WantokColors.primary),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: WantokColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.body,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: WantokColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(body),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      ),
    );
  }
}
