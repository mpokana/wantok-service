import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_core/wantok_core.dart';
import 'package:wantok_ui/wantok_ui.dart';

import '../services/commerce_browse_page.dart';
import '../services/event_browse_page.dart';
import '../services/open_request_page.dart';
import '../services/reservation_browse_page.dart';
import '../services/taxi_ride_page.dart';
import '../services/water_transport_page.dart';

class ClientHome extends StatefulWidget {
  const ClientHome({super.key});

  @override
  State<ClientHome> createState() => _ClientHomeState();
}

class _ClientHomeState extends State<ClientHome> {
  final _catalog = const CatalogRepository();
  late Future<List<WantokServiceCategory>> _services;

  @override
  void initState() {
    super.initState();
    _services = _catalog.loadActiveServices();
  }

  Future<void> _reload() async {
    setState(() => _services = _catalog.loadActiveServices());
    await _services;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          const _LocationSearchCard(),
          const SizedBox(height: 16),
          const _WalletStrip(),
          const SizedBox(height: 22),
          Text(
            'What do you need today?',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Transport, food, deliveries, people and places — from one Wantok account.',
            style: TextStyle(color: WantokColors.muted),
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<WantokServiceCategory>>(
            future: _services,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Could not load services from the backend.',
                          ),
                        ),
                        IconButton(
                          onPressed: _reload,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final services = snapshot.data ?? const <WantokServiceCategory>[];
              return GridView.builder(
                itemCount: services.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 112,
                  mainAxisExtent: 116,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 6,
                ),
                itemBuilder: (context, index) {
                  final service = services[index];
                  final visual = _visualFor(service.slug);
                  return WantokServiceTile(
                    label: service.name,
                    icon: visual.icon,
                    accentColor: visual.accent,
                    surfaceColor: visual.surface,
                    badge: _badgeFor(service.slug),
                    onTap: () => _openService(service),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 18),
          const _PromoCard(),
          const SizedBox(height: 18),
          const _SafetyCard(),
        ],
      ),
    );
  }

  void _openService(WantokServiceCategory service) {
    if (service.slug == 'taxi-ride') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (context) => const TaxiRidePage()),
      );
      return;
    }

    if (const {
      'vehicle-hire',
      'boat-hire',
      'venue-booking',
    }.contains(service.slug)) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => ReservationBrowsePage(category: service),
        ),
      );
      return;
    }

    if (service.slug == 'boat-ship-rides') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => const WaterTransportPage(),
        ),
      );
      return;
    }

    if (service.slug == 'events') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (context) => const EventBrowsePage()),
      );
      return;
    }

    if (const {'food', 'groceries'}.contains(service.slug)) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => CommerceBrowsePage(category: service),
        ),
      );
      return;
    }

    if (const {
      'delivery',
      'errands',
      'specialist-services',
      'general-labour',
    }.contains(service.slug)) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => OpenRequestPage(category: service),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${service.name} module is being connected.')),
    );
  }

  _ServiceVisual _visualFor(String slug) => switch (slug) {
    'taxi-ride' => const _ServiceVisual(
      Icons.local_taxi,
      Color(0xFF007A50),
      Color(0xFFDDF5E9),
    ),
    'vehicle-hire' => const _ServiceVisual(
      Icons.directions_car,
      Color(0xFF2864DC),
      Color(0xFFE3EDFF),
    ),
    'boat-hire' => const _ServiceVisual(
      Icons.directions_boat,
      Color(0xFF087F8C),
      Color(0xFFDDF6F8),
    ),
    'boat-ship-rides' => const _ServiceVisual(
      Icons.sailing,
      Color(0xFF006C7C),
      Color(0xFFDDF3F5),
    ),
    'specialist-services' => const _ServiceVisual(
      Icons.handyman,
      Color(0xFFD86020),
      Color(0xFFFFE9DB),
    ),
    'general-labour' => const _ServiceVisual(
      Icons.groups,
      Color(0xFF744AC7),
      Color(0xFFEEE6FF),
    ),
    'venue-booking' => const _ServiceVisual(
      Icons.meeting_room,
      Color(0xFF8A4CA6),
      Color(0xFFF4E6F7),
    ),
    'events' => const _ServiceVisual(
      Icons.event,
      Color(0xFFD84A6A),
      Color(0xFFFFE4EA),
    ),
    'delivery' => const _ServiceVisual(
      Icons.local_shipping,
      Color(0xFF1585C1),
      Color(0xFFE0F2FF),
    ),
    'errands' => const _ServiceVisual(
      Icons.shopping_bag,
      Color(0xFFB66A00),
      Color(0xFFFFF0D8),
    ),
    'food' => const _ServiceVisual(
      Icons.restaurant,
      Color(0xFFE24B2D),
      Color(0xFFFFE5DE),
    ),
    'groceries' => const _ServiceVisual(
      Icons.local_grocery_store,
      Color(0xFF2E8B57),
      Color(0xFFE1F4E7),
    ),
    _ => const _ServiceVisual(
      Icons.apps,
      WantokColors.primaryDark,
      Color(0xFFE7F4ED),
    ),
  };

  String? _badgeFor(String slug) => switch (slug) {
    'taxi-ride' || 'delivery' => 'FAST',
    _ => null,
  };
}

class _ServiceVisual {
  const _ServiceVisual(this.icon, this.accent, this.surface);

  final IconData icon;
  final Color accent;
  final Color surface;
}

class _LocationSearchCard extends StatelessWidget {
  const _LocationSearchCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Good day 👋',
              style: TextStyle(
                color: WantokColors.primaryDark,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Where are you going, or what can a Wantok help with?',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              readOnly: true,
              onTap: () {},
              decoration: const InputDecoration(
                hintText: 'Search services or enter a place',
                prefixIcon: Icon(Icons.search),
                suffixIcon: Icon(Icons.my_location_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletStrip extends StatelessWidget {
  const _WalletStrip();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              color: WantokColors.primary,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wantok Pay',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Cash, cards and PNG payment rails will connect here.',
                    style: TextStyle(fontSize: 12, color: WantokColors.muted),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2D2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'COMING',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [WantokColors.primaryDark, WantokColors.primary],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(20),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'One app. Plenty ways to move PNG.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Ride, hire, deliver, book, buy or find skilled people nearby.',
                  style: TextStyle(color: Color(0xFFD9F3E5)),
                ),
              ],
            ),
          ),
          SizedBox(width: 14),
          Icon(Icons.explore_outlined, color: Colors.white, size: 54),
        ],
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  const _SafetyCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(0xFFFFE7E1),
          child: Icon(
            Icons.health_and_safety_outlined,
            color: WantokColors.coral,
          ),
        ),
        title: Text(
          'Safety built into every service',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          'Verified providers, trip/job records, SOS and dispute support are core platform services.',
        ),
        trailing: Icon(Icons.chevron_right),
      ),
    );
  }
}
