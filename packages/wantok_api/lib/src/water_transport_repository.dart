import 'wantok_backend.dart';

class WaterTransportRepository {
  const WaterTransportRepository();

  String get _userId {
    final user = WantokBackend.client.auth.currentUser;
    if (user == null) {
      throw StateError('Authentication required.');
    }
    return user.id;
  }

  Future<List<Map<String, dynamic>>> loadUpcomingDepartures() async {
    final rows = await WantokBackend.client
        .from('water_departures')
        .select(
          'id, provider_id, provider_service_id, route_id, vessel_id, departs_at, arrives_at, status, booking_open, boarding_point, notes, water_routes(name, origin_name, origin_address, origin_province, origin_town, destination_name, destination_address, destination_province, destination_town, estimated_minutes), water_vessels(name, registration_number, vessel_type, total_capacity), provider_profiles(display_name, rating_average, rating_count)',
        )
        .eq('booking_open', true)
        .eq('status', 'scheduled')
        .gte('departs_at', DateTime.now().toUtc().toIso8601String())
        .order('departs_at')
        .limit(100);

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> loadFareClasses(String departureId) async {
    final rows = await WantokBackend.client
        .from('water_fare_classes')
        .select(
          'id, departure_id, name, description, price, currency, capacity, is_active, sort_order',
        )
        .eq('departure_id', departureId)
        .eq('is_active', true)
        .order('sort_order')
        .order('name');

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> bookDeparture({
    required String departureId,
    required String fareClassId,
    required List<Map<String, dynamic>> passengers,
    String? contactPhone,
    String? note,
    String? trustedPersonId,
  }) async {
    final response = await WantokBackend.client.rpc(
      'book_water_departure',
      params: {
        'p_departure_id': departureId,
        'p_fare_class_id': fareClassId,
        'p_passengers': passengers,
        'p_contact_phone': _emptyToNull(contactPhone),
        'p_note': _emptyToNull(note),
        'p_trusted_person_id': trustedPersonId,
      },
    );

    return _asMap(response);
  }

  Future<List<Map<String, dynamic>>> loadMyBookings() async {
    final rows = await WantokBackend.client
        .from('water_passenger_bookings')
        .select(
          'id, departure_id, fare_class_id, passenger_count, unit_fare, total_amount, currency, status, payment_status, contact_phone, note, booked_at, trusted_person_id, beneficiary_name, beneficiary_relationship, beneficiary_phone, beneficiary_email, water_departures(departs_at, arrives_at, status, boarding_point, water_routes(name, origin_name, destination_name), water_vessels(name, registration_number, vessel_type)), water_fare_classes(name), water_booking_passengers(id, full_name, phone, passenger_type, document_reference, metadata)',
        )
        .eq('customer_id', _userId)
        .order('created_at', ascending: false)
        .limit(50);

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    await WantokBackend.client.rpc(
      'cancel_water_booking',
      params: {'p_booking_id': bookingId, 'p_reason': _emptyToNull(reason)},
    );
  }

  Future<List<Map<String, dynamic>>> loadVendorServices() async {
    final rows = await WantokBackend.client
        .from('provider_services')
        .select(
          'id, provider_id, title, description, currency, status, service_categories(id, slug, name, booking_mode)',
        )
        .eq('provider_id', _userId)
        .order('created_at');

    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((row) {
          final category = _asMap(row['service_categories']);
          return category['slug'] == 'boat-ship-rides' &&
              category['booking_mode'] == 'scheduled';
        })
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> loadVendorRoutes() async {
    final rows = await WantokBackend.client
        .from('water_routes')
        .select(
          'id, provider_id, provider_service_id, name, origin_name, origin_address, origin_province, origin_town, destination_name, destination_address, destination_province, destination_town, estimated_minutes, status',
        )
        .eq('provider_id', _userId)
        .order('name');

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> loadVendorVessels() async {
    final rows = await WantokBackend.client
        .from('water_vessels')
        .select(
          'id, provider_id, provider_service_id, name, registration_number, vessel_type, total_capacity, description, status',
        )
        .eq('provider_id', _userId)
        .order('name');

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> loadVendorDepartures() async {
    final rows = await WantokBackend.client
        .from('water_departures')
        .select(
          'id, provider_id, provider_service_id, route_id, vessel_id, departs_at, arrives_at, status, booking_open, boarding_point, notes, water_routes(name, origin_name, destination_name), water_vessels(name, registration_number, total_capacity)',
        )
        .eq('provider_id', _userId)
        .order('departs_at', ascending: false)
        .limit(100);

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<String> createRoute({
    required String providerServiceId,
    required String name,
    required String originName,
    String? originAddress,
    String? originProvince,
    String? originTown,
    required String destinationName,
    String? destinationAddress,
    String? destinationProvince,
    String? destinationTown,
    int? estimatedMinutes,
  }) async {
    final row = await WantokBackend.client
        .from('water_routes')
        .insert({
          'provider_id': _userId,
          'provider_service_id': providerServiceId,
          'name': name.trim(),
          'origin_name': originName.trim(),
          'origin_address': _emptyToNull(originAddress),
          'origin_province': _emptyToNull(originProvince),
          'origin_town': _emptyToNull(originTown),
          'destination_name': destinationName.trim(),
          'destination_address': _emptyToNull(destinationAddress),
          'destination_province': _emptyToNull(destinationProvince),
          'destination_town': _emptyToNull(destinationTown),
          'estimated_minutes': estimatedMinutes,
          'status': 'active',
        })
        .select('id')
        .single();

    return row['id'] as String;
  }

  Future<String> createVessel({
    required String providerServiceId,
    required String name,
    String? registrationNumber,
    required String vesselType,
    required int totalCapacity,
    String? description,
  }) async {
    final row = await WantokBackend.client
        .from('water_vessels')
        .insert({
          'provider_id': _userId,
          'provider_service_id': providerServiceId,
          'name': name.trim(),
          'registration_number': _emptyToNull(registrationNumber),
          'vessel_type': vesselType,
          'total_capacity': totalCapacity,
          'description': _emptyToNull(description),
          'status': 'active',
        })
        .select('id')
        .single();

    return row['id'] as String;
  }

  Future<String> createDeparture({
    required String providerServiceId,
    required String routeId,
    required String vesselId,
    required DateTime departsAt,
    DateTime? arrivesAt,
    String? boardingPoint,
    String? notes,
  }) async {
    final row = await WantokBackend.client
        .from('water_departures')
        .insert({
          'provider_id': _userId,
          'provider_service_id': providerServiceId,
          'route_id': routeId,
          'vessel_id': vesselId,
          'departs_at': departsAt.toUtc().toIso8601String(),
          'arrives_at': arrivesAt?.toUtc().toIso8601String(),
          'status': 'scheduled',
          'booking_open': true,
          'boarding_point': _emptyToNull(boardingPoint),
          'notes': _emptyToNull(notes),
        })
        .select('id')
        .single();

    return row['id'] as String;
  }

  Future<void> createFareClass({
    required String departureId,
    required String name,
    String? description,
    required double price,
    required String currency,
    required int capacity,
  }) async {
    await WantokBackend.client.from('water_fare_classes').insert({
      'departure_id': departureId,
      'name': name.trim(),
      'description': _emptyToNull(description),
      'price': price,
      'currency': currency,
      'capacity': capacity,
      'is_active': true,
    });
  }

  Future<List<Map<String, dynamic>>> loadVendorFareClasses(
    String departureId,
  ) async {
    final rows = await WantokBackend.client
        .from('water_fare_classes')
        .select(
          'id, departure_id, name, description, price, currency, capacity, is_active, sort_order',
        )
        .eq('departure_id', departureId)
        .order('sort_order')
        .order('name');

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> loadManifest(String departureId) async {
    final rows = await WantokBackend.client
        .from('water_passenger_bookings')
        .select(
          'id, departure_id, fare_class_id, customer_id, passenger_count, unit_fare, total_amount, currency, status, payment_status, contact_phone, note, booked_at, trusted_person_id, beneficiary_name, beneficiary_relationship, beneficiary_phone, beneficiary_email, profiles(full_name, phone), water_fare_classes(name), water_booking_passengers(id, full_name, phone, passenger_type, document_reference, metadata)',
        )
        .eq('departure_id', departureId)
        .order('created_at');

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> setDepartureStatus(String departureId, String status) async {
    await WantokBackend.client.rpc(
      'vendor_set_water_departure_status',
      params: {'p_departure_id': departureId, 'p_status': status},
    );
  }

  Future<void> setBookingStatus(String bookingId, String status) async {
    await WantokBackend.client.rpc(
      'vendor_set_water_booking_status',
      params: {'p_booking_id': bookingId, 'p_status': status},
    );
  }

  Future<void> setRouteStatus(String routeId, String status) async {
    await WantokBackend.client
        .from('water_routes')
        .update({'status': status})
        .eq('id', routeId)
        .eq('provider_id', _userId);
  }

  Future<void> setVesselStatus(String vesselId, String status) async {
    await WantokBackend.client
        .from('water_vessels')
        .update({'status': status})
        .eq('id', vesselId)
        .eq('provider_id', _userId);
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
