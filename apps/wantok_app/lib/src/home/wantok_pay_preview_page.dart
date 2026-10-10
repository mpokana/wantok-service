import 'package:flutter/material.dart';

import 'smoke_data.dart';

import 'package:wantok_ui/wantok_ui.dart';

import 'png_visuals.dart';

class WantokPayPreviewPage extends StatelessWidget {
  const WantokPayPreviewPage({this.embedded = false, super.key});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Wallet',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  color: WantokColors.ink,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF064431),
                      Color(0xFF096B4B),
                      Color(0xFF128761),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wantok Wallet preview',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 7),
                          Text(
                            'K0.00',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 33,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Preview only - payment rails are not active yet.',
                            style: TextStyle(
                              color: Color(0xFFE3F5EC),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        color: WantokColors.primary,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (WantokSmokeData.enabled)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SmokePreviewSection(
              scene: SmokeScene.wallet,
              heading: 'Sample recent activity',
            ),
          ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: PngSectionTitle(
            title: 'Planned actions',
            subtitle: 'Prepared for future PNG payment integrations.',
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height:
              116 +
              (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0, 2) * 100,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            scrollDirection: Axis.horizontal,
            children: const [
              _PayAction(icon: Icons.add_card_rounded, label: 'Top up'),
              _PayAction(icon: Icons.qr_code_scanner_rounded, label: 'Scan'),
              _PayAction(icon: Icons.north_east_rounded, label: 'Send'),
              _PayAction(icon: Icons.south_west_rounded, label: 'Receive'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Card(
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: Color(0xFFE2F4EA),
                child: Icon(
                  Icons.verified_user_outlined,
                  color: WantokColors.primary,
                ),
              ),
              title: Text(
                'Profile verification will unlock payment features',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                'Identity, limits and payment-provider integration will be '
                'connected only after the Wantok Pay design gate.',
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: PngSectionTitle(
            title: 'Planned payment methods',
            subtitle:
                'Visible for product planning only. No rail is active yet.',
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _PaymentMethodPreview(
                icon: Icons.credit_card_rounded,
                label: 'Visa',
                note: 'Planned card rail',
              ),
              _PaymentMethodPreview(
                icon: Icons.credit_card_rounded,
                label: 'Mastercard',
                note: 'Planned card rail',
              ),
              _PaymentMethodPreview(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Google Pay',
                note: 'Planned wallet rail',
              ),
              _PaymentMethodPreview(
                icon: Icons.payments_rounded,
                label: 'PayPal',
                note: 'Planned online rail',
              ),
              _PaymentMethodPreview(
                icon: Icons.account_balance_rounded,
                label: 'Bank Transfer',
                note: 'Market-specific bank rails',
              ),
              _PaymentMethodPreview(
                icon: Icons.phone_android_rounded,
                label: 'Mobile money',
                note: 'Market-specific wallet rails',
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: PngSectionTitle(
            title: 'Planned services',
            subtitle: 'Designed for local and international payment needs.',
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _PlannedChip(
                icon: Icons.phone_android_rounded,
                label: 'Mobile top-up',
              ),
              _PlannedChip(
                icon: Icons.receipt_long_rounded,
                label: 'Pay bills',
              ),
              _PlannedChip(
                icon: Icons.account_balance_rounded,
                label: 'Bank rails',
              ),
              _PlannedChip(icon: Icons.redeem_rounded, label: 'Rewards'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: PngSectionTitle(
            title: 'Recent activity',
            subtitle: 'Wallet history will appear here when payment rails are enabled.',
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(22),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: WantokColors.purplePay,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No Wantok Pay transactions yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'This remains a safe preview. Cash-in, transfers, QR payments, bills and settlement are disabled until the Wantok Pay design gate is approved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: WantokColors.muted, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );

    if (embedded) {
      return ColoredBox(color: WantokColors.canvas, child: content);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FB),
      appBar: AppBar(
        backgroundColor: WantokColors.purplePay,
        foregroundColor: Colors.white,
        title: const Text(
          'Wantok Pay',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: content,
    );
  }
}

class _PayAction extends StatelessWidget {
  const _PayAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width:
          108 +
          (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0, 2) * 70,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7E0F1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: WantokColors.purplePay, size: 26),
          const SizedBox(height: 7),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _PaymentMethodPreview extends StatelessWidget {
  const _PaymentMethodPreview({
    required this.icon,
    required this.label,
    required this.note,
  });

  final IconData icon;
  final String label;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 164,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E0F1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFF0E9FC),
            child: Icon(icon, color: WantokColors.purplePay, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: WantokColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  note,
                  style: const TextStyle(
                    color: WantokColors.muted,
                    fontSize: 9.5,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannedChip extends StatelessWidget {
  const _PlannedChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE6E1EE)),
      ),
      child: Row(
        children: [
          Icon(icon, color: WantokColors.purplePay),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
