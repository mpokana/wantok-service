import 'package:flutter/material.dart';
import 'package:wantok_ui/wantok_ui.dart';

/// Only existing Operations modules have active navigation destinations.
/// Technical controls, money movement and approval powers remain separate.
class OperationsSidebar extends StatelessWidget {
  const OperationsSidebar({
    required this.selected,
    required this.onSelect,
    super.key,
  });
  final int selected;
  final ValueChanged<int> onSelect;
  static const entries = <(String, IconData)>[
    ('Overview', Icons.dashboard_rounded),
    ('Provider approvals', Icons.how_to_reg_outlined),
    ('Services & listings', Icons.storefront_outlined),
    ('Resources', Icons.inventory_2_outlined),
    ('Bookings & orders', Icons.receipt_long_outlined),
    ('Audit & activity', Icons.history_outlined),
    ('Support & inquiries', Icons.support_agent_outlined),
    ('Modules', Icons.tune_rounded),
  ];

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: WantokColors.primaryDark,
    child: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(10, 19, 10, 16),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(10, 3, 10, 13),
            child: Text(
              'OPERATIONS',
              style: TextStyle(
                color: WantokColors.gold,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ),
          for (var i = 0; i < entries.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: ListTile(
                key: ValueKey('operations-nav-$i'),
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                selected: i == selected,
                selectedTileColor: const Color(0xFFE0F3E8),
                textColor: Colors.white,
                iconColor: Colors.white,
                selectedColor: WantokColors.primaryDark,
                leading: Icon(
                  entries[i].$2,
                  size: 21,
                  color: i == selected
                      ? WantokColors.primaryDark
                      : Colors.white,
                ),
                title: Text(
                  entries[i].$1,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => onSelect(i),
              ),
            ),
          const Divider(color: Colors.white24, height: 28),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'PLANNED MODULES',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const ListTile(
            dense: true,
            enabled: false,
            leading: Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white54,
            ),
            title: Text(
              'Payments & settlements',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            subtitle: Text(
              'Not active',
              style: TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ),
          const ListTile(
            dense: true,
            enabled: false,
            leading: Icon(Icons.analytics_outlined, color: Colors.white54),
            title: Text(
              'Advanced analytics',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            subtitle: Text(
              'Roadmap',
              style: TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0C6A4A),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.groups_rounded, color: WantokColors.gold),
                SizedBox(height: 12),
                Text(
                  'Stronger communities',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontSize: 17,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Local people. Local services. Real impact.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
