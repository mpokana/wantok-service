import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

class ProviderApplicationPage extends StatefulWidget {
  const ProviderApplicationPage({super.key});

  @override
  State<ProviderApplicationPage> createState() =>
      _ProviderApplicationPageState();
}

class _ProviderApplicationPageState extends State<ProviderApplicationPage> {
  static const _repository = ProviderApplicationRepository();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.loadMyApplications();
  }

  Future<void> _refresh() async {
    setState(() => _future = _repository.loadMyApplications());
    await _future;
  }

  Future<void> _apply(List<Map<String, dynamic>> current) async {
    final blockedTypes = current
        .where((row) => const {'pending', 'approved'}.contains(row['status']))
        .map((row) => row['service_type']?.toString())
        .whereType<String>()
        .toSet();

    final draft = await showDialog<_ApplicationDraft>(
      context: context,
      builder: (context) =>
          _ProviderApplicationDialog(blockedTypes: blockedTypes),
    );
    if (draft == null) return;

    try {
      await _repository.submitApplication(
        serviceType: draft.serviceType,
        companyName: draft.companyName,
        vehiclePlate: draft.vehiclePlate,
        vehicleMake: draft.vehicleMake,
        vehicleModel: draft.vehicleModel,
        vehicleColor: draft.vehicleColor,
        notes: draft.notes,
      );
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Application submitted. Wantok Admin will review it.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor applications')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.error_outline,
                      color: WantokColors.coral,
                    ),
                    title: const Text('Could not load applications'),
                    subtitle: Text(snapshot.error.toString()),
                    trailing: IconButton(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                ),
              ),
            );
          }

          final rows = snapshot.data ?? const <Map<String, dynamic>>[];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [WantokColors.primaryDark, WantokColors.primary],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.all(22),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        color: Colors.white,
                        size: 42,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Earn with Wantok',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Apply for one or more service categories. '
                              'Your client account stays the same; approved '
                              'vendor capabilities are added to it.',
                              style: TextStyle(
                                color: Color(0xFFD9F3E5),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => _apply(rows),
                  icon: const Icon(Icons.add_business_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 13),
                    child: Text('Apply for a service'),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'My applications',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                if (rows.isEmpty)
                  const _EmptyApplications()
                else
                  ...rows.map(
                    (row) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ApplicationCard(row: row),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final type = row['service_type']?.toString() ?? 'provider';
    final status = row['status']?.toString() ?? 'pending';
    final option = _providerOptions.firstWhere(
      (item) => item.serviceType == type,
      orElse: () => _ProviderOption(
        serviceType: type,
        label: _humanise(type),
        icon: Icons.storefront_outlined,
        description: 'Wantok provider service.',
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFE7F4ED),
              child: Icon(option.icon, color: WantokColors.primaryDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          option.label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      _StatusChip(status: status),
                    ],
                  ),
                  if (row['company_name'] != null) ...[
                    const SizedBox(height: 4),
                    Text(row['company_name'].toString()),
                  ],
                  const SizedBox(height: 5),
                  Text(
                    _statusMessage(status),
                    style: const TextStyle(
                      color: WantokColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderApplicationDialog extends StatefulWidget {
  const _ProviderApplicationDialog({required this.blockedTypes});

  final Set<String> blockedTypes;

  @override
  State<_ProviderApplicationDialog> createState() =>
      _ProviderApplicationDialogState();
}

class _ProviderApplicationDialogState
    extends State<_ProviderApplicationDialog> {
  late _ProviderOption _selected;
  final _company = TextEditingController();
  final _notes = TextEditingController();
  final _plate = TextEditingController();
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _colour = TextEditingController();
  String? _error;

  List<_ProviderOption> get _available => _providerOptions
      .where((item) => !widget.blockedTypes.contains(item.serviceType))
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    final available = _available;
    _selected = available.isEmpty ? _providerOptions.first : available.first;
  }

  @override
  void dispose() {
    _company.dispose();
    _notes.dispose();
    _plate.dispose();
    _make.dispose();
    _model.dispose();
    _colour.dispose();
    super.dispose();
  }

  void _submit() {
    if (_available.isEmpty) {
      setState(() {
        _error = 'You already have applications for all available services.';
      });
      return;
    }

    if (_selected.serviceType == 'driver' &&
        (_plate.text.trim().isEmpty ||
            _make.text.trim().isEmpty ||
            _model.text.trim().isEmpty)) {
      setState(() {
        _error =
            'Taxi/driver applications require vehicle plate, make and model.';
      });
      return;
    }

    Navigator.of(context).pop(
      _ApplicationDraft(
        serviceType: _selected.serviceType,
        companyName: _company.text.trim(),
        vehiclePlate: _plate.text.trim(),
        vehicleMake: _make.text.trim(),
        vehicleModel: _model.text.trim(),
        vehicleColor: _colour.text.trim(),
        notes: _notes.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final available = _available;
    return AlertDialog(
      title: const Text('Apply to provide a service'),
      content: SizedBox(
        width: 520,
        child: available.isEmpty
            ? const Text(
                'You already have a pending or approved application for every '
                'currently available provider category.',
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<_ProviderOption>(
                      initialValue: _selected,
                      decoration: const InputDecoration(
                        labelText: 'Service category',
                      ),
                      items: available
                          .map(
                            (option) => DropdownMenuItem(
                              value: option,
                              child: Text(option.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selected = value;
                            _error = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selected.description,
                      style: const TextStyle(
                        color: WantokColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _company,
                      decoration: const InputDecoration(
                        labelText: 'Business / trading name (optional)',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                    ),
                    if (_selected.serviceType == 'driver') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _plate,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle registration',
                          prefixIcon: Icon(Icons.pin_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _make,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle make',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _model,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle model',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _colour,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle colour',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notes,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Tell us about your service',
                        hintText: 'Experience, operating area, qualifications, equipment or other useful information',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
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
          onPressed: available.isEmpty ? null : _submit,
          child: const Text('Submit application'),
        ),
      ],
    );
  }
}

class _EmptyApplications extends StatelessWidget {
  const _EmptyApplications();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 46,
              color: WantokColors.primary,
            ),
            SizedBox(height: 10),
            Text(
              'No vendor applications yet.',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 5),
            Text(
              'Choose a service above when you are ready to earn through Wantok.',
              textAlign: TextAlign.center,
              style: TextStyle(color: WantokColors.muted),
            ),
          ],
        ),
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
      'approved' => const Color(0xFFDFF2E7),
      'rejected' => const Color(0xFFFFE7E1),
      _ => const Color(0xFFFFF2D2),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _ApplicationDraft {
  const _ApplicationDraft({
    required this.serviceType,
    required this.companyName,
    required this.vehiclePlate,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.notes,
  });

  final String serviceType;
  final String companyName;
  final String vehiclePlate;
  final String vehicleMake;
  final String vehicleModel;
  final String vehicleColor;
  final String notes;
}

class _ProviderOption {
  const _ProviderOption({
    required this.serviceType,
    required this.label,
    required this.icon,
    required this.description,
  });

  final String serviceType;
  final String label;
  final IconData icon;
  final String description;
}

const _providerOptions = <_ProviderOption>[
  _ProviderOption(
    serviceType: 'driver',
    label: 'Taxi / Ride Driver',
    icon: Icons.local_taxi_outlined,
    description:
        'Provide passenger rides using an approved vehicle and driver profile.',
  ),
  _ProviderOption(
    serviceType: 'vehicle_hire',
    label: 'Vehicle Hire',
    icon: Icons.directions_car_outlined,
    description:
        'List cars, 4WDs, trucks or other vehicles for scheduled hire.',
  ),
  _ProviderOption(
    serviceType: 'boat_hire',
    label: 'Boat Hire',
    icon: Icons.directions_boat_outlined,
    description: 'List dinghies or private boats for approved scheduled hire.',
  ),
  _ProviderOption(
    serviceType: 'boat_operator',
    label: 'Boat / Ship Passenger Service',
    icon: Icons.sailing_outlined,
    description: 'Operate scheduled or route-based passenger water transport.',
  ),
  _ProviderOption(
    serviceType: 'delivery',
    label: 'Delivery / Courier',
    icon: Icons.local_shipping_outlined,
    description: 'Provide parcel, document and goods delivery services.',
  ),
  _ProviderOption(
    serviceType: 'food_vendor',
    label: 'Food Vendor',
    icon: Icons.restaurant_outlined,
    description: 'Sell prepared food and drinks through Wantok.',
  ),
  _ProviderOption(
    serviceType: 'shop',
    label: 'Groceries / Shop',
    icon: Icons.local_grocery_store_outlined,
    description: 'Sell groceries and everyday goods through Wantok.',
  ),
  _ProviderOption(
    serviceType: 'specialist',
    label: 'Specialist / Trade Service',
    icon: Icons.handyman_outlined,
    description: 'Offer professional or trade services such as electrical, plumbing, IT or media work.',
  ),
  _ProviderOption(
    serviceType: 'general_labour',
    label: 'General Labour',
    icon: Icons.groups_outlined,
    description: 'Offer short-term labour and helper services.',
  ),
  _ProviderOption(
    serviceType: 'venue',
    label: 'Venue',
    icon: Icons.meeting_room_outlined,
    description: 'List halls, rooms, fields or other reservable spaces.',
  ),
  _ProviderOption(
    serviceType: 'events',
    label: 'Events',
    icon: Icons.event_outlined,
    description: 'Publish and operate approved event services.',
  ),
];

String _statusMessage(String status) => switch (status) {
  'approved' => 'Approved. Your vendor capabilities and draft service listing are available.',
  'rejected' =>
    'Not approved. You can correct the details and submit a new application.',
  _ => 'Under review by Wantok Admin.',
};

String _humanise(String value) => value
    .split('_')
    .map(
      (part) => part.isEmpty
          ? part
          : '${part.substring(0, 1).toUpperCase()}${part.substring(1)}',
    )
    .join(' ');

String _friendlyError(Object error) =>
    error.toString().replaceFirst('StateError: ', '');
