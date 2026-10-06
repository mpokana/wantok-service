import 'wantok_backend.dart';

class CommerceRepository {
  const CommerceRepository();

  String get _userId {
    final user = WantokBackend.client.auth.currentUser;
    if (user == null) {
      throw StateError('Authentication required.');
    }
    return user.id;
  }

  Future<List<Map<String, dynamic>>> loadStores(String categorySlug) async {
    final category = await WantokBackend.client
        .from('service_categories')
        .select('id')
        .eq('slug', categorySlug)
        .eq('is_active', true)
        .maybeSingle();

    if (category == null) return const [];

    final rows = await WantokBackend.client
        .from('provider_services')
        .select(
          'id, provider_id, title, description, currency, service_address, metadata, provider_profiles(display_name, rating_average, rating_count)',
        )
        .eq('category_id', category['id'])
        .eq('status', 'active')
        .order('title');

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> loadCatalog(
    String providerServiceId,
  ) async {
    final rows = await WantokBackend.client
        .from('commerce_catalog_items')
        .select(
          'id, provider_service_id, provider_id, name, description, sku, unit_label, price, currency, image_url, is_available, sort_order, metadata',
        )
        .eq('provider_service_id', providerServiceId)
        .eq('is_available', true)
        .order('sort_order')
        .order('name');

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> placeOrder({
    required String providerServiceId,
    required Map<String, num> quantities,
    required String fulfillmentType,
    String? deliveryAddress,
    double? deliveryLat,
    double? deliveryLng,
    String? customerNote,
    String paymentMethod = 'cash',
    String? trustedPersonId,
  }) async {
    final items = quantities.entries
        .where((entry) => entry.value > 0)
        .map((entry) => {'item_id': entry.key, 'quantity': entry.value})
        .toList(growable: false);

    if (items.isEmpty) {
      throw StateError('Add at least one item to the order.');
    }

    final response = await WantokBackend.client.rpc(
      'create_commerce_order',
      params: {
        'p_provider_service_id': providerServiceId,
        'p_items': items,
        'p_fulfillment_type': fulfillmentType,
        'p_delivery_address': _emptyToNull(deliveryAddress),
        'p_delivery_lat': deliveryLat,
        'p_delivery_lng': deliveryLng,
        'p_customer_note': _emptyToNull(customerNote),
        'p_payment_method': paymentMethod,
        'p_trusted_person_id': trustedPersonId,
      },
    );

    return _asMap(response);
  }

  Future<List<Map<String, dynamic>>> loadMyOrders() async {
    final rows = await WantokBackend.client
        .from('commerce_orders')
        .select(
          'id, status, fulfillment_type, delivery_address, customer_note, subtotal, delivery_fee, total_amount, currency, payment_method, payment_status, placed_at, accepted_at, preparing_at, ready_at, out_for_delivery_at, completed_at, cancelled_at, rejection_reason:cancellation_reason, trusted_person_id, beneficiary_name, beneficiary_relationship, beneficiary_phone, beneficiary_email, provider_services(title), service_categories(name, slug), commerce_order_items(id, item_name, unit_label, quantity, unit_price, line_total)',
        )
        .eq('customer_id', _userId)
        .order('created_at', ascending: false)
        .limit(30);

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> cancelOrder(String orderId, {String? reason}) async {
    await WantokBackend.client.rpc(
      'cancel_commerce_order',
      params: {'p_order_id': orderId, 'p_reason': _emptyToNull(reason)},
    );
  }

  Future<List<Map<String, dynamic>>> loadVendorCommerceServices() async {
    final rows = await WantokBackend.client
        .from('provider_services')
        .select(
          'id, provider_id, title, description, currency, service_address, status, service_categories(id, slug, name, booking_mode)',
        )
        .eq('provider_id', _userId)
        .order('created_at');

    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((row) {
          final category = _asMap(row['service_categories']);
          return category['booking_mode'] == 'commerce' &&
              const {'food', 'groceries'}.contains(category['slug']);
        })
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> loadVendorCatalog() async {
    final rows = await WantokBackend.client
        .from('commerce_catalog_items')
        .select(
          'id, provider_service_id, provider_id, name, description, sku, unit_label, price, currency, image_url, is_available, sort_order, metadata',
        )
        .eq('provider_id', _userId)
        .order('provider_service_id')
        .order('sort_order')
        .order('name');

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> createCatalogItem({
    required String providerServiceId,
    required String name,
    String? description,
    String? sku,
    String? unitLabel,
    required double price,
    required String currency,
    bool isAvailable = true,
  }) async {
    await WantokBackend.client.from('commerce_catalog_items').insert({
      'provider_service_id': providerServiceId,
      'provider_id': _userId,
      'name': name.trim(),
      'description': _emptyToNull(description),
      'sku': _emptyToNull(sku),
      'unit_label': _emptyToNull(unitLabel),
      'price': price,
      'currency': currency,
      'is_available': isAvailable,
    });
  }

  Future<void> updateCatalogItem({
    required String itemId,
    required String name,
    String? description,
    String? sku,
    String? unitLabel,
    required double price,
    required bool isAvailable,
  }) async {
    await WantokBackend.client
        .from('commerce_catalog_items')
        .update({
          'name': name.trim(),
          'description': _emptyToNull(description),
          'sku': _emptyToNull(sku),
          'unit_label': _emptyToNull(unitLabel),
          'price': price,
          'is_available': isAvailable,
        })
        .eq('id', itemId)
        .eq('provider_id', _userId);
  }

  Future<void> deleteCatalogItem(String itemId) async {
    await WantokBackend.client
        .from('commerce_catalog_items')
        .delete()
        .eq('id', itemId)
        .eq('provider_id', _userId);
  }

  Future<List<Map<String, dynamic>>> loadVendorOrders() async {
    final rows = await WantokBackend.client
        .from('commerce_orders')
        .select(
          'id, customer_id, status, fulfillment_type, delivery_address, customer_note, subtotal, delivery_fee, total_amount, currency, payment_method, payment_status, placed_at, trusted_person_id, beneficiary_name, beneficiary_relationship, beneficiary_phone, beneficiary_email, profiles(full_name, phone), provider_services(title), service_categories(name, slug), commerce_order_items(id, item_name, unit_label, quantity, unit_price, line_total)',
        )
        .eq('provider_id', _userId)
        .inFilter('status', [
          'placed',
          'accepted',
          'preparing',
          'ready',
          'out_for_delivery',
        ])
        .order('created_at');

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> updateVendorOrderStatus(String orderId, String status) async {
    await WantokBackend.client.rpc(
      'vendor_update_commerce_order_status',
      params: {'p_order_id': orderId, 'p_status': status},
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    return <String, dynamic>{};
  }

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
