import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

class VendorEventsPage extends StatefulWidget {
  const VendorEventsPage({super.key});

  @override
  State<VendorEventsPage> createState() => _VendorEventsPageState();
}

class _VendorEventsPageState extends State<VendorEventsPage> {
  static const _repository = EventsRepository();
  late Future<_EventConsoleData> _future;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_EventConsoleData> _load() async {
    final values = await Future.wait([
      _repository.loadVendorEventServices(),
      _repository.loadVendorEvents(),
    ]);
    return _EventConsoleData(services: values[0], events: values[1]);
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

  Future<void> _addEvent(List<Map<String, dynamic>> services) async {
    final active = services
        .where((service) => service['status'] == 'active')
        .toList(growable: false);

    if (active.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You need an active Events provider listing before creating an event.',
          ),
        ),
      );
      return;
    }

    final draft = await showDialog<_EventDraft>(
      context: context,
      builder: (context) => _EventEditorDialog(services: active),
    );
    if (draft == null) return;

    await _run(
      'new-event',
      () => _repository.createEvent(
        providerServiceId: draft.providerServiceId,
        title: draft.title,
        description: draft.description,
        venueName: draft.venueName,
        venueAddress: draft.venueAddress,
        startsAt: draft.startsAt,
        endsAt: draft.endsAt,
        capacity: draft.capacity,
      ),
    );
  }

  Future<void> _editEvent(
    Map<String, dynamic> event,
    List<Map<String, dynamic>> services,
  ) async {
    final draft = await showDialog<_EventDraft>(
      context: context,
      builder: (context) =>
          _EventEditorDialog(services: services, event: event),
    );
    if (draft == null) return;

    await _run(
      event['id'] as String,
      () => _repository.updateEvent(
        eventId: event['id'] as String,
        title: draft.title,
        description: draft.description,
        venueName: draft.venueName,
        venueAddress: draft.venueAddress,
        startsAt: draft.startsAt,
        endsAt: draft.endsAt,
        capacity: draft.capacity,
      ),
    );
  }

  Future<void> _setStatus(Map<String, dynamic> event, String status) async {
    await _run(
      event['id'] as String,
      () => _repository.setEventStatus(event['id'] as String, status),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events Organiser Console')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_EventConsoleData>(
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
                _Hero(eventCount: data.events.length),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Your events',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _addEvent(data.services),
                      icon: const Icon(Icons.add),
                      label: const Text('Create event'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (data.events.isEmpty)
                  const _EmptyCard(
                    icon: Icons.event_outlined,
                    title: 'No events yet',
                    body: 'Create an event under your approved Events provider listing.',
                  )
                else
                  ...data.events.map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      event['title'].toString(),
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  _Status(text: event['status'].toString()),
                                ],
                              ),
                              const SizedBox(height: 7),
                              Text(_formatDateTime(event['starts_at'])),
                              if (event['venue_name'] != null)
                                Text(
                                  event['venue_name'].toString(),
                                  style: const TextStyle(
                                    color: WantokColors.muted,
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _busyId == event['id']
                                        ? null
                                        : () =>
                                              _editEvent(event, data.services),
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Edit'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (context) =>
                                            _ManageEventPage(event: event),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.confirmation_number_outlined,
                                    ),
                                    label: const Text('Tickets & attendees'),
                                  ),
                                  if (event['status'] == 'draft')
                                    FilledButton(
                                      onPressed: _busyId == event['id']
                                          ? null
                                          : () =>
                                                _setStatus(event, 'published'),
                                      child: const Text('Publish'),
                                    ),
                                  if (event['status'] == 'published')
                                    OutlinedButton(
                                      onPressed: _busyId == event['id']
                                          ? null
                                          : () => _setStatus(event, 'draft'),
                                      child: const Text('Unpublish'),
                                    ),
                                  if (event['status'] != 'cancelled' &&
                                      event['status'] != 'completed')
                                    TextButton(
                                      onPressed: _busyId == event['id']
                                          ? null
                                          : () =>
                                                _setStatus(event, 'cancelled'),
                                      child: const Text('Cancel event'),
                                    ),
                                ],
                              ),
                            ],
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

