import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

class VendorCommercePage extends StatefulWidget {
  const VendorCommercePage({super.key});

  @override
  State<VendorCommercePage> createState() => _VendorCommercePageState();
}

class _VendorCommercePageState extends State<VendorCommercePage> {
  static const _repository = CommerceRepository();
  late Future<_VendorCommerceData> _future;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_VendorCommerceData> _load() async {
    final values = await Future.wait([
      _repository.loadVendorCommerceServices(),
      _repository.loadVendorCatalog(),
      _repository.loadVendorOrders(),
    ]);

    return _VendorCommerceData(
      services: values[0],
      items: values[1],
      orders: values[2],
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _run(String id, Future<void> Function() action) async {
    setState(() => _busyId = id);
    try {
      await action();
      await _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _addItem(List<Map<String, dynamic>> services) async {
    final active = services
        .where((service) => service['status'] == 'active')
        .toList(growable: false);

    if (active.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You need an active Food or Groceries service before adding catalogue items.',
          ),
        ),
      );
      return;
    }

    final draft = await showDialog<_CatalogDraft>(
      context: context,
      builder: (context) => _CatalogEditorDialog(services: active),
    );
    if (draft == null) return;

    await _run(
      'new-item',
      () => _repository.createCatalogItem(
        providerServiceId: draft.providerServiceId,
        name: draft.name,
        description: draft.description,
        sku: draft.sku,
        unitLabel: draft.unitLabel,
        price: draft.price,
        currency: draft.currency,
        isAvailable: draft.isAvailable,
      ),
    );
  }

  Future<void> _editItem(
    Map<String, dynamic> item,
    List<Map<String, dynamic>> services,
  ) async {
    final draft = await showDialog<_CatalogDraft>(
      context: context,
      builder: (context) =>
          _CatalogEditorDialog(services: services, item: item),
    );
    if (draft == null) return;

    await _run(
      item['id'] as String,
      () => _repository.updateCatalogItem(
        itemId: item['id'] as String,
        name: draft.name,
        description: draft.description,
        sku: draft.sku,
        unitLabel: draft.unitLabel,
        price: draft.price,
        isAvailable: draft.isAvailable,
      ),
    );
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete catalogue item?'),
        content: Text(
          'Delete "${item['name']?.toString() ?? 'this item'}"? Existing order snapshots will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await _run(
      item['id'] as String,
      () => _repository.deleteCatalogItem(item['id'] as String),
    );
  }

  Future<void> _advanceOrder(Map<String, dynamic> order, String target) async {
    await _run(
      order['id'] as String,
      () => _repository.updateVendorOrderStatus(order['id'] as String, target),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food & Shop Console')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_VendorCommerceData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 100),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }

            final data = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
              children: [
                _VendorCommerceHero(
                  stores: data.services.length,
                  openOrders: data.orders.length,
                ),
                const SizedBox(height: 18),
                _SectionHeader(
                  title: 'Storefronts',
                  trailing: Text(
                    data.services.length.toString(),
                    style: const TextStyle(
                      color: WantokColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (data.services.isEmpty)
                  const _EmptyCard(
                    icon: Icons.storefront_outlined,
                    title: 'No Food or Shop service yet',
                    body: 'Apply for Food or Groceries / Shops, then activate the approved listing to use commerce.',
                  )
                else
                  ...data.services.map((service) {
                    final category = _asMap(service['service_categories']);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFE7F4ED),
                            child: Icon(
                              category['slug'] == 'food'
                                  ? Icons.restaurant_outlined
                                  : Icons.storefront_outlined,
                              color: WantokColors.primary,
                            ),
                          ),
                          title: Text(
                            service['title']?.toString() ?? 'Storefront',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            '${category['name']?.toString() ?? 'Commerce'} • ${service['status']}',
                          ),
                          trailing: _MiniStatus(
                            text: service['status'].toString(),
                          ),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 18),
                _SectionHeader(
                  title: 'Catalogue',
                  trailing: FilledButton.tonalIcon(
                    onPressed: () => _addItem(data.services),
                    icon: const Icon(Icons.add),
                    label: const Text('Add item'),
                  ),
                ),
                const SizedBox(height: 8),
                if (data.items.isEmpty)
                  const _EmptyCard(
                    icon: Icons.inventory_2_outlined,
                    title: 'No catalogue items',
                    body: 'Add meals, drinks, groceries or other products customers can order.',
                  )
                else
                  ...data.items.map((item) {
                    final service = _findService(
                      data.services,
                      item['provider_service_id'],
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Card(
                        child: ListTile(
                          onTap: () => _editItem(item, data.services),
                          leading: CircleAvatar(
                            backgroundColor: item['is_available'] == true
                                ? const Color(0xFFE7F4ED)
                                : const Color(0xFFF0F0F0),
                            child: Icon(
                              item['is_available'] == true
                                  ? Icons.check_circle_outline
                                  : Icons.pause_circle_outline,
                              color: item['is_available'] == true
                                  ? WantokColors.primary
                                  : WantokColors.muted,
                            ),
                          ),
                          title: Text(
                            item['name']?.toString() ?? 'Item',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            '${service?['title']?.toString() ?? 'Store'} • K${_money(item['price'])}${item['unit_label'] == null ? '' : ' / ${item['unit_label']}'}',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editItem(item, data.services);
                              } else if (value == 'delete') {
                                _deleteItem(item);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'Open orders',
                  trailing: Text(
                    data.orders.length.toString(),
                    style: const TextStyle(
                      color: WantokColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (data.orders.isEmpty)
                  const _EmptyCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'No open orders',
                    body: 'New Food and Shop orders will appear here.',
                  )
                else
                  ...data.orders.map(
                    (order) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _VendorOrderCard(
                        order: order,
                        busy: _busyId == order['id'],
                        onAdvance: (target) => _advanceOrder(order, target),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _VendorOrderCard extends StatelessWidget {
  const _VendorOrderCard({
    required this.order,
    required this.busy,
    required this.onAdvance,
  });

  final Map<String, dynamic> order;
  final bool busy;
  final ValueChanged<String> onAdvance;

  @override
  Widget build(BuildContext context) {
    final status = order['status']?.toString() ?? 'placed';
    final service = _asMap(order['provider_services']);
    final items =
        (order['commerce_order_items'] as List<dynamic>? ?? const <dynamic>[])
            .map(_asMap)
            .toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    service['title']?.toString() ?? 'Commerce order',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _MiniStatus(text: status),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('${item['quantity']} × ${item['item_name']}'),
              ),
            ),
            const Divider(height: 22),
            if (order['delivery_address'] != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 19,
                    color: WantokColors.primary,
                  ),
                  const SizedBox(width: 7),
                  Expanded(child: Text(order['delivery_address'].toString())),
                ],
              ),
            if (order['customer_note'] != null) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.notes_outlined,
                    size: 19,
                    color: WantokColors.primary,
                  ),
                  const SizedBox(width: 7),
                  Expanded(child: Text(order['customer_note'].toString())),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    order['fulfillment_type'] == 'pickup'
                        ? 'Customer pickup'
                        : 'Delivery',
                    style: const TextStyle(color: WantokColors.muted),
                  ),
                ),
                Text(
                  'K${_money(order['total_amount'])}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: WantokColors.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _actions(status, order['fulfillment_type'].toString())
                  .map(
                    (action) => action.outlined
                        ? OutlinedButton(
                            onPressed: busy
                                ? null
                                : () => onAdvance(action.target),
                            child: Text(action.label),
                          )
                        : FilledButton(
                            onPressed: busy
                                ? null
                                : () => onAdvance(action.target),
                            child: Text(busy ? 'Working...' : action.label),
                          ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }

  List<_OrderAction> _actions(String status, String fulfillment) {
    return switch (status) {
      'placed' => const [
        _OrderAction('accepted', 'Accept'),
        _OrderAction('rejected', 'Reject', outlined: true),
      ],
      'accepted' => const [_OrderAction('preparing', 'Start preparing')],
      'preparing' => const [_OrderAction('ready', 'Mark ready')],
      'ready' =>
        fulfillment == 'pickup'
            ? const [_OrderAction('completed', 'Handed to customer')]
            : const [_OrderAction('out_for_delivery', 'Out for delivery')],
      'out_for_delivery' => const [
        _OrderAction('completed', 'Complete delivery'),
      ],
      _ => const <_OrderAction>[],
    };
  }
}

class _CatalogEditorDialog extends StatefulWidget {
  const _CatalogEditorDialog({required this.services, this.item});

  final List<Map<String, dynamic>> services;
  final Map<String, dynamic>? item;

  @override
  State<_CatalogEditorDialog> createState() => _CatalogEditorDialogState();
}

class _CatalogEditorDialogState extends State<_CatalogEditorDialog> {
  late String _serviceId;
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _sku;
  late final TextEditingController _unit;
  late final TextEditingController _price;
  late bool _available;
  String? _error;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _serviceId =
        item?['provider_service_id']?.toString() ??
        widget.services.first['id'].toString();
    _name = TextEditingController(text: item?['name']?.toString() ?? '');
    _description = TextEditingController(
      text: item?['description']?.toString() ?? '',
    );
    _sku = TextEditingController(text: item?['sku']?.toString() ?? '');
    _unit = TextEditingController(text: item?['unit_label']?.toString() ?? '');
    _price = TextEditingController(
      text: item?['price'] == null ? '' : _money(item?['price']),
    );
    _available = item?['is_available'] as bool? ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _sku.dispose();
    _unit.dispose();
    _price.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final price = double.tryParse(_price.text.trim());

    if (name.length < 2) {
      setState(() => _error = 'Enter an item name.');
      return;
    }
    if (price == null || price < 0) {
      setState(() => _error = 'Enter a valid Kina price.');
      return;
    }

    final service = widget.services.firstWhere(
      (service) => service['id'] == _serviceId,
    );

    Navigator.of(context).pop(
      _CatalogDraft(
        providerServiceId: _serviceId,
        name: name,
        description: _description.text.trim(),
        sku: _sku.text.trim(),
        unitLabel: _unit.text.trim(),
        price: price,
        currency: service['currency']?.toString() ?? 'PGK',
        isAvailable: _available,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.item != null;

    return AlertDialog(
      title: Text(editing ? 'Edit catalogue item' : 'Add catalogue item'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _serviceId,
                decoration: const InputDecoration(labelText: 'Storefront'),
                items: widget.services
                    .map(
                      (service) => DropdownMenuItem(
                        value: service['id'].toString(),
                        child: Text(service['title'].toString()),
                      ),
                    )
                    .toList(growable: false),
                onChanged: editing
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _serviceId = value);
                        }
                      },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Item name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _description,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Price (Kina / K)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _unit,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  hintText: 'plate, cup, kg, packet, each...',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _sku,
                decoration: const InputDecoration(
                  labelText: 'SKU / code (optional)',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _available,
                onChanged: (value) => setState(() => _available = value),
                title: const Text('Available for ordering'),
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(editing ? 'Save' : 'Add item'),
        ),
      ],
    );
  }
}

class _CatalogDraft {
  const _CatalogDraft({
    required this.providerServiceId,
    required this.name,
    required this.description,
    required this.sku,
    required this.unitLabel,
    required this.price,
    required this.currency,
    required this.isAvailable,
  });

  final String providerServiceId;
  final String name;
  final String description;
  final String sku;
  final String unitLabel;
  final double price;
  final String currency;
  final bool isAvailable;
}

class _VendorCommerceData {
  const _VendorCommerceData({
    required this.services,
    required this.items,
    required this.orders,
  });

  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> orders;
}

class _OrderAction {
  const _OrderAction(this.target, this.label, {this.outlined = false});

  final String target;
  final String label;
  final bool outlined;
}

class _VendorCommerceHero extends StatelessWidget {
  const _VendorCommerceHero({required this.stores, required this.openOrders});

  final int stores;
  final int openOrders;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [WantokColors.primaryDark, WantokColors.primary],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.store_mall_directory_outlined,
            color: Colors.white,
            size: 50,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Commerce workspace',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$stores storefront(s) • $openOrders open order(s)',
                  style: const TextStyle(color: Color(0xFFD9F3E5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.trailing});

  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        trailing,
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(icon, size: 45, color: WantokColors.primary),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
            const SizedBox(height: 5),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: WantokColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatus extends StatelessWidget {
  const _MiniStatus({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F4ED),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
      ),
    );
  }
}

Map<String, dynamic>? _findService(
  List<Map<String, dynamic>> services,
  dynamic serviceId,
) {
  for (final service in services) {
    if (service['id'] == serviceId) return service;
  }
  return null;
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
