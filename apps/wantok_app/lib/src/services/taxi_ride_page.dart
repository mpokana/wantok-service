import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

enum _TaxiPointMode { pickup, destination }

class TaxiRidePage extends StatefulWidget {
  const TaxiRidePage({super.key});

  @override
  State<TaxiRidePage> createState() => _TaxiRidePageState();
}

class _TaxiRidePageState extends State<TaxiRidePage> {
  static const _repository = TaxiRepository();
  static const _laeCenter = LatLng(-6.7303, 147.0000);

  final _mapController = MapController();
  final _pickupLabelController = TextEditingController();
  final _dropoffLabelController = TextEditingController();

  LatLng _pickup = _laeCenter;
  LatLng? _dropoff;
  _TaxiPointMode _pointMode = _TaxiPointMode.destination;
  Map<String, dynamic>? _ride;
  List<Map<String, dynamic>> _history = const [];
  Timer? _pollTimer;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pickupLabelController.dispose();
    _dropoffLabelController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final activeRide = await _repository.loadActivePassengerRide();
      if (activeRide != null) {
        _setRide(activeRide);
      } else {
        await _useCurrentLocation(silent: true);
        _history = await _repository.loadPassengerHistory();
      }
    } catch (error) {
      _error = _friendlyError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Position?> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Location services are disabled on this device.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError(
        'Location permission is required to use your current pickup position.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> _useCurrentLocation({bool silent = false}) async {
    try {
      final position = await _currentPosition();
      if (position == null || !mounted) return;

      final point = LatLng(position.latitude, position.longitude);
      setState(() {
        _pickup = point;
        if (_pickupLabelController.text.trim().isEmpty) {
          _pickupLabelController.text = 'Current location';
        }
        _error = null;
      });
      _mapController.move(point, 15);
    } catch (error) {
      if (!silent && mounted) {
        setState(() => _error = _friendlyError(error));
      }
    }
  }

  void _onMapTap(TapPosition _, LatLng point) {
    if (_ride != null) return;
    setState(() {
      if (_pointMode == _TaxiPointMode.pickup) {
        _pickup = point;
      } else {
        _dropoff = point;
      }
      _error = null;
    });
  }

  Future<void> _requestRide() async {
    final destination = _dropoff;
    if (destination == null) {
      setState(() => _error = 'Tap the map to choose your destination.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final created = await _repository.requestRide(
        pickupLat: _pickup.latitude,
        pickupLng: _pickup.longitude,
        dropoffLat: destination.latitude,
        dropoffLng: destination.longitude,
        pickupLabel: _pickupLabelController.text,
        dropoffLabel: _dropoffLabelController.text,
      );
      final rideId = created['id'] as String;
      final details = await _repository.loadRideDetails(rideId);
      _setRide(details);
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setRide(Map<String, dynamic> ride) {
    _ride = ride;
    _syncRidePoints(ride);
    _startPolling();
    if (mounted) setState(() {});
  }

  void _syncRidePoints(Map<String, dynamic> ride) {
    final pickupLat = _toDouble(ride['pickup_lat']);
    final pickupLng = _toDouble(ride['pickup_lng']);
    final dropoffLat = _toDouble(ride['dropoff_lat']);
    final dropoffLng = _toDouble(ride['dropoff_lng']);

    if (pickupLat != null && pickupLng != null) {
      _pickup = LatLng(pickupLat, pickupLng);
    }
    if (dropoffLat != null && dropoffLng != null) {
      _dropoff = LatLng(dropoffLat, dropoffLng);
    }

    final pickupLabel = ride['pickup_label']?.toString();
    final dropoffLabel = ride['dropoff_label']?.toString();
    if (pickupLabel != null && pickupLabel.isNotEmpty) {
      _pickupLabelController.text = pickupLabel;
    }
    if (dropoffLabel != null && dropoffLabel.isNotEmpty) {
      _dropoffLabelController.text = dropoffLabel;
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollRide());
  }

  Future<void> _pollRide() async {
    final ride = _ride;
    if (ride == null) return;
    final rideId = ride['id'] as String;

    try {
      if (ride['status'] == 'pending') {
        await _repository.refreshDispatch(rideId);
      }

      final details = await _repository.loadRideDetails(rideId);
      if (!mounted) return;

      setState(() {
        _ride = details;
        _syncRidePoints(details);
      });

      final status = details['status']?.toString();
      if (status == 'completed' || status == 'cancelled') {
        _pollTimer?.cancel();
        _history = await _repository.loadPassengerHistory();
        if (mounted) setState(() {});
      }
    } catch (_) {
      // A transient poll failure should not destroy an active ride screen.
    }
  }

  Future<void> _cancelRide() async {
    final ride = _ride;
    if (ride == null) return;
    setState(() => _busy = true);
    try {
      await _repository.cancelRide(
        ride['id'] as String,
        reason: 'Cancelled by passenger',
      );
      final details = await _repository.loadRideDetails(ride['id'] as String);
      _pollTimer?.cancel();
      _history = await _repository.loadPassengerHistory();
      if (mounted) {
        setState(() {
          _ride = details;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _newRide() {
    setState(() {
      _ride = null;
      _dropoff = null;
      _dropoffLabelController.clear();
      _pointMode = _TaxiPointMode.destination;
      _error = null;
    });
    _useCurrentLocation(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final ride = _ride;
    final driverPoint = ride == null
        ? null
        : _latLng(ride['driver_lat'], ride['driver_lng']);

    return Scaffold(
      appBar: AppBar(title: const Text('Taxi / Ride')),
      body: _busy && ride == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                SizedBox(
                  height: 360,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _pickup,
                        initialZoom: 14,
                        onTap: _onMapTap,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'io.wantok.service',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _pickup,
                              width: 46,
                              height: 46,
                              child: const _MapPin(
                                icon: Icons.trip_origin,
                                color: WantokColors.primary,
                              ),
                            ),
                            if (_dropoff != null)
                              Marker(
                                point: _dropoff!,
                                width: 46,
                                height: 46,
                                child: const _MapPin(
                                  icon: Icons.location_on,
                                  color: WantokColors.coral,
                                ),
                              ),
                            if (driverPoint != null)
                              Marker(
                                point: driverPoint,
                                width: 54,
                                height: 54,
                                child: const _MapPin(
                                  icon: Icons.local_taxi,
                                  color: WantokColors.gold,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (ride == null)
                  _buildRequestCard(context)
                else
                  _buildRideCard(context, ride),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (ride == null && _history.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Text(
                    'Recent rides',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  ..._history.map(_HistoryCard.new),
                ],
              ],
            ),
    );
  }

  Widget _buildRequestCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Where are you going?',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            SegmentedButton<_TaxiPointMode>(
              segments: const [
                ButtonSegment(
                  value: _TaxiPointMode.pickup,
                  label: Text('Pickup'),
                  icon: Icon(Icons.trip_origin),
                ),
                ButtonSegment(
                  value: _TaxiPointMode.destination,
                  label: Text('Destination'),
                  icon: Icon(Icons.location_on_outlined),
                ),
              ],
              selected: {_pointMode},
              onSelectionChanged: (selection) {
                setState(() => _pointMode = selection.first);
              },
              showSelectedIcon: false,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pickupLabelController,
              decoration: InputDecoration(
                labelText: 'Pickup label',
                prefixIcon: const Icon(Icons.my_location_outlined),
                suffixIcon: IconButton(
                  tooltip: 'Use current location',
                  onPressed: _busy ? null : _useCurrentLocation,
                  icon: const Icon(Icons.gps_fixed),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _dropoffLabelController,
              decoration: const InputDecoration(
                labelText: 'Destination label',
                hintText: 'Example: Top Town, Lae',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tap Pickup or Destination above, then tap the map to position that point.',
              style: TextStyle(color: WantokColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _requestRide,
              icon: const Icon(Icons.local_taxi_outlined),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Text(_busy ? 'Finding drivers...' : 'Request ride'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideCard(BuildContext context, Map<String, dynamic> ride) {
    final status = ride['status']?.toString() ?? 'pending';
    final driverName = ride['driver_name']?.toString();
    final finalFare = _toDouble(ride['final_fare']);
    final fare = finalFare ?? _toDouble(ride['fare_estimate']);
    final distance = _toDouble(ride['distance_km']);
    final terminal = status == 'completed' || status == 'cancelled';

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
                    _passengerStatusTitle(status),
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                _RideStatusChip(status: status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _passengerStatusBody(status),
              style: const TextStyle(color: WantokColors.muted),
            ),
            const SizedBox(height: 14),
            _RouteRow(
              pickup: ride['pickup_label']?.toString() ?? 'Pickup',
              destination: ride['dropoff_label']?.toString() ?? 'Destination',
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _InfoBox(
                    label: finalFare == null ? 'Estimated fare' : 'Final fare',
                    value: fare == null
                        ? 'K —'
                        : 'K${fare.toStringAsFixed(2)}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoBox(
                    label: 'Trip distance',
                    value: distance == null
                        ? '—'
                        : '${distance.toStringAsFixed(1)} km',
                  ),
                ),
              ],
            ),
            if (driverName != null && driverName.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(
                  driverName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  [
                        ride['vehicle_make'],
                        ride['vehicle_model'],
                        ride['vehicle_colour'],
                        ride['vehicle_rego'],
                      ]
                      .where(
                        (value) => value != null && value.toString().isNotEmpty,
                      )
                      .join(' · '),
                ),
                trailing: const Icon(Icons.verified_outlined),
              ),
            ],
            if (!terminal && status != 'in_progress') ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _busy ? null : _cancelRide,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel ride'),
              ),
            ],
            if (terminal) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _newRide,
                child: const Text('Book another ride'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Color(0x33000000),
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(color: color, width: 3),
      ),
      child: Icon(icon, color: color),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({required this.pickup, required this.destination});

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
            const SizedBox(width: 10),
            Expanded(child: Text(pickup)),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(height: 18, child: VerticalDivider(width: 1)),
          ),
        ),
        Row(
          children: [
            const Icon(Icons.location_on, color: WantokColors.coral, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(destination)),
          ],
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: WantokColors.muted)),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _RideStatusChip extends StatelessWidget {
  const _RideStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final background = switch (status) {
      'completed' => const Color(0xFFDFF2E7),
      'cancelled' => const Color(0xFFFFE7E1),
      'in_progress' => const Color(0xFFE7F0FF),
      _ => const Color(0xFFFFF2D2),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard(this.ride);

  final Map<String, dynamic> ride;

  @override
  Widget build(BuildContext context) {
    final fare =
        _toDouble(ride['final_fare']) ?? _toDouble(ride['fare_estimate']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.local_taxi_outlined)),
          title: Text(
            '${ride['pickup_label']?.toString() ?? 'Pickup'} → ${ride['dropoff_label']?.toString() ?? 'Destination'}',
          ),
          subtitle: Text(
            (ride['status']?.toString() ?? '').replaceAll('_', ' '),
          ),
          trailing: fare == null
              ? null
              : Text(
                  'K${fare.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
        ),
      ),
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

String _passengerStatusTitle(String status) => switch (status) {
  'pending' => 'Finding a driver',
  'accepted' => 'Driver accepted',
  'arriving' => 'Driver is on the way',
  'arrived' => 'Your driver has arrived',
  'in_progress' => 'Trip in progress',
  'completed' => 'Trip completed',
  'cancelled' => 'Ride cancelled',
  _ => 'Ride update',
};

String _passengerStatusBody(String status) => switch (status) {
  'pending' => 'Wantok is offering your request to nearby approved drivers.',
  'accepted' =>
    'Your driver accepted the trip and is preparing to come to you.',
  'arriving' => 'Track the driver marker as it moves toward your pickup.',
  'arrived' => 'Meet your driver at the pickup point when it is safe.',
  'in_progress' => 'You are on the way to your destination.',
  'completed' => 'Your trip is complete. The final fare is shown below.',
  'cancelled' => 'This request has been closed.',
  _ => 'Your ride status has changed.',
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
