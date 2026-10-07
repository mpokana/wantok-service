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
import 'provider_discovery_page.dart';
import 'service_catalog_taxonomy.dart';
import 'services_hub_page.dart';

class ClientHome extends StatefulWidget {
  const ClientHome({
    this.onAccountTap,
    this.onAgentTap,
    this.onServicesTap,
    this.loadServices,
    super.key,
  });

  // Kept for compatibility with older injected/test surfaces. Account/profile
  // now lives in the main application header rather than inside the dashboard.
  final VoidCallback? onAccountTap;
  final VoidCallback? onAgentTap;
  final VoidCallback? onServicesTap;
  final Future<List<WantokServiceCategory>> Function()? loadServices;

  @override
  State<ClientHome> createState() => _ClientHomeState();
}

class _ClientHomeState extends State<ClientHome> {
  static const _catalog = CatalogRepository();
  static const _providerDiscovery = ProviderDiscoveryRepository();

  late Future<List<WantokServiceCategory>> _services;
  late Future<List<ClientProviderDiscovery>> _topProviders;

  Future<List<WantokServiceCategory>> _loadServices() =>
      (widget.loadServices ?? _catalog.loadActiveServices)();

  Future<List<ClientProviderDiscovery>> _loadTopProviders() async {
    if (widget.loadServices != null) {
      return const <ClientProviderDiscovery>[];
    }
    try {
      return await _providerDiscovery.loadTopProviders(displayLimit: 5);
    } catch (_) {
      return const <ClientProviderDiscovery>[];
    }
  }

  @override
  void initState() {
    super.initState();
    _services = _loadServices();
    _topProviders = _loadTopProviders();
  }

  Future<void> _reload() async {
    final services = _loadServices();
    final providers = _loadTopProviders();
    setState(() {
      _services = services;
      _topProviders = providers;
    });
    try {
      await Future.wait<dynamic>([services, providers]);
    } catch (_) {
      // Individual builders surface their own safe retry/empty states.
    }
  }

