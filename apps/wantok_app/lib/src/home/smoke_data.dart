import 'package:flutter/material.dart';
import 'package:wantok_ui/wantok_ui.dart';

/// Development-only presentation data. Nothing in this file is written to
/// Supabase or used by payment, dispatch, booking, or provider APIs.
abstract final class WantokSmokeData {
  static const enabled = bool.fromEnvironment(
    'WANTOK_SMOKE_DATA',
    defaultValue: false,
  );

  static const namespace = 'SMOKE_20261008';
}

enum SmokeScene {
  providers,
  food,
  groceries,
  bookings,
  wallet,
  inbox,
  events,
  travel,
  trades,
}

class SmokeRecord {
  const SmokeRecord({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.icon,
    this.detail = '',
  });

  final String id;
  final String title;
  final String subtitle;
  final String asset;
  final IconData icon;
  final String detail;
}

abstract final class SmokeCatalogue {
  static const providers = <SmokeRecord>[
    SmokeRecord(
      id: 'SMOKE_20261008_PROVIDER_001',
      title: 'The Waterfront',
      subtitle: 'Sample restaurant · Port Moresby',
      asset: 'assets/images/hero_food.png',
      icon: Icons.restaurant,
      detail: 'Sample listing only · Food & Restaurants',
    ),
    SmokeRecord(
      id: 'SMOKE_20261008_PROVIDER_002',
      title: 'Local market vendor',
      subtitle: 'Sample fresh produce shop',
      asset: 'assets/images/hero_groceries.png',
      icon: Icons.shopping_basket,
      detail: 'Sample listing only · Groceries',
    ),
  ];

  static const food = <SmokeRecord>[
    SmokeRecord(
      id: 'SMOKE_20261008_FOOD_001',
      title: 'The Waterfront',
      subtitle: 'Sample food provider · not accepting real orders',
      asset: 'assets/images/hero_food.png',
      icon: Icons.restaurant,
      detail: 'Sample grilled fish menu · K38.00',
    ),
    SmokeRecord(
      id: 'SMOKE_20261008_FOOD_002',
      title: 'Trukai Haus',
      subtitle: 'Sample PNG-style meal provider',
      asset: 'assets/images/hero_food.png',
      icon: Icons.restaurant_menu,
      detail: 'Sample local dishes · K32.00',
    ),
  ];

  static const groceries = <SmokeRecord>[
    SmokeRecord(
      id: 'SMOKE_20261008_GROCERY_001',
      title: 'Fresh Market Basket',
      subtitle: 'Sample produce catalogue',
      asset: 'assets/images/hero_groceries.png',
      icon: Icons.shopping_basket,
      detail: 'Sample vegetables and fruit · K25.00',
    ),
  ];

  static const bookings = <SmokeRecord>[
    SmokeRecord(
      id: 'SMOKE_20261008_BOOKING_001',
      title: 'Taxi to Ela Beach',
      subtitle: 'Sample trip · driver on the way',
      asset: 'assets/images/hero_delivery.png',
      icon: Icons.local_taxi,
      detail: 'Illustrative booking · no vehicle dispatched',
    ),
    SmokeRecord(
      id: 'SMOKE_20261008_BOOKING_002',
      title: 'The Waterfront',
      subtitle: 'Sample food order · preparing',
      asset: 'assets/images/hero_food.png',
      icon: Icons.restaurant,
      detail: 'Illustrative order · no payment collected',
    ),
    SmokeRecord(
      id: 'SMOKE_20261008_BOOKING_003',
      title: 'Coastal water transfer',
      subtitle: 'Sample trip · awaiting confirmation',
      asset: 'assets/images/hero_water.png',
      icon: Icons.directions_boat,
      detail: 'Illustrative reservation · not booked',
    ),
  ];

  static const wallet = <SmokeRecord>[
    SmokeRecord(
      id: 'SMOKE_20261008_WALLET_001',
      title: 'The Waterfront',
      subtitle: 'Sample payment history',
      asset: 'assets/images/hero_food.png',
      icon: Icons.receipt_long,
      detail: '− K38.00 · not a real transaction',
    ),
    SmokeRecord(
      id: 'SMOKE_20261008_WALLET_002',
      title: 'Taxi ride',
      subtitle: 'Sample payment history',
      asset: 'assets/images/hero_delivery.png',
      icon: Icons.local_taxi,
      detail: '− K25.00 · not a real transaction',
    ),
  ];

