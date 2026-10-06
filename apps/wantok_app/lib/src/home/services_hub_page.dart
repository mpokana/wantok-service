import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_core/wantok_core.dart';
import 'package:wantok_ui/wantok_ui.dart';

import '../services/commerce_browse_page.dart';
import '../services/event_browse_page.dart';
import '../services/open_request_page.dart';
import '../services/reservation_browse_page.dart';
import '../services/taxi_ride_page.dart';
import '../services/water_transport_page.dart';
import 'client_account_tools.dart';
import 'png_visuals.dart';

class ServicesHubPage extends StatefulWidget {
  const ServicesHubPage({
    this.loadServices,
    this.loadRecommendations,
    this.loadPlaces,
    super.key,
  });

  final Future<List<WantokServiceCategory>> Function()? loadServices;
  final Future<List<ClientServiceRecommendation>> Function()?
  loadRecommendations;
  final Future<List<ClientServicePlace>> Function()? loadPlaces;

  @override
  State<ServicesHubPage> createState() => _ServicesHubPageState();
}

class _ServicesHubPageState extends State<ServicesHubPage> {
  static const _catalog = CatalogRepository();
  static const _experience = ClientExperienceRepository();

  late Future<List<WantokServiceCategory>> _future;
  final _search = TextEditingController();
  final Set<String> _savedCategoryIds = <String>{};
  final Set<String> _savingSavedIds = <String>{};
  List<ClientServiceRecommendation> _recommendations =
      const <ClientServiceRecommendation>[];
  bool _recommendationsLoading = false;
  List<ClientServicePlace> _places = const <ClientServicePlace>[];
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedItems();
      _loadRecommendations();
      _loadPlaces();
    });
  }

  Future<List<ClientServiceRecommendation>> _loadRecommendationData() async {
    final injected = widget.loadRecommendations;
    if (injected != null) return injected();

    // An injected catalogue is used by offline/widget tests. Do not reach the
    // backend from those deterministic test surfaces unless recommendations
    // are injected as well.
    if (widget.loadServices != null) {
      return const <ClientServiceRecommendation>[];
    }

    double? lat;
    double? lng;
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getLastKnownPosition();
        lat = position?.latitude;
        lng = position?.longitude;
      }
    } catch (_) {
      // Recommendations remain useful from saved/history signals when device
      // location is unavailable, disabled or unsupported on this platform.
    }

    return _experience.loadServiceRecommendations(lat: lat, lng: lng);
  }

  Future<void> _loadRecommendations() async {
    if (_recommendationsLoading) return;
    if (mounted) setState(() => _recommendationsLoading = true);
    try {
      final recommendations = await _loadRecommendationData();
      if (mounted) {
        setState(() => _recommendations = recommendations);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _recommendations = const <ClientServiceRecommendation>[],
        );
      }
    } finally {
      if (mounted) setState(() => _recommendationsLoading = false);
    }
  }

  Future<void> _loadPlaces() async {
    try {
      final injected = widget.loadPlaces;
      final places = injected != null
          ? await injected()
          : widget.loadServices != null
          ? const <ClientServicePlace>[]
          : await _experience.loadServicePlaces();
      if (mounted) setState(() => _places = places);
    } catch (_) {
      if (mounted) setState(() => _places = const <ClientServicePlace>[]);
    }
  }

  Future<void> _loadSavedItems() async {
    try {
      final ids = await _experience.loadSavedIds('category');
      if (mounted) {
        setState(() {
          _savedCategoryIds
            ..clear()
            ..addAll(ids);
        });
      }
    } catch (_) {
      // Saved items are optional discovery enhancement; catalogue still works.
    }
  }

  Future<void> _toggleSaved(WantokServiceCategory service) async {
    if (_savingSavedIds.contains(service.id)) return;
    final wasSaved = _savedCategoryIds.contains(service.id);
    setState(() => _savingSavedIds.add(service.id));
    try {
      await _experience.setSavedItem(
        itemType: 'category',
        entityId: service.id,
        saved: !wasSaved,
      );
      if (mounted) {
        setState(() {
          if (wasSaved) {
            _savedCategoryIds.remove(service.id);
          } else {
            _savedCategoryIds.add(service.id);
          }
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('StateError: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingSavedIds.remove(service.id));
    }
  }

  Future<void> _openSaved() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const SavedItemsPage()),
    );
    if (mounted) await _loadSavedItems();
  }

  Future<void> _openPlace(
    ClientServicePlace place,
    List<WantokServiceCategory> services,
  ) async {
    final available = services
        .where((service) => place.categoryIds.contains(service.id))
        .toList(growable: false);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                place.town == null
                    ? place.province
                    : '${place.town}, ${place.province}',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                '${place.coverageCount} active coverage point${place.coverageCount == 1 ? '' : 's'} across ${available.length} service type${available.length == 1 ? '' : 's'}.',
                style: const TextStyle(color: WantokColors.muted),
              ),
              const SizedBox(height: 14),
              if (available.isEmpty)
                const Text('No matching client service is available right now.')
              else
                ...available.map(
                  (service) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: _visualFor(service.slug).surface,
                      child: Icon(
                        _visualFor(service.slug).icon,
                        color: _visualFor(service.slug).accent,
                      ),
                    ),
                    title: Text(
                      service.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(context).pop();
                      _openService(service);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reload() async {
    final next = _loadServices();
    setState(() {
      _future = next;
    });
    try {
      await next;
      await Future.wait([
        _loadSavedItems(),
        _loadRecommendations(),
        _loadPlaces(),
      ]);
    } catch (_) {
      // The FutureBuilder presents the retryable catalogue error state.
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
              if (query.isEmpty &&
                  _family == _ServiceFamily.all &&
                  _recommendations.isNotEmpty) ...[
                const SizedBox(height: 20),
                const PngSectionTitle(
                  title: 'For you',
                  subtitle: 'From saved items, recent activity and services available around you.',
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 148 + ((textScale - 1).clamp(0, 1) * 24),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recommendations.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final recommendation = _recommendations[index];
                      final visual = _visualFor(recommendation.categorySlug);
                      return _RecommendationCard(
                        title: recommendation.categoryName,
                        reason: recommendation.reason,
                        distanceKm: recommendation.distanceKm,
                        icon: visual.icon,
                        accent: visual.accent,
                        surface: visual.surface,
                        onTap: () {
                          for (final service in services) {
                            if (service.id == recommendation.categoryId) {
                              _openService(service);
                              return;
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
              if (query.isEmpty &&
                  _family == _ServiceFamily.all &&
                  _places.isNotEmpty) ...[
                const SizedBox(height: 20),
                const PngSectionTitle(
                  title: 'Explore PNG',
                  subtitle: 'Places appear here only when active Wantok services cover them.',
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 132 + ((textScale - 1).clamp(0, 1) * 20),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _places.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final place = _places[index];
                      return _PlaceCard(
                        place: place,
                        onTap: () => _openPlace(place, services),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20),
              PngSectionTitle(
                title: 'Services',
                subtitle: snapshot.connectionState != ConnectionState.done
                    ? 'Loading available services…'
                    : snapshot.hasError
                    ? 'Services are temporarily unavailable.'
                    : '${filtered.length} service${filtered.length == 1 ? '' : 's'} available.',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Saved',
                      onPressed: _openSaved,
                      icon: const Icon(Icons.bookmarks_outlined),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
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
                            isSaved: _savedCategoryIds.contains(service.id),
                            onSavedToggle: () => _toggleSaved(service),
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

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place, required this.onTap});

  final ClientServicePlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = place.town ?? place.province;
    final subtitle = place.town == null ? 'Province / region' : place.province;
    final serviceTypes = place.categoryIds.length;

    return SizedBox(
      width: 174,
      child: Material(
        color: const Color(0xFFF1F7F4),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place_outlined, color: WantokColors.primary),
                const Spacer(),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: WantokColors.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$serviceTypes service type${serviceTypes == 1 ? '' : 's'} • ${place.coverageCount} coverage',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: WantokColors.primaryDark,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
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

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.title,
    required this.reason,
    required this.distanceKm,
    required this.icon,
    required this.accent,
    required this.surface,
    required this.onTap,
  });

  final String title;
  final String reason;
  final double? distanceKm;
  final IconData icon;
  final Color accent;
  final Color surface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final distance = distanceKm;
    final distanceLabel = distance == null
        ? null
        : distance < 1
        ? '${(distance * 1000).round()} m away'
        : '${distance.toStringAsFixed(distance < 10 ? 1 : 0)} km away';

    return SizedBox(
      width: 176,
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white.withValues(alpha: 0.82),
                  child: Icon(icon, color: accent),
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  reason,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (distanceLabel != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    distanceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: WantokColors.muted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
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
