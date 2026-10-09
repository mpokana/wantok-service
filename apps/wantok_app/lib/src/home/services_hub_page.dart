import 'package:flutter/material.dart';

import 'smoke_data.dart';
import 'offline_demo_navigation.dart';
import 'reference_services_gallery.dart';
import 'category_information_page.dart';

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
import 'provider_discovery_page.dart';
import 'service_catalog_taxonomy.dart';
import 'wantok_category_ui.dart';
import 'adaptive_category_grid.dart';

class ServicesHubPage extends StatefulWidget {
  const ServicesHubPage({
    this.loadServices,
    this.loadTopProviders,
    this.loadRecommendations,
    this.loadPlaces,
    this.showMarketplaceLandingWhenInjected = false,
    this.demoMode = false,
    super.key,
  });

  final Future<List<WantokServiceCategory>> Function()? loadServices;
  final Future<List<ClientProviderDiscovery>> Function()? loadTopProviders;
  final Future<List<ClientServiceRecommendation>> Function()?
  loadRecommendations;
  final Future<List<ClientServicePlace>> Function()? loadPlaces;
  final bool showMarketplaceLandingWhenInjected;
  final bool demoMode;

  @override
  State<ServicesHubPage> createState() => _ServicesHubPageState();
}

class _ServicesHubPageState extends State<ServicesHubPage> {
  static const _catalog = CatalogRepository();
  static const _experience = ClientExperienceRepository();
  static const _providerDiscovery = ProviderDiscoveryRepository();

  late Future<List<WantokServiceCategory>> _future;
  bool _referenceCategories = true;
  final _search = TextEditingController();
  final Set<String> _savedCategoryIds = <String>{};
  final Set<String> _savingSavedIds = <String>{};
  List<ClientServiceRecommendation> _recommendations =
      const <ClientServiceRecommendation>[];
  bool _recommendationsLoading = false;
  List<ClientServicePlace> _places = const <ClientServicePlace>[];
  List<ClientProviderDiscovery> _topProviders =
      const <ClientProviderDiscovery>[];
  String _query = '';
  WantokServiceFamily _family = WantokServiceFamily.all;

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
      _family = WantokServiceFamily.all;
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
      _loadTopProviders();
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

  Future<void> _loadTopProviders() async {
    if (widget.loadTopProviders != null) {
      final providers = await widget.loadTopProviders!();
      if (mounted) setState(() => _topProviders = providers);
      return;
    }
    if (widget.loadServices != null) return;
    try {
      final providers = await _providerDiscovery.loadTopProviders(
        displayLimit: 5,
      );
      if (mounted) setState(() => _topProviders = providers);
    } catch (_) {
      if (mounted) {
        setState(() => _topProviders = const <ClientProviderDiscovery>[]);
      }
    }
  }