  static const inbox = <SmokeRecord>[
    SmokeRecord(
      id: 'SMOKE_20261008_INBOX_001',
      title: 'Driver John P.',
      subtitle: 'Sample conversation: I am on my way.',
      asset: 'assets/images/hero_delivery.png',
      icon: Icons.chat,
      detail: 'Preview-only conversation · no real message sent',
    ),
  ];

  static const events = <SmokeRecord>[
    SmokeRecord(
      id: 'SMOKE_20261008_EVENT_001',
      title: 'Community cultural showcase',
      subtitle: 'Sample community event',
      asset: 'assets/images/hero_events.png',
      icon: Icons.celebration,
      detail: 'Preview only · no registration available',
    ),
  ];

  static const travel = <SmokeRecord>[
    SmokeRecord(
      id: 'SMOKE_20261008_TRAVEL_001',
      title: 'Island travel experience',
      subtitle: 'Sample travel enquiry',
      asset: 'assets/images/hero_water.png',
      icon: Icons.flight,
      detail: 'Preview only · no actual travel inventory',
    ),
  ];

  static const trades = <SmokeRecord>[
    SmokeRecord(
      id: 'SMOKE_20261008_TRADES_001',
      title: 'Local electrical services',
      subtitle: 'Sample service provider',
      asset: 'assets/images/hero_trades.png',
      icon: Icons.handyman,
      detail: 'Preview only · no provider contacted',
    ),
  ];

  static List<SmokeRecord> recordsFor(SmokeScene scene) => switch (scene) {
    SmokeScene.providers => providers,
    SmokeScene.food => food,
    SmokeScene.groceries => groceries,
    SmokeScene.bookings => bookings,
    SmokeScene.wallet => wallet,
    SmokeScene.inbox => inbox,
    SmokeScene.events => events,
    SmokeScene.travel => travel,
    SmokeScene.trades => trades,
  };
}

/// The lower-case s is deliberately small but visible beside every sample.
class SmokeMarker extends StatelessWidget {
  const SmokeMarker({super.key});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Smoke / sample content — not a real record',
    child: Semantics(
      label: 's, smoke sample data',
      child: Container(
        width: 17,
        height: 17,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFE5F0FF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: WantokColors.primary),
        ),
        child: const Text(
          's',
          style: TextStyle(
            color: WantokColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    ),
  );
}

class SmokePreviewSection extends StatelessWidget {
  const SmokePreviewSection({required this.scene, this.heading, super.key});

  final SmokeScene scene;
  final String? heading;

  @override
  Widget build(BuildContext context) {
    final records = SmokeCatalogue.recordsFor(scene);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SmokeMarker(),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  heading ?? 'Sample preview',
                  style: const TextStyle(
                    color: WantokColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text(
            'Smoke/sample records. No real orders, bookings or payments.',
            style: TextStyle(color: WantokColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 8),
          for (final record in records)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SmokeRecordTile(record: record),
            ),
        ],
      ),
    );
  }
}

class _SmokeRecordTile extends StatelessWidget {
  const _SmokeRecordTile({required this.record});

  final SmokeRecord record;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: ValueKey(record.id),
        borderRadius: BorderRadius.circular(16),
        onTap: () => showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const SmokeMarker(),
                const SizedBox(width: 9),
                Expanded(child: Text(record.title)),
              ],
            ),
            content: Text(
              '${record.detail}\n\nSample ID: ${record.id}\n'
              'This item is presentation-only and cannot submit a real action.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close sample'),
              ),
            ],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EDF5)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.asset(
                  record.asset,
                  width: 65,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            record.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        const SmokeMarker(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.subtitle,
                      style: const TextStyle(
                        color: WantokColors.muted,
                        fontSize: 11,
                      ),
                    ),
                    if (record.detail.isNotEmpty)
                      Text(
                        record.detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: WantokColors.primary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: WantokColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