class _ManageEventPage extends StatefulWidget {
  const _ManageEventPage({required this.event});

  final Map<String, dynamic> event;

  @override
  State<_ManageEventPage> createState() => _ManageEventPageState();
}

class _ManageEventPageState extends State<_ManageEventPage> {
  static const _repository = EventsRepository();
  late Future<_ManageData> _future;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ManageData> _load() async {
    final values = await Future.wait([
      _repository.loadVendorTicketTypes(widget.event['id'] as String),
      _repository.loadVendorRegistrations(widget.event['id'] as String),
    ]);
    return _ManageData(tickets: values[0], registrations: values[1]);
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

  Future<void> _addTicket() async {
    final draft = await showDialog<_TicketDraft>(
      context: context,
      builder: (context) => const _TicketDialog(),
    );
    if (draft == null) return;

    await _run(
      'new-ticket',
      () => _repository.createTicketType(
        eventId: widget.event['id'] as String,
        name: draft.name,
        description: draft.description,
        price: draft.price,
        currency: 'PGK',
        capacity: draft.capacity,
        isActive: draft.isActive,
      ),
    );
  }

  Future<void> _editTicket(Map<String, dynamic> ticket) async {
    final draft = await showDialog<_TicketDraft>(
      context: context,
      builder: (context) => _TicketDialog(ticket: ticket),
    );
    if (draft == null) return;

    await _run(
      ticket['id'] as String,
      () => _repository.updateTicketType(
        ticketTypeId: ticket['id'] as String,
        name: draft.name,
        description: draft.description,
        price: draft.price,
        capacity: draft.capacity,
        isActive: draft.isActive,
      ),
    );
  }

  Future<void> _setRegistration(
    Map<String, dynamic> registration,
    String status,
  ) async {
    await _run(
      registration['id'] as String,
      () => _repository.setRegistrationStatus(
        registration['id'] as String,
        status,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.event['title'].toString())),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_ManageData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final data =
                snapshot.data ??
                const _ManageData(
                  tickets: <Map<String, dynamic>>[],
                  registrations: <Map<String, dynamic>>[],
                );

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ticket types',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _addTicket,
                      icon: const Icon(Icons.add),
                      label: const Text('Add ticket'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (data.tickets.isEmpty)
                  const _EmptyCard(
                    icon: Icons.confirmation_number_outlined,
                    title: 'No ticket types',
                    body: 'Add a free registration type or a paid ticket before publishing.',
                  )
                else
                  ...data.tickets.map(
                    (ticket) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: ListTile(
                          onTap: () => _editTicket(ticket),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFE7F4ED),
                            child: Icon(
                              ticket['is_active'] == true
                                  ? Icons.confirmation_number
                                  : Icons.pause_circle_outline,
                              color: WantokColors.primary,
                            ),
                          ),
                          title: Text(
                            ticket['name'].toString(),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            _ticketPrice(ticket) +
                                (ticket['capacity'] == null
                                    ? ''
                                    : ' • capacity ${ticket['capacity']}'),
                          ),
                          trailing: const Icon(Icons.edit_outlined),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  'Registrations & attendees',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                if (data.registrations.isEmpty)
                  const _EmptyCard(
                    icon: Icons.groups_outlined,
                    title: 'No registrations yet',
                    body: 'Customer registrations will appear here after the event is published.',
                  )
                else
                  ...data.registrations.map((registration) {
                    final profile = _asMap(registration['profiles']);
                    final ticket = _asMap(registration['event_ticket_types']);
                    final status = registration['status'].toString();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      registration['attendee_name']
                                              ?.toString() ??
                                          profile['full_name']?.toString() ??
                                          'Attendee',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  _Status(text: status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                ticket['name']?.toString() ?? 'Registration',
                              ),
                              Text(
                                '${registration['quantity']} ticket(s) • ${registration['payment_status']}',
                                style: const TextStyle(
                                  color: WantokColors.muted,
                                ),
                              ),
                              if (registration['attendee_contact'] != null)
                                Text(
                                  registration['attendee_contact'].toString(),
                                  style: const TextStyle(
                                    color: WantokColors.muted,
                                  ),
                                ),
                              if (status == 'reserved') ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    FilledButton.icon(
                                      onPressed: _busyId == registration['id']
                                          ? null
                                          : () => _setRegistration(
                                              registration,
                                              'checked_in',
                                            ),
                                      icon: const Icon(Icons.how_to_reg),
                                      label: const Text('Check in'),
                                    ),
                                    OutlinedButton(
                                      onPressed: _busyId == registration['id']
                                          ? null
                                          : () => _setRegistration(
                                              registration,
                                              'cancelled',
                                            ),
                                      child: const Text('Cancel'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
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

class _EventEditorDialog extends StatefulWidget {
  const _EventEditorDialog({required this.services, this.event});

  final List<Map<String, dynamic>> services;
  final Map<String, dynamic>? event;

  @override
  State<_EventEditorDialog> createState() => _EventEditorDialogState();
}

class _EventEditorDialogState extends State<_EventEditorDialog> {
  late String _serviceId;
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _venue;
  late final TextEditingController _address;
  late final TextEditingController _capacity;
  late DateTime _startsAt;
  late DateTime _endsAt;
  String? _error;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _serviceId =
        event?['provider_service_id']?.toString() ??
        widget.services.first['id'].toString();
    _title = TextEditingController(text: event?['title']?.toString() ?? '');
    _description = TextEditingController(
      text: event?['description']?.toString() ?? '',
    );
    _venue = TextEditingController(
      text: event?['venue_name']?.toString() ?? '',
    );
    _address = TextEditingController(
      text: event?['venue_address']?.toString() ?? '',
    );
    _capacity = TextEditingController(
      text: event?['capacity']?.toString() ?? '',
    );
    _startsAt = event?['starts_at'] == null
        ? DateTime.now().add(const Duration(days: 7))
        : DateTime.parse(event!['starts_at'].toString()).toLocal();
    _endsAt = event?['ends_at'] == null
        ? _startsAt.add(const Duration(hours: 2))
        : DateTime.parse(event!['ends_at'].toString()).toLocal();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _venue.dispose();
    _address.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final value = await _pickDateTime(context, _startsAt);
    if (value == null) return;
    setState(() {
      _startsAt = value;
      if (!_endsAt.isAfter(_startsAt)) {
        _endsAt = _startsAt.add(const Duration(hours: 2));
      }
    });
  }

  Future<void> _pickEnd() async {
    final value = await _pickDateTime(context, _endsAt);
    if (value == null) return;
    setState(() => _endsAt = value);
  }

  void _save() {
    final capacityText = _capacity.text.trim();
    final capacity = capacityText.isEmpty ? null : int.tryParse(capacityText);

    if (_title.text.trim().length < 3) {
      setState(() => _error = 'Enter an event title.');
      return;
    }
    if (!_endsAt.isAfter(_startsAt)) {
      setState(() => _error = 'End time must be after the start time.');
      return;
    }
    if (capacityText.isNotEmpty && (capacity == null || capacity <= 0)) {
      setState(() => _error = 'Enter a valid capacity or leave it blank.');
      return;
    }

    Navigator.of(context).pop(
      _EventDraft(
        providerServiceId: _serviceId,
        title: _title.text.trim(),
        description: _description.text.trim(),
        venueName: _venue.text.trim(),
        venueAddress: _address.text.trim(),
        startsAt: _startsAt,
        endsAt: _endsAt,
        capacity: capacity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.event != null;

    return AlertDialog(
      title: Text(editing ? 'Edit event' : 'Create event'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _serviceId,
                decoration: const InputDecoration(labelText: 'Events listing'),
                items: widget.services
                    .map(
                      (service) => DropdownMenuItem(
                        value: service['id'].toString(),
                        child: Text(service['title'].toString()),
                      ),
                    )
                    .toList(growable: false),
                onChanged: editing
                    ? null
                    : (value) {
                        if (value != null) setState(() => _serviceId = value);
                      },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Event title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _description,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _venue,
                decoration: const InputDecoration(labelText: 'Venue name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _address,
                decoration: const InputDecoration(
                  labelText: 'Venue address / landmark',
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: _pickStart,
                leading: const Icon(Icons.event_outlined),
                title: const Text('Starts'),
                subtitle: Text(_formatDateTime(_startsAt)),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: _pickEnd,
                leading: const Icon(Icons.event_available_outlined),
                title: const Text('Ends'),
                subtitle: Text(_formatDateTime(_endsAt)),
              ),
              TextField(
                controller: _capacity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Overall capacity (optional)',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(editing ? 'Save' : 'Create draft'),
        ),
      ],
    );
  }
}

class _TicketDialog extends StatefulWidget {
  const _TicketDialog({this.ticket});

  final Map<String, dynamic>? ticket;

  @override
  State<_TicketDialog> createState() => _TicketDialogState();
}

class _TicketDialogState extends State<_TicketDialog> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _capacity;
  late bool _active;
  String? _error;

  @override
  void initState() {
    super.initState();
    final ticket = widget.ticket;
    _name = TextEditingController(text: ticket?['name']?.toString() ?? '');
    _description = TextEditingController(
      text: ticket?['description']?.toString() ?? '',
    );
    _price = TextEditingController(
      text: ticket?['price'] == null ? '0.00' : _money(ticket?['price']),
    );
    _capacity = TextEditingController(
      text: ticket?['capacity']?.toString() ?? '',
    );
    _active = ticket?['is_active'] as bool? ?? true;
  }

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
    final capacityText = _capacity.text.trim();
    final capacity = capacityText.isEmpty ? null : int.tryParse(capacityText);

    if (_name.text.trim().length < 2) {
      setState(() => _error = 'Enter a ticket name.');
      return;
    }
    if (price == null || price < 0) {
      setState(() => _error = 'Enter a valid price.');
      return;
    }
    if (capacityText.isNotEmpty && (capacity == null || capacity <= 0)) {
      setState(() => _error = 'Enter a valid capacity.');
      return;
    }

    Navigator.of(context).pop(
      _TicketDraft(
        name: _name.text.trim(),
        description: _description.text.trim(),
        price: price,
        capacity: capacity,
        isActive: _active,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.ticket == null ? 'Add ticket type' : 'Edit ticket type',
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Ticket / registration name',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Price (PGK)',
                helperText: 'Use 0 for a free registration.',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _capacity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ticket capacity (optional)',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _active,
              onChanged: (value) => setState(() => _active = value),
              title: const Text('Available for registration'),
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
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _EventDraft {
  const _EventDraft({
    required this.providerServiceId,
    required this.title,
    required this.description,
    required this.venueName,
    required this.venueAddress,
    required this.startsAt,
    required this.endsAt,
    required this.capacity,
  });

  final String providerServiceId;
  final String title;
  final String description;
  final String venueName;
  final String venueAddress;
  final DateTime startsAt;
  final DateTime endsAt;
  final int? capacity;
}

class _TicketDraft {
  const _TicketDraft({
    required this.name,
    required this.description,
    required this.price,
    required this.capacity,
    required this.isActive,
  });

  final String name;
  final String description;
  final double price;
  final int? capacity;
  final bool isActive;
}

class _EventConsoleData {
  const _EventConsoleData({required this.services, required this.events});

  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> events;
}

class _ManageData {
  const _ManageData({required this.tickets, required this.registrations});

  final List<Map<String, dynamic>> tickets;
  final List<Map<String, dynamic>> registrations;
}

class _Hero extends StatelessWidget {
  const _Hero({required this.eventCount});

  final int eventCount;

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
          const Icon(Icons.event_note_outlined, color: Colors.white, size: 50),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Events workspace',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$eventCount event(s) under your organiser account.',
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

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(icon, size: 45, color: WantokColors.primary),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
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

String _money(dynamic value) {
  final amount = _toDouble(value);
  return amount == null ? value.toString() : amount.toStringAsFixed(2);
}

String _ticketPrice(Map<String, dynamic> ticket) {
  final price = _toDouble(ticket['price']) ?? 0;
  return price == 0 ? 'FREE' : 'PGK ${price.toStringAsFixed(2)}';
}

String _formatDateTime(dynamic value) {
  final date = value is DateTime
      ? value
      : DateTime.parse(value.toString()).toLocal();
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.day}/${date.month}/${date.year} $hour:$minute';
}
