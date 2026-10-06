import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

class BookingForSelector extends StatefulWidget {
  const BookingForSelector({
    required this.selectedTrustedPersonId,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final String? selectedTrustedPersonId;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  State<BookingForSelector> createState() => _BookingForSelectorState();
}

class _BookingForSelectorState extends State<BookingForSelector> {
  static const _repository = ClientExperienceRepository();
  static const _selfValue = '__wantok_self__';
  late Future<List<TrustedPerson>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.loadTrustedPeople();
  }

  Future<void> _retry() async {
    final next = _repository.loadTrustedPeople();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TrustedPerson>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Text('Loading trusted people...')),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: ListTile(
              leading: const Icon(
                Icons.person_off_outlined,
                color: WantokColors.coral,
              ),
              title: const Text('Who is this for?'),
              subtitle: const Text(
                'Trusted people could not be loaded. You can still book for yourself.',
              ),
              trailing: IconButton(
                tooltip: 'Retry',
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
              ),
            ),
          );
        }

        final people = snapshot.data ?? const <TrustedPerson>[];
        TrustedPerson? selected;
        for (final person in people) {
          if (person.id == widget.selectedTrustedPersonId) {
            selected = person;
            break;
          }
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.family_restroom_outlined,
                      color: WantokColors.primaryDark,
                    ),
                    SizedBox(width: 9),
                    Text(
                      'Who is this for?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: widget.selectedTrustedPersonId ?? _selfValue,
                  decoration: const InputDecoration(
                    labelText: 'Service beneficiary',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: _selfValue,
                      child: Text('Myself'),
                    ),
                    ...people.map(
                      (person) => DropdownMenuItem<String>(
                        value: person.id,
                        child: Text(
                          person.relationship?.trim().isNotEmpty == true
                              ? '${person.displayName} — ${person.relationship}'
                              : person.displayName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: widget.enabled
                      ? (value) =>
                            widget.onChanged(value == _selfValue ? null : value)
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  selected == null
                      ? 'You are booking for yourself.'
                      : 'You remain the Wantok account owner and payer. '
                            '${selected.displayName} only receives the service.',
                  style: const TextStyle(
                    color: WantokColors.muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                if (selected != null &&
                    (selected.phone?.trim().isNotEmpty == true ||
                        selected.relationship?.trim().isNotEmpty == true)) ...[
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      if (selected.relationship?.trim().isNotEmpty == true)
                        _Meta(
                          icon: Icons.group_outlined,
                          text: selected.relationship!,
                        ),
                      if (selected.phone?.trim().isNotEmpty == true)
                        _Meta(
                          icon: Icons.phone_outlined,
                          text: selected.phone!,
                        ),
                    ],
                  ),
                ],
                if (people.isEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'To book for a relative, family member or staff member, add them first under Account → Trusted people.',
                    style: TextStyle(
                      color: WantokColors.primaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: WantokColors.muted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: WantokColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}
