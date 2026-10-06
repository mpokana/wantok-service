import 'package:wantok_core/wantok_core.dart';

import 'wantok_backend.dart';

class ReservationRepository {
  const ReservationRepository();

  String get _userId {
    final user = WantokBackend.client.auth.currentUser;
    if (user == null) {
      throw StateError('Authentication required.');
    }
    return user.id;
  }

  Future<List<ReservableOffer>> loadOffers(String categorySlug) async {
    final client = WantokBackend.client;
    final category = _asMap(
      await client
          .from('service_categories')
          .select('id, slug, name')
          .eq('slug', categorySlug)
          .single(),
    );

    final categoryId = category['id'] as String;
    final categoryName = category['name'] as String;

    final services =
        (await client
                    .from('provider_services')
                    .select(
                      'id, provider_id, category_id, title, description, pricing_model, base_price, currency, unit_label, service_address, provider_profiles(display_name, rating_average, rating_count)',
                    )
                    .eq('category_id', categoryId)
                    .eq('status', 'active')
                    .order('title')
                as List<dynamic>)
            .cast<Map<String, dynamic>>();

    final resources =
        (await client
                    .from('provider_resources')
                    .select(
                      'id, provider_id, category_id, resource_type, name, description, capacity, address_text, metadata',
                    )
                    .eq('category_id', categoryId)
                    .eq('status', 'active')
                    .order('name')
                as List<dynamic>)
            .cast<Map<String, dynamic>>();

    final resourcesByProvider = <String, List<Map<String, dynamic>>>{};
    for (final resource in resources) {
      final providerId = resource['provider_id'] as String;
      resourcesByProvider.putIfAbsent(providerId, () => []).add(resource);
    }

    final offers = <ReservableOffer>[];
    for (final service in services) {
      final providerId = service['provider_id'] as String;
      final provider = _asMap(service['provider_profiles']);
      final providerResources =
          resourcesByProvider[providerId] ?? const <Map<String, dynamic>>[];

      for (final resource in providerResources) {
        offers.add(
          ReservableOffer(
            categoryId: categoryId,
            categorySlug: categorySlug,
            categoryName: categoryName,
            serviceId: service['id'] as String,
            providerId: providerId,
            providerName:
                provider['display_name'] as String? ?? 'Wantok Provider',
            serviceTitle: service['title'] as String? ?? categoryName,
            serviceDescription: service['description'] as String?,
            pricingModel: service['pricing_model'] as String? ?? 'quote',
            basePrice: _toDouble(service['base_price']),
            currency: service['currency'] as String? ?? 'PGK',
            unitLabel: service['unit_label'] as String?,
            serviceAddress: service['service_address'] as String?,
            providerRating: _toDouble(provider['rating_average']),
            providerRatingCount: _toInt(provider['rating_count']) ?? 0,
            resourceId: resource['id'] as String,
            resourceType: resource['resource_type'] as String? ?? 'resource',
            resourceName: resource['name'] as String? ?? 'Available resource',
            resourceDescription: resource['description'] as String?,
            capacity: _toInt(resource['capacity']),
            resourceAddress: resource['address_text'] as String?,
            metadata: _asMap(resource['metadata']),
          ),
        );
      }
    }

    return offers;
  }

