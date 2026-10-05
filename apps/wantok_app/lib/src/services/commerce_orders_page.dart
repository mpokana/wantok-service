import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

class CommerceOrdersPage extends StatefulWidget {
  const CommerceOrdersPage({super.key});

  @override
  State<CommerceOrdersPage> createState() => _CommerceOrdersPageState();
}

class _CommerceOrdersPageState extends State<CommerceOrdersPage> {
  static const _repository = CommerceRepository();
  late Future<List<Map<String, dynamic>>> _future;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _future = _repository.loadMyOrders();
  }

  Future<void> _refresh() async {
    setState(() => _future = _repository.loadMyOrders());
    await _future;
  }

  Future<void> _cancel(String orderId) async {
    setState(() => _busyId = orderId);
    try {
      await _repository.cancelOrder(orderId, reason: 'Cancelled by customer');
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
      appBar: AppBar(title: const Text('My Food & Shop Orders')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final orders = snapshot.data ?? const <Map<String, dynamic>>[];
            if (orders.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 110),
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 58,
                    color: WantokColors.primary,
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: Text(
                      'No commerce orders yet',
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
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final service = _asMap(order['provider_services']);
                final category = _asMap(order['service_categories']);
                final items =
                    (order['commerce_order_items'] as List<dynamic>? ??
                            const <dynamic>[])
                        .map(_asMap)
                        .toList(growable: false);
                final status = order['status']?.toString() ?? 'placed';
                final id = order['id'] as String;

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
                                  service['title']?.toString() ??
                                      category['name']?.toString() ??
                                      'Order',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              _OrderStatusChip(status: status),
                            ],
                          ),
                          const SizedBox(height: 9),
                          ...items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item['quantity']} × ${item['item_name']}',
                                    ),
                                  ),
                                  Text(
                                    'PGK ${_money(item['line_total'])}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  (order['fulfillment_type'] == 'pickup'
                                          ? 'Pickup'
                                          : 'Delivery') +
                                      (order['delivery_address'] == null
                                          ? ''
                                          : ' • ${order['delivery_address']}'),
                                  style: const TextStyle(
                                    color: WantokColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Text(
                                'PGK ${_money(order['total_amount'])}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: WantokColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _statusText(status),
                            style: const TextStyle(
                              color: WantokColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          if (status == 'placed') ...[
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: _busyId == id
                                  ? null
                                  : () => _cancel(id),
                              icon: const Icon(Icons.cancel_outlined),
                              label: Text(
                                _busyId == id
                                    ? 'Cancelling...'
                                    : 'Cancel order',
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

class _OrderStatusChip extends StatelessWidget {
  const _OrderStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F4ED),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
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

String _money(dynamic value) {
  final amount = _toDouble(value);
  return amount == null ? value.toString() : amount.toStringAsFixed(2);
}

String _statusText(String status) => switch (status) {
  'placed' => 'Waiting for the vendor to accept your order.',
  'accepted' => 'The vendor accepted your order.',
  'preparing' => 'Your order is being prepared.',
  'ready' => 'Your order is ready.',
  'out_for_delivery' => 'Your order is out for delivery.',
  'completed' => 'Order completed.',
  'cancelled' => 'Order cancelled.',
  'rejected' => 'The vendor could not fulfil this order.',
  _ => 'Order status is updating.',
};
