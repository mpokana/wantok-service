import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

class VendorWaterTransportPage extends StatefulWidget {
  const VendorWaterTransportPage({super.key});

  @override
  State<VendorWaterTransportPage> createState() =>
      _VendorWaterTransportPageState();
}

class _VendorWaterTransportPageState extends State<VendorWaterTransportPage> {
  static const _repository = WaterTransportRepository();
  late Future<_ConsoleData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ConsoleData> _load() async {
    final values = await Future.wait([
      _repository.loadVendorServices(),
      _repository.loadVendorRoutes(),
      _repository.loadVendorVessels(),
      _repository.loadVendorDepartures(),
    ]);
    return _ConsoleData(
      services: values[0],
      routes: values[1],
      vessels: values[2],
      departures: values[3],
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _run(String _, Future<void> Function() action) async {
    try {
      await action();
      await _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _addRoute(List<Map<String, dynamic>> services) async {
    final active = services
        .where((service) => service['status'] == 'active')
        .toList(growable: false);
    if (active.isEmpty) {
      _message('Activate a Boat / Ship Rides listing first.');
      return;
    }

    final draft = await showDialog<_RouteDraft>(
      context: context,
      builder: (context) => _RouteDialog(services: active),
    );
    if (draft == null) return;

    await _run(
      'new-route',
      () => _repository.createRoute(
        providerServiceId: draft.serviceId,
        name: draft.name,
        originName: draft.originName,
        originAddress: draft.originAddress,
        destinationName: draft.destinationName,
        destinationAddress: draft.destinationAddress,
        estimatedMinutes: draft.estimatedMinutes,
      ),
    );
  }

  Future<void> _addVessel(List<Map<String, dynamic>> services) async {
    final active = services
        .where((service) => service['status'] == 'active')
        .toList(growable: false);
    if (active.isEmpty) {
      _message('Activate a Boat / Ship Rides listing first.');
      return;
    }

    final draft = await showDialog<_VesselDraft>(
      context: context,
      builder: (context) => _VesselDialog(services: active),
    );
    if (draft == null) return;

    await _run(
      'new-vessel',
      () => _repository.createVessel(
        providerServiceId: draft.serviceId,
        name: draft.name,
        registrationNumber: draft.registrationNumber,
        vesselType: draft.vesselType,
        totalCapacity: draft.capacity,
        description: draft.description,
      ),
    );
  }

  Future<void> _addDeparture(_ConsoleData data) async {
    final activeServices = data.services
        .where((service) => service['status'] == 'active')
        .toList(growable: false);
    final routes = data.routes
        .where((route) => route['status'] == 'active')
        .toList(growable: false);
    final vessels = data.vessels
        .where((vessel) => vessel['status'] == 'active')
        .toList(growable: false);

    if (activeServices.isEmpty || routes.isEmpty || vessels.isEmpty) {
      _message(
        'You need an active service, an active route and an active vessel before scheduling a departure.',
      );
      return;
    }

    final draft = await showDialog<_DepartureDraft>(
      context: context,
      builder: (context) => _DepartureDialog(
        services: activeServices,
        routes: routes,
        vessels: vessels,
      ),
    );
    if (draft == null) return;

    await _run(
      'new-departure',
      () => _repository.createDeparture(
        providerServiceId: draft.serviceId,
        routeId: draft.routeId,
        vesselId: draft.vesselId,
        departsAt: draft.departsAt,
        arrivesAt: draft.arrivesAt,
        boardingPoint: draft.boardingPoint,
        notes: draft.notes,
      ),
    );
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Water Transport Console')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_ConsoleData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 100),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }

            final data = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
              children: [
                _Hero(
                  routes: data.routes.length,
                  vessels: data.vessels.length,
                  departures: data.departures.length,
                ),
                const SizedBox(height: 18),
                _Section(
                  title: 'Routes',
                  action: FilledButton.tonalIcon(
                    onPressed: () => _addRoute(data.services),
                    icon: const Icon(Icons.add),
                    label: const Text('Add route'),
                  ),
                ),
                const SizedBox(height: 8),
                if (data.routes.isEmpty)
                  const _Empty(
                    icon: Icons.route_outlined,
                    title: 'No routes',
                    body: 'Create an origin-to-destination passenger route.',
                  )
                else
                  ...data.routes.map(
                    (route) => Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE7F4ED),
                          child: Icon(
                            Icons.route_outlined,
                            color: WantokColors.primary,
                          ),
                        ),
                        title: Text(
                          route['name'].toString(),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Text(
                          '${route['origin_name']} → ${route['destination_name']}',
                        ),
                        trailing: _Status(text: route['status'].toString()),
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                _Section(
                  title: 'Vessels',
                  action: FilledButton.tonalIcon(
                    onPressed: () => _addVessel(data.services),
                    icon: const Icon(Icons.add),
                    label: const Text('Add vessel'),
                  ),
                ),
                const SizedBox(height: 8),
                if (data.vessels.isEmpty)
                  const _Empty(
                    icon: Icons.sailing_outlined,
                    title: 'No vessels',
                    body:
                        'Add a boat, ferry or ship and its passenger capacity.',
                  )
                else
                  ...data.vessels.map(
                    (vessel) => Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE7F4ED),
                          child: Icon(
                            Icons.sailing_outlined,
                            color: WantokColors.primary,
                          ),
                        ),
                        title: Text(
                          vessel['name'].toString(),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Text(
                          '${vessel['vessel_type']} • capacity ${vessel['total_capacity']}${vessel['registration_number'] == null ? '' : ' • ${vessel['registration_number']}'}',
                        ),
                        trailing: _Status(text: vessel['status'].toString()),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                _Section(
                  title: 'Departures',
                  action: FilledButton.tonalIcon(
                    onPressed: () => _addDeparture(data),
                    icon: const Icon(Icons.add),
                    label: const Text('Schedule'),
                  ),
                ),
                const SizedBox(height: 8),
                if (data.departures.isEmpty)
                  const _Empty(
                    icon: Icons.calendar_month_outlined,
                    title: 'No departures',
                    body:
                        'Schedule a route and vessel to start taking bookings.',
                  )
                else
                  ...data.departures.map((departure) {
                    final route = _asMap(departure['water_routes']);
                    final vessel = _asMap(departure['water_vessels']);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) =>
                                  _ManageDeparturePage(departure: departure),
                            ),
                          ),
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE7F4ED),
                            child: Icon(
                              Icons.directions_boat_outlined,
                              color: WantokColors.primary,
                            ),
                          ),
                          title: Text(
                            route['name']?.toString() ?? 'Departure',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            _formatDateTime(departure['departs_at']) +
                                (vessel['name'] == null
                                    ? ''
                                    : ' • ${vessel['name']}'),
                          ),
                          trailing: _Status(
                            text: departure['status'].toString(),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ManageDeparturePage extends StatefulWidget {
  const _ManageDeparturePage({required this.departure});

  final Map<String, dynamic> departure;

  @override
  State<_ManageDeparturePage> createState() => _ManageDeparturePageState();
}

class _ManageDeparturePageState extends State<_ManageDeparturePage> {
  static const _repository = WaterTransportRepository();
  late Future<_DepartureData> _future;
  late String _status;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _status = widget.departure['status'].toString();
    _future = _load();
  }

  Future<_DepartureData> _load() async {
    final values = await Future.wait([
      _repository.loadVendorFareClasses(widget.departure['id'] as String),
      _repository.loadManifest(widget.departure['id'] as String),
    ]);
    return _DepartureData(fares: values[0], manifest: values[1]);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _run(String id, Future<void> Function() action) async {
    setState(() => _busyId = id);
    try {
      await action();
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

  Future<void> _addFare() async {
    final draft = await showDialog<_FareDraft>(
      context: context,
      builder: (context) => const _FareDialog(),
    );
    if (draft == null) return;

    await _run(
      'new-fare',
      () => _repository.createFareClass(
        departureId: widget.departure['id'] as String,
        name: draft.name,
        description: draft.description,
        price: draft.price,
        currency: 'PGK',
        capacity: draft.capacity,
      ),
    );
  }

  Future<void> _setDeparture(String target) async {
    await _run(
      'departure-status',
      () => _repository.setDepartureStatus(
        widget.departure['id'] as String,
        target,
      ),
    );
    if (mounted) setState(() => _status = target);
  }

  Future<void> _setBooking(Map<String, dynamic> booking, String target) async {
    await _run(
      booking['id'] as String,
      () => _repository.setBookingStatus(booking['id'] as String, target),
    );
  }

  @override
  Widget build(BuildContext context) {
    final route = _asMap(widget.departure['water_routes']);
    final vessel = _asMap(widget.departure['water_vessels']);

    return Scaffold(
      appBar: AppBar(title: Text(route['name']?.toString() ?? 'Departure')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_DepartureData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final data =
                snapshot.data ??
                const _DepartureData(
                  fares: <Map<String, dynamic>>[],
                  manifest: <Map<String, dynamic>>[],
                );

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(17),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                route['name']?.toString() ?? 'Departure',
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            _Status(text: _status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(_formatDateTime(widget.departure['departs_at'])),
                        if (vessel['name'] != null)
                          Text(
                            vessel['name'].toString(),
                            style: const TextStyle(color: WantokColors.muted),
                          ),
                        if (widget.departure['boarding_point'] != null)
                          Text(
                            'Boarding: ${widget.departure['boarding_point']}',
                            style: const TextStyle(color: WantokColors.muted),
                          ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _departureActions(_status)
                              .map(
                                (action) => action.outlined
                                    ? OutlinedButton(
                                        onPressed: _busyId != null
                                            ? null
                                            : () =>
                                                  _setDeparture(action.target),
                                        child: Text(action.label),
                                      )
                                    : FilledButton(
                                        onPressed: _busyId != null
                                            ? null
                                            : () =>
                                                  _setDeparture(action.target),
                                        child: Text(action.label),
                                      ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _Section(
                  title: 'Fare classes',
                  action: FilledButton.tonalIcon(
                    onPressed: _status == 'scheduled' ? _addFare : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Add fare'),
                  ),
                ),
                const SizedBox(height: 8),
                if (data.fares.isEmpty)
                  const _Empty(
                    icon: Icons.airline_seat_recline_normal,
                    title: 'No fares yet',
                    body: 'Add at least one fare class before customers can book.',
                  )
                else
                  ...data.fares.map(
                    (fare) => Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE7F4ED),
                          child: Icon(
                            Icons.airline_seat_recline_normal,
                            color: WantokColors.primary,
                          ),
                        ),
                        title: Text(
                          fare['name'].toString(),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Text('Capacity ${fare['capacity']}'),
                        trailing: Text(
                          _moneyLabel(fare['price']),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  'Passenger manifest',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                if (data.manifest.isEmpty)
                  const _Empty(
                    icon: Icons.groups_outlined,
                    title: 'No passenger bookings',
                    body: 'Booked passengers will appear here.',
                  )
                else
                  ...data.manifest.map(
                    (booking) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _ManifestCard(
                        booking: booking,
                        departureStatus: _status,
                        busy: _busyId == booking['id'],
                        onStatus: (target) => _setBooking(booking, target),
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

class _ManifestCard extends StatelessWidget {
  const _ManifestCard({
    required this.booking,
    required this.departureStatus,
    required this.busy,
    required this.onStatus,
  });

  final Map<String, dynamic> booking;
  final String departureStatus;
  final bool busy;
  final ValueChanged<String> onStatus;

  @override
  Widget build(BuildContext context) {
    final profile = _asMap(booking['profiles']);
    final fare = _asMap(booking['water_fare_classes']);
    final passengers =
        (booking['water_booking_passengers'] as List<dynamic>? ??
                const <dynamic>[])
            .map(_asMap)
            .toList(growable: false);
    final status = booking['status'].toString();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    profile['full_name']?.toString() ?? 'Booking customer',
                    style: const TextStyle(fontWeight: FontWeight.w900),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking['beneficiary_relationship'] == null
                          ? 'Primary passenger: ${booking['beneficiary_name']}'
                          : 'Primary passenger: ${booking['beneficiary_name']} (${booking['beneficiary_relationship']})',
                      style: const TextStyle(
                        color: WantokColors.primaryDark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (booking['beneficiary_phone'] != null)
                      Text(booking['beneficiary_phone'].toString()),
                    Text(
                      'Booked by: ${profile['full_name']?.toString() ?? 'Wantok account'}',
                      style: const TextStyle(
                        color: WantokColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 5),
            Text(
              '${fare['name']?.toString() ?? 'Fare'} • ${booking['passenger_count']} passenger(s)',
              style: const TextStyle(color: WantokColors.muted),
            ),
            if (booking['contact_phone'] != null)
              Text(
                booking['contact_phone'].toString(),
                style: const TextStyle(color: WantokColors.muted),
              ),
            const Divider(height: 20),
            ...passengers.map(
              (passenger) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '• ${passenger['full_name']} — ${passenger['passenger_type']}${_asMap(passenger['metadata'])['trusted_person_primary'] == true ? ' • Primary' : ''}${passenger['document_reference'] == null ? '' : ' • ID ${passenger['document_reference']}'}',
                ),
              ),
            ),
            if (status == 'booked' && departureStatus == 'boarding') ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: busy ? null : () => onStatus('boarded'),
                    icon: const Icon(Icons.how_to_reg),
                    label: const Text('Board'),
                  ),
                  OutlinedButton(
                    onPressed: busy ? null : () => onStatus('no_show'),
                    child: const Text('No show'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RouteDialog extends StatefulWidget {
  const _RouteDialog({required this.services});

  final List<Map<String, dynamic>> services;

  @override
  State<_RouteDialog> createState() => _RouteDialogState();
}

class _RouteDialogState extends State<_RouteDialog> {
  late String _serviceId;
  final _name = TextEditingController();
  final _origin = TextEditingController();
  final _originAddress = TextEditingController();
  final _destination = TextEditingController();
  final _destinationAddress = TextEditingController();
  final _minutes = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _serviceId = widget.services.first['id'].toString();
  }

  @override
  void dispose() {
    _name.dispose();
    _origin.dispose();
    _originAddress.dispose();
    _destination.dispose();
    _destinationAddress.dispose();
    _minutes.dispose();
    super.dispose();
  }

  void _save() {
    final minutesText = _minutes.text.trim();
    final minutes = minutesText.isEmpty ? null : int.tryParse(minutesText);
    if (_name.text.trim().length < 3 ||
        _origin.text.trim().length < 2 ||
        _destination.text.trim().length < 2) {
      setState(() => _error = 'Enter the route name, origin and destination.');
      return;
    }
    if (minutesText.isNotEmpty && (minutes == null || minutes <= 0)) {
      setState(() => _error = 'Enter valid estimated minutes.');
      return;
    }

    Navigator.of(context).pop(
      _RouteDraft(
        serviceId: _serviceId,
        name: _name.text.trim(),
        originName: _origin.text.trim(),
        originAddress: _originAddress.text.trim(),
        destinationName: _destination.text.trim(),
        destinationAddress: _destinationAddress.text.trim(),
        estimatedMinutes: minutes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add passenger route'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _serviceId,
                decoration: const InputDecoration(
                  labelText: 'Provider listing',
                ),
                items: widget.services
                    .map(
                      (service) => DropdownMenuItem(
                        value: service['id'].toString(),
                        child: Text(service['title'].toString()),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) setState(() => _serviceId = value);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Route name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _origin,
                decoration: const InputDecoration(labelText: 'Origin'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _originAddress,
                decoration: const InputDecoration(
                  labelText: 'Origin wharf / address',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _destination,
                decoration: const InputDecoration(labelText: 'Destination'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _destinationAddress,
                decoration: const InputDecoration(
                  labelText: 'Destination wharf / address',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _minutes,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Estimated travel minutes',
                ),
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
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
        FilledButton(onPressed: _save, child: const Text('Create route')),
      ],
    );
  }
}

class _VesselDialog extends StatefulWidget {
  const _VesselDialog({required this.services});

  final List<Map<String, dynamic>> services;

  @override
  State<_VesselDialog> createState() => _VesselDialogState();
}

class _VesselDialogState extends State<_VesselDialog> {
  late String _serviceId;
  String _type = 'boat';
  final _name = TextEditingController();
  final _registration = TextEditingController();
  final _capacity = TextEditingController();
  final _description = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _serviceId = widget.services.first['id'].toString();
  }

  @override
  void dispose() {
    _name.dispose();
    _registration.dispose();
    _capacity.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    final capacity = int.tryParse(_capacity.text.trim());
    if (_name.text.trim().length < 2 || capacity == null || capacity <= 0) {
      setState(() => _error = 'Enter a vessel name and valid capacity.');
      return;
    }

    Navigator.of(context).pop(
      _VesselDraft(
        serviceId: _serviceId,
        name: _name.text.trim(),
        registrationNumber: _registration.text.trim(),
        vesselType: _type,
        capacity: capacity,
        description: _description.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add vessel'),
      content: SizedBox(
        width: 430,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _serviceId,
              decoration: const InputDecoration(labelText: 'Provider listing'),
              items: widget.services
                  .map(
                    (service) => DropdownMenuItem(
                      value: service['id'].toString(),
                      child: Text(service['title'].toString()),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) setState(() => _serviceId = value);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Vessel name'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Vessel type'),
              items: const [
                DropdownMenuItem(value: 'dinghy', child: Text('Dinghy')),
                DropdownMenuItem(value: 'boat', child: Text('Boat')),
                DropdownMenuItem(value: 'ferry', child: Text('Ferry')),
                DropdownMenuItem(value: 'ship', child: Text('Ship')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _registration,
              decoration: const InputDecoration(
                labelText: 'Registration number',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _capacity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Passenger capacity',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Add vessel')),
      ],
    );
  }
}

class _DepartureDialog extends StatefulWidget {
  const _DepartureDialog({
    required this.services,
    required this.routes,
    required this.vessels,
  });

  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> routes;
  final List<Map<String, dynamic>> vessels;

  @override
  State<_DepartureDialog> createState() => _DepartureDialogState();
}

class _DepartureDialogState extends State<_DepartureDialog> {
  late String _serviceId;
  late String _routeId;
  late String _vesselId;
  late DateTime _departsAt;
  late DateTime _arrivesAt;
  final _boarding = TextEditingController();
  final _notes = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _serviceId = widget.services.first['id'].toString();
    _routeId = widget.routes.first['id'].toString();
    _vesselId = widget.vessels.first['id'].toString();
    _departsAt = DateTime.now().add(const Duration(days: 1));
    _arrivesAt = _departsAt.add(const Duration(hours: 2));
  }

  @override
  void dispose() {
    _boarding.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDeparture() async {
    final value = await _pickDateTime(context, _departsAt);
    if (value == null) return;
    setState(() {
      _departsAt = value;
      if (!_arrivesAt.isAfter(_departsAt)) {
        _arrivesAt = _departsAt.add(const Duration(hours: 2));
      }
    });
  }

  Future<void> _pickArrival() async {
    final value = await _pickDateTime(context, _arrivesAt);
    if (value != null) setState(() => _arrivesAt = value);
  }

  void _save() {
    if (!_arrivesAt.isAfter(_departsAt)) {
      setState(() => _error = 'Arrival must be after departure.');
      return;
    }

    Navigator.of(context).pop(
      _DepartureDraft(
        serviceId: _serviceId,
        routeId: _routeId,
        vesselId: _vesselId,
        departsAt: _departsAt,
        arrivesAt: _arrivesAt,
        boardingPoint: _boarding.text.trim(),
        notes: _notes.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Schedule departure'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _serviceId,
                decoration: const InputDecoration(
                  labelText: 'Provider listing',
                ),
                items: widget.services
                    .map(
                      (service) => DropdownMenuItem(
                        value: service['id'].toString(),
                        child: Text(service['title'].toString()),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) setState(() => _serviceId = value);
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _routeId,
                decoration: const InputDecoration(labelText: 'Route'),
                items: widget.routes
                    .map(
                      (route) => DropdownMenuItem(
                        value: route['id'].toString(),
                        child: Text(route['name'].toString()),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) setState(() => _routeId = value);
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _vesselId,
                decoration: const InputDecoration(labelText: 'Vessel'),
                items: widget.vessels
                    .map(
                      (vessel) => DropdownMenuItem(
                        value: vessel['id'].toString(),
                        child: Text(vessel['name'].toString()),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) setState(() => _vesselId = value);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: _pickDeparture,
                leading: const Icon(Icons.schedule_outlined),
                title: const Text('Departure'),
                subtitle: Text(_formatDateTime(_departsAt)),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: _pickArrival,
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Expected arrival'),
                subtitle: Text(_formatDateTime(_arrivesAt)),
              ),
              TextField(
                controller: _boarding,
                decoration: const InputDecoration(
                  labelText: 'Boarding point / wharf',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
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
        FilledButton(onPressed: _save, child: const Text('Schedule')),
      ],
    );
  }
}

class _FareDialog extends StatefulWidget {
  const _FareDialog();

  @override
  State<_FareDialog> createState() => _FareDialogState();
}

class _FareDialogState extends State<_FareDialog> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController(text: '0.00');
  final _capacity = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _capacity.dispose();
    super.dispose();
  }

  void _save() {
    final price = double.tryParse(_price.text.trim());
    final capacity = int.tryParse(_capacity.text.trim());
    if (_name.text.trim().length < 2 ||
        price == null ||
        price < 0 ||
        capacity == null ||
        capacity <= 0) {
      setState(() => _error = 'Enter a fare name, valid price and capacity.');
      return;
    }

    Navigator.of(context).pop(
      _FareDraft(
        name: _name.text.trim(),
        description: _description.text.trim(),
        price: price,
        capacity: capacity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add fare class'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Fare class name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Price (Kina / K)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _capacity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Class capacity'),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Add fare')),
      ],
    );
  }
}

class _RouteDraft {
  const _RouteDraft({
    required this.serviceId,
    required this.name,
    required this.originName,
    required this.originAddress,
    required this.destinationName,
    required this.destinationAddress,
    required this.estimatedMinutes,
  });

  final String serviceId;
  final String name;
  final String originName;
  final String originAddress;
  final String destinationName;
  final String destinationAddress;
  final int? estimatedMinutes;
}

class _VesselDraft {
  const _VesselDraft({
    required this.serviceId,
    required this.name,
    required this.registrationNumber,
    required this.vesselType,
    required this.capacity,
    required this.description,
  });

  final String serviceId;
  final String name;
  final String registrationNumber;
  final String vesselType;
  final int capacity;
  final String description;
}

class _DepartureDraft {
  const _DepartureDraft({
    required this.serviceId,
    required this.routeId,
    required this.vesselId,
    required this.departsAt,
    required this.arrivesAt,
    required this.boardingPoint,
    required this.notes,
  });

  final String serviceId;
  final String routeId;
  final String vesselId;
  final DateTime departsAt;
  final DateTime arrivesAt;
  final String boardingPoint;
  final String notes;
}

class _FareDraft {
  const _FareDraft({
    required this.name,
    required this.description,
    required this.price,
    required this.capacity,
  });

  final String name;
  final String description;
  final double price;
  final int capacity;
}

class _ConsoleData {
  const _ConsoleData({
    required this.services,
    required this.routes,
    required this.vessels,
    required this.departures,
  });

  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> routes;
  final List<Map<String, dynamic>> vessels;
  final List<Map<String, dynamic>> departures;
}

class _DepartureData {
  const _DepartureData({required this.fares, required this.manifest});

  final List<Map<String, dynamic>> fares;
  final List<Map<String, dynamic>> manifest;
}

class _DepartureAction {
  const _DepartureAction(this.target, this.label, {this.outlined = false});

  final String target;
  final String label;
  final bool outlined;
}

List<_DepartureAction> _departureActions(String status) => switch (status) {
  'scheduled' => const [
    _DepartureAction('boarding', 'Open boarding'),
    _DepartureAction('cancelled', 'Cancel departure', outlined: true),
  ],
  'boarding' => const [
    _DepartureAction('departed', 'Depart'),
    _DepartureAction('cancelled', 'Cancel departure', outlined: true),
  ],
  'departed' => const [_DepartureAction('arrived', 'Mark arrived')],
  _ => const <_DepartureAction>[],
};

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.action});

  final String title;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        action,
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.routes,
    required this.vessels,
    required this.departures,
  });

  final int routes;
  final int vessels;
  final int departures;

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
      child: Row(
        children: [
          const Icon(Icons.sailing, color: Colors.white, size: 50),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scheduled water transport',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$routes route(s) • $vessels vessel(s) • $departures departure(s)',
                  style: const TextStyle(color: Color(0xFFD9F3E5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 44, color: WantokColors.primary),
            const SizedBox(height: 9),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: WantokColors.muted),
            ),
          ],
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

Future<DateTime?> _pickDateTime(BuildContext context, DateTime initial) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime.now().subtract(const Duration(days: 1)),
    lastDate: DateTime.now().add(const Duration(days: 730)),
  );
  if (date == null || !context.mounted) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null) return null;

  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
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

String _moneyLabel(dynamic value) {
  final amount = _toDouble(value) ?? 0;
  return amount == 0 ? 'FREE' : 'K${amount.toStringAsFixed(2)}';
}

String _formatDateTime(dynamic value) {
  final date = value is DateTime
      ? value
      : DateTime.parse(value.toString()).toLocal();
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.day}/${date.month}/${date.year} $hour:$minute';
}
