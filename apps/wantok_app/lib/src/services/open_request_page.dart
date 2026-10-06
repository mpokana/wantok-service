import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_core/wantok_core.dart';
import 'package:wantok_ui/wantok_ui.dart';

import 'booking_for_selector.dart';

class OpenRequestPage extends StatefulWidget {
  const OpenRequestPage({required this.category, super.key});

  final WantokServiceCategory category;

  @override
  State<OpenRequestPage> createState() => _OpenRequestPageState();
}

class _OpenRequestPageState extends State<OpenRequestPage> {
  static const _repository = OpenRequestRepository();

  final _serviceAddressController = TextEditingController();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _notesController = TextEditingController();
  final _budgetController = TextEditingController();

  DateTime? _scheduledStart;
  String? _trustedPersonId;
  bool _busy = false;
  String? _error;

  bool get _isDelivery => widget.category.slug == 'delivery';

  @override
  void dispose() {
    _serviceAddressController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _notesController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _chooseSchedule() async {
    final now = DateTime.now();
    final initial = _scheduledStart ?? now.add(const Duration(hours: 2));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;

    setState(() {
      _scheduledStart = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_isDelivery &&
        (_originController.text.trim().isEmpty ||
            _destinationController.text.trim().isEmpty)) {
      setState(() {
        _error = 'Delivery needs both a pickup and destination location.';
      });
      return;
    }

    if (!_isDelivery && _serviceAddressController.text.trim().isEmpty) {
      setState(() => _error = 'Enter where the service is needed.');
      return;
    }

    if (_notesController.text.trim().isEmpty) {
      setState(() => _error = 'Tell vendors what you need.');
      return;
    }

    final budgetText = _budgetController.text.trim();
    final budget = budgetText.isEmpty ? null : double.tryParse(budgetText);
    if (budgetText.isNotEmpty && budget == null) {
      setState(() => _error = 'Enter a valid Kina budget or leave it blank.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _repository.createRequest(
        categorySlug: widget.category.slug,
        serviceAddress: _serviceAddressController.text,
        originAddress: _originController.text,
        destinationAddress: _destinationController.text,
        scheduledStart: _scheduledStart,
        notes: _notesController.text,
        requestedAmount: budget,
        metadata: {
          'client_surface': 'wantok_app',
          'request_kind': widget.category.slug,
        },
        trustedPersonId: _trustedPersonId,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() => _error = _friendlyError(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          _RequestHero(category: widget.category),
          const SizedBox(height: 18),
          Text(
            _isDelivery ? 'Delivery details' : 'Describe the job',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your request is shown only to approved vendors that provide this service.',
            style: TextStyle(color: WantokColors.muted),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 12),
          if (_isDelivery) ...[
            TextField(
              controller: _originController,
              decoration: const InputDecoration(
                labelText: 'Pickup location',
                prefixIcon: Icon(Icons.trip_origin),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'Destination',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
          ] else
            TextField(
              controller: _serviceAddressController,
              decoration: const InputDecoration(
                labelText: 'Service location / area',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: _notesLabel(widget.category.slug),
              hintText: _notesHint(widget.category.slug),
              alignLabelWithHint: true,
              prefixIcon: const Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _budgetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Budget in Kina / K (optional)',
              hintText: 'Leave blank to receive quotes',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              onTap: _chooseSchedule,
              leading: const Icon(
                Icons.schedule_outlined,
                color: WantokColors.primary,
              ),
              title: const Text(
                'When do you need it?',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                _scheduledStart == null
                    ? 'As soon as possible'
                    : _formatDateTime(_scheduledStart!),
              ),
              trailing: const Icon(Icons.edit_calendar_outlined),
            ),
          ),
          if (_scheduledStart != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _scheduledStart = null),
                child: const Text('Use ASAP instead'),
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _busy ? null : _submit,
            icon: const Icon(Icons.campaign_outlined),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Text(_busy ? 'Posting request...' : 'Post request'),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Posting a request does not charge you. Qualified vendors can respond with a quote, and you choose whether to accept it.',
            textAlign: TextAlign.center,
            style: TextStyle(color: WantokColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RequestHero extends StatelessWidget {
  const _RequestHero({required this.category});

  final WantokServiceCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [WantokColors.primaryDark, WantokColors.primary],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(19),
            ),
            child: Icon(_iconFor(category.slug), color: Colors.white, size: 33),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _heroText(category.slug),
                  style: const TextStyle(
                    color: Color(0xFFD9F3E5),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _iconFor(String slug) => switch (slug) {
  'delivery' => Icons.local_shipping_outlined,
  'errands' => Icons.shopping_bag_outlined,
  'specialist-services' => Icons.handyman_outlined,
  'general-labour' => Icons.groups_outlined,
  _ => Icons.work_outline,
};

String _heroText(String slug) => switch (slug) {
  'delivery' => 'Tell us where to collect and deliver. Approved couriers can quote the job.',
  'errands' =>
    'Ask a Wantok to buy, collect, queue or complete a practical task for you.',
  'specialist-services' =>
    'Find electricians, plumbers, ICT, builders and other skilled providers.',
  'general-labour' =>
    'Post short-term work and connect with approved people available to help.',
  _ =>
    'Post what you need and receive responses from approved local providers.',
};

String _notesLabel(String slug) => switch (slug) {
  'delivery' => 'What is being delivered?',
  'errands' => 'What should the Wantok do?',
  'specialist-services' => 'What work do you need?',
  'general-labour' => 'Describe the work',
  _ => 'Request details',
};

String _notesHint(String slug) => switch (slug) {
  'delivery' => 'Parcel type, size, contact person, handling instructions...',
  'errands' =>
    'What to buy or collect, where to go, quantities and instructions...',
  'specialist-services' =>
    'Describe the fault, installation, project or specialist help required...',
  'general-labour' =>
    'Number of people, type of work, expected hours and any tools needed...',
  _ => 'Give providers enough detail to quote accurately.',
};

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}

String _friendlyError(Object error) {
  final text = error.toString();
  const marker = 'message: ';
  final markerIndex = text.indexOf(marker);
  if (markerIndex >= 0) {
    return text.substring(markerIndex + marker.length).replaceAll(')', '');
  }
  return text.replaceFirst('StateError: ', '');
}
