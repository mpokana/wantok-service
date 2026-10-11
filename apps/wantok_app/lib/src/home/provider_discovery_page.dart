import 'dart:async';

import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

import 'png_visuals.dart';

class ProviderDiscoveryPage extends StatefulWidget {
  const ProviderDiscoveryPage({
    this.initialQuery,
    this.initialCategoryId,
    this.initialCategoryName,
    super.key,
  });

  final String? initialQuery;
  final String? initialCategoryId;
  final String? initialCategoryName;

  @override
  State<ProviderDiscoveryPage> createState() => _ProviderDiscoveryPageState();
}

class _ProviderDiscoveryPageState extends State<ProviderDiscoveryPage> {
  static const _repository = ProviderDiscoveryRepository();
  static const _experience = ClientExperienceRepository();

  final _search = TextEditingController();
  Timer? _debounce;
  late Future<List<ClientProviderDiscovery>> _future;
  final Set<String> _savedProviderIds = <String>{};
  final Set<String> _savingIds = <String>{};
  List<ClientServicePlace> _places = const <ClientServicePlace>[];
  List<Map<String, dynamic>> _availableLocations = const [];
  String? _countryCode;
  String _countryLabel = 'Country';
  String? _providerType;
  double? _minRating;
  bool _remoteOnly = false;
  String _sort = 'recommended';
  String? _categoryId;
  String? _province;
  String? _town;
  bool _showingTop = true;

  @override
  void initState() {
    super.initState();
    final initialQuery = widget.initialQuery?.trim() ?? '';
    _search.text = initialQuery;
    _categoryId = widget.initialCategoryId;
    // Browser/device locale is an initial suggestion, not GPS verification.
    _countryCode = WidgetsBinding.instance.platformDispatcher.locale.countryCode
        ?.toUpperCase();
    if (_countryCode == null || _countryCode!.length != 2) _countryCode = 'PG';
    _countryLabel = _countryCode!;
    _showingTop = false;
    _future = _repository.searchProviders(
      query: initialQuery,
      categoryId: _categoryId,
      countryCode: _countryCode,
    );
    _loadSaved();
    _loadFilterOptions();
    _loadLocationPreference();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    try {
      final ids = await _experience.loadSavedIds('provider');
      if (mounted) {
        setState(() {
          _savedProviderIds
            ..clear()
            ..addAll(ids);
        });
      }
    } catch (_) {
      // Provider discovery remains usable if Saved cannot load.
    }
  }

  Future<void> _loadFilterOptions() async {
    try {
      final places = await _experience.loadServicePlaces(limit: 100);
      final locations = await _repository.listLocations();
      if (mounted) {
        setState(() {
          _places = places;
          _availableLocations = locations;
        });
      }
    } catch (_) {
      // Provider search remains usable if structured filter options cannot load.
    }
  }

  Future<void> _loadLocationPreference() async {
    try {
      final pref = await _repository.loadDiscoveryPreferences();
      if (!mounted || pref == null) return;
      setState(() {
        _countryCode = pref['country_code'] as String?;
        _countryLabel = _countryCode ?? 'All countries';
        _province = pref['region'] as String?;
        _town = pref['town'] as String?;
      });
      _runSearch();
    } catch (_) {
      // Locale remains a suggestion if preferences cannot load.
    }
  }

  void _setCountry(String? value, [String? name]) {
    setState(() {
      _countryCode = value;
      _countryLabel = name ?? value ?? 'All countries';
      _province = null;
      _town = null;
    });
    if (value != null) {
      _repository
          .saveDiscoveryPreferences(countryCode: value)
          .catchError((Object _) {});
    }
    _runSearch();
  }

  Map<String, String> get _categoryOptions {
    final options = <String, String>{};
    for (final place in _places) {
      final count = place.categoryIds.length < place.categoryNames.length
          ? place.categoryIds.length
          : place.categoryNames.length;
      for (var index = 0; index < count; index++) {
        options[place.categoryIds[index]] = place.categoryNames[index];
      }
    }
    if (widget.initialCategoryId case final id?) {
      options.putIfAbsent(
        id,
        () => widget.initialCategoryName ?? 'Selected category',
      );
    }
    final entries = options.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return Map<String, String>.fromEntries(entries);
  }

