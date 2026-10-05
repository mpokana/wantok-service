import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

import 'messages_page.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  static const _repository = ReservationRepository();
  static const _messaging = MessagingRepository();
  late Future<List<Map<String, dynamic>>> _future;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _future = _repository.loadMyReservations();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _repository.loadMyReservations();
    });
    await _future;
  }

  Future<void> _run(String bookingId, Future<void> Function() action) async {
    setState(() => _busyId = bookingId);
    try {
      await action();
      await _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _openConversation({
    required String bookingId,
    required String providerName,
    required String categoryName,
  }) async {
    setState(() => _busyId = bookingId);
    try {
      final threadId = await _messaging.ensureForBooking(bookingId);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => ConversationPage(
            threadId: threadId,
            title: providerName,
            subtitle: categoryName,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.error_outline,
                      color: WantokColors.coral,
                    ),
                    title: const Text('Could not load your activity'),
                    subtitle: Text(snapshot.error.toString()),
                    trailing: IconButton(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                ),
              ],
            );
          }

          final rows = snapshot.data ?? const <Map<String, dynamic>>[];
          if (rows.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(28),
              children: const [
                SizedBox(height: 90),
                Icon(
                  Icons.receipt_long_outlined,
                  size: 58,
                  color: WantokColors.primary,
                ),
                SizedBox(height: 14),
                Text(
                  'No activity yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 7),
                Text(
                  'Your service requests, reservations and completed bookings will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: WantokColors.muted),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 11),
            itemBuilder: (context, index) {
              final row = rows[index];
              final id = row['id'] as String;
              final status = row['status'] as String? ?? 'unknown';
              final category = _asMap(row['service_categories']);
              final provider = _asMap(row['provider_profiles']);
              final resource = _asMap(row['provider_resources']);
              final quotes = _asList(row['service_quotes']);
              final pendingQuote = quotes
                  .cast<Map<String, dynamic>?>()
                  .firstWhere(
                    (quote) => quote?['status'] == 'pending',
                    orElse: () => null,
                  );
              final busy = _busyId == id;
              final amount =
                  row['final_amount'] ??
                  row['quoted_amount'] ??
                  row['requested_amount'];

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              category['name'] as String? ?? 'Wantok Service',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          _StatusChip(status: status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (resource['name'] != null)
                        Text(
                          resource['name'] as String,
                          style: const TextStyle(
                            color: WantokColors.primaryDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      if (provider['display_name'] != null)
                        Text('Provider: ${provider['display_name']}'),
                      if (row['scheduled_start'] != null)
                        Text(
                          'When: ${_formatRange(row['scheduled_start'], row['scheduled_end'])}',
                        ),
                      if (row['service_address'] != null)
                        Text('Location: ${row['service_address']}'),
                      if (row['origin_address'] != null)
                        Text('Pickup: ${row['origin_address']}'),
                      if (row['destination_address'] != null)
                        Text('Destination: ${row['destination_address']}'),
                      if (amount != null)
                        Text(
                          'Amount: ${row['currency'] ?? 'PGK'} $amount',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      if (pendingQuote != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7E3),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.request_quote_outlined,
                                color: WantokColors.primaryDark,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  'Vendor quote: ${pendingQuote['currency'] ?? 'PGK'} ${pendingQuote['amount']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              FilledButton(
                                onPressed: busy
                                    ? null
                                    : () => _run(
                                        id,
                                        () => _repository.acceptQuote(
                                          pendingQuote['id'] as String,
                                        ),
                                      ),
                                child: const Text('Accept'),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (provider.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: busy
                                ? null
                                : () => _openConversation(
                                    bookingId: id,
                                    providerName:
                                        provider['display_name'] as String? ??
                                        'Wantok Provider',
                                    categoryName:
                                        category['name'] as String? ??
                                        'Wantok Service',
                                  ),
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Message provider'),
                          ),
                        ),
                      ],
                      if (_canCancel(status)) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: busy
                                ? null
                                : () => _run(
                                    id,
                                    () => _repository.cancelBooking(id),
                                  ),
                            icon: const Icon(Icons.cancel_outlined),
                            label: Text(busy ? 'Working...' : 'Cancel request'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final background = switch (status) {
      'confirmed' || 'completed' => const Color(0xFFDFF2E7),
      'cancelled' || 'rejected' => const Color(0xFFFFE7E1),
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

bool _canCancel(String status) =>
    const {'requested', 'quoted', 'accepted', 'confirmed'}.contains(status);

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  if (value is List<dynamic>) return value;
  return const <dynamic>[];
}

String _formatRange(dynamic startValue, dynamic endValue) {
  final start = DateTime.tryParse(startValue?.toString() ?? '')?.toLocal();
  final end = DateTime.tryParse(endValue?.toString() ?? '')?.toLocal();
  if (start == null) return 'Not scheduled';

  final startText = _formatDateTime(start);
  if (end == null) return startText;
  return '$startText – ${_formatDateTime(end)}';
}

String _formatDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/${value.year} $hour:$minute';
}

String _friendlyError(Object error) =>
    error.toString().replaceFirst('StateError: ', '');
