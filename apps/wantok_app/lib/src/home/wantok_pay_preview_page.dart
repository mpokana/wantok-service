import 'package:flutter/material.dart';
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
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5123B2), Color(0xFF7B35D8)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'A preview of everyday payments for PNG.',
                style: TextStyle(
                  color: Color(0xFFEDE4FF),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wantok Wallet preview',
                            style: TextStyle(
                              color: WantokColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'K0.00',
                            style: TextStyle(
                              color: WantokColors.ink,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Preview only — payment rails are not active yet.',
                            style: TextStyle(
                              color: WantokColors.muted,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFFEDE3FF),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: WantokColors.purplePay,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                backgroundColor: Color(0xFFE6F0FF),
                child: Icon(
                  Icons.verified_user_outlined,
                  color: Color(0xFF2864DC),
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
            title: 'Planned services',
            subtitle: 'Designed for Papua New Guinea payment needs.',
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
      return ColoredBox(color: const Color(0xFFF7F5FB), child: content);
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
