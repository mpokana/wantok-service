import 'wantok_backend.dart';

class TaxiRepository {
  const TaxiRepository();

  String get _userId {
    final user = WantokBackend.client.auth.currentUser;
    if (user == null) {
      throw StateError('Authentication required.');
    }
    return user.id;
  }

  Future<Map<String, dynamic>> requestRide({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    String? pickupLabel,
    String? dropoffLabel,
  }) async {
    final response = await WantokBackend.client.rpc(
      'request_taxi_ride',
      params: {
        'p_pickup_lat': pickupLat,
        'p_pickup_lng': pickupLng,
        'p_dropoff_lat': dropoffLat,
        'p_dropoff_lng': dropoffLng,
        'p_pickup_label': _emptyToNull(pickupLabel),
        'p_dropoff_label': _emptyToNull(dropoffLabel),
      },
    );
    return _asMap(response);
  }

  Future<Map<String, dynamic>?> loadActivePassengerRide() async {
    final rows = await WantokBackend.client
        .from('rides')
        .select('id, status, created_at')
        .eq('passenger_id', _userId)
        .inFilter('status', [
          'pending',
          'accepted',
          'arriving',
          'arrived',
          'in_progress',
        ])
        .order('created_at', ascending: false)
        .limit(1);

    final list = (rows as List<dynamic>).cast<Map<String, dynamic>>();
    if (list.isEmpty) return null;
    return loadRideDetails(list.first['id'] as String);
  }

  Future<List<Map<String, dynamic>>> loadPassengerHistory() async {
    final rows = await WantokBackend.client
        .from('rides')
        .select(
          'id, status, pickup_label, dropoff_label, fare_estimate, final_fare, distance_km, created_at, completed_at, cancelled_at',
        )
        .eq('passenger_id', _userId)
        .inFilter('status', ['completed', 'cancelled'])
        .order('created_at', ascending: false)
        .limit(10);

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> loadDriverLocation() async {
    final rows = await WantokBackend.client
        .from('driver_locations')
        .select('driver_id, lat, lng, heading, is_online, updated_at')
        .eq('driver_id', _userId)
        .limit(1);

    final list = (rows as List<dynamic>).cast<Map<String, dynamic>>();
    return list.isEmpty ? null : list.first;
  }

  Future<Map<String, dynamic>?> loadActiveDriverRide() async {
    final rows = await WantokBackend.client
        .from('rides')
        .select('id, status, created_at')
        .eq('driver_id', _userId)
        .inFilter('status', ['accepted', 'arriving', 'arrived', 'in_progress'])
        .order('created_at', ascending: false)
        .limit(1);

    final list = (rows as List<dynamic>).cast<Map<String, dynamic>>();
    if (list.isEmpty) return null;
    return loadRideDetails(list.first['id'] as String);
  }

  Future<Map<String, dynamic>> loadRideDetails(String rideId) async {
    final response = await WantokBackend.client.rpc(
      'get_taxi_ride_details',
      params: {'p_ride_id': rideId},
    );
    return _asMap(response);
  }

  Future<bool> refreshDispatch(String rideId) async {
    final response = await WantokBackend.client.rpc(
      'refresh_taxi_dispatch',
      params: {'p_ride_id': rideId},
    );
    return response == true;
  }

  Future<void> cancelRide(String rideId, {String? reason}) async {
    await WantokBackend.client.rpc(
      'cancel_taxi_ride',
      params: {'p_ride_id': rideId, 'p_reason': _emptyToNull(reason)},
    );
  }

  Future<Map<String, dynamic>?> loadPendingDriverOffer() async {
    final response = await WantokBackend.client.rpc(
      'get_driver_pending_ride_offer',
    );
    if (response == null) return null;
    final map = _asMap(response);
    return map.isEmpty ? null : map;
  }

  Future<void> respondToOffer(String rideId, bool accept) async {
    await WantokBackend.client.rpc(
      'driver_respond_taxi_offer',
      params: {'p_ride_id': rideId, 'p_accept': accept},
    );
  }

  Future<void> updateDriverStatus(String rideId, String status) async {
    await WantokBackend.client.rpc(
      'driver_update_taxi_status',
      params: {'p_ride_id': rideId, 'p_status': status},
    );
  }

  Future<void> setDriverOnline({
    required double lat,
    required double lng,
    double? heading,
    required bool isOnline,
  }) async {
    await WantokBackend.client.rpc(
      'set_driver_online',
      params: {
        'p_lat': lat,
        'p_lng': lng,
        'p_heading': heading,
        'p_is_online': isOnline,
      },
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
