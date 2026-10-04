import 'package:flutter/material.dart';
import 'package:wantok_ui/wantok_ui.dart';

class VendorHome extends StatelessWidget {
  const VendorHome({required this.hasVendorAccess, super.key});

  final bool hasVendorAccess;

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
            FilledButton.tonalIcon(
              onPressed: () {},
              icon: const Icon(Icons.toggle_on_outlined),
              label: const Text('Available'),
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
                value: '—',
                icon: Icons.work_outline,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Active jobs',
                value: '—',
                icon: Icons.pending_actions_outlined,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Rating',
                value: '—',
                icon: Icons.star_outline,
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
        const _ActionCard(
          icon: Icons.request_quote_outlined,
          title: 'Requests & quotes',
          body: 'Review matching customer requests and submit secure quotes.',
        ),
        const SizedBox(height: 10),
        const _ActionCard(
          icon: Icons.storefront_outlined,
          title: 'My services',
          body: 'Manage listings, pricing, service areas and approval status.',
        ),
        const SizedBox(height: 10),
        const _ActionCard(
          icon: Icons.calendar_month_outlined,
          title: 'Availability',
          body: 'Control schedules and resource availability without double bookings.',
        ),
        const SizedBox(height: 10),
        const _ActionCard(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Earnings & settlements',
          body: 'Future payment and settlement records will be managed here.',
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
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
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
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: WantokColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(body),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
