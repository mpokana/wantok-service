import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

import '../client_load_error.dart';

import 'booking_for_selector.dart';
import 'event_registrations_page.dart';

class EventBrowsePage extends StatefulWidget {
  const EventBrowsePage({super.key});

  @override
  State<EventBrowsePage> createState() => _EventBrowsePageState();
}

class _EventBrowsePageState extends State<EventBrowsePage> {
  static const _repository = EventsRepository();
  static const _experience = ClientExperienceRepository();

  late Future<List<Map<String, dynamic>>> _future;
  final Set<String> _savedEventIds = <String>{};
  final Set<String> _savingEventIds = <String>{};

  @override
  void initState() {
    super.initState();
    _future = _repository.loadUpcomingEvents();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedEvents();
    });
  }

  Future<void> _loadSavedEvents() async {
    try {
      final ids = await _experience.loadSavedIds('event');
      if (!mounted) return;
      setState(() {
        _savedEventIds
          ..clear()
          ..addAll(ids);
      });
    } catch (_) {
      // Saving is optional; event browsing remains available.
    }
  }

  Future<void> _toggleSavedEvent(String eventId) async {
    if (_savingEventIds.contains(eventId)) return;
    final wasSaved = _savedEventIds.contains(eventId);
    setState(() => _savingEventIds.add(eventId));
    try {
      await _experience.setSavedItem(
        itemType: 'event',
        entityId: eventId,
        saved: !wasSaved,
      );
      if (!mounted) return;
      setState(() {
        if (wasSaved) {
          _savedEventIds.remove(eventId);
        } else {
          _savedEventIds.add(eventId);
        }
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('StateError: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingEventIds.remove(eventId));
    }
  }

  Future<void> _refresh() async {
    final next = _repository.loadUpcomingEvents();
    setState(() {
      _future = next;
    });
    try {
      await next;
      await _loadSavedEvents();
    } catch (_) {
      // The FutureBuilder presents the retryable error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            tooltip: 'My registrations',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const EventRegistrationsPage(),
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
                title: 'Could not load events',
                onRetry: _refresh,
              );
            }

            final events = snapshot.data ?? const <Map<String, dynamic>>[];
            if (events.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 100),
                  Icon(
                    Icons.event_outlined,
                    size: 58,
                    color: WantokColors.primary,
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: Text(
                      'No upcoming events yet',
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
                const _EventsHero(),
                const SizedBox(height: 18),
                ...events.map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _EventCard(
                      event: event,
                      isSaved: _savedEventIds.contains(event['id']),
                      busy: _savingEventIds.contains(event['id']),
                      onSavedToggle: () =>
                          _toggleSavedEvent(event['id'] as String),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => _EventDetailPage(event: event),
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

class _EventDetailPage extends StatefulWidget {
  const _EventDetailPage({required this.event});

  final Map<String, dynamic> event;

  @override
  State<_EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<_EventDetailPage> {
  static const _repository = EventsRepository();
  late Future<List<Map<String, dynamic>>> _tickets;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tickets = _repository.loadTicketTypes(widget.event['id'] as String);
  }

  Future<void> _register(Map<String, dynamic> ticket) async {
    final draft = await showDialog<_RegistrationDraft>(
      context: context,
      builder: (context) => _RegistrationDialog(ticket: ticket),
    );
    if (draft == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _repository.register(
        eventId: widget.event['id'] as String,
        ticketTypeId: ticket['id'] as String,
        quantity: draft.quantity,
        attendeeName: draft.name,
        attendeeContact: draft.contact,
        note: draft.note,
        trustedPersonId: draft.trustedPersonId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event registration reserved.')),
      );
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => const EventRegistrationsPage(),
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
    final event = widget.event;
    final organiser = _asMap(event['provider_profiles']);

    return Scaffold(
      appBar: AppBar(title: Text(event['title'].toString())),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(19),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title'].toString(),
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.schedule_outlined,
                    text: _formatDateTime(event['starts_at']),
                  ),
                  if (event['venue_name'] != null) ...[
                    const SizedBox(height: 7),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      text:
                          event['venue_name'].toString() +
                          (event['venue_address'] == null
                              ? ''
                              : ' • ${event['venue_address']}'),
                    ),
                  ],
                  if (organiser['display_name'] != null) ...[
                    const SizedBox(height: 7),
                    _InfoRow(
                      icon: Icons.business_outlined,
                      text: 'Organiser: ${organiser['display_name']}',
                    ),
                  ],
                  if (event['description'] != null) ...[
                    const Divider(height: 26),
                    Text(event['description'].toString()),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Tickets & registration',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _tickets,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final tickets = snapshot.data ?? const <Map<String, dynamic>>[];
              if (tickets.isEmpty) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Registration not available yet'),
                    subtitle: Text(
                      'The organiser has not published a ticket or registration type.',
                    ),
                  ),
                );
              }

              return Column(
                children: tickets
                    .map((ticket) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(14),
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFE7F4ED),
                              child: Icon(
                                Icons.confirmation_number_outlined,
                                color: WantokColors.primary,
                              ),
                            ),
                            title: Text(
                              ticket['name'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            subtitle: ticket['description'] == null
                                ? null
                                : Text(ticket['description'].toString()),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _ticketPrice(ticket),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: WantokColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'REGISTER',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            onTap: _busy ? null : () => _register(ticket),
                          ),
                        ),
                      );
                    })
                    .toList(growable: false),
              );
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'Paid tickets are reserved as unpaid until Wantok Payments is connected. Free registrations need no payment.',
            style: TextStyle(color: WantokColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RegistrationDialog extends StatefulWidget {
  const _RegistrationDialog({required this.ticket});

  final Map<String, dynamic> ticket;

  @override
  State<_RegistrationDialog> createState() => _RegistrationDialogState();
}

class _RegistrationDialogState extends State<_RegistrationDialog> {
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _note = TextEditingController();
  int _quantity = 1;
  String? _trustedPersonId;

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final price = _toDouble(widget.ticket['price']) ?? 0;
    final total = price * _quantity;

    return AlertDialog(
      title: Text(widget.ticket['name'].toString()),
      content: SizedBox(
        width: 430,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(child: Text('Quantity')),
                  IconButton(
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    _quantity.toString(),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  IconButton(
                    onPressed: _quantity < 20
                        ? () => setState(() => _quantity++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              BookingForSelector(
                selectedTrustedPersonId: _trustedPersonId,
                onChanged: (value) {
                  setState(() {
                    _trustedPersonId = value;
                  });
                },
              ),
              if (_trustedPersonId == null) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Attendee name (optional)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _contact,
                  decoration: const InputDecoration(
                    labelText: 'Contact (optional)',
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  _quantity > 1
                      ? 'The selected Trusted person will be the primary attendee for this $_quantity-ticket registration.'
                      : 'The selected Trusted person will be the attendee for this registration.',
                  style: const TextStyle(
                    color: WantokColors.muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: _note,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 14),
              Text(
                price == 0
                    ? 'Free registration'
                    : 'Total: K${total.toStringAsFixed(2)} • payment pending',
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
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            _RegistrationDraft(
              quantity: _quantity,
              name: _name.text,
              contact: _contact.text,
              note: _note.text,
              trustedPersonId: _trustedPersonId,
            ),
          ),
          child: const Text('Reserve'),
        ),
      ],
    );
  }
}

class _RegistrationDraft {
  const _RegistrationDraft({
    required this.quantity,
    required this.name,
    required this.contact,
    required this.note,
    required this.trustedPersonId,
  });

  final int quantity;
  final String name;
  final String contact;
  final String note;
  final String? trustedPersonId;
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.isSaved,
    required this.busy,
    required this.onSavedToggle,
    required this.onTap,
  });

  final Map<String, dynamic> event;
  final bool isSaved;
  final bool busy;
  final VoidCallback onSavedToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final organiser = _asMap(event['provider_profiles']);
    final start = DateTime.parse(event['starts_at'].toString()).toLocal();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 62,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F4ED),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      _month(start.month),
                      style: const TextStyle(
                        color: WantokColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      start.day.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['title'].toString(),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(event['starts_at']),
                      style: const TextStyle(
                        color: WantokColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (event['venue_name'] != null)
                      Text(
                        event['venue_name'].toString(),
                        style: const TextStyle(color: WantokColors.muted),
                      ),
                    if (organiser['display_name'] != null)
                      Text(
                        organiser['display_name'].toString(),
                        style: const TextStyle(
                          color: WantokColors.muted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: isSaved ? 'Remove event from Saved' : 'Save event',
                    onPressed: busy ? null : onSavedToggle,
                    icon: busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: isSaved
                                ? WantokColors.primary
                                : WantokColors.muted,
                          ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventsHero extends StatelessWidget {
  const _EventsHero();

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
          Icon(Icons.event_available, color: Colors.white, size: 50),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What is happening?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Discover approved local events and register from your Wantok account.',
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

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

String _ticketPrice(Map<String, dynamic> ticket) {
  final price = _toDouble(ticket['price']) ?? 0;
  if (price == 0) return 'FREE';
  return 'K${price.toStringAsFixed(2)}';
}

String _formatDateTime(dynamic value) {
  final date = DateTime.parse(value.toString()).toLocal();
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.day} ${_month(date.month)} ${date.year} • $hour:$minute';
}

String _month(int month) => const [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
][month - 1];

String _friendlyError(Object error) {
  final text = error.toString();
  const marker = 'message: ';
  final index = text.indexOf(marker);
  if (index >= 0) {
    return text.substring(index + marker.length).replaceAll(')', '');
  }
  return text.replaceFirst('StateError: ', '');
}
