import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_core/wantok_core.dart';
import 'package:wantok_ui/wantok_ui.dart';

import '../home/png_visuals.dart';
import 'booking_for_selector.dart';
import 'commerce_orders_page.dart';

class CommerceBrowsePage extends StatefulWidget {
  const CommerceBrowsePage({required this.category, super.key});

  final WantokServiceCategory category;

  @override
  State<CommerceBrowsePage> createState() => _CommerceBrowsePageState();
}

class _CommerceBrowsePageState extends State<CommerceBrowsePage> {
  static const _repository = CommerceRepository();
  late Future<List<Map<String, dynamic>>> _future;
  String _query = '';
  bool _topRatedOnly = false;

  @override
  void initState() {
    super.initState();
    _future = _repository.loadStores(widget.category.slug);
  }

  Future<void> _refresh() async {
    final next = _repository.loadStores(widget.category.slug);
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
    final isFood = widget.category.slug == 'food';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F7),
      appBar: AppBar(
        title: Text(
          isFood ? 'Food' : 'Groceries & Shops',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'My orders',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const CommerceOrdersPage(),
              ),
            ),
            icon: const Icon(Icons.receipt_long_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  _MessageCard(
                    icon: Icons.cloud_off_outlined,
                    title: 'Could not load stores',
                    body: snapshot.error.toString(),
                  ),
                ],
              );
            }

            final stores = snapshot.data ?? const <Map<String, dynamic>>[];
            if (stores.isEmpty) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
                children: [
                  _CommerceHero(isFood: isFood, count: 0),
                  const SizedBox(height: 14),
                  _CommerceSearch(isFood: isFood, onChanged: (_) {}),
                  const SizedBox(height: 18),
                  _MessageCard(
                    icon: isFood
                        ? Icons.restaurant_outlined
                        : Icons.local_grocery_store_outlined,
                    title: isFood
                        ? 'No food vendors are live yet'
                        : 'No shops are live yet',
                    body: 'Approved Wantok vendors will appear here when their storefront is active.',
                  ),
                ],
              );
            }

            final filtered = stores
                .where((store) {
                  final provider = _asMap(store['provider_profiles']);
                  final haystack = [
                    store['title'],
                    store['description'],
                    provider['display_name'],
                    store['service_address'],
                  ].whereType<Object>().join(' ').toLowerCase();
                  final matchesQuery =
                      _query.trim().isEmpty ||
                      haystack.contains(_query.toLowerCase());
                  final rating = _toDouble(provider['rating_average']) ?? 0;
                  final matchesRating = !_topRatedOnly || rating >= 4.0;
                  return matchesQuery && matchesRating;
                })
                .toList(growable: false);

            return ListView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
              children: [
                _CommerceHero(isFood: isFood, count: stores.length),
                const SizedBox(height: 14),
                _CommerceSearch(
                  isFood: isFood,
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 10),
                _CommerceFilters(
                  topRatedOnly: _topRatedOnly,
                  isFood: isFood,
                  onAll: () => setState(() => _topRatedOnly = false),
                  onTopRated: () => setState(() => _topRatedOnly = true),
                ),
                const SizedBox(height: 20),
                PngSectionTitle(
                  title: isFood ? 'Popular local food' : 'Local shops',
                  subtitle: filtered.isEmpty
                      ? 'No vendors match your filters.'
                      : '${filtered.length} approved Wantok vendor${filtered.length == 1 ? '' : 's'}.',
                  trailing: IconButton(
                    tooltip: 'Refresh',
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  const _MessageCard(
                    icon: Icons.search_off_rounded,
                    title: 'Nothing matched',
                    body: 'Try another search or clear the Top rated filter.',
                  )
                else ...[
                  SizedBox(
                    height: 190,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final store = filtered[index];
                        return _StoreFeatureCard(
                          store: store,
                          isFood: isFood,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => _StorefrontPage(
                                store: store,
                                category: widget.category,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  PngSectionTitle(
                    title: isFood ? 'All food vendors' : 'All shops',
                    subtitle: 'Approved providers on Wantok Services.',
                  ),
                  const SizedBox(height: 10),
                  ...filtered.map(
                    (store) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _StoreCard(
                        store: store,
                        isFood: isFood,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => _StorefrontPage(
                              store: store,
                              category: widget.category,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StorefrontPage extends StatefulWidget {
  const _StorefrontPage({required this.store, required this.category});

  final Map<String, dynamic> store;
  final WantokServiceCategory category;

  @override
  State<_StorefrontPage> createState() => _StorefrontPageState();
}

class _StorefrontPageState extends State<_StorefrontPage> {
  static const _repository = CommerceRepository();

  late Future<List<Map<String, dynamic>>> _future;
  final Map<String, num> _quantities = {};
  bool _ordering = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _future = _repository.loadCatalog(widget.store['id'] as String);
  }

  int get _itemCount =>
      _quantities.values.fold<num>(0, (total, value) => total + value).round();

  double _subtotal(List<Map<String, dynamic>> items) {
    var total = 0.0;
    for (final item in items) {
      final quantity = _quantities[item['id']] ?? 0;
      total += (_toDouble(item['price']) ?? 0) * quantity;
    }
    return total;
  }

  void _changeQuantity(String itemId, num delta) {
    setState(() {
      final next = (_quantities[itemId] ?? 0) + delta;
      if (next <= 0) {
        _quantities.remove(itemId);
      } else {
        _quantities[itemId] = next;
      }
      _error = null;
    });
  }

  Future<void> _checkout(List<Map<String, dynamic>> items) async {
    if (_quantities.isEmpty) return;

    final draft = await showModalBottomSheet<_CheckoutDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _CheckoutSheet(
        storeTitle: widget.store['title']?.toString() ?? 'Store',
        itemCount: _itemCount,
        subtotal: _subtotal(items),
      ),
    );
    if (draft == null) return;

    setState(() {
      _ordering = true;
      _error = null;
    });

    try {
      await _repository.placeOrder(
        providerServiceId: widget.store['id'] as String,
        quantities: _quantities,
        fulfillmentType: draft.fulfillmentType,
        deliveryAddress: draft.deliveryAddress,
        customerNote: draft.note,
        trustedPersonId: draft.trustedPersonId,
      );

      if (!mounted) return;
      _quantities.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully.')),
      );
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => const CommerceOrdersPage(),
        ),
      );
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _ordering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = _asMap(widget.store['provider_profiles']);
    final title = widget.store['title']?.toString() ?? 'Store';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? const <Map<String, dynamic>>[];

          return Stack(
            children: [
              ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  _itemCount > 0 ? 112 : 28,
                ),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFFE7F4ED),
                            child: Icon(
                              widget.category.slug == 'food'
                                  ? Icons.restaurant
                                  : Icons.storefront,
                              color: WantokColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (provider['display_name'] != null)
                                  Text(
                                    provider['display_name'].toString(),
                                    style: const TextStyle(
                                      color: WantokColors.muted,
                                    ),
                                  ),
                                if (widget.store['service_address'] != null)
                                  Text(
                                    widget.store['service_address'].toString(),
                                    style: const TextStyle(
                                      color: WantokColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.category.slug == 'food' ? 'Menu' : 'Products',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  if (snapshot.hasError)
                    _MessageCard(
                      icon: Icons.error_outline,
                      title: 'Could not load catalogue',
                      body: snapshot.error.toString(),
                    )
                  else if (items.isEmpty)
                    const _MessageCard(
                      icon: Icons.inventory_2_outlined,
                      title: 'Catalogue is empty',
                      body: 'This vendor has not published any available items yet.',
                    )
                  else
                    ...items.map((item) {
                      final itemId = item['id'] as String;
                      final quantity = _quantities[itemId] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F5F2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    widget.category.slug == 'food'
                                        ? Icons.lunch_dining_outlined
                                        : Icons.shopping_basket_outlined,
                                    color: WantokColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name']?.toString() ?? 'Item',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      if (item['description'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 3,
                                          ),
                                          child: Text(
                                            item['description'].toString(),
                                            style: const TextStyle(
                                              color: WantokColors.muted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 7),
                                      Text(
                                        'K${_money(item['price'])}${item['unit_label'] == null ? '' : ' / ${item['unit_label']}'}',
                                        style: const TextStyle(
                                          color: WantokColors.primaryDark,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (quantity <= 0)
                                  IconButton.filledTonal(
                                    onPressed: () => _changeQuantity(itemId, 1),
                                    icon: const Icon(Icons.add),
                                  )
                                else
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () =>
                                            _changeQuantity(itemId, -1),
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                      ),
                                      Text(
                                        quantity.toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            _changeQuantity(itemId, 1),
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
              if (_itemCount > 0)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    minimum: const EdgeInsets.all(14),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _ordering ? null : () => _checkout(items),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            _ordering
                                ? 'Placing order...'
                                : 'View cart • $_itemCount item(s) • K${_subtotal(items).toStringAsFixed(2)}',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CheckoutSheet extends StatefulWidget {
  const _CheckoutSheet({
    required this.storeTitle,
    required this.itemCount,
    required this.subtotal,
  });

  final String storeTitle;
  final int itemCount;
  final double subtotal;

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  String _fulfillmentType = 'delivery';
  String? _trustedPersonId;
  String? _error;

  @override
  void dispose() {
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_fulfillmentType == 'delivery' &&
        _addressController.text.trim().isEmpty) {
      setState(() => _error = 'Enter a delivery address.');
      return;
    }

    Navigator.of(context).pop(
      _CheckoutDraft(
        fulfillmentType: _fulfillmentType,
        deliveryAddress: _fulfillmentType == 'delivery'
            ? _addressController.text.trim()
            : null,
        note: _noteController.text.trim(),
        trustedPersonId: _trustedPersonId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(18, 14, 18, 18 + bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Checkout',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.storeTitle} • ${widget.itemCount} item(s) • K${widget.subtotal.toStringAsFixed(2)}',
            style: const TextStyle(color: WantokColors.muted),
          ),
          const SizedBox(height: 18),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'delivery',
                label: Text('Delivery'),
                icon: Icon(Icons.delivery_dining_outlined),
              ),
              ButtonSegment(
                value: 'pickup',
                label: Text('Pickup'),
                icon: Icon(Icons.store_mall_directory_outlined),
              ),
            ],
            selected: {_fulfillmentType},
            showSelectedIcon: false,
            onSelectionChanged: (value) {
              setState(() {
                _fulfillmentType = value.first;
                _error = null;
              });
            },
          ),
          if (_fulfillmentType == 'delivery') ...[
            const SizedBox(height: 14),
            TextField(
              controller: _addressController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Delivery address / landmark',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
          ],
          const SizedBox(height: 14),
          BookingForSelector(
            selectedTrustedPersonId: _trustedPersonId,
            onChanged: (value) {
              setState(() {
                _trustedPersonId = value;
                _error = null;
              });
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _noteController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Order note (optional)',
              hintText:
                  'Special instructions, substitutions, contact details...',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(
                Icons.payments_outlined,
                color: WantokColors.primary,
              ),
              title: Text(
                'Cash payment',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                'Online payment integration will be connected in a later payment phase.',
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submit,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 13),
              child: Text('Place order'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutDraft {
  const _CheckoutDraft({
    required this.fulfillmentType,
    this.deliveryAddress,
    this.note,
    this.trustedPersonId,
  });

  final String fulfillmentType;
  final String? deliveryAddress;
  final String? note;
  final String? trustedPersonId;
}

class _CommerceSearch extends StatelessWidget {
  const _CommerceSearch({required this.isFood, required this.onChanged});

  final bool isFood;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: isFood
            ? 'Search local food or vendors'
            : 'Search shops or groceries',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: const Icon(Icons.tune_rounded),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

class _CommerceFilters extends StatelessWidget {
  const _CommerceFilters({
    required this.topRatedOnly,
    required this.isFood,
    required this.onAll,
    required this.onTopRated,
  });

  final bool topRatedOnly;
  final bool isFood;
  final VoidCallback onAll;
  final VoidCallback onTopRated;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ChoiceChip(
            selected: !topRatedOnly,
            onSelected: (_) => onAll(),
            avatar: const Icon(Icons.apps_rounded, size: 17),
            label: const Text('All'),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            selected: topRatedOnly,
            onSelected: (_) => onTopRated(),
            avatar: const Icon(Icons.star_rounded, size: 17),
            label: const Text('Top rated'),
          ),
          const SizedBox(width: 8),
          Chip(
            avatar: Icon(
              isFood ? Icons.restaurant_menu_rounded : Icons.storefront_rounded,
              size: 17,
            ),
            label: Text(isFood ? 'Local favourites' : 'Local stores'),
          ),
          const SizedBox(width: 8),
          const Chip(
            avatar: Icon(Icons.payments_rounded, size: 17),
            label: Text('Kina'),
          ),
        ],
      ),
    );
  }
}

class _StoreFeatureCard extends StatelessWidget {
  const _StoreFeatureCard({
    required this.store,
    required this.isFood,
    required this.onTap,
  });

  final Map<String, dynamic> store;
  final bool isFood;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final provider = _asMap(store['provider_profiles']);
    final rating = _toDouble(provider['rating_average']) ?? 0;
    final ratingCount = provider['rating_count'] ?? 0;
    final title = store['title']?.toString() ?? 'Wantok Store';
    final palette = _palette(title);

    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE4E8E6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: palette),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(23),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -10,
                          bottom: -14,
                          child: Icon(
                            isFood
                                ? Icons.ramen_dining_rounded
                                : Icons.shopping_basket_rounded,
                            color: Colors.white.withValues(alpha: 0.18),
                            size: 92,
                          ),
                        ),
                        Center(
                          child: CircleAvatar(
                            radius: 33,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.9,
                            ),
                            child: Icon(
                              isFood
                                  ? Icons.restaurant_rounded
                                  : Icons.storefront_rounded,
                              color: palette.first,
                              size: 33,
                            ),
                          ),
                        ),
                        const Positioned(
                          left: 10,
                          top: 10,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: WantokColors.gold,
                              borderRadius: BorderRadius.all(
                                Radius.circular(999),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Text(
                                'LOCAL',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          if (ratingCount != 0) ...[
                            const Icon(
                              Icons.star_rounded,
                              color: WantokColors.gold,
                              size: 17,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '($ratingCount)',
                              style: const TextStyle(
                                color: WantokColors.muted,
                                fontSize: 10,
                              ),
                            ),
                          ] else
                            const Text(
                              'New on Wantok',
                              style: TextStyle(
                                color: WantokColors.primaryDark,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          const Spacer(),
                          const Icon(Icons.chevron_right_rounded, size: 19),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _palette(String title) {
    final value = title.codeUnits.fold<int>(0, (sum, item) => sum + item);
    const palettes = [
      [Color(0xFFD86020), Color(0xFFED8B3A)],
      [Color(0xFF087A4B), Color(0xFF2BA66C)],
      [Color(0xFF0B79A8), Color(0xFF3DA9C8)],
      [Color(0xFF744AC7), Color(0xFF9D73DD)],
      [Color(0xFFC85536), Color(0xFFE8845D)],
    ];
    return palettes[value % palettes.length];
  }
}

class _CommerceHero extends StatelessWidget {
  const _CommerceHero({required this.isFood, required this.count});
  final bool isFood;
  final int count;

  @override
  Widget build(BuildContext context) {
    return PngScenicBackdrop(
      height: 176,
      colors: isFood
          ? const [Color(0xFF8A381D), Color(0xFFD86020), Color(0xFF087A4B)]
          : const [Color(0xFF075C3A), Color(0xFF2E8B57), Color(0xFF0B79A8)],
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isFood
                      ? 'PNG flavours, close by.'
                      : 'Local shops. Everyday needs.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    height: 1.03,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$count approved Wantok vendor${count == 1 ? '' : 's'} available.',
                  style: const TextStyle(
                    color: Color(0xFFF7EEE4),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 11),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isFood
                        ? 'Food • Local vendors • Kina pricing'
                        : 'Groceries • Shops • Kina pricing',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 32,
            backgroundColor: Color(0x33FFFFFF),
            child: Icon(
              isFood
                  ? Icons.restaurant_rounded
                  : Icons.local_grocery_store_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.store,
    required this.isFood,
    required this.onTap,
  });

  final Map<String, dynamic> store;
  final bool isFood;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final provider = _asMap(store['provider_profiles']);
    final rating = _toDouble(provider['rating_average']) ?? 0;
    final ratingCount = provider['rating_count'] ?? 0;

    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          radius: 27,
          backgroundColor: const Color(0xFFE7F4ED),
          child: Icon(
            isFood ? Icons.restaurant_outlined : Icons.storefront_outlined,
            color: WantokColors.primary,
          ),
        ),
        title: Text(
          store['title']?.toString() ?? 'Wantok Store',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (store['description'] != null)
              Text(
                store['description'].toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (ratingCount != 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('★ ${rating.toStringAsFixed(1)} ($ratingCount)'),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Icon(icon, size: 54, color: WantokColors.primary),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: WantokColors.muted),
          ),
        ],
      ),
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

double? _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

String _money(dynamic value) {
  final amount = _toDouble(value);
  return amount == null ? value.toString() : amount.toStringAsFixed(2);
}

String _friendlyError(Object error) {
  final text = error.toString();
  const marker = 'message: ';
  final markerIndex = text.indexOf(marker);
  if (markerIndex >= 0) {
    return text.substring(markerIndex + marker.length).replaceAll(')', '');
  }
  return text.replaceFirst('StateError: ', '');
}
