import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

class TaxiDriverPage extends StatefulWidget {
  const TaxiDriverPage({super.key});

  @override
  State<TaxiDriverPage> createState() => _TaxiDriverPageState();
}

class _TaxiDriverPageState extends State<TaxiDriverPage> {
  static const _repository = TaxiRepository();
  static const _laeCenter = LatLng(-6.7303, 147.0000);

  final _mapController = MapController();

  Map<String, dynamic>? _offer;
  Map<String, dynamic>? _ride;
  Position? _position;
  Timer? _timer;
  bool _online = false;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<Position> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError(
        'Location permission is required while the driver is online.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> _bootstrap() async {
    try {
      _position = await _currentPosition();
      final savedLocation = await _repository.loadDriverLocation();
      _ride = await _repository.loadActiveDriverRide();
      _online = _ride != null || savedLocation?['is_online'] == true;

      if (_online && _position != null) {
        await _repository.setDriverOnline(
          lat: _position!.latitude,
          lng: _position!.longitude,
          heading: _position!.heading,
          isOnline: true,
        );
      }

      if (_ride == null && _online) {
        _offer = await _repository.loadPendingDriverOffer();
      }
      _startPolling();
    } catch (error) {
      _error = _friendlyError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _poll());
  }

  Future<void> _poll() async {
    if (!mounted || _busy) return;
    try {
      if (_online) {
        final position = await _currentPosition();
        _position = position;
        await _repository.setDriverOnline(
          lat: position.latitude,
          lng: position.longitude,
          heading: position.heading,
          isOnline: true,
        );
      }

      final activeRide = await _repository.loadActiveDriverRide();
      Map<String, dynamic>? offer;
      if (activeRide == null && _online) {
        offer = await _repository.loadPendingDriverOffer();
      }

      if (!mounted) return;
      setState(() {
        _ride = activeRide;
        _offer = offer;
        _error = null;
      });
    } catch (_) {
      // Keep the current dispatch screen during transient network/location errors.
    }
  }

