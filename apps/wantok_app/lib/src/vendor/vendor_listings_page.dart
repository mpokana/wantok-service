import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

class VendorListingsPage extends StatefulWidget {
  const VendorListingsPage({super.key});

  @override
  State<VendorListingsPage> createState() => _VendorListingsPageState();
}

class _VendorListingsPageState extends State<VendorListingsPage> {
  static const _repository = ReservationRepository();
  late Future<_VendorCatalogue> _future;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_VendorCatalogue> _load() async {
    final values = await Future.wait([
      _repository.loadVendorServices(),
      _repository.loadVendorResources(),
    ]);
    return _VendorCatalogue(services: values[0], resources: values[1]);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _editService(Map<String, dynamic> service) async {
    final draft = await showDialog<_ServiceDraft>(
      context: context,
      builder: (context) => _ServiceEditorDialog(service: service),
    );
    if (draft == null) return;

    final id = service['id'] as String;
    await _run(
      id,
      () => _repository.updateVendorService(
        serviceId: id,
        title: draft.title,
        description: draft.description,
        pricingModel: draft.pricingModel,
        basePrice: draft.basePrice,
        unitLabel: draft.unitLabel,
        serviceAddress: draft.address,
      ),
    );
  }

  Future<void> _addResource(List<Map<String, dynamic>> services) async {
    final eligible = services.where((service) {
      final category = _asMap(service['service_categories']);
      return const {'vehicle-hire', 'boat-hire', 'venue-booking'}
          .contains(category['slug']);
    }).toList();

    if (eligible.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You need a Vehicle Hire, Boat Hire or Venue Booking service before adding a reservable resource.',
          ),
        ),
      );
      return;
    }

    final draft = await showDialog<_ResourceDraft>(
      context: context,
      builder: (context) => _ResourceEditorDialog(services: eligible),
    );
    if (draft == null) return;

    await _run(
      'new-resource',
      () => _repository.createVendorResource(
        categoryId: draft.categoryId,
        resourceType: draft.resourceType,
        name: draft.name,
        description: draft.description,
        capacity: draft.capacity,
        address: draft.address,
      ),
    );
  }

  Future<void> _editResource(
    Map<String, dynamic> resource,
    List<Map<String, dynamic>> services,
  ) async {
    final draft = await showDialog<_ResourceDraft>(
      context: context,
      builder: (context) => _ResourceEditorDialog(
        services: services,
        resource: resource,
      ),
    );
    if (draft == null) return;

    final id = resource['id'] as String;
    await _run(
      id,
      () => _repository.updateVendorResource(
        resourceId: id,
        resourceType: draft.resourceType,
        name: draft.name,
        description: draft.description,
        capacity: draft.capacity,
        address: draft.address,
      ),
    );
  }

  Future<void> _blockTime(Map<String, dynamic> resource) async {
    final draft = await showDialog<_BlockTimeDraft>(
      context: context,
      builder: (context) =>
          _BlockTimeDialog(resourceName: resource['name'] as String? ?? 'Resource'),
    );
    if (draft == null) return;

    final id = resource['id'] as String;
    await _run(
      id,
      () => _repository.blockResourceTime(
        resourceId: id,
        startsAt: draft.startsAt,
        endsAt: draft.endsAt,
        reason: draft.reason,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<_VendorCatalogue>(
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
                    title: const Text('Could not load vendor catalogue'),
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

          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'My services',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const Text(
                'Configure the service first, then submit it for admin review.',
                style: TextStyle(color: WantokColors.muted),
              ),
              const SizedBox(height: 12),
              if (data.services.isEmpty)
                const _EmptyCard(
                  icon: Icons.storefront_outlined,
                  message:
                      'No provider services are attached to this account yet.',
                )
              else
                ...data.services.map(
                  (service) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ServiceCard(
                      service: service,
                      busy: _busyId == service['id'],
                      onEdit: () => _editService(service),
                      onSubmit: () => _run(
                        service['id'] as String,
                        () => _repository.submitVendorService(
                          service['id'] as String,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Vehicles, boats & venues',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _addResource(data.services),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const Text(
                'Each physical asset or venue is approved separately and protected from confirmed double-bookings.',
                style: TextStyle(color: WantokColors.muted),
              ),
              const SizedBox(height: 12),
              if (data.resources.isEmpty)
                const _EmptyCard(
                  icon: Icons.event_available_outlined,
                  message: 'No reservable resources have been added yet.',
                )
              else
                ...data.resources.map(
                  (resource) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ResourceCard(
                      resource: resource,
                      busy: _busyId == resource['id'],
                      onEdit: () => _editResource(resource, data.services),
                      onSubmit: () => _run(
                        resource['id'] as String,
                        () => _repository.submitVendorResource(
                          resource['id'] as String,
                        ),
                      ),
                      onBlockTime: () => _blockTime(resource),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.busy,
    required this.onEdit,
    required this.onSubmit,
  });

  final Map<String, dynamic> service;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final category = _asMap(service['service_categories']);
    final status = service['status'] as String? ?? 'draft';
    final editable = const {'draft', 'rejected'}.contains(status);
    final price = service['base_price'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    service['title'] as String? ?? 'Untitled service',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              category['name'] as String? ?? 'Service',
              style: const TextStyle(color: WantokColors.primaryDark),
            ),
            if (price != null)
              Text(
                '${service['currency'] ?? 'PGK'} $price • ${service['pricing_model'] ?? 'quote'}',
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (editable)
                  OutlinedButton.icon(
                    onPressed: busy ? null : onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                if (editable)
                  FilledButton.icon(
                    onPressed: busy ? null : onSubmit,
                    icon: const Icon(Icons.verified_outlined),
                    label: Text(busy ? 'Working...' : 'Submit for review'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({
    required this.resource,
    required this.busy,
    required this.onEdit,
    required this.onSubmit,
    required this.onBlockTime,
  });

  final Map<String, dynamic> resource;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onSubmit;
  final VoidCallback onBlockTime;

  @override
  Widget build(BuildContext context) {
    final category = _asMap(resource['service_categories']);
    final status = resource['status'] as String? ?? 'draft';
    final editable = const {'draft', 'rejected'}.contains(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  color: WantokColors.primary,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    resource['name'] as String? ?? 'Resource',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${category['name'] ?? 'Service'} • ${resource['resource_type'] ?? 'resource'}',
            ),
            if (resource['capacity'] != null)
              Text('Capacity: ${resource['capacity']}'),
            if (resource['address_text'] != null)
              Text('Location: ${resource['address_text']}'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (editable)
                  OutlinedButton.icon(
                    onPressed: busy ? null : onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                if (editable)
                  FilledButton.icon(
                    onPressed: busy ? null : onSubmit,
                    icon: const Icon(Icons.verified_outlined),
                    label: Text(busy ? 'Working...' : 'Submit for review'),
                  ),
                if (status == 'active')
                  OutlinedButton.icon(
                    onPressed: busy ? null : onBlockTime,
                    icon: const Icon(Icons.event_busy_outlined),
                    label: const Text('Block time'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceEditorDialog extends StatefulWidget {
  const _ServiceEditorDialog({required this.service});

  final Map<String, dynamic> service;

  @override
  State<_ServiceEditorDialog> createState() => _ServiceEditorDialogState();
}

class _ServiceEditorDialogState extends State<_ServiceEditorDialog> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _unit;
  late final TextEditingController _address;
  late String _pricingModel;

  static const _pricingModels = [
    'quote',
    'fixed',
    'hourly',
    'daily',
    'per_job',
    'per_person',
    'per_km',
    'free',
  ];

  @override
  void initState() {
    super.initState();
    final service = widget.service;
    _title = TextEditingController(text: service['title']?.toString() ?? '');
    _description =
        TextEditingController(text: service['description']?.toString() ?? '');
    _price = TextEditingController(text: service['base_price']?.toString() ?? '');
    _unit = TextEditingController(text: service['unit_label']?.toString() ?? '');
    _address =
        TextEditingController(text: service['service_address']?.toString() ?? '');
    _pricingModel = service['pricing_model']?.toString() ?? 'quote';
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _unit.dispose();
    _address.dispose();
    super.dispose();
  }

  void _submit() {
    if (_title.text.trim().isEmpty) return;
    final basePrice =
        _price.text.trim().isEmpty ? null : double.tryParse(_price.text.trim());
    Navigator.of(context).pop(
      _ServiceDraft(
        title: _title.text.trim(),
        description: _description.text.trim(),
        pricingModel: _pricingModel,
        basePrice: basePrice,
        unitLabel: _unit.text.trim(),
        address: _address.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit service'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Service title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _description,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _pricingModel,
                decoration: const InputDecoration(labelText: 'Pricing model'),
                items: _pricingModels
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.replaceAll('_', ' ')),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _pricingModel = value);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _price,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Base price (PGK)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _unit,
                decoration: const InputDecoration(
                  labelText: 'Unit label',
                  hintText: 'day, hour, trip, person',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Service address'),
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
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

class _ResourceEditorDialog extends StatefulWidget {
  const _ResourceEditorDialog({
    required this.services,
    this.resource,
  });

  final List<Map<String, dynamic>> services;
  final Map<String, dynamic>? resource;

  @override
  State<_ResourceEditorDialog> createState() => _ResourceEditorDialogState();
}

class _ResourceEditorDialogState extends State<_ResourceEditorDialog> {
  late String _categoryId;
  late final TextEditingController _type;
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _capacity;
  late final TextEditingController _address;

  @override
  void initState() {
    super.initState();
    final resource = widget.resource;
    _categoryId = resource?['category_id'] as String? ??
        widget.services.first['category_id'] as String;
    _type = TextEditingController(
      text: resource?['resource_type']?.toString() ?? '',
    );
    _name = TextEditingController(text: resource?['name']?.toString() ?? '');
    _description =
        TextEditingController(text: resource?['description']?.toString() ?? '');
    _capacity =
        TextEditingController(text: resource?['capacity']?.toString() ?? '');
    _address =
        TextEditingController(text: resource?['address_text']?.toString() ?? '');
  }

  @override
  void dispose() {
    _type.dispose();
    _name.dispose();
    _description.dispose();
    _capacity.dispose();
    _address.dispose();
    super.dispose();
  }

  void _submit() {
    if (_type.text.trim().isEmpty || _name.text.trim().isEmpty) return;
    Navigator.of(context).pop(
      _ResourceDraft(
        categoryId: _categoryId,
        resourceType: _type.text.trim(),
        name: _name.text.trim(),
        description: _description.text.trim(),
        capacity: int.tryParse(_capacity.text.trim()),
        address: _address.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.resource == null ? 'Add resource' : 'Edit resource'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Service'),
                items: widget.services.map((service) {
                  final category = _asMap(service['service_categories']);
                  return DropdownMenuItem(
                    value: service['category_id'] as String,
                    child: Text(category['name'] as String? ?? 'Service'),
                  );
                }).toList(),
                onChanged: widget.resource == null
                    ? (value) {
                        if (value != null) setState(() => _categoryId = value);
                      }
                    : null,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _type,
                decoration: const InputDecoration(
                  labelText: 'Resource type',
                  hintText: '4wd, dinghy, hall, conference room...',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Toyota Hilux, MV Example, Main Hall...',
                ),
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
                controller: _capacity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Capacity'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Location'),
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
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

class _BlockTimeDialog extends StatefulWidget {
  const _BlockTimeDialog({required this.resourceName});

  final String resourceName;

  @override
  State<_BlockTimeDialog> createState() => _BlockTimeDialogState();
}

class _BlockTimeDialogState extends State<_BlockTimeDialog> {
  late DateTime _start;
  late DateTime _end;
  final _reason = TextEditingController();

  @override
  void initState() {
    super.initState();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _start = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8);
    _end = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 17);
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Block ${widget.resourceName}'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              onTap: () async {
                final value = await _pick(_start);
                if (value != null) setState(() => _start = value);
              },
              title: const Text('From'),
              subtitle: Text(_formatDateTime(_start)),
              trailing: const Icon(Icons.edit_calendar_outlined),
            ),
            ListTile(
              onTap: () async {
                final value = await _pick(_end);
                if (value != null) setState(() => _end = value);
              },
              title: const Text('Until'),
              subtitle: Text(_formatDateTime(_end)),
              trailing: const Icon(Icons.edit_calendar_outlined),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reason,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Maintenance, private booking, unavailable...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: !_end.isAfter(_start)
              ? null
              : () => Navigator.of(context).pop(
                    _BlockTimeDraft(
                      startsAt: _start,
                      endsAt: _end,
                      reason: _reason.text.trim(),
                    ),
                  ),
          child: const Text('Block time'),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final background = switch (status) {
      'active' => const Color(0xFFDFF2E7),
      'rejected' => const Color(0xFFFFE7E1),
      'pending_review' => const Color(0xFFFFF2D2),
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

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(icon, size: 44, color: WantokColors.primary),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: WantokColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _VendorCatalogue {
  const _VendorCatalogue({required this.services, required this.resources});

  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> resources;
}

class _ServiceDraft {
  const _ServiceDraft({
    required this.title,
    required this.description,
    required this.pricingModel,
    required this.basePrice,
    required this.unitLabel,
    required this.address,
  });

  final String title;
  final String description;
  final String pricingModel;
  final double? basePrice;
  final String unitLabel;
  final String address;
}

class _ResourceDraft {
  const _ResourceDraft({
    required this.categoryId,
    required this.resourceType,
    required this.name,
    required this.description,
    required this.capacity,
    required this.address,
  });

  final String categoryId;
  final String resourceType;
  final String name;
  final String description;
  final int? capacity;
  final String address;
}

class _BlockTimeDraft {
  const _BlockTimeDraft({
    required this.startsAt,
    required this.endsAt,
    required this.reason,
  });

  final DateTime startsAt;
  final DateTime endsAt;
  final String reason;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

String _formatDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/${value.year} $hour:$minute';
}
