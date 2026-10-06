import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

import '../client_load_error.dart';

import 'booking_for_selector.dart';
import 'water_trip_bookings_page.dart';

class WaterTransportPage extends StatefulWidget {
  const WaterTransportPage({super.key});

  @override
  State<WaterTransportPage> createState() => _WaterTransportPageState();
}

class _WaterTransportPageState extends State<WaterTransportPage> {
  static const _repository = WaterTransportRepository();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.loadUpcomingDepartures();
  }

  Future<void> _refresh() async {
    final next = _repository.loadUpcomingDepartures();
    setState(() {
      _future = next;
    });
    try {
      await next;
    } catch (_) {
      // The FutureBuilder presents the retryable error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boat / Ship Rides'),
        actions: [
          IconButton(
            tooltip: 'My water trips',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const WaterTripBookingsPage(),
              ),
            ),
            icon: const Icon(Icons.confirmation_number_outlined),
          ),
        ],
      ),
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
                title: 'Could not load departures',
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
                    size: 62,
                    color: WantokColors.primary,
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: Text(
                      'No scheduled departures available',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                const _Hero(),
                const SizedBox(height: 18),
                ...rows.map(
                  (departure) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DepartureCard(
                      departure: departure,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              _DepartureDetailPage(departure: departure),
                        ),
                      ),
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

class _DepartureDetailPage extends StatefulWidget {
  const _DepartureDetailPage({required this.departure});

  final Map<String, dynamic> departure;

  @override
  State<_DepartureDetailPage> createState() => _DepartureDetailPageState();
}

class _DepartureDetailPageState extends State<_DepartureDetailPage> {
  static const _repository = WaterTransportRepository();
  late Future<List<Map<String, dynamic>>> _fares;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fares = _repository.loadFareClasses(widget.departure['id'] as String);
  }

  Future<void> _book(Map<String, dynamic> fare) async {
    final draft = await showDialog<_WaterBookingDraft>(
      context: context,
      builder: (context) => _WaterBookingDialog(fare: fare),
    );
    if (draft == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _repository.bookDeparture(
        departureId: widget.departure['id'] as String,
        fareClassId: fare['id'] as String,
        passengers: draft.passengers,
        contactPhone: draft.contactPhone,
        note: draft.note,
        trustedPersonId: draft.trustedPersonId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passenger booking created.')),
      );
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => const WaterTripBookingsPage(),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final departure = widget.departure;
    final route = _asMap(departure['water_routes']);
    final vessel = _asMap(departure['water_vessels']);
    final operator = _asMap(departure['provider_profiles']);

    return Scaffold(
      appBar: AppBar(title: Text(route['name']?.toString() ?? 'Water trip')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route['name']?.toString() ?? 'Scheduled trip',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _Info(
                    icon: Icons.trip_origin,
                    text: route['origin_name']?.toString() ?? 'Origin',
                  ),
                  const SizedBox(height: 7),
                  _Info(
                    icon: Icons.location_on_outlined,
                    text:
                        route['destination_name']?.toString() ?? 'Destination',
                  ),
                  const SizedBox(height: 7),
                  _Info(
                    icon: Icons.schedule_outlined,
                    text: _formatDateTime(departure['departs_at']),
                  ),
                  if (departure['boarding_point'] != null) ...[
                    const SizedBox(height: 7),
                    _Info(
                      icon: Icons.directions_boat_outlined,
                      text: 'Boarding: ${departure['boarding_point']}',
                    ),
                  ],
                  if (vessel['name'] != null) ...[
                    const Divider(height: 24),
                    _Info(
                      icon: Icons.sailing_outlined,
                      text:
                          '${vessel['name']} • ${vessel['total_capacity']} passengers',
                    ),
                  ],
                  if (operator['display_name'] != null) ...[
                    const SizedBox(height: 7),
                    _Info(
                      icon: Icons.business_outlined,
                      text: 'Operator: ${operator['display_name']}',
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Fares',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fares,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              final fares = snapshot.data ?? const <Map<String, dynamic>>[];
              if (fares.isEmpty) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('No fare classes published yet'),
                  ),
                );
              }

              return Column(
                children: fares
                    .map((fare) {
                      final price = _toDouble(fare['price']) ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(14),
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFE7F4ED),
                              child: Icon(
                                Icons.airline_seat_recline_normal,
                                color: WantokColors.primary,
                              ),
                            ),
                            title: Text(
                              fare['name'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            subtitle: fare['description'] == null
                                ? Text('Capacity ${fare['capacity']}')
                                : Text(fare['description'].toString()),
                            trailing: Text(
                              price == 0
                                  ? 'FREE'
                                  : 'K${price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: WantokColors.primaryDark,
                              ),
                            ),
                            onTap: _busy ? null : () => _book(fare),
                          ),
                        ),
                      );
                    })
                    .toList(growable: false),
              );
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'Paid fares are reserved as unpaid until Wantok Payments is connected.',
            style: TextStyle(color: WantokColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _WaterBookingDialog extends StatefulWidget {
  const _WaterBookingDialog({required this.fare});

  final Map<String, dynamic> fare;

  @override
  State<_WaterBookingDialog> createState() => _WaterBookingDialogState();
}

class _WaterBookingDialogState extends State<_WaterBookingDialog> {
  final _contact = TextEditingController();
  final _note = TextEditingController();
  final List<_PassengerDraft> _passengers = [_PassengerDraft()];
  String? _trustedPersonId;
  String? _error;

  @override
  void dispose() {
    _contact.dispose();
    _note.dispose();
    for (final passenger in _passengers) {
      passenger.dispose();
    }
    super.dispose();
  }

  void _addPassenger() {
    if (_passengers.length >= 20) return;
    setState(() => _passengers.add(_PassengerDraft()));
  }

  void _removePassenger(int index) {
    if (_passengers.length == 1) return;
    final item = _passengers.removeAt(index);
    item.dispose();
    setState(() {});
  }

  void _submit() {
    for (var index = 0; index < _passengers.length; index++) {
      final passenger = _passengers[index];
      final trustedPrimary = index == 0 && _trustedPersonId != null;
      if (!trustedPrimary && passenger.name.text.trim().length < 2) {
        setState(() => _error = 'Enter the full name for every passenger.');
        return;
      }
    }

    Navigator.of(context).pop(
      _WaterBookingDraft(
        passengers: _passengers
            .map(
              (passenger) => {
                'full_name': passenger.name.text.trim(),
                'phone': passenger.phone.text.trim(),
                'passenger_type': passenger.type,
                'document_reference': passenger.document.text.trim(),
              },
            )
            .toList(growable: false),
        contactPhone: _contact.text.trim(),
        note: _note.text.trim(),
        trustedPersonId: _trustedPersonId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final price = _toDouble(widget.fare['price']) ?? 0;
    final total = price * _passengers.length;

    return AlertDialog(
      title: Text(widget.fare['name'].toString()),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BookingForSelector(
                selectedTrustedPersonId: _trustedPersonId,
                onChanged: (value) {
                  setState(() {
                    _trustedPersonId = value;
                    _error = null;
                  });
                },
              ),
              const SizedBox(height: 10),
              ...List.generate(_passengers.length, (index) {
                final passenger = _passengers[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Passenger ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (_passengers.length > 1)
                              IconButton(
                                onPressed: () => _removePassenger(index),
                                icon: const Icon(Icons.delete_outline),
                              ),
                          ],
                        ),
                        if (index == 0 && _trustedPersonId != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F6F3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Primary passenger name and phone will come from the selected Trusted person. Passenger type and ID remain editable below.',
                              style: TextStyle(
                                color: WantokColors.primaryDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          )
                        else
                          TextField(
                            controller: passenger.name,
                            decoration: const InputDecoration(
                              labelText: 'Full name',
                            ),
                          ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: passenger.type,
                          decoration: const InputDecoration(
                            labelText: 'Passenger type',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'adult',
                              child: Text('Adult'),
                            ),
                            DropdownMenuItem(
                              value: 'child',
                              child: Text('Child'),
                            ),
                            DropdownMenuItem(
                              value: 'infant',
                              child: Text('Infant'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) passenger.type = value;
                          },
                        ),
                        if (!(index == 0 && _trustedPersonId != null)) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: passenger.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone (optional)',
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        TextField(
                          controller: passenger.document,
                          decoration: const InputDecoration(
                            labelText: 'ID / document reference (optional)',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              OutlinedButton.icon(
                onPressed: _passengers.length >= 20 ? null : _addPassenger,
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('Add passenger'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _contact,
                decoration: const InputDecoration(
                  labelText: 'Booking contact phone (optional)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _note,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Travel note / baggage note (optional)',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                price == 0
                    ? '${_passengers.length} passenger(s) • FREE'
                    : '${_passengers.length} passenger(s) • K${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: WantokColors.primaryDark,
                ),
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
        FilledButton(onPressed: _submit, child: const Text('Book passage')),
      ],
    );
  }
}

class _PassengerDraft {
  final name = TextEditingController();
  final phone = TextEditingController();
  final document = TextEditingController();
  String type = 'adult';

  void dispose() {
    name.dispose();
    phone.dispose();
    document.dispose();
  }
}

class _WaterBookingDraft {
  const _WaterBookingDraft({
    required this.passengers,
    required this.contactPhone,
    required this.note,
    required this.trustedPersonId,
  });

  final List<Map<String, dynamic>> passengers;
  final String contactPhone;
  final String note;
  final String? trustedPersonId;
}

class _DepartureCard extends StatelessWidget {
  const _DepartureCard({required this.departure, required this.onTap});

  final Map<String, dynamic> departure;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final route = _asMap(departure['water_routes']);
    final vessel = _asMap(departure['water_vessels']);
    final operator = _asMap(departure['provider_profiles']);

    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(14),
        leading: const CircleAvatar(
          radius: 28,
          backgroundColor: Color(0xFFE7F4ED),
          child: Icon(Icons.sailing_outlined, color: WantokColors.primary),
        ),
        title: Text(
          route['name']?.toString() ??
              '${route['origin_name']?.toString() ?? 'Origin'} → ${route['destination_name']?.toString() ?? 'Destination'}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatDateTime(departure['departs_at'])),
            if (vessel['name'] != null)
              Text(
                vessel['name'].toString(),
                style: const TextStyle(color: WantokColors.muted),
              ),
            if (operator['display_name'] != null)
              Text(
                operator['display_name'].toString(),
                style: const TextStyle(color: WantokColors.muted, fontSize: 12),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

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
      child: const Row(
        children: [
          Icon(Icons.sailing, color: Colors.white, size: 50),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scheduled water transport',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Book passenger seats on approved boat, ferry and ship services.',
                  style: TextStyle(color: Color(0xFFD9F3E5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: WantokColors.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
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

String _formatDateTime(dynamic value) {
  final date = DateTime.parse(value.toString()).toLocal();
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.day}/${date.month}/${date.year} $hour:$minute';
}

String _friendlyError(Object error) {
  final text = error.toString();
  const marker = 'message: ';
  final index = text.indexOf(marker);
  if (index >= 0) {
    return text.substring(index + marker.length).replaceAll(')', '');
  }
  return text.replaceFirst('StateError: ', '');
}