  void _openServices() {
    if (widget.onServicesTap != null) {
      widget.onServicesTap!();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Services')),
          body: ServicesHubPage(loadServices: widget.loadServices),
        ),
      ),
    );
  }

  void _openAgent() {
    final callback = widget.onAgentTap;
    if (callback != null) callback();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<List<WantokServiceCategory>>(
        future: _services,
        builder: (context, snapshot) {
          final services = snapshot.data ?? const <WantokServiceCategory>[];
          final quickServices = _quickAccessServices(services);
          final textScale = MediaQuery.textScalerOf(context).scale(1);

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
            children: [
              _MarketplaceHero(onSearchTap: _openServices),
              if (quickServices.isNotEmpty || widget.onAgentTap != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount:
                        quickServices.length +
                        1 +
                        (widget.onAgentTap == null ? 0 : 1),
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ActionChip(
                          avatar: const Icon(Icons.grid_view_rounded, size: 17),
                          label: const Text('All'),
                          onPressed: _openServices,
                        );
                      }
                      if (index <= quickServices.length) {
                        final service = quickServices[index - 1];
                        final visual = _visualFor(service.slug);
                        return ActionChip(
                          avatar: Icon(
                            visual.icon,
                            color: visual.accent,
                            size: 17,
                          ),
                          label: Text(_shortLabel(service)),
                          onPressed: () => _openService(service),
                        );
                      }
                      return ActionChip(
                        avatar: const Icon(
                          Icons.auto_awesome_rounded,
                          color: WantokColors.primaryDark,
                          size: 17,
                        ),
                        label: const Text('Ask Wantok'),
                        onPressed: _openAgent,
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _MarketplacePromo(onTap: _openServices),
              const SizedBox(height: 22),
              PngSectionTitle(
                title: 'Popular categories',
                trailing: TextButton(
                  onPressed: _openServices,
                  child: const Text('See all'),
                ),
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState != ConnectionState.done)
                const Padding(
                  padding: EdgeInsets.all(30),
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
                          tooltip: 'Retry services',
                          onPressed: _reload,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                  ),
                )
              else if (services.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(22),
                    child: Text(
                      'No services available yet. Please check back soon.',
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xFFE4ECE8)),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columns =
                          (constraints.maxWidth / (88 * textScale.clamp(1, 2)))
                              .floor()
                              .clamp(2, 6);
                      return GridView.builder(
                        itemCount: quickServices.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisExtent:
                              90 +
                              MediaQuery.textScalerOf(context).scale(11.5) *
                                  2.4,
                          crossAxisSpacing: 5,
                          mainAxisSpacing: 3,
                        ),
                        itemBuilder: (context, index) {
                          final service = quickServices[index];
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
                ),
              if (widget.loadServices == null) ...[
                const SizedBox(height: 22),
                PngSectionTitle(
                  title: 'Top providers',
                  subtitle: 'Verified providers with real Wantok ratings.',
                  trailing: TextButton(
                    onPressed: _openProviderSearch,
                    child: const Text('See all'),
                  ),
                ),
                const SizedBox(height: 10),
                FutureBuilder<List<ClientProviderDiscovery>>(
                  future: _topProviders,
                  builder: (context, providerSnapshot) {
                    if (providerSnapshot.connectionState !=
                        ConnectionState.done) {
                      return const SizedBox(
                        height: 132,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final providers =
                        providerSnapshot.data ??
                        const <ClientProviderDiscovery>[];
                    if (providers.isEmpty) {
                      return _ProviderSearchCard(onTap: _openProviderSearch);
                    }

                    return SizedBox(
                      height: 160 + ((textScale - 1).clamp(0, 1) * 28),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: providers.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final provider = providers[index];
                          return _HomeProviderCard(
                            provider: provider,
                            onTap: () => _openProvider(provider),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
              if (services.isNotEmpty) ...[
                const SizedBox(height: 24),
                const PngSectionTitle(
                  title: 'Popular ways to use Wantok',
                  subtitle: 'Jump straight into an everyday service.',
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 190 + (textScale - 1).clamp(0, 2) * 130,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _spotlights(services),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const _SafetyCard(),
            ],
          );
        },
      ),
    );
  }

  void _openProviderSearch() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const ProviderDiscoveryPage(),
      ),
    );
  }

  void _openProvider(ClientProviderDiscovery provider) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProviderDetailPage(provider: provider),
      ),
    );
  }

  List<WantokServiceCategory> _quickAccessServices(
    List<WantokServiceCategory> services,
  ) {
    final bySlug = <String, WantokServiceCategory>{
      for (final service in services) service.slug: service,
    };
    final selected = wantokHomeQuickAccessOrder
        .map((slug) => bySlug[slug])
        .whereType<WantokServiceCategory>()
        .toList();

    if (selected.length >= 6 || selected.length == services.length) {
      return selected;
    }

    for (final service in services) {
      if (selected.any((item) => item.id == service.id)) continue;
      selected.add(service);
      if (selected.length == 6) break;
    }
    return selected;
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

  String _shortLabel(WantokServiceCategory service) => switch (service.slug) {
    'taxi-ride' => 'Ride',
    'delivery' => 'Delivery',
    'vehicle-hire' => 'Hire car',
    'specialist-services' => 'Specialists',
    'groceries' => 'Groceries',
    _ => service.name,
  };

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

class _MarketplaceHero extends StatelessWidget {
  const _MarketplaceHero({required this.onSearchTap});

  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFEF8), Color(0xFFF1F8F3)],
        ),
        border: Border.all(color: const Color(0xFFE1EBE5)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -12,
            child: Icon(
              Icons.landscape_rounded,
              size: 150,
              color: WantokColors.primaryDark.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            right: 24,
            top: 3,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: WantokColors.gold.withValues(alpha: 0.82),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Explore services and goods',
                style: TextStyle(
                  color: WantokColors.ink,
                  fontSize: 29,
                  height: 1.04,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.9,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Find trusted providers for everyday needs wherever you are.',
                style: TextStyle(
                  color: WantokColors.muted,
                  fontSize: 13.5,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                elevation: 1,
                shadowColor: Colors.black.withValues(alpha: 0.12),
                child: InkWell(
                  onTap: onSearchTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(15, 8, 8, 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: WantokColors.ink,
                          size: 27,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Search services, goods or providers',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: WantokColors.muted,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Container(
                          decoration: BoxDecoration(
                            color: WantokColors.primaryDark,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: IconButton(
                            tooltip: 'Search services',
                            onPressed: onSearchTap,
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarketplacePromo extends StatelessWidget {
  const _MarketplacePromo({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 152),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF075C3A), Color(0xFF0A7D50)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              right: -22,
              bottom: -20,
              child: Icon(
                Icons.shopping_bag_rounded,
                color: Colors.white.withValues(alpha: 0.12),
                size: 160,
              ),
            ),
            Positioned(
              right: 26,
              top: 22,
              child: CircleAvatar(
                radius: 37,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                child: const Icon(
                  Icons.handshake_rounded,
                  size: 38,
                  color: WantokColors.gold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 17, 120, 17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LOCAL PROVIDERS',
                    style: TextStyle(
                      color: WantokColors.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Services for everyday life',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Great providers. Real people.',
                    style: TextStyle(color: Color(0xFFE0F1E8), fontSize: 12.5),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: WantokColors.gold,
                      foregroundColor: const Color(0xFF2D1B05),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                    label: const Text('Explore services'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeProviderCard extends StatelessWidget {
  const _HomeProviderCard({required this.provider, required this.onTap});

  final ClientProviderDiscovery provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final category = provider.categoryNames.isEmpty
        ? 'Wantok provider'
        : provider.categoryNames.first;
    final rating = provider.ratingCount == 0
        ? 'New'
        : '${provider.ratingAverage.toStringAsFixed(1)} (${provider.ratingCount})';
    final place = provider.coverageTowns.isNotEmpty
        ? provider.coverageTowns.first
        : provider.coverageProvinces.isNotEmpty
        ? provider.coverageProvinces.first
        : 'Available on Wantok';

    return SizedBox(
      width: 220,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 68,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE2F4EA), Color(0xFFF9F4DF)],
                  ),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.storefront_rounded,
                        color: WantokColors.primaryDark,
                        size: 38,
                      ),
                    ),
                    const Positioned(
                      right: 10,
                      top: 10,
                      child: Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF07865D),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: WantokColors.muted,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFF5A900),
                          size: 17,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          rating,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            place,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: WantokColors.muted,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderSearchCard extends StatelessWidget {
  const _ProviderSearchCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE2F3EA),
          child: Icon(
            Icons.manage_search_rounded,
            color: WantokColors.primaryDark,
          ),
        ),
        title: const Text(
          'Find a trusted provider',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: const Text(
          'Search verified providers by service, category and location.',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
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
          'Verified providers, job records and support are part of the shared Wantok platform.',
        ),
      ),
    );
  }
}
