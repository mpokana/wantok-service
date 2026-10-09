import 'package:flutter/material.dart';

import 'smoke_data.dart';

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
import 'explore_page.dart';
import 'provider_discovery_page.dart';
import 'service_catalog_taxonomy.dart';
import 'wantok_category_ui.dart';
import 'services_hub_page.dart';
import 'wantok_pay_preview_page.dart';

class ClientHome extends StatefulWidget {
  const ClientHome({
    this.onAccountTap,
    this.onAgentTap,
    this.onServicesTap,
    this.onExploreTap,
    this.loadServices,
    super.key,
  });

  // Kept for compatibility with older injected/test surfaces. Account/profile
  // now lives in the main application header rather than inside the dashboard.
  final VoidCallback? onAccountTap;
  final VoidCallback? onAgentTap;
  final VoidCallback? onServicesTap;
  final VoidCallback? onExploreTap;
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

  void _openExplore() {
    if (widget.onExploreTap != null) {
      widget.onExploreTap!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExplorePage(onBrowseServices: _openServices),
      ),
    );
  }

  void _openAgent() {
    final callback = widget.onAgentTap;
    if (callback != null) callback();
  }

  void _openPlannedGlobalService(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label is part of Wantok global travel and is being connected.',
        ),
      ),
    );
  }

  void _openWantokPay() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const WantokPayPreviewPage(),
      ),
    );
  }

  void _showPlannedPaymentRail(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label is planned for Wantok payments and is not active yet.',
        ),
      ),
    );
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
              _MarketplaceHero(
                onSearchTap: _openServices,
                onAgentTap: widget.onAgentTap == null ? null : _openAgent,
              ),
              // Home shows one quick category grid; the duplicate chip rail
              // is omitted so Services remains the full catalogue.
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
                          constraints.maxWidth >= 520 && textScale <= 1.1
                          ? 8
                          : (constraints.maxWidth /
                                    (88 * textScale.clamp(1, 2)))
                                .floor()
                                .clamp(2, 6);
                      final categoryCount = quickServices.length + 2;
                      return GridView.builder(
                        itemCount: categoryCount,
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
                          if (index < quickServices.length) {
                            final service = quickServices[index];
                            return WantokCategoryTile(
                              key: ValueKey('home-category-${service.slug}'),
                              compact: true,
                              style: WantokCategoryStyles.bySlug(service.slug),
                              label: _shortLabel(service),
                              badge: _badgeFor(service.slug),
                              onTap: () => _openService(service),
                            );
                          }

                          if (index == quickServices.length) {
                            return WantokCategoryTile(
                              compact: true,
                              style: WantokCategoryStyles.travel,
                              label: 'Travel & Flights',
                              onTap: () =>
                                  _openPlannedGlobalService('Travel & Flights'),
                            );
                          }

                          return WantokCategoryTile(
                            compact: true,
                            style: WantokCategoryStyles.hotels,
                            onTap: () => _openPlannedGlobalService('Hotels'),
                          );
                        },
                      );
                    },
                  ),
                ),
              if (WantokSmokeData.enabled)
                const SmokePreviewSection(
                  scene: SmokeScene.providers,
                  heading: 'Sample popular near you',
                ),
              const SizedBox(height: 18),
              _MarketplacePromo(onTap: _openProviderSearch),
              const SizedBox(height: 22),
              if (widget.loadServices == null) ...[
                const SizedBox(height: 22),
                PngSectionTitle(
                  title: 'Top providers',
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
                const SizedBox(height: 24),
                PngSectionTitle(
                  title: 'Pay your way',
                  subtitle: 'Secure and convenient payments.',
                  trailing: TextButton(
                    onPressed: _openWantokPay,
                    child: const Text('See all'),
                  ),
                ),
                const SizedBox(height: 10),
                _PaymentRailStrip(
                  onWantokPayTap: _openWantokPay,
                  onPlannedRailTap: _showPlannedPaymentRail,
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
              const SizedBox(height: 28),
              // Explore sits at the very bottom of Home, not beside Vanessa.
              _ScenicExploreBanner(onTap: _openExplore),
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
    final picks = <String, ({String title, String subtitle})>{
      'taxi-ride': (
        title: 'Need a ride?',
        subtitle: 'Request a local taxi or driver.',
      ),
      'food': (title: 'Hungry?', subtitle: 'Browse food from local vendors.'),
      'delivery': (
        title: 'Send something',
        subtitle: 'Book a courier or delivery.',
      ),
      'specialist-services': (
        title: 'Find skilled help',
        subtitle: 'Trades, specialists and services.',
      ),
    };

    final widgets = <Widget>[];
    for (final entry in picks.entries) {
      final service = services.cast<WantokServiceCategory?>().firstWhere(
        (item) => item?.slug == entry.key,
        orElse: () => null,
      );
      if (service == null) continue;
      widgets.add(
        _ServiceSpotlight(
          title: entry.value.title,
          subtitle: entry.value.subtitle,
          style: WantokCategoryStyles.bySlug(service.slug),
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

  String? _badgeFor(String slug) => switch (slug) {
    'taxi-ride' || 'delivery' => 'FAST',
    _ => null,
  };
}

class _MarketplaceHero extends StatelessWidget {
  const _MarketplaceHero({required this.onSearchTap, this.onAgentTap});

  final VoidCallback onSearchTap;
  final VoidCallback? onAgentTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What do you need today?',
          style: TextStyle(
            color: WantokColors.ink,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE3E8F1)),
          ),
          child: InkWell(
            onTap: onSearchTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                children: [
                  const Icon(Icons.search, color: WantokColors.muted),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Search services, goods or providers',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: WantokColors.muted, fontSize: 13),
                    ),
                  ),
                  if (onAgentTap != null)
                    IconButton(
                      tooltip: 'Ask Wantok',
                      onPressed: onAgentTap,
                      icon: const Icon(
                        Icons.auto_awesome_outlined,
                        color: WantokColors.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScenicExploreBanner extends StatelessWidget {
  const _ScenicExploreBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height:
              165 +
              (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0, 2) * 450,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: const DecorationImage(
              image: AssetImage('assets/images/hero_water.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xE4092852),
                  Color(0xB1092852),
                  Color(0x11092852),
                ],
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explore PNG and beyond',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          height: 1.12,
                          fontSize: 22,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Discover services across our communities.',
                        style: TextStyle(color: Color(0xFFE8F1FF)),
                      ),
                    ],
                  ),
                ),
                const CircleAvatar(
                  radius: 21,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: WantokColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
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
      constraints: const BoxConstraints(minHeight: 164),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: const Color(0xFF075C3A),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 0.54,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/vanessa_local_provider.jpg',
                        fit: BoxFit.cover,
                        alignment: const Alignment(0.45, -0.2),
                        filterQuality: FilterQuality.medium,
                      ),
                      Align(
                        alignment: const Alignment(0.42, -0.58),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.filter_vintage_rounded,
                              color: Color(0xFFE42F46),
                              size: 32,
                            ),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: WantokColors.gold,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: const [0, 0.48, 0.7, 1],
                    colors: [
                      const Color(0xFF075C3A),
                      const Color(0xFF075C3A).withValues(alpha: 0.96),
                      const Color(0xFF075C3A).withValues(alpha: 0.34),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            FractionallySizedBox(
              widthFactor: 0.58,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 17, 8, 17),
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
                      style: TextStyle(
                        color: Color(0xFFE0F1E8),
                        fontSize: 12.5,
                      ),
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
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF163D31).withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PromoDot(active: true),
                      SizedBox(width: 6),
                      _PromoDot(),
                      SizedBox(width: 6),
                      _PromoDot(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoDot extends StatelessWidget {
  const _PromoDot({this.active = false});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: active
            ? WantokColors.gold
            : Colors.white.withValues(alpha: 0.55),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _PaymentRailStrip extends StatelessWidget {
  const _PaymentRailStrip({
    required this.onWantokPayTap,
    required this.onPlannedRailTap,
  });

  final VoidCallback onWantokPayTap;
  final ValueChanged<String> onPlannedRailTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _PaymentBrandTile(
            width: 112,
            onTap: onWantokPayTap,
            child: const Row(
              children: [
                _PaymentIconBox(
                  icon: Icons.account_balance_wallet_rounded,
                  foreground: Colors.white,
                  background: Color(0xFF6C35D7),
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wantok Pay',
                        maxLines: 1,
                        style: TextStyle(
                          color: WantokColors.ink,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Kina wallet',
                        style: TextStyle(
                          color: WantokColors.muted,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _PaymentBrandTile(
            width: 54,
            onTap: () => onPlannedRailTap('Visa'),
            child: const Center(
              child: Text(
                'VISA',
                style: TextStyle(
                  color: Color(0xFF1A2A7A),
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _PaymentBrandTile(
            width: 56,
            onTap: () => onPlannedRailTap('Mastercard'),
            child: Center(
              child: SizedBox(
                width: 42,
                height: 26,
                child: Stack(
                  children: [
                    Positioned(
                      left: 3,
                      top: 2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEB001B),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 3,
                      top: 2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF79E1B),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _PaymentBrandTile(
            width: 60,
            onTap: () => onPlannedRailTap('PayPal'),
            child: const Center(
              child: Text(
                'PayPal',
                style: TextStyle(
                  color: Color(0xFF003087),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _PaymentBrandTile(
            width: 58,
            onTap: () => onPlannedRailTap('Google Pay'),
            child: const Center(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'G',
                      style: TextStyle(
                        color: Color(0xFF4285F4),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: ' Pay',
                      style: TextStyle(
                        color: WantokColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _PaymentBrandTile(
            width: 76,
            onTap: () => onPlannedRailTap('Bank Transfer'),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_rounded,
                  color: Color(0xFF7547CE),
                  size: 20,
                ),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Bank\nTransfer',
                    style: TextStyle(
                      color: Color(0xFF7547CE),
                      height: 1.05,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _PaymentBrandTile(
            width: 36,
            onTap: onWantokPayTap,
            child: const Center(
              child: Icon(
                Icons.chevron_right_rounded,
                color: WantokColors.primaryDark,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentBrandTile extends StatelessWidget {
  const _PaymentBrandTile({
    required this.onTap,
    required this.child,
    this.width = 94,
  });

  final VoidCallback onTap;
  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE3EAE6)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _PaymentIconBox extends StatelessWidget {
  const _PaymentIconBox({
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(11),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: foreground, size: 21),
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
    required this.style,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final WantokCategoryStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 188,
      margin: const EdgeInsets.only(right: 10),
      child: Material(
        color: style.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: WantokCategoryPicture(style: style),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: WantokColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: WantokColors.muted,
                    fontSize: 11,
                  ),
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