  void _openCategoryInformation(
    WantokCategoryStyle style,
    String? description, {
    String? categoryId,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoryInformationPage(
          style: style,
          categoryId: categoryId,
          description:
              description ??
              'This category is being prepared for verified Wantok providers '
                  'across Papua New Guinea.',
        ),
      ),
    );
  }

  void _openReferenceCategory(
    ReferenceCategorySpec spec,
    List<WantokServiceCategory> services,
  ) {
    if (widget.demoMode && spec.title != 'More') {
      OfflineDemoNavigation.category(
        context,
        spec.slug ?? 'specialist-services',
      );
      return;
    }
    if (spec.title == 'More') {
      setState(() => _referenceCategories = false);
      return;
    }
    for (final service in services) {
      if (spec.slug == service.slug) {
        _openService(service);
        return;
      }
    }
    // Do not invent a provider or show unmarked demonstration bookings when
    // a category is not yet available in the currently connected backend.
    _openCategoryInformation(spec.style, null);
  }

  void _openProviderSearch() {
    if (widget.demoMode) {
      OfflineDemoNavigation.providers(context);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const ProviderDiscoveryPage(),
      ),
    );
  }

  void _openProvider(ClientProviderDiscovery provider) {
    if (widget.demoMode) {
      OfflineDemoNavigation.providers(context);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProviderDetailPage(provider: provider),
      ),
    );
  }

  Future<void> _loadSavedItems() async {
    if (widget.demoMode || widget.loadServices != null) return;
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
    if (widget.demoMode) {
      OfflineDemoNavigation.notice(context, 'Saved services');
      return;
    }
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
    if (widget.demoMode) {
      OfflineDemoNavigation.notice(context, 'Saved services');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const SavedItemsPage()),
    );
    if (mounted) await _loadSavedItems();
  }

  Future<void> _openAllServices(List<WantokServiceCategory> services) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFF7F9F8),
      builder: (sheetContext) {
        final textScale = MediaQuery.textScalerOf(sheetContext).scale(1);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.62,
          maxChildSize: 0.96,
          builder: (context, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 26),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All Wantok Services',
                          style: TextStyle(
                            color: WantokColors.ink,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Move, eat, shop, send, book and find trusted help.',
                          style: TextStyle(
                            color: WantokColors.muted,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (final family in WantokServiceFamily.catalogueFamilies) ...[
                Builder(
                  builder: (context) {
                    final matches = services
                        .where((service) => family.matches(service.slug))
                        .toList(growable: false);
                    if (matches.isEmpty) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: WantokColors.primaryDark
                                    .withValues(alpha: 0.08),
                                child: Icon(
                                  family.icon,
                                  size: 19,
                                  color: WantokColors.primaryDark,
                                ),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      family.label,
                                      style: const TextStyle(
                                        color: WantokColors.ink,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      family.subtitle,
                                      style: const TextStyle(
                                        color: WantokColors.muted,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return AdaptiveCategoryGrid(
                                itemCount: matches.length,
                                tileHeight:
                                    124 + ((textScale - 1).clamp(0, 1) * 20),
                                columnSpacing: 8,
                                rowSpacing: 8,
                                itemBuilder: (context, index) {
                                  final service = matches[index];
                                  final visual = _visualFor(service.slug);
                                  return _AllServicesTile(
                                    service: service,
                                    icon: visual.icon,
                                    accent: visual.accent,
                                    surface: visual.surface,
                                    onTap: () {
                                      Navigator.of(sheetContext).pop();
                                      Future<void>.delayed(
                                        Duration.zero,
                                        () => _openService(service),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
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
        _loadTopProviders(),
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

          // The screenshot-matched 12-icon landing is the canonical entry.
          // An injected catalogue keeps the established deterministic tests.
          if ((widget.loadServices == null || widget.demoMode) &&
              _referenceCategories) {
            return ReferenceServicesLanding(
              onCategory: (spec) => _openReferenceCategory(spec, services),
              onAllServices: () => setState(() => _referenceCategories = false),
              onSearch: (value) {
                _search.text = value;
                setState(() {
                  _query = value;
                  _referenceCategories = false;
                });
              },
            );
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
            children: [
              if (widget.loadServices == null || widget.demoMode)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const ValueKey('reference-categories-back'),
                    onPressed: () => setState(() {
                      _referenceCategories = true;
                      _query = '';
                      _search.clear();
                      _family = WantokServiceFamily.all;
                    }),
                    icon: const Icon(Icons.grid_view_rounded),
                    label: const Text('Categories'),
                  ),
                ),
              const Text(
                'Services',
                style: TextStyle(
                  color: WantokColors.ink,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Explore everyday services, shops and trusted local providers.',
                style: TextStyle(color: WantokColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _search,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search services, goods or providers',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? const Icon(
                          Icons.arrow_forward_rounded,
                          color: WantokColors.primaryDark,
                        )
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    borderSide: BorderSide(color: Color(0xFFDCE7E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    borderSide: BorderSide(color: Color(0xFFDCE7E1)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const PngSectionTitle(
                title: 'Browse services',
                subtitle: 'Choose a need or search the complete catalogue.',
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: WantokServiceFamily.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final family = WantokServiceFamily.values[index];
                    return ChoiceChip(
                      avatar: Icon(family.icon, size: 17),
                      label: Text(family.shortLabel),
                      selected: _family == family,
                      onSelected: (_) => setState(() => _family = family),
                    );
                  },
                ),
              ),
              if ((widget.loadServices == null ||
                      widget.showMarketplaceLandingWhenInjected ||
                      widget.demoMode) &&
                  query.isEmpty &&
                  _family == WantokServiceFamily.all) ...[
                const SizedBox(height: 18),
                _ServicesMarketplacePromo(onTap: _openProviderSearch),
                const SizedBox(height: 22),
                PngSectionTitle(
                  title: 'Popular categories',
                  subtitle: 'Jump straight into everyday services and goods.',
                  trailing: TextButton(
                    onPressed: () => _openAllServices(services),
                    child: const Text('See all'),
                  ),
                ),
                const SizedBox(height: 10),
                _buildPopularCategories(services, textScale: textScale),
                const SizedBox(height: 22),
                PngSectionTitle(
                  title: 'Top providers',
                  subtitle: 'Verified providers ranked organically from real service signals.',
                  trailing: TextButton(
                    onPressed: _openProviderSearch,
                    child: const Text('See all'),
                  ),
                ),
                const SizedBox(height: 10),
                if (_topProviders.isEmpty)
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE2F3EA),
                        child: Icon(
                          Icons.storefront_outlined,
                          color: WantokColors.primaryDark,
                        ),
                      ),
                      title: const Text(
                        'Find a Wantok provider',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: const Text(
                        'Ratings, review counts and approved services are shown in provider search.',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _openProviderSearch,
                    ),
                  )
                else
                  SizedBox(
                    height: 142 + ((textScale - 1).clamp(0, 1) * 22),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _topProviders.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final provider = _topProviders[index];
                        return _TopProviderCard(
                          provider: provider,
                          onTap: () => _openProvider(provider),
                        );
                      },
                    ),
                  ),
              ],
              if (query.isEmpty &&
                  _family == WantokServiceFamily.all &&
                  _recommendations.isNotEmpty) ...[
                const SizedBox(height: 20),
                const PngSectionTitle(
                  title: 'Recommended for you',
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
                  _family == WantokServiceFamily.all &&
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
                title: query.isEmpty && _family == WantokServiceFamily.all
                    ? 'Service catalogue'
                    : 'Matching services',
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
                _buildServiceCatalogue(
                  filtered,
                  grouped: query.isEmpty && _family == WantokServiceFamily.all,
                  textScale: textScale,
                ),
              if (WantokSmokeData.enabled &&
                  query.isEmpty &&
                  _family == WantokServiceFamily.all)
                const SmokePreviewSection(
                  scene: SmokeScene.trades,
                  heading: 'Sample trusted services',
                ),
              const SizedBox(height: 18),
              const _ServicePromiseCard(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPopularCategories(
    List<WantokServiceCategory> services, {
    required double textScale,
  }) {
    const preferredSlugs = <String>[
      'taxi-ride',
      'food',
      'delivery',
      'groceries',
      'specialist-services',
      'vehicle-hire',
    ];

    final bySlug = <String, WantokServiceCategory>{
      for (final service in services) service.slug: service,
    };
    final popular = <WantokServiceCategory>[
      for (final slug in preferredSlugs)
        if (bySlug[slug] != null) bySlug[slug]!,
    ];

    if (popular.isEmpty) {
      popular.addAll(services.take(6));
    }

    Widget item(WantokServiceCategory service) {
      final visual = _visualFor(service.slug);
      return InkWell(
        onTap: () => _openService(service),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: visual.surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Icon(visual.icon, color: visual.accent, size: 27),
              ),
              const SizedBox(height: 7),
              Text(
                service.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: WantokColors.ink,
                  fontSize: 10.5,
                  height: 1.08,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth >= 360 && textScale <= 1.18;
        if (compact && popular.length <= 6) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < popular.length; index++) ...[
                Expanded(child: item(popular[index])),
                if (index != popular.length - 1) const SizedBox(width: 4),
              ],
            ],
          );
        }

        return SizedBox(
          height: 102 + ((textScale - 1).clamp(0, 1) * 20),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: popular.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) =>
                SizedBox(width: 82, child: item(popular[index])),
          ),
        );
      },
    );
  }

  Widget _buildServiceCatalogue(
    List<WantokServiceCategory> services, {
    required bool grouped,
    required double textScale,
  }) {
    if (!grouped) {
      return _buildServicePanel(services, textScale: textScale);
    }

    return Column(
      children: [
        for (final family in WantokServiceFamily.catalogueFamilies)
          if (services
              .where((service) => family.matches(service.slug))
              .isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildFamilyPanel(
                family,
                services
                    .where((service) => family.matches(service.slug))
                    .toList(growable: false),
                textScale: textScale,
              ),
            ),
      ],
    );
  }

  Widget _buildFamilyPanel(
    WantokServiceFamily family,
    List<WantokServiceCategory> services, {
    required double textScale,
  }) {
    final accent = switch (family) {
      WantokServiceFamily.moveTravel => const Color(0xFF0B6F9E),
      WantokServiceFamily.foodShopping => const Color(0xFFB85624),
      WantokServiceFamily.sendTasks => const Color(0xFF007A50),
      WantokServiceFamily.peopleSkills => const Color(0xFF744AC7),
      WantokServiceFamily.bookEvents => const Color(0xFFD84A6A),
      WantokServiceFamily.all => WantokColors.primaryDark,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4ECE8)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: accent.withValues(alpha: 0.10),
                child: Icon(family.icon, color: accent, size: 22),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      family.label,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      family.subtitle,
                      style: const TextStyle(
                        color: WantokColors.muted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${services.length}',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildServiceGrid(services, textScale: textScale),
        ],
      ),
    );
  }

  Widget _buildServicePanel(
    List<WantokServiceCategory> services, {
    required double textScale,
  }) {
    return Container(
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
      child: _buildServiceGrid(services, textScale: textScale),
    );
  }

  Widget _buildServiceGrid(
    List<WantokServiceCategory> services, {
    required double textScale,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AdaptiveCategoryGrid(
          itemCount: services.length,
          tileHeight: 122,
          columnSpacing: 5,
          rowSpacing: 3,
          itemBuilder: (context, index) {
            final service = services[index];
            return WantokCategoryTile(
              key: ValueKey('catalogue-category-${service.slug}'),
              compact: true,
              label: service.name,
              style: WantokCategoryStyles.bySlug(service.slug),
              badge: _badgeFor(service.slug),
              saved: _savedCategoryIds.contains(service.id),
              onSavedToggle: () => _toggleSaved(service),
              onTap: () => _openService(service),
            );
          },
        );
      },
    );
  }

  void _openService(WantokServiceCategory service) {
    if (widget.demoMode) {
      OfflineDemoNavigation.category(context, service.slug);
      return;
    }
    if (service.bookingMode == 'information') {
      _openCategoryInformation(
        WantokCategoryStyles.bySlug(service.slug),
        service.description,
        categoryId: service.id,
      );
      return;
    }

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

  _ServiceVisual _visualFor(String slug) {
    final style = WantokCategoryStyles.bySlug(slug);
    return _ServiceVisual(style.icon, style.accent, style.surface);
  }

  String? _badgeFor(String slug) => switch (slug) {
    'taxi-ride' || 'delivery' => 'FAST',
    _ => null,
  };
}

class _ServicesMarketplacePromo extends StatelessWidget {
  const _ServicesMarketplacePromo({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 146),
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
              right: -16,
              bottom: -24,
              child: Icon(
                Icons.storefront_rounded,
                size: 160,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              right: 26,
              top: 22,
              child: CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                child: const Icon(
                  Icons.handshake_rounded,
                  color: WantokColors.gold,
                  size: 36,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 17, 116, 17),
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
                      fontSize: 21,
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
                    ),
                    icon: const Icon(Icons.search_rounded, size: 17),
                    label: const Text('Explore providers'),
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

class _TopProviderCard extends StatelessWidget {
  const _TopProviderCard({required this.provider, required this.onTap});

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

    return SizedBox(
      width: 210,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFFE2F3EA),
                      child: Icon(
                        Icons.storefront_rounded,
                        color: WantokColors.primaryDark,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.verified_rounded,
                      color: WantokColors.primary,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  provider.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: WantokColors.muted,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFE6A100),
                      size: 17,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      rating,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
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

class _AllServicesTile extends StatelessWidget {
  const _AllServicesTile({
    required this.service,
    required this.icon,
    required this.accent,
    required this.surface,
    required this.onTap,
  });

  final WantokServiceCategory service;
  final IconData icon;
  final Color accent;
  final Color surface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 9, 8, 8),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(height: 7),
              Expanded(
                child: Text(
                  service.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: WantokColors.ink,
                    fontSize: 10.5,
                    height: 1.08,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceVisual {
  const _ServiceVisual(this.icon, this.accent, this.surface);
  final IconData icon;
  final Color accent;
  final Color surface;
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
                  '$serviceTypes service type${serviceTypes == 1 ? '' : 's'} | ${place.coverageCount} coverage',
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