  Future<void> _toggleOnline(bool value) async {
    setState(() => _busy = true);
    try {
      final position = await _currentPosition();
      if (!value && _offer != null) {
        await _repository.respondToOffer(_offer!['ride_id'] as String, false);
        _offer = null;
      }
      await _repository.setDriverOnline(
        lat: position.latitude,
        lng: position.longitude,
        heading: position.heading,
        isOnline: value,
      );
      if (!mounted) return;
      setState(() {
        _position = position;
        _online = value;
        _offer = value ? _offer : null;
        _error = null;
      });
      if (value) await _poll();
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _respondToOffer(bool accept) async {
    final offer = _offer;
    if (offer == null) return;
    setState(() => _busy = true);
    try {
      await _repository.respondToOffer(offer['ride_id'] as String, accept);
      if (accept) {
        _ride = await _repository.loadRideDetails(offer['ride_id'] as String);
      }
      _offer = null;
      if (mounted) setState(() => _error = null);
      if (!accept) await _poll();
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _advanceRide() async {
    final ride = _ride;
    if (ride == null) return;
    final current = ride['status']?.toString();
    final next = switch (current) {
      'accepted' => 'arriving',
      'arriving' => 'arrived',
      'arrived' => 'in_progress',
      'in_progress' => 'completed',
      _ => null,
    };
    if (next == null) return;

    setState(() => _busy = true);
    try {
      await _repository.updateDriverStatus(ride['id'] as String, next);
      final details = await _repository.loadRideDetails(ride['id'] as String);
      if (!mounted) return;
      setState(() {
        _ride = details['status'] == 'completed' ? null : details;
        _error = null;
      });
      if (details['status'] == 'completed') {
        await _poll();
      }
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelAssignedRide() async {
    final ride = _ride;
    if (ride == null) return;
    setState(() => _busy = true);
    try {
      await _repository.cancelRide(
        ride['id'] as String,
        reason: 'Cancelled by driver',
      );
      if (!mounted) return;
      setState(() {
        _ride = null;
        _error = null;
      });
      await _poll();
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = _ride;
    final offer = _offer;
    final pickup = _latLng(
      ride?['pickup_lat'] ?? offer?['pickup_lat'],
      ride?['pickup_lng'] ?? offer?['pickup_lng'],
    );
    final dropoff = _latLng(
      ride?['dropoff_lat'] ?? offer?['dropoff_lat'],
      ride?['dropoff_lng'] ?? offer?['dropoff_lng'],
    );
    final driver = _position == null
        ? null
        : LatLng(_position!.latitude, _position!.longitude);
    final center = driver ?? pickup ?? _laeCenter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Taxi Driver'),
        actions: [
          Row(
            children: [
              Text(
                _online ? 'Online' : 'Offline',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _online ? WantokColors.primary : WantokColors.muted,
                ),
              ),
              Switch(
                value: _online,
                onChanged: _busy || ride != null ? null : _toggleOnline,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: _busy && _position == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                SizedBox(
                  height: 330,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: 14,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'io.wantok.service',
                        ),
                        MarkerLayer(
                          markers: [
                            if (driver != null)
                              Marker(
                                point: driver,
                                width: 52,
                                height: 52,
                                child: const _DriverMapPin(
                                  icon: Icons.local_taxi,
                                  color: WantokColors.gold,
                                ),
                              ),
                            if (pickup != null)
                              Marker(
                                point: pickup,
                                width: 46,
                                height: 46,
                                child: const _DriverMapPin(
                                  icon: Icons.trip_origin,
                                  color: WantokColors.primary,
                                ),
                              ),
                            if (dropoff != null)
                              Marker(
                                point: dropoff,
                                width: 46,
                                height: 46,
                                child: const _DriverMapPin(
                                  icon: Icons.location_on,
                                  color: WantokColors.coral,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (!_online && ride == null)
                  const _DriverStateCard(
                    icon: Icons.power_settings_new,
                    title: 'You are offline',
                    message: 'Go online to receive nearby taxi requests. Your foreground location is shared only while online.',
                  )
                else if (ride != null)
                  _buildActiveRide(context, ride)
                else if (offer != null)
                  _buildOffer(context, offer)
                else
                  const _DriverStateCard(
                    icon: Icons.radar,
                    title: 'Waiting for a ride',
                    message: 'You are online. Wantok will offer nearby requests when you are the best available driver.',
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildOffer(BuildContext context, Map<String, dynamic> offer) {
    final fare = _toDouble(offer['fare_estimate']);
    final distance = _toDouble(offer['trip_distance_km']);
    final driverDistance = _toDouble(offer['driver_distance_km']);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'New ride request',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                const _DriverBadge(label: 'OFFER'),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              offer['passenger_name']?.toString() ?? 'Wantok passenger',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            if (offer['is_delegated'] == true)
              Text(
                'Booked by: ${offer['booked_by_name'] ?? 'Wantok account'}',
                style: const TextStyle(color: WantokColors.muted, fontSize: 12),
              ),
            const SizedBox(height: 12),
            _DriverRouteRow(
              pickup: offer['pickup_label']?.toString() ?? 'Pickup',
              destination: offer['dropoff_label']?.toString() ?? 'Destination',
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _DriverMetric(
                    label: 'Pickup away',
                    value: driverDistance == null
                        ? '—'
                        : '${driverDistance.toStringAsFixed(1)} km',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DriverMetric(
                    label: 'Trip',
                    value: distance == null
                        ? '—'
                        : '${distance.toStringAsFixed(1)} km',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DriverMetric(
                    label: 'Est. fare',
                    value: fare == null ? 'K —' : 'K${fare.toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => _respondToOffer(false),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _busy ? null : () => _respondToOffer(true),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveRide(BuildContext context, Map<String, dynamic> ride) {
    final status = ride['status']?.toString() ?? 'accepted';
    final nextLabel = switch (status) {
      'accepted' => 'Start heading to pickup',
      'arriving' => 'Mark arrived',
      'arrived' => 'Start trip',
      'in_progress' => 'Complete trip',
      _ => 'Update ride',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _driverStatusTitle(status),
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                _DriverBadge(label: status.replaceAll('_', ' ').toUpperCase()),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              ride['passenger_name']?.toString() ?? 'Wantok passenger',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            if (ride['passenger_phone'] != null)
              Text(ride['passenger_phone'].toString()),
            if (ride['is_delegated'] == true)
              Text(
                'Booked by: ${ride['booked_by_name'] ?? 'Wantok account'}',
                style: const TextStyle(color: WantokColors.muted, fontSize: 12),
              ),
            const SizedBox(height: 12),
            _DriverRouteRow(
              pickup: ride['pickup_label']?.toString() ?? 'Pickup',
              destination: ride['dropoff_label']?.toString() ?? 'Destination',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _advanceRide,
              icon: Icon(_nextActionIcon(status)),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(nextLabel),
              ),
            ),
            if (status != 'in_progress') ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _busy ? null : _cancelAssignedRide,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel assigned ride'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DriverMapPin extends StatelessWidget {
  const _DriverMapPin({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Color(0x33000000),
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: color),
    );
  }
}

class _DriverStateCard extends StatelessWidget {
  const _DriverStateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 48, color: WantokColors.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: WantokColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverBadge extends StatelessWidget {
  const _DriverBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2D2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _DriverMetric extends StatelessWidget {
  const _DriverMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6F3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: WantokColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _DriverRouteRow extends StatelessWidget {
  const _DriverRouteRow({required this.pickup, required this.destination});

  final String pickup;
  final String destination;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(
              Icons.trip_origin,
              color: WantokColors.primary,
              size: 18,
            ),
            const SizedBox(width: 9),
            Expanded(child: Text(pickup)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on, color: WantokColors.coral, size: 18),
            const SizedBox(width: 9),
            Expanded(child: Text(destination)),
          ],
        ),
      ],
    );
  }
}

LatLng? _latLng(dynamic lat, dynamic lng) {
  final latitude = _toDouble(lat);
  final longitude = _toDouble(lng);
  if (latitude == null || longitude == null) return null;
  return LatLng(latitude, longitude);
}

double? _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

IconData _nextActionIcon(String status) => switch (status) {
  'accepted' => Icons.navigation_outlined,
  'arriving' => Icons.place_outlined,
  'arrived' => Icons.play_arrow,
  'in_progress' => Icons.task_alt,
  _ => Icons.sync,
};

String _driverStatusTitle(String status) => switch (status) {
  'accepted' => 'Ride accepted',
  'arriving' => 'Heading to pickup',
  'arrived' => 'At pickup',
  'in_progress' => 'Trip in progress',
  _ => 'Active ride',
};

String _friendlyError(Object error) {
  final text = error.toString();
  const marker = 'message: ';
  final markerIndex = text.indexOf(marker);
  if (markerIndex >= 0) {
    return text.substring(markerIndex + marker.length).replaceAll(')', '');
  }
  return text.replaceFirst('StateError: ', '').replaceFirst('Exception: ', '');
}
