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
import 'png_visuals.dart';
import 'wantok_pay_preview_page.dart';

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
    final next = _catalog.loadActiveServices();
    setState(() {
      _services = next;
    });
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<List<WantokServiceCategory>>(
        future: _services,
        builder: (context, snapshot) {
          final services = snapshot.data ?? const <WantokServiceCategory>[];

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
            children: [
              const _PngHomeHero(),
              const SizedBox(height: 14),
              _WantokPayStrip(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const WantokPayPreviewPage(),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const PngSectionTitle(
                title: 'What do you need today?',
                subtitle: 'Local transport, food, delivery, people and places — one Wantok account.',
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState != ConnectionState.done)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snapshot.hasError)
                Card(
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
                )
              else
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xFFE4ECE8)),
                    boxShadow: [
                      BoxShadow(
                        color: WantokColors.primaryDark.withValues(alpha: 0.07),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: GridView.builder(
                    itemCount: services.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisExtent: 114,
                          crossAxisSpacing: 5,
                          mainAxisSpacing: 3,
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
                  ),
                ),
              if (services.isNotEmpty) ...[
                const SizedBox(height: 22),
                PngSectionTitle(
                  title: 'Popular ways to use Wantok',
                  subtitle: 'Jump straight into a service.',
                  trailing: TextButton(
                    onPressed: _reload,
                    child: const Text('Refresh'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 152,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _spotlights(services),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              const _PngPurposeBanner(),
              const SizedBox(height: 18),
              const _SafetyCard(),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _spotlights(List<WantokServiceCategory> services) {
    final picks = <String, ({String title, String subtitle, IconData icon})>{
      'taxi-ride': (
        title: 'Need a ride?',
        subtitle: 'Request a local taxi or driver.',
        icon: Icons.local_taxi_rounded,
      ),
      'food': (
        title: 'Hungry?',
        subtitle: 'Browse food from local vendors.',
        icon: Icons.restaurant_rounded,
      ),
      'delivery': (
        title: 'Send something',
        subtitle: 'Book a courier or delivery.',
        icon: Icons.local_shipping_rounded,
      ),
      'specialist-services': (
        title: 'Find skilled help',
        subtitle: 'Trades, specialists and services.',
        icon: Icons.handyman_rounded,
      ),
    };

    final widgets = <Widget>[];
    for (final entry in picks.entries) {
      final service = services.cast<WantokServiceCategory?>().firstWhere(
        (item) => item?.slug == entry.key,
        orElse: () => null,
      );
      if (service == null) continue;
      final visual = _visualFor(service.slug);
      widgets.add(
        _ServiceSpotlight(
          title: entry.value.title,
          subtitle: entry.value.subtitle,
          icon: entry.value.icon,
          accent: visual.accent,
          surface: visual.surface,
          onTap: () => _openService(service),
        ),
      );
    }
    return widgets;
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
      Icons.local_taxi_rounded,
      Color(0xFF007A50),
      Color(0xFFDDF5E9),
    ),
    'vehicle-hire' => const _ServiceVisual(
      Icons.directions_car_rounded,
      Color(0xFF2864DC),
      Color(0xFFE3EDFF),
    ),
    'boat-hire' => const _ServiceVisual(
      Icons.directions_boat_rounded,
      Color(0xFF087F8C),
      Color(0xFFDDF6F8),
    ),
    'boat-ship-rides' => const _ServiceVisual(
      Icons.sailing_rounded,
      Color(0xFF006C7C),
      Color(0xFFDDF3F5),
    ),
    'specialist-services' => const _ServiceVisual(
      Icons.handyman_rounded,
      Color(0xFFD86020),
      Color(0xFFFFE9DB),
    ),
    'general-labour' => const _ServiceVisual(
      Icons.groups_rounded,
      Color(0xFF744AC7),
      Color(0xFFEEE6FF),
    ),
    'venue-booking' => const _ServiceVisual(
      Icons.apartment_rounded,
      Color(0xFF8A4CA6),
      Color(0xFFF4E6F7),
    ),
    'events' => const _ServiceVisual(
      Icons.event_rounded,
      Color(0xFFD84A6A),
      Color(0xFFFFE4EA),
    ),
    'delivery' => const _ServiceVisual(
      Icons.local_shipping_rounded,
      Color(0xFF1585C1),
      Color(0xFFE0F2FF),
    ),
    'errands' => const _ServiceVisual(
      Icons.shopping_bag_rounded,
      Color(0xFFB66A00),
      Color(0xFFFFF0D8),
    ),
    'food' => const _ServiceVisual(
      Icons.restaurant_rounded,
      Color(0xFFE24B2D),
      Color(0xFFFFE5DE),
    ),
    'groceries' => const _ServiceVisual(
      Icons.local_grocery_store_rounded,
      Color(0xFF2E8B57),
      Color(0xFFE1F4E7),
    ),
    _ => const _ServiceVisual(
      Icons.apps_rounded,
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

class _PngHomeHero extends StatelessWidget {
  const _PngHomeHero();

  @override
  Widget build(BuildContext context) {
    return PngScenicBackdrop(
      height: 214,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                color: WantokColors.gold,
                size: 18,
              ),
              SizedBox(width: 5),
              Text(
                'Papua New Guinea',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Spacer(),
              _HeroChip(icon: Icons.verified_user_outlined, label: 'Local'),
            ],
          ),
          const Spacer(),
          const Text(
            'Wan ples. Planti rot.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Local people. Real services. One Wantok.',
            style: TextStyle(
              color: Color(0xFFE4F6EE),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.97),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const TextField(
              readOnly: true,
              decoration: InputDecoration(
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                hintText: 'Search services, places or people',
                prefixIcon: Icon(Icons.search_rounded),
                suffixIcon: Icon(Icons.qr_code_scanner_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _WantokPayStrip extends StatelessWidget {
  const _WantokPayStrip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE5E7E5)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5123B2), Color(0xFF7B35D8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wantok Pay',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Kina wallet preview • payment rails coming later',
                      style: TextStyle(
                        color: WantokColors.muted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceSpotlight extends StatelessWidget {
  const _ServiceSpotlight({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.surface,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color surface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 188,
      margin: const EdgeInsets.only(right: 10),
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Stack(
              children: [
                Positioned(
                  right: -8,
                  bottom: -8,
                  child: Icon(
                    icon,
                    color: accent.withValues(alpha: 0.13),
                    size: 88,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white.withValues(alpha: 0.92),
                      child: Icon(icon, color: accent),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: const TextStyle(
                        color: WantokColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      style: const TextStyle(
                        color: WantokColors.muted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PngPurposeBanner extends StatelessWidget {
  const _PngPurposeBanner();

  @override
  Widget build(BuildContext context) {
    return PngScenicBackdrop(
      height: 142,
      colors: const [Color(0xFF60331E), Color(0xFF8A4A25), Color(0xFF087A4B)],
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Move PNG forward together.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Ride, hire, deliver, book, buy or find skilled people nearby.',
                  style: TextStyle(color: Color(0xFFF2E9DD), fontSize: 12.5),
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          CircleAvatar(
            radius: 26,
            backgroundColor: Color(0x33FFFFFF),
            child: Icon(Icons.explore_rounded, color: Colors.white, size: 31),
          ),
        ],
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  const _SafetyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1E2D3)),
      ),
      child: const ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Color(0xFFFFE5DA),
          child: Icon(
            Icons.health_and_safety_rounded,
            color: WantokColors.clay,
          ),
        ),
        title: Text(
          'Safety belongs in every service',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          'Verified providers, job records, support and future SOS tools are '
          'part of the shared Wantok platform.',
        ),
      ),
    );
  }
}