  Map<String, String> get _provinceOptions {
    final provinces =
        _availableLocations
            .where(
              (row) =>
                  _countryCode == null || row['country_code'] == _countryCode,
            )
            .map((row) => (row['region']?.toString() ?? '').trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return <String, String>{
      for (final province in provinces) province: province,
    };
  }

  Map<String, String> get _townOptions {
    final towns =
        _availableLocations
            .where(
              (row) =>
                  (_countryCode == null ||
                      row['country_code'] == _countryCode) &&
                  (_province == null ||
                      (row['region']?.toString() ?? '').toLowerCase() ==
                          _province!.toLowerCase()),
            )
            .map((row) => row['town']?.toString().trim())
            .whereType<String>()
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return <String, String>{for (final town in towns) town: town};
  }

  bool get _hasFilters =>
      _categoryId != null ||
      _countryCode != null ||
      _province != null ||
      _town != null ||
      _providerType != null ||
      _minRating != null ||
      _remoteOnly;

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _runSearch(value);
    });
  }

  void _setCategory(String? value) {
    setState(() => _categoryId = value);
    _runSearch();
  }

  void _setProvince(String? value) {
    setState(() {
      _province = value;
      if (_town != null && !_townOptions.containsKey(_town)) {
        _town = null;
      }
    });
    if (_countryCode != null) {
      _repository
          .saveDiscoveryPreferences(
            countryCode: _countryCode!,
            region: _province,
          )
          .catchError((Object _) {});
    }
    _runSearch();
  }

  void _setTown(String? value) {
    setState(() => _town = value);
    if (_countryCode != null) {
      _repository
          .saveDiscoveryPreferences(
            countryCode: _countryCode!,
            region: _province,
            town: _town,
          )
          .catchError((Object _) {});
    }
    _runSearch();
  }

  void _clearAll() {
    _search.clear();
    setState(() {
      _categoryId = null;
      _countryCode = null;
      _countryLabel = 'All countries';
      _province = null;
      _town = null;
      _providerType = null;
      _minRating = null;
      _remoteOnly = false;
    });
    _runSearch('');
  }

  Future<void> _runSearch([String? value]) async {
    final query = (value ?? _search.text).trim();
    final showTop = query.isEmpty && !_hasFilters;
    final next = _repository.searchProviders(
      query: query,
      categoryId: _categoryId,
      countryCode: _countryCode,
      province: _province,
      town: _town,
      providerType: _providerType,
      minRating: _minRating,
      remoteOnly: _remoteOnly,
      limit: 60,
    );

    setState(() {
      _showingTop = showTop;
      _future = next;
    });

    try {
      await next;
    } catch (_) {
      // FutureBuilder presents the retry state.
    }
  }

  Future<void> _toggleSaved(ClientProviderDiscovery provider) async {
    if (_savingIds.contains(provider.providerId)) return;
    final wasSaved = _savedProviderIds.contains(provider.providerId);
    setState(() => _savingIds.add(provider.providerId));
    try {
      await _experience.setSavedItem(
        itemType: 'provider',
        entityId: provider.providerId,
        saved: !wasSaved,
      );
      if (mounted) {
        setState(() {
          if (wasSaved) {
            _savedProviderIds.remove(provider.providerId);
          } else {
            _savedProviderIds.add(provider.providerId);
          }
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _savingIds.remove(provider.providerId));
    }
  }

  void _openProvider(ClientProviderDiscovery provider) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProviderDetailPage(provider: provider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        title: const Text(
          'Find Wantok providers',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                _runSearch(),
                _loadSaved(),
                _loadFilterOptions(),
              ]);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF003E2D), Color(0xFF08694A)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Search people & businesses',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Find approved Wantok providers by name, service or category.',
                              style: TextStyle(
                                color: Color(0xFFE4F4EE),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      CircleAvatar(
                        radius: 27,
                        backgroundColor: Color(0x33FFFFFF),
                        child: Icon(
                          Icons.manage_search_rounded,
                          color: Colors.white,
                          size: 31,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: TextField(
                      controller: _search,
                      onChanged: _onSearchChanged,
                      onSubmitted: _runSearch,
                      decoration: InputDecoration(
                        labelText: 'Provider, service or category',
                        hintText: 'e.g. plumber, vehicle hire, catering',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear',
                                onPressed: () {
                                  _search.clear();
                                  _runSearch('');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.filter_alt_outlined,
                              color: WantokColors.primaryDark,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Filter providers',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                            if (_hasFilters)
                              TextButton(
                                onPressed: _clearAll,
                                child: const Text('Clear all'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LayoutBuilder(
                          builder: (context, layout) {
                            final columns = layout.maxWidth >= 780
                                ? 3
                                : layout.maxWidth >= 490
                                ? 2
                                : 1;
                            final width =
                                (layout.maxWidth - 12 * (columns - 1)) /
                                columns;
                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                SizedBox(
                                  width: width,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.public_rounded),
                                    label: Text(
                                      'Country: $_countryLabel',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onPressed: () => showCountryPicker(
                                      context: context,
                                      showPhoneCode: false,
                                      onSelect: (country) => _setCountry(
                                        country.countryCode,
                                        country.name,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: width,
                                  child: _ProviderFilterSelect(
                                    label: 'Category',
                                    allLabel: 'All categories',
                                    value: _categoryId,
                                    options: _categoryOptions,
                                    onChanged: _setCategory,
                                  ),
                                ),
                                SizedBox(
                                  width: width,
                                  child: _ProviderFilterSelect(
                                    label: 'State / Province / Region',
                                    allLabel: 'All regions',
                                    value: _province,
                                    options: _provinceOptions,
                                    onChanged: _provinceOptions.isEmpty
                                        ? null
                                        : _setProvince,
                                  ),
                                ),
                                SizedBox(
                                  width: width,
                                  child: _ProviderFilterSelect(
                                    label: 'Town / City',
                                    allLabel: 'All towns',
                                    value: _town,
                                    options: _townOptions,
                                    onChanged: _townOptions.isEmpty
                                        ? null
                                        : _setTown,
                                  ),
                                ),
                                SizedBox(
                                  width: width,
                                  child: _ProviderFilterSelect(
                                    label: 'Provider type',
                                    allLabel: 'All providers',
                                    value: _providerType,
                                    options: const {
                                      'individual': 'Individuals',
                                      'business': 'Businesses',
                                      'organisation': 'Organisations',
                                    },
                                    onChanged: (value) {
                                      setState(() => _providerType = value);
                                      _runSearch();
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: width,
                                  child: _ProviderFilterSelect(
                                    label: 'Minimum rating',
                                    allLabel: 'Any rating',
                                    value: _minRating?.toStringAsFixed(1),
                                    options: const {
                                      '3.0': '3 stars & above',
                                      '4.0': '4 stars & above',
                                      '4.5': '4.5 stars & above',
                                    },
                                    onChanged: (value) {
                                      setState(
                                        () => _minRating = double.tryParse(
                                          value ?? '',
                                        ),
                                      );
                                      _runSearch();
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: width,
                                  child: _ProviderFilterSelect(
                                    label: 'Sort by',
                                    allLabel: 'Recommended',
                                    value: _sort == 'recommended'
                                        ? null
                                        : _sort,
                                    options: const {
                                      'rating': 'Highest rated',
                                      'reviews': 'Most reviews',
                                      'name': 'Provider name',
                                    },
                                    onChanged: (value) => setState(
                                      () => _sort = value ?? 'recommended',
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: width,
                                  child: SwitchListTile.adaptive(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Remote / Online'),
                                    value: _remoteOnly,
                                    onChanged: (value) {
                                      setState(() => _remoteOnly = value);
                                      _runSearch();
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (_countryCode != null)
                              TextButton.icon(
                                onPressed: () => _setCountry(null),
                                icon: const Icon(Icons.travel_explore),
                                label: const Text('Search all countries'),
                              ),
                            const Chip(
                              avatar: Icon(
                                Icons.verified_user_outlined,
                                size: 16,
                              ),
                              label: Text('Verified providers only'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                PngSectionTitle(
                  title: _showingTop ? 'Top Wantoks' : 'Search results',
                  subtitle: _showingTop
                      ? 'A rotating selection from highly rated eligible providers.'
                      : 'Only active verified providers with approved services appear.',
                ),
                const SizedBox(height: 10),
                FutureBuilder<List<ClientProviderDiscovery>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.all(38),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
                      return _StateCard(
                        icon: Icons.cloud_off_outlined,
                        title: 'Could not load providers',
                        body: 'Check your connection and try again.',
                        actionLabel: 'Retry',
                        onAction: _runSearch,
                      );
                    }

                    final providers = [
                      ...snapshot.data ?? const <ClientProviderDiscovery>[],
                    ];
                    if (_sort != 'recommended') {
                      providers.sort(
                        (a, b) => switch (_sort) {
                          'rating' => b.ratingAverage.compareTo(
                            a.ratingAverage,
                          ),
                          'reviews' => b.ratingCount.compareTo(a.ratingCount),
                          'name' => a.displayName.toLowerCase().compareTo(
                            b.displayName.toLowerCase(),
                          ),
                          _ => 0,
                        },
                      );
                    }
                    if (providers.isEmpty) {
                      return _StateCard(
                        icon: Icons.search_off_rounded,
                        title: 'No matching providers',
                        body: 'Try another provider name, service or category. Wantok Agent can guide the next step when normal search cannot find a match.',
                        actionLabel: _hasFilters
                            ? 'Clear filters'
                            : 'Clear search',
                        onAction: _clearAll,
                      );
                    }

                    return Column(
                      children: [
                        for (final provider in providers) ...[
                          _ProviderCard(
                            provider: provider,
                            isSaved: _savedProviderIds.contains(
                              provider.providerId,
                            ),
                            saving: _savingIds.contains(provider.providerId),
                            onSaved: () => _toggleSaved(provider),
                            onTap: () => _openProvider(provider),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProviderFilterSelect extends StatelessWidget {
  const _ProviderFilterSelect({
    required this.label,
    required this.allLabel,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String allLabel;
  final String? value;
  final Map<String, String> options;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value ?? '',
          isExpanded: true,
          isDense: true,
          items: [
            DropdownMenuItem<String>(value: '', child: Text(allLabel)),
            for (final option in options.entries)
              DropdownMenuItem<String>(
                value: option.key,
                child: Text(option.value, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onChanged == null
              ? null
              : (next) =>
                    onChanged!(next == null || next.isEmpty ? null : next),
        ),
      ),
    );
  }
}

class ProviderDetailPage extends StatefulWidget {
  const ProviderDetailPage({required this.provider, super.key});

  final ClientProviderDiscovery provider;

  @override
  State<ProviderDetailPage> createState() => _ProviderDetailPageState();
}

class _ProviderDetailPageState extends State<ProviderDetailPage> {
  static const _repository = ProviderDiscoveryRepository();
  late Future<List<ClientProviderService>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.loadProviderServices(widget.provider.providerId);
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(title: Text(provider.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 29,
                        backgroundColor: const Color(0xFFE2F3EA),
                        child: Icon(
                          provider.providerType == 'business'
                              ? Icons.storefront_rounded
                              : provider.providerType == 'organisation'
                              ? Icons.apartment_rounded
                              : Icons.person_rounded,
                          color: WantokColors.primaryDark,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.displayName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              provider.providerType[0].toUpperCase() +
                                  provider.providerType.substring(1),
                              style: const TextStyle(color: WantokColors.muted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.verified_rounded,
                        color: WantokColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  _RatingLine(provider: provider),
                  if (provider.bio?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    Text(provider.bio!, style: const TextStyle(height: 1.4)),
                  ],
                  if (provider.coverageProvinces.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: provider.coverageProvinces
                          .map(
                            (place) => Chip(
                              avatar: const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                              ),
                              label: Text(place),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const PngSectionTitle(
            title: 'Approved services',
            subtitle: 'Only active Wantok service listings are shown for this provider.',
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<ClientProviderService>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return const _StateCard(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load services',
                  body: 'Try again later.',
                );
              }

              final services = snapshot.data ?? const <ClientProviderService>[];
              if (services.isEmpty) {
                return const _StateCard(
                  icon: Icons.miscellaneous_services_outlined,
                  title: 'No active services',
                  body: 'This provider currently has no approved active listings.',
                );
              }

              return Column(
                children: services
                    .map((service) => _ProviderServiceCard(service: service))
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.provider,
    required this.isSaved,
    required this.saving,
    required this.onSaved,
    required this.onTap,
  });

  final ClientProviderDiscovery provider;
  final bool isSaved;
  final bool saving;
  final VoidCallback onSaved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final categories = provider.categoryNames.take(3).join(' • ');
    final places = provider.coverageTowns.isNotEmpty
        ? provider.coverageTowns.take(2).join(', ')
        : provider.coverageProvinces.take(2).join(', ');

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFFE2F3EA),
                child: Icon(
                  provider.providerType == 'business'
                      ? Icons.storefront_rounded
                      : Icons.person_rounded,
                  color: WantokColors.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            provider.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.verified_rounded,
                          color: WantokColors.primary,
                          size: 17,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    _RatingLine(provider: provider),
                    if (categories.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        categories,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                    if (places.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        places,
                        style: const TextStyle(
                          color: WantokColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: isSaved ? 'Remove from saved' : 'Save provider',
                onPressed: saving ? null : onSaved,
                icon: saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: WantokColors.primaryDark,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingLine extends StatelessWidget {
  const _RatingLine({required this.provider});

  final ClientProviderDiscovery provider;

  @override
  Widget build(BuildContext context) {
    if (!provider.hasRatings) {
      return const Text(
        'New provider • No ratings yet',
        style: TextStyle(color: WantokColors.muted, fontSize: 12),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFE6A100), size: 18),
        const SizedBox(width: 3),
        Text(
          provider.ratingAverage.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: 4),
        Text(
          '(${provider.ratingCount})',
          style: const TextStyle(color: WantokColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class _ProviderServiceCard extends StatelessWidget {
  const _ProviderServiceCard({required this.service});

  final ClientProviderService service;

  @override
  Widget build(BuildContext context) {
    final place = [
      if (service.coverageTown?.trim().isNotEmpty == true)
        service.coverageTown!,
      if (service.coverageProvince?.trim().isNotEmpty == true)
        service.coverageProvince!,
    ].join(', ');

    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE7F4ED),
          child: Icon(
            Icons.miscellaneous_services_rounded,
            color: WantokColors.primaryDark,
          ),
        ),
        title: Text(
          service.title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          [
            service.categoryName,
            if (place.isNotEmpty) place,
            _priceLabel(service),
          ].where((value) => value.isNotEmpty).join(' • '),
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
            Icon(icon, size: 44, color: WantokColors.primary),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: WantokColors.muted),
            ),
            if (onAction != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel ?? 'Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _priceLabel(ClientProviderService service) {
  if (service.basePrice == null) {
    return service.pricingModel == 'quote'
        ? 'Quote'
        : service.pricingModel.replaceAll('_', ' ');
  }

  final amount = service.basePrice!.toStringAsFixed(2);
  final unit = service.unitLabel?.trim();
  return unit == null || unit.isEmpty ? 'K$amount' : 'K$amount / $unit';
}

String _friendlyError(Object error) {
  return error
      .toString()
      .replaceFirst('StateError: ', '')
      .replaceFirst('PostgrestException(message: ', '');
}
