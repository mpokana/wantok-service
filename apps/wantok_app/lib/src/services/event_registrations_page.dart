import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

import '../client_load_error.dart';

class EventRegistrationsPage extends StatefulWidget {
  const EventRegistrationsPage({super.key});

  @override
  State<EventRegistrationsPage> createState() => _EventRegistrationsPageState();
}

class _EventRegistrationsPageState extends State<EventRegistrationsPage> {
  static const _repository = EventsRepository();
  late Future<List<Map<String, dynamic>>> _future;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _future = _repository.loadMyRegistrations();
  }

  Future<void> _refresh() async {
    final next = _repository.loadMyRegistrations();
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
      await _repository.cancelRegistration(id);
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
      appBar: AppBar(title: const Text('My Event Registrations')),
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
                title: 'Could not load your event registrations',
                onRetry: _refresh,
              );
            }

            final rows = snapshot.data ?? const <Map<String, dynamic>>[];
            if (rows.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 110),
                  Icon(
                    Icons.confirmation_number_outlined,
                    size: 58,
                    color: WantokColors.primary,
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: Text(
                      'No event registrations yet',
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
                final row = rows[index];
                final event = _asMap(row['events']);
                final ticket = _asMap(row['event_ticket_types']);
                final id = row['id'] as String;
                final status = row['status'].toString();

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
                                  event['title']?.toString() ?? 'Event',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              _Status(text: status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ticket['name']?.toString() ?? 'Registration',
                            style: const TextStyle(
                              color: WantokColors.primaryDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          if (row['attendee_name'] != null) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F6F3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.person_pin_circle_outlined,
                                    color: WantokColors.primaryDark,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      row['trusted_person_id'] != null
                                          ? 'For: ${row['attendee_name']}${row['attendee_relationship'] == null ? '' : ' (${row['attendee_relationship']})'}'
                                          : 'Attendee: ${row['attendee_name']}',
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
                          if (event['starts_at'] != null)
                            Text(_formatDateTime(event['starts_at'])),
                          if (event['venue_name'] != null)
                            Text(
                              event['venue_name'].toString(),
                              style: const TextStyle(color: WantokColors.muted),
                            ),
                          const Divider(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${row['quantity']} ticket(s) • ${row['payment_status']}',
                                  style: const TextStyle(
                                    color: WantokColors.muted,
                                  ),
                                ),
                              ),
                              Text(
                                _amount(row),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          if (status == 'reserved') ...[
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: _busyId == id
                                  ? null
                                  : () => _cancel(id),
                              icon: const Icon(Icons.cancel_outlined),
                              label: Text(
                                _busyId == id
                                    ? 'Cancelling...'
                                    : 'Cancel registration',
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

String _amount(Map<String, dynamic> row) {
  final amount = _toDouble(row['total_amount']) ?? 0;
  return amount == 0 ? 'FREE' : 'K${amount.toStringAsFixed(2)}';
}

String _formatDateTime(dynamic value) {
  final date = DateTime.parse(value.toString()).toLocal();
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.day}/${date.month}/${date.year} $hour:$minute';
}