  Future<bool> isResourceAvailable({
    required String resourceId,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    final result = await WantokBackend.client.rpc(
      'is_resource_available',
      params: {
        'p_resource_id': resourceId,
        'p_starts_at': startsAt.toUtc().toIso8601String(),
        'p_ends_at': endsAt.toUtc().toIso8601String(),
        'p_exclude_booking_id': null,
      },
    );
    return result == true;
  }

  Future<void> createReservation({
    required ReservableOffer offer,
    required DateTime startsAt,
    required DateTime endsAt,
    double quantity = 1,
    String? serviceAddress,
    String? notes,
    String? trustedPersonId,
  }) async {
    await WantokBackend.client.rpc(
      'create_resource_reservation',
      params: {
        'p_provider_service_id': offer.serviceId,
        'p_resource_id': offer.resourceId,
        'p_starts_at': startsAt.toUtc().toIso8601String(),
        'p_ends_at': endsAt.toUtc().toIso8601String(),
        'p_quantity': quantity,
        'p_service_address': serviceAddress,
        'p_notes': notes,
        'p_trusted_person_id': trustedPersonId,
      },
    );
  }

  Future<List<Map<String, dynamic>>> loadMyReservations() async {
    final rows = await WantokBackend.client
        .from('service_bookings')
        .select(
          'id, status, scheduled_start, scheduled_end, requested_amount, quoted_amount, final_amount, currency, service_address, origin_address, destination_address, notes, created_at, trusted_person_id, beneficiary_name, beneficiary_relationship, beneficiary_phone, beneficiary_email, service_categories(name, slug), provider_profiles(display_name), provider_resources(name, resource_type, address_text), service_quotes(id, amount, currency, message, status, expires_at), service_reviews(id, rating, title, comment, visibility, created_at)',
        )
        .eq('customer_id', _userId)
        .order('created_at', ascending: false)
        .limit(100);

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> cancelBooking(String bookingId) async {
    await WantokBackend.client.rpc(
      'cancel_service_booking',
      params: {'p_booking_id': bookingId},
    );
  }

  Future<void> acceptQuote(String quoteId) async {
    await WantokBackend.client.rpc(
      'accept_service_quote',
      params: {'p_quote_id': quoteId},
    );
  }

  Future<List<Map<String, dynamic>>> loadVendorServices() async {
    final rows = await WantokBackend.client
        .from('provider_services')
        .select(
          'id, provider_id, category_id, title, description, pricing_model, base_price, minimum_charge, currency, unit_label, service_address, booking_notice_minutes, status, service_categories(name, slug)',
        )
        .eq('provider_id', _userId)
        .order('created_at');

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> updateVendorService({
    required String serviceId,
    required String title,
    String? description,
    required String pricingModel,
    double? basePrice,
    String? unitLabel,
    String? serviceAddress,
  }) async {
    await WantokBackend.client
        .from('provider_services')
        .update({
          'title': title.trim(),
          'description': _emptyToNull(description),
          'pricing_model': pricingModel,
          'base_price': basePrice,
          'unit_label': _emptyToNull(unitLabel),
          'service_address': _emptyToNull(serviceAddress),
        })
        .eq('id', serviceId)
        .eq('provider_id', _userId);
  }

  Future<void> submitVendorService(String serviceId) async {
    await WantokBackend.client.rpc(
      'submit_provider_service_for_review',
      params: {'p_service_id': serviceId},
    );
  }

  Future<List<Map<String, dynamic>>> loadVendorResources() async {
    final rows = await WantokBackend.client
        .from('provider_resources')
        .select(
          'id, provider_id, category_id, resource_type, name, description, capacity, address_text, status, metadata, service_categories(name, slug)',
        )
        .eq('provider_id', _userId)
        .order('created_at');

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> createVendorResource({
    required String categoryId,
    required String resourceType,
    required String name,
    String? description,
    int? capacity,
    String? address,
  }) async {
    await WantokBackend.client.from('provider_resources').insert({
      'provider_id': _userId,
      'category_id': categoryId,
      'resource_type': resourceType.trim(),
      'name': name.trim(),
      'description': _emptyToNull(description),
      'capacity': capacity,
      'address_text': _emptyToNull(address),
      'metadata': <String, dynamic>{},
    });
  }

  Future<void> updateVendorResource({
    required String resourceId,
    required String resourceType,
    required String name,
    String? description,
    int? capacity,
    String? address,
  }) async {
    await WantokBackend.client
        .from('provider_resources')
        .update({
          'resource_type': resourceType.trim(),
          'name': name.trim(),
          'description': _emptyToNull(description),
          'capacity': capacity,
          'address_text': _emptyToNull(address),
        })
        .eq('id', resourceId)
        .eq('provider_id', _userId);
  }

  Future<void> submitVendorResource(String resourceId) async {
    await WantokBackend.client.rpc(
      'submit_provider_resource_for_review',
      params: {'p_resource_id': resourceId},
    );
  }

  Future<void> blockResourceTime({
    required String resourceId,
    required DateTime startsAt,
    required DateTime endsAt,
    String? reason,
  }) async {
    if (!endsAt.isAfter(startsAt)) {
      throw ArgumentError('End time must be after start time.');
    }

    await WantokBackend.client.from('provider_time_off').insert({
      'provider_id': _userId,
      'resource_id': resourceId,
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': endsAt.toUtc().toIso8601String(),
      'reason': _emptyToNull(reason),
    });
  }

  Future<List<Map<String, dynamic>>> loadVendorBookings() async {
    final rows = await WantokBackend.client
        .from('service_bookings')
        .select(
          'id, provider_id, status, scheduled_start, scheduled_end, requested_amount, quoted_amount, final_amount, currency, service_address, origin_address, destination_address, notes, created_at, beneficiary_name, beneficiary_relationship, service_categories(name, slug), provider_services(title, pricing_model), provider_resources(name, resource_type, address_text)',
        )
        .inFilter('status', [
          'requested',
          'quoted',
          'accepted',
          'confirmed',
          'in_progress',
        ])
        .order('scheduled_start');

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> respondToBooking(String bookingId, bool accept) async {
    await WantokBackend.client.rpc(
      'provider_respond_service_booking',
      params: {'p_booking_id': bookingId, 'p_accept': accept},
    );
  }

  Future<void> submitServiceQuote({
    required String bookingId,
    required double amount,
    String? message,
  }) async {
    await WantokBackend.client.rpc(
      'submit_service_quote',
      params: {
        'p_booking_id': bookingId,
        'p_amount': amount,
        'p_message': _emptyToNull(message),
        'p_expires_at': null,
      },
    );
  }

  Future<void> advanceBooking(String bookingId, String status) async {
    await WantokBackend.client.rpc(
      'provider_advance_service_booking',
      params: {'p_booking_id': bookingId, 'p_status': status},
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
