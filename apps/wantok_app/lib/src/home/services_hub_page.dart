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

class ServicesHubPage extends StatefulWidget {
  const ServicesHubPage({this.loadServices, super.key});

  final Future<List<WantokServiceCategory>> Function()? loadServices;

  @override
  State<ServicesHubPage> createState() => _ServicesHubPageState();
}

class _ServicesHubPageState extends State<ServicesHubPage> {
  static const _catalog = CatalogRepository();

  late Future<List<WantokServiceCategory>> _future;
  final _search = TextEditingController();
  String _query = '';
  _ServiceFamily _family = _ServiceFamily.all;

  Future<List<WantokServiceCategory>> _loadServices() =>
      (widget.loadServices ?? _catalog.loadActiveServices)();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _search.clear();
    setState(() {
      _query = '';
      _family = _ServiceFamily.all;
    });
  }

  @override
  void initState() {
    super.initState();
    _future = _loadServices();
  }

  Future<void> _reload() async {
    final next = _loadServices();
    setState(() {
      _future = next;
    });
    try {
      await next;
    } catch (_) {
      // The FutureBuilder presents the retryable error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<List<WantokServiceCategory>>(
        future: _future,
        builder: (context, snapshot) {
          final services = snapshot.data ?? const <WantokServiceCategory>[];
          final query = _query.trim().toLowerCase();
          final filtered = services
              .where((service) {
                final matchesQuery =
                    query.isEmpty ||
                    service.name.toLowerCase().contains(query) ||
                    service.slug.toLowerCase().contains(query);
                return matchesQuery && _family.matches(service.slug);
              })
              .toList(growable: false);
          final textScale = MediaQuery.textScalerOf(context).scale(1);

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
            children: [
              PngScenicBackdrop(
                minHeight: 158,
                colors: const [
                  Color(0xFF075C3A),
                  Color(0xFF0B79A8),
                  Color(0xFF6C3C24),
                ],
                child: const Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'All Wantok Services',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.7,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Move, eat, shop, book and find local help across PNG.',
                            style: TextStyle(
                              color: Color(0xFFE5F5EE),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    CircleAvatar(
                      radius: 29,
                      backgroundColor: Color(0x33FFFFFF),
                      child: Icon(
                        Icons.apps_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _search,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  labelText: 'Search Wantok Services',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final family in _ServiceFamily.values)
                    ChoiceChip(
                      label: Text(family.label),
                      selected: _family == family,
                      onSelected: (_) => setState(() => _family = family),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              PngSectionTitle(
                title: 'Services',
                subtitle: snapshot.connectionState != ConnectionState.done
                    ? 'Loading available services…'
                    : snapshot.hasError
                    ? 'Services are temporarily unavailable.'
                    : '${filtered.length} service${filtered.length == 1 ? '' : 's'} available.',
                trailing: IconButton(
                  tooltip: 'Refresh',
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState != ConnectionState.done)
                const Padding(
                  padding: EdgeInsets.all(34),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snapshot.hasError)
                _StateCard(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load services',
                  body: 'Check your connection and try again.',
                  actionLabel: 'Retry',
                  onAction: _reload,
                )
              else if (services.isEmpty)
                _StateCard(
                  icon: Icons.storefront_outlined,
                  title: 'No services available yet',
                  body: 'Please check back soon for local services.',
                  actionLabel: 'Refresh',
                  onAction: _reload,
                )
              else if (filtered.isEmpty)
                _StateCard(
                  icon: Icons.search_off_rounded,
                  title: 'No service matched',
                  body: 'Try another name or service family.',
                  actionLabel: 'Clear filters',
                  onAction: _clearFilters,
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columns =
                          (constraints.maxWidth / (88 * textScale.clamp(1, 2)))
                              .floor()
                              .clamp(2, 6);
                      return GridView.builder(
                        itemCount: filtered.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisExtent:
                              92 +
                              MediaQuery.textScalerOf(context).scale(11.8) *
                                  2.4,
                          crossAxisSpacing: 5,
                          mainAxisSpacing: 3,
                        ),
                        itemBuilder: (context, index) {
                          final service = filtered[index];
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
              const SizedBox(height: 18),
              const _ServicePromiseCard(),
            ],
          );
        },
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

enum _ServiceFamily {
  all('All'),
  move('Move'),
  eatShop('Eat & shop'),
  book('Book'),
  people('People');

  const _ServiceFamily(this.label);
  final String label;

  bool matches(String slug) => switch (this) {
    all => true,
    move => const {
      'taxi-ride',
      'vehicle-hire',
      'boat-hire',
      'boat-ship-rides',
      'delivery',
      'errands',
    }.contains(slug),
    eatShop => const {'food', 'groceries'}.contains(slug),
    book => const {'venue-booking', 'events'}.contains(slug),
    people => const {'specialist-services', 'general-labour'}.contains(slug),
  };
}

class _ServicePromiseCard extends StatelessWidget {
  const _ServicePromiseCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0E2D4)),
      ),
      child: const ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Color(0xFFFFE5DA),
          child: Icon(Icons.handshake_rounded, color: WantokColors.clay),
        ),
        title: Text(
          'One account. Many local services.',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          'Wantok Services keeps transport, bookings, commerce and local '
          'providers together without mixing their service workflows.',
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(icon, size: 46, color: WantokColors.primary),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: WantokColors.muted),
            ),
            if (onAction != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
