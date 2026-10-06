import 'wantok_backend.dart';

class EventsRepository {
  const EventsRepository();

  String get _userId {
    final user = WantokBackend.client.auth.currentUser;
    if (user == null) {
      throw StateError('Authentication required.');
    }
    return user.id;
  }

  Future<List<Map<String, dynamic>>> loadUpcomingEvents() async {
    final rows = await WantokBackend.client
        .from('events')
        .select(
          'id, provider_id, provider_service_id, title, description, venue_name, venue_address, venue_lat, venue_lng, starts_at, ends_at, capacity, status, image_url, is_featured, provider_services(title), provider_profiles(display_name, rating_average, rating_count)',
        )
        .eq('status', 'published')
        .gte('starts_at', DateTime.now().toUtc().toIso8601String())
        .order('starts_at')
        .limit(100);

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> loadTicketTypes(String eventId) async {
    final rows = await WantokBackend.client
        .from('event_ticket_types')
        .select(
          'id, event_id, name, description, price, currency, capacity, sales_start, sales_end, is_active, sort_order',
        )
        .eq('event_id', eventId)
        .eq('is_active', true)
        .order('sort_order')
        .order('name');

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> register({
    required String eventId,
    required String ticketTypeId,
    required int quantity,
    String? attendeeName,
    String? attendeeContact,
    String? note,
    String? trustedPersonId,
  }) async {
    final response = await WantokBackend.client.rpc(
      'register_for_event',
      params: {
        'p_event_id': eventId,
        'p_ticket_type_id': ticketTypeId,
        'p_quantity': quantity,
        'p_attendee_name': _emptyToNull(attendeeName),
        'p_attendee_contact': _emptyToNull(attendeeContact),
        'p_note': _emptyToNull(note),
        'p_trusted_person_id': trustedPersonId,
      },
    );
    return _asMap(response);
  }

  Future<List<Map<String, dynamic>>> loadMyRegistrations() async {
    final rows = await WantokBackend.client
        .from('event_registrations')
        .select(
          'id, event_id, ticket_type_id, quantity, unit_price, total_amount, currency, status, payment_status, attendee_name, attendee_contact, attendee_relationship, attendee_phone, attendee_email, trusted_person_id, note, registered_at, events(title, venue_name, venue_address, starts_at, ends_at, status), event_ticket_types(name)',
        )
        .eq('customer_id', _userId)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> cancelRegistration(String registrationId) async {
    await WantokBackend.client.rpc(
      'cancel_event_registration',
      params: {'p_registration_id': registrationId},
    );
  }

  Future<List<Map<String, dynamic>>> loadVendorEventServices() async {
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
          return category['slug'] == 'events' &&
              category['booking_mode'] == 'ticketing';
        })
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> loadVendorEvents() async {
    final rows = await WantokBackend.client
        .from('events')
        .select(
          'id, provider_id, provider_service_id, title, description, venue_name, venue_address, starts_at, ends_at, capacity, status, image_url, is_featured, provider_services(title)',
        )
        .eq('provider_id', _userId)
        .order('starts_at', ascending: false);

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<String> createEvent({
    required String providerServiceId,
    required String title,
    String? description,
    String? venueName,
    String? venueAddress,
    required DateTime startsAt,
    DateTime? endsAt,
    int? capacity,
  }) async {
    final row = await WantokBackend.client
        .from('events')
        .insert({
          'provider_id': _userId,
          'provider_service_id': providerServiceId,
          'title': title.trim(),
          'description': _emptyToNull(description),
          'venue_name': _emptyToNull(venueName),
          'venue_address': _emptyToNull(venueAddress),
          'starts_at': startsAt.toUtc().toIso8601String(),
          'ends_at': endsAt?.toUtc().toIso8601String(),
          'capacity': capacity,
          'status': 'draft',
        })
        .select('id')
        .single();

    return row['id'] as String;
  }

  Future<void> updateEvent({
    required String eventId,
    required String title,
    String? description,
    String? venueName,
    String? venueAddress,
    required DateTime startsAt,
    DateTime? endsAt,
    int? capacity,
  }) async {
    await WantokBackend.client
        .from('events')
        .update({
          'title': title.trim(),
          'description': _emptyToNull(description),
          'venue_name': _emptyToNull(venueName),
          'venue_address': _emptyToNull(venueAddress),
          'starts_at': startsAt.toUtc().toIso8601String(),
          'ends_at': endsAt?.toUtc().toIso8601String(),
          'capacity': capacity,
        })
        .eq('id', eventId)
        .eq('provider_id', _userId);
  }

  Future<void> setEventStatus(String eventId, String status) async {
    await WantokBackend.client
        .from('events')
        .update({'status': status})
        .eq('id', eventId)
        .eq('provider_id', _userId);
  }

  Future<List<Map<String, dynamic>>> loadVendorTicketTypes(
    String eventId,
  ) async {
    final rows = await WantokBackend.client
        .from('event_ticket_types')
        .select(
          'id, event_id, name, description, price, currency, capacity, sales_start, sales_end, is_active, sort_order',
        )
        .eq('event_id', eventId)
        .order('sort_order')
        .order('name');

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> createTicketType({
    required String eventId,
    required String name,
    String? description,
    required double price,
    required String currency,
    int? capacity,
    bool isActive = true,
  }) async {
    await WantokBackend.client.from('event_ticket_types').insert({
      'event_id': eventId,
      'name': name.trim(),
      'description': _emptyToNull(description),
      'price': price,
      'currency': currency,
      'capacity': capacity,
      'is_active': isActive,
    });
  }

  Future<void> updateTicketType({
    required String ticketTypeId,
    required String name,
    String? description,
    required double price,
    int? capacity,
    required bool isActive,
  }) async {
    await WantokBackend.client
        .from('event_ticket_types')
        .update({
          'name': name.trim(),
          'description': _emptyToNull(description),
          'price': price,
          'capacity': capacity,
          'is_active': isActive,
        })
        .eq('id', ticketTypeId);
  }

  Future<List<Map<String, dynamic>>> loadVendorRegistrations(
    String eventId,
  ) async {
    final rows = await WantokBackend.client
        .from('event_registrations')
        .select(
          'id, event_id, ticket_type_id, customer_id, quantity, unit_price, total_amount, currency, status, payment_status, attendee_name, attendee_contact, attendee_relationship, attendee_phone, attendee_email, trusted_person_id, note, registered_at, event_ticket_types(name), profiles(full_name, phone)',
        )
        .eq('event_id', eventId)
        .order('created_at');

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> setRegistrationStatus(
    String registrationId,
    String status,
  ) async {
    await WantokBackend.client.rpc(
      'vendor_set_event_registration_status',
      params: {'p_registration_id': registrationId, 'p_status': status},
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
