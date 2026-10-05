import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

import '../home/messages_page.dart';

class VendorJobsPage extends StatefulWidget {
  const VendorJobsPage({super.key});

  @override
  State<VendorJobsPage> createState() => _VendorJobsPageState();
}

class _VendorJobsPageState extends State<VendorJobsPage> {
  static const _repository = ReservationRepository();
  static const _messaging = MessagingRepository();
  late Future<List<Map<String, dynamic>>> _future;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _future = _repository.loadVendorBookings();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _repository.loadVendorBookings();
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

  Future<void> _quote(String bookingId) async {
    final draft = await showDialog<_QuoteDraft>(
      context: context,
      builder: (context) => const _QuoteDialog(),
    );
    if (draft == null) return;

    await _run(
      bookingId,
      () => _repository.submitServiceQuote(
        bookingId: bookingId,
        amount: draft.amount,
        message: draft.message,
      ),
    );
  }

  Future<void> _openConversation({
    required String bookingId,
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
            title: 'Customer',
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
                    title: const Text('Could not load vendor jobs'),
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
                Icon(Icons.work_outline, size: 58, color: WantokColors.primary),
                SizedBox(height: 14),
                Text(
                  'No active jobs',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 7),
                Text(
                  'Assigned reservation requests and active bookings will appear here.',
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
              final service = _asMap(row['provider_services']);
              final resource = _asMap(row['provider_resources']);
              final requestedAmount = _toDouble(row['requested_amount']);
              final isOpenRequest = row['provider_id'] == null;
              final busy = _busyId == id;

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
                              category['name'] as String? ?? 'Wantok job',
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
                      Text(
                        resource['name'] as String? ??
                            service['title'] as String? ??
                            'Assigned service',
                        style: const TextStyle(
                          color: WantokColors.primaryDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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
                      if (row['notes'] != null &&
                          row['notes'].toString().trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          row['notes'].toString(),
                          style: const TextStyle(color: WantokColors.muted),
                        ),
                      ],
                      if (requestedAmount != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Requested amount: ${row['currency'] ?? 'PGK'} ${requestedAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: _actionsFor(
                          bookingId: id,
                          categoryName:
                              category['name'] as String? ?? 'Wantok Service',
                          status: status,
                          requestedAmount: requestedAmount,
                          isOpenRequest: isOpenRequest,
                          busy: busy,
                        ),
                      ),
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

  List<Widget> _actionsFor({
    required String bookingId,
    required String categoryName,
    required String status,
    required double? requestedAmount,
    required bool isOpenRequest,
    required bool busy,
  }) {
    final actions = <Widget>[];

    if (!isOpenRequest) {
      actions.add(
        OutlinedButton.icon(
          onPressed: busy
              ? null
              : () => _openConversation(
                  bookingId: bookingId,
                  categoryName: categoryName,
                ),
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Message customer'),
        ),
      );
    }

    if (status == 'requested') {
      if (isOpenRequest) {
        actions.add(
          FilledButton.icon(
            onPressed: busy ? null : () => _quote(bookingId),
            icon: const Icon(Icons.request_quote_outlined),
            label: const Text('Send quote'),
          ),
        );
        return actions;
      }

      actions.add(
        OutlinedButton(
          onPressed: busy
              ? null
              : () => _run(
                  bookingId,
                  () => _repository.respondToBooking(bookingId, false),
                ),
          child: const Text('Reject'),
        ),
      );
      actions.add(
        requestedAmount == null
            ? FilledButton.icon(
                onPressed: busy ? null : () => _quote(bookingId),
                icon: const Icon(Icons.request_quote_outlined),
                label: const Text('Send quote'),
              )
            : FilledButton.icon(
                onPressed: busy
                    ? null
                    : () => _run(
                        bookingId,
                        () => _repository.respondToBooking(bookingId, true),
                      ),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(busy ? 'Working...' : 'Confirm'),
              ),
      );
      return actions;
    }

    if (status == 'quoted') {
      actions.add(
        const Chip(
          avatar: Icon(Icons.hourglass_top, size: 17),
          label: Text('Waiting for client'),
        ),
      );
      return actions;
    }

    if (status == 'confirmed') {
      actions.add(
        FilledButton.icon(
          onPressed: busy
              ? null
              : () => _run(
                  bookingId,
                  () => _repository.advanceBooking(bookingId, 'in_progress'),
                ),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start job'),
        ),
      );
      return actions;
    }

    if (status == 'in_progress') {
      actions.add(
        FilledButton.icon(
          onPressed: busy
              ? null
              : () => _run(
                  bookingId,
                  () => _repository.advanceBooking(bookingId, 'completed'),
                ),
          icon: const Icon(Icons.task_alt),
          label: const Text('Complete'),
        ),
      );
    }

    return actions;
  }
}

class _QuoteDialog extends StatefulWidget {
  const _QuoteDialog();

  @override
  State<_QuoteDialog> createState() => _QuoteDialogState();
}

class _QuoteDialogState extends State<_QuoteDialog> {
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount < 0) {
      setState(() => _error = 'Enter a valid quote amount.');
      return;
    }

    Navigator.of(
      context,
    ).pop(_QuoteDraft(amount: amount, message: _messageController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Send quote'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount (PGK)',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: 'What is included in the quote?',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Send quote')),
      ],
    );
  }
}

class _QuoteDraft {
  const _QuoteDraft({required this.amount, required this.message});

  final double amount;
  final String message;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final background = switch (status) {
      'confirmed' => const Color(0xFFDFF2E7),
      'in_progress' => const Color(0xFFE7F0FF),
      'quoted' => const Color(0xFFFFF2D2),
      _ => const Color(0xFFF2F4F3),
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

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

double? _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

String _formatRange(dynamic startValue, dynamic endValue) {
  final start = DateTime.tryParse(startValue?.toString() ?? '')?.toLocal();
  final end = DateTime.tryParse(endValue?.toString() ?? '')?.toLocal();
  if (start == null) return 'Not scheduled';
  final first = _formatDateTime(start);
  return end == null ? first : '$first – ${_formatDateTime(end)}';
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
