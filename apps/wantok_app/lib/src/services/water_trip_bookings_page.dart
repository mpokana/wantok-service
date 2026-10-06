import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

import '../client_load_error.dart';

class WaterTripBookingsPage extends StatefulWidget {
  const WaterTripBookingsPage({super.key});

  @override
  State<WaterTripBookingsPage> createState() => _WaterTripBookingsPageState();
}

class _WaterTripBookingsPageState extends State<WaterTripBookingsPage> {
  static const _repository = WaterTransportRepository();
  late Future<List<Map<String, dynamic>>> _future;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _future = _repository.loadMyBookings();
  }

  Future<void> _refresh() async {
    final next = _repository.loadMyBookings();
    setState(() {
      _future = next;
    });
    try {
      await next;
    } catch (_) {
      // The FutureBuilder presents the retryable error state.
    }
  }

  Future<void> _cancel(String id) async {
    setState(() => _busyId = id);
    try {
      await _repository.cancelBooking(id, reason: 'Cancelled by passenger');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Water Trips')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ClientLoadError(
                title: 'Could not load your water trips',
                onRetry: _refresh,
              );
            }

            final rows = snapshot.data ?? const <Map<String, dynamic>>[];
            if (rows.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 110),
                  Icon(
                    Icons.sailing_outlined,
                    size: 60,
                    color: WantokColors.primary,
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: Text(
                      'No water-trip bookings yet',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final booking = rows[index];
                final departure = _asMap(booking['water_departures']);
                final route = _asMap(departure['water_routes']);
                final vessel = _asMap(departure['water_vessels']);
                final fare = _asMap(booking['water_fare_classes']);
                final passengers =
                    (booking['water_booking_passengers'] as List<dynamic>? ??
                            const <dynamic>[])
                        .map(_asMap)
                        .toList(growable: false);
                final id = booking['id'] as String;
                final status = booking['status'].toString();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  route['name']?.toString() ?? 'Water trip',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              _Status(text: status),
                            ],
                          ),
                          if (booking['beneficiary_name'] != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F6F3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.family_restroom_outlined,
                                    color: WantokColors.primaryDark,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      booking['beneficiary_relationship'] ==
                                              null
                                          ? 'Primary passenger: ${booking['beneficiary_name']}'
                                          : 'Primary passenger: ${booking['beneficiary_name']} (${booking['beneficiary_relationship']})',
                                      style: const TextStyle(
                                        color: WantokColors.primaryDark,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 7),
                          if (departure['departs_at'] != null)
                            Text(_formatDateTime(departure['departs_at'])),
                          if (vessel['name'] != null)
                            Text(
                              vessel['name'].toString(),
                              style: const TextStyle(color: WantokColors.muted),
                            ),
                          if (departure['boarding_point'] != null)
                            Text(
                              'Boarding: ${departure['boarding_point']}',
                              style: const TextStyle(color: WantokColors.muted),
                            ),
                          const Divider(height: 22),
                          Text(
                            '${fare['name']?.toString() ?? 'Fare'} • ${booking['passenger_count']} passenger(s)',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 5),
                          ...passengers.map(
                            (passenger) => Text(
                              '• ${passenger['full_name']} (${passenger['passenger_type']})',
                            ),
                          ),
                          const Divider(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  booking['payment_status'].toString(),
                                  style: const TextStyle(
                                    color: WantokColors.muted,
                                  ),
                                ),
                              ),
                              Text(
                                _amount(booking),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: WantokColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                          if (status == 'booked' &&
                              departure['status'] == 'scheduled') ...[
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: _busyId == id
                                  ? null
                                  : () => _cancel(id),
                              icon: const Icon(Icons.cancel_outlined),
                              label: Text(
                                _busyId == id
                                    ? 'Cancelling...'
                                    : 'Cancel booking',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.text});

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

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

double? _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

String _amount(Map<String, dynamic> booking) {
  final amount = _toDouble(booking['total_amount']) ?? 0;
  return amount == 0 ? 'FREE' : 'K${amount.toStringAsFixed(2)}';
}

String _formatDateTime(dynamic value) {
  final date = DateTime.parse(value.toString()).toLocal();
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.day}/${date.month}/${date.year} $hour:$minute';
}
