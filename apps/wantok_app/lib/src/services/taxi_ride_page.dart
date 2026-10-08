import 'dart:async';

import 'package:flutter/material.dart';

import '../home/wantok_category_ui.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

import 'booking_for_selector.dart';

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
  String? _trustedPersonId;
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
        trustedPersonId: _trustedPersonId,
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
      _trustedPersonId = null;
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
      appBar: AppBar(
        title: const Row(
          children: [
            WantokCategoryBadge(
              style: WantokCategoryStyles.taxi,
              size: 33,
              iconSize: 18,
            ),
            SizedBox(width: 9),
            Text('Taxi / Ride'),
          ],
        ),
      ),
      body: _busy && ride == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                SizedBox(
                  height: 430,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _pickup,
                              initialZoom: 14,
                              onTap: _onMapTap,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                        if (ride == null)
                          Positioned(
                            left: 12,
                            right: 12,
                            top: 12,
                            child: _MapRouteSearchCard(
                              pickup: _pickupLabelController.text.trim().isEmpty
                                  ? 'Choose pickup'
                                  : _pickupLabelController.text.trim(),
                              destination:
                                  _dropoffLabelController.text.trim().isEmpty
                                  ? 'Where to?'
                                  : _dropoffLabelController.text.trim(),
                              activeMode: _pointMode,
                              onPickupTap: () => setState(
                                () => _pointMode = _TaxiPointMode.pickup,
                              ),
                              onDestinationTap: () => setState(
                                () => _pointMode = _TaxiPointMode.destination,
                              ),
                            ),
                          ),
                        Positioned(
                          right: 14,
                          bottom: 14,
                          child: FloatingActionButton.small(
                            heroTag: 'taxi-current-location',
                            tooltip: 'Use current location',
                            onPressed: _busy ? null : _useCurrentLocation,
                            backgroundColor: Colors.white,
                            foregroundColor: WantokColors.primaryDark,
                            child: const Icon(Icons.my_location_rounded),
                          ),
                        ),
                        if (ride == null)
                          Positioned(
                            left: 14,
                            bottom: 14,
                            child: _MapModePill(mode: _pointMode),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(17, 16, 17, 17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Plan your ride',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2F3EA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        size: 16,
                        color: WantokColors.primaryDark,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Now',
                        style: TextStyle(
                          color: WantokColors.primaryDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Text(
              'Choose the pickup and destination, then confirm the rider.',
              style: TextStyle(color: WantokColors.muted, fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            _RidePointField(
              active: _pointMode == _TaxiPointMode.pickup,
              icon: Icons.trip_origin_rounded,
              iconColor: WantokColors.primary,
              label: 'Pickup',
              controller: _pickupLabelController,
              hintText: 'Current location or pickup point',
              onTap: () => setState(() => _pointMode = _TaxiPointMode.pickup),
              onChanged: (_) => setState(() => _error = null),
              trailing: IconButton(
                tooltip: 'Use current location',
                onPressed: _busy ? null : _useCurrentLocation,
                icon: const Icon(Icons.my_location_rounded),
              ),
            ),
            const SizedBox(height: 10),
            _RidePointField(
              active: _pointMode == _TaxiPointMode.destination,
              icon: Icons.location_on_rounded,
              iconColor: WantokColors.coral,
              label: 'Destination',
              controller: _dropoffLabelController,
              hintText: 'Where to?',
              onTap: () =>
                  setState(() => _pointMode = _TaxiPointMode.destination),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8F7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    _pointMode == _TaxiPointMode.pickup
                        ? Icons.trip_origin_rounded
                        : Icons.location_on_rounded,
                    color: _pointMode == _TaxiPointMode.pickup
                        ? WantokColors.primary
                        : WantokColors.coral,
                    size: 18,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _pointMode == _TaxiPointMode.pickup
                          ? 'Tap the map to place the pickup pin.'
                          : 'Tap the map to place the destination pin.',
                      style: const TextStyle(
                        color: WantokColors.muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            BookingForSelector(
              selectedTrustedPersonId: _trustedPersonId,
              enabled: !_busy,
              onChanged: (value) {
                setState(() {
                  _trustedPersonId = value;
                  _error = null;
                });
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _requestRide,
              icon: const Icon(Icons.local_taxi_rounded),
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
            if (ride['beneficiary_name'] != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F6F3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.family_restroom_outlined,
                      color: WantokColors.primaryDark,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        ride['beneficiary_relationship'] != null &&
                                ride['beneficiary_relationship']
                                    .toString()
                                    .trim()
                                    .isNotEmpty
                            ? 'Ride for ${ride['beneficiary_name']} (${ride['beneficiary_relationship']})'
                            : 'Ride for ${ride['beneficiary_name']}',
                        style: const TextStyle(
                          color: WantokColors.primaryDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
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
                    value: fare == null ? 'K —' : 'K${fare.toStringAsFixed(2)}',
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

class _MapRouteSearchCard extends StatelessWidget {
  const _MapRouteSearchCard({
    required this.pickup,
    required this.destination,
    required this.activeMode,
    required this.onPickupTap,
    required this.onDestinationTap,
  });

  final String pickup;
  final String destination;
  final _TaxiPointMode activeMode;
  final VoidCallback onPickupTap;
  final VoidCallback onDestinationTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.98),
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        child: Column(
          children: [
            _MapRouteLine(
              icon: Icons.trip_origin_rounded,
              iconColor: WantokColors.primary,
              label: 'Pickup',
              value: pickup,
              selected: activeMode == _TaxiPointMode.pickup,
              onTap: onPickupTap,
            ),
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Divider(height: 9),
            ),
            _MapRouteLine(
              icon: Icons.location_on_rounded,
              iconColor: WantokColors.coral,
              label: 'Destination',
              value: destination,
              selected: activeMode == _TaxiPointMode.destination,
              onTap: onDestinationTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _MapRouteLine extends StatelessWidget {
  const _MapRouteLine({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      color: selected
                          ? WantokColors.primaryDark
                          : WantokColors.muted,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: WantokColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.touch_app_rounded : Icons.chevron_right_rounded,
              color: selected ? WantokColors.primaryDark : WantokColors.muted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _MapModePill extends StatelessWidget {
  const _MapModePill({required this.mode});

  final _TaxiPointMode mode;

  @override
  Widget build(BuildContext context) {
    final pickup = mode == _TaxiPointMode.pickup;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xEEFFFFFF),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            pickup ? Icons.trip_origin_rounded : Icons.location_on_rounded,
            size: 16,
            color: pickup ? WantokColors.primary : WantokColors.coral,
          ),
          const SizedBox(width: 6),
          Text(
            pickup ? 'Place pickup' : 'Place destination',
            style: const TextStyle(
              color: WantokColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RidePointField extends StatelessWidget {
  const _RidePointField({
    required this.active,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.controller,
    required this.hintText,
    required this.onTap,
    required this.onChanged,
    this.trailing,
  });

  final bool active;
  final IconData icon;
  final Color iconColor;
  final String label;
  final TextEditingController controller;
  final String hintText;
  final VoidCallback onTap;
  final ValueChanged<String> onChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onTap: onTap,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: iconColor),
        suffixIcon: trailing,
        filled: true,
        fillColor: active ? const Color(0xFFF0F8F4) : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: active ? WantokColors.primaryDark : const Color(0xFFDCE7E1),
            width: active ? 1.5 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: WantokColors.primaryDark,
            width: 1.8,
          ),
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
            '${ride['pickup_label']?.toString() ?? 'Pickup'} > ${ride['dropoff_label']?.toString() ?? 'Destination'}',
          ),
          subtitle: Text(
            [
              (ride['status']?.toString() ?? '').replaceAll('_', ' '),
              if (ride['beneficiary_name'] != null)
                'for ${ride['beneficiary_name']}',
            ].where((value) => value.isNotEmpty).join(', '),
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
