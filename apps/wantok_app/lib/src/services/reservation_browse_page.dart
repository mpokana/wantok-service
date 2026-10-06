import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_core/wantok_core.dart';
import 'package:wantok_ui/wantok_ui.dart';

import 'booking_for_selector.dart';

class ReservationBrowsePage extends StatefulWidget {
  const ReservationBrowsePage({required this.category, super.key});

  final WantokServiceCategory category;

  @override
  State<ReservationBrowsePage> createState() => _ReservationBrowsePageState();
}

class _ReservationBrowsePageState extends State<ReservationBrowsePage> {
  static const _repository = ReservationRepository();
  static const _experience = ClientExperienceRepository();

  late Future<List<ReservableOffer>> _future;
  final Set<String> _savedResourceIds = <String>{};
  final Set<String> _savedProviderIds = <String>{};
  final Set<String> _savingKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _future = _repository.loadOffers(widget.category.slug);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSaved();
    });
  }

  Future<void> _loadSaved() async {
    try {
      final results = await Future.wait<Set<String>>([
        _experience.loadSavedIds('resource'),
        _experience.loadSavedIds('provider'),
      ]);
      if (!mounted) return;
      setState(() {
        _savedResourceIds
          ..clear()
          ..addAll(results[0]);
        _savedProviderIds
          ..clear()
          ..addAll(results[1]);
      });
    } catch (_) {
      // Saving is optional; browsing must remain available.
    }
  }

  Future<void> _toggleSaved({
    required String itemType,
    required String entityId,
  }) async {
    final key = '$itemType:$entityId';
    if (_savingKeys.contains(key)) return;

    final target = itemType == 'resource'
        ? _savedResourceIds
        : _savedProviderIds;
    final wasSaved = target.contains(entityId);

    setState(() => _savingKeys.add(key));
    try {
      await _experience.setSavedItem(
        itemType: itemType,
        entityId: entityId,
        saved: !wasSaved,
      );
      if (!mounted) return;
      setState(() {
        if (wasSaved) {
          target.remove(entityId);
        } else {
          target.add(entityId);
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
      if (mounted) setState(() => _savingKeys.remove(key));
    }
  }

  Future<void> _refresh() async {
    final next = _repository.loadOffers(widget.category.slug);
    setState(() {
      _future = next;
    });
    try {
      await next;
      await _loadSaved();
    } catch (_) {
      // The FutureBuilder presents the retryable error state.
    }
  }

  Future<void> _openReservation(ReservableOffer offer) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _ReservationSheet(offer: offer),
    );

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reservation request sent. The vendor will confirm or quote shortly.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<ReservableOffer>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _StateCard(
                    icon: Icons.cloud_off_outlined,
                    title: 'Could not load available options',
                    message: snapshot.error.toString(),
                    actionLabel: 'Retry',
                    onAction: _refresh,
                  ),
                ],
              );
            }

            final offers = snapshot.data ?? const <ReservableOffer>[];
            if (offers.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _StateCard(
                    icon: _iconFor(widget.category.slug),
                    title: 'No approved options yet',
                    message:
                        'Approved vendors and resources for ${widget.category.name} will appear here as they become available.',
                    actionLabel: 'Refresh',
                    onAction: _refresh,
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: [
                _CategoryHero(category: widget.category),
                const SizedBox(height: 18),
                Text(
                  'Available options',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Choose an approved provider and resource. Availability is checked again before the request is created.',
                  style: TextStyle(color: WantokColors.muted),
                ),
                const SizedBox(height: 14),
                ...offers.map(
                  (offer) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OfferCard(
                      offer: offer,
                      resourceSaved: _savedResourceIds.contains(
                        offer.resourceId,
                      ),
                      providerSaved: _savedProviderIds.contains(
                        offer.providerId,
                      ),
                      resourceBusy: _savingKeys.contains(
                        'resource:${offer.resourceId}',
                      ),
                      providerBusy: _savingKeys.contains(
                        'provider:${offer.providerId}',
                      ),
                      onToggleResource: () => _toggleSaved(
                        itemType: 'resource',
                        entityId: offer.resourceId,
                      ),
                      onToggleProvider: () => _toggleSaved(
                        itemType: 'provider',
                        entityId: offer.providerId,
                      ),
                      onTap: () => _openReservation(offer),
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

class _CategoryHero extends StatelessWidget {
  const _CategoryHero({required this.category});

  final WantokServiceCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [WantokColors.primaryDark, WantokColors.primary],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(_iconFor(category.slug), color: Colors.white, size: 34),
          ),
          const SizedBox(width: 16),
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
                  category.description ??
                      'Book approved local services through Wantok.',
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

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.resourceSaved,
    required this.providerSaved,
    required this.resourceBusy,
    required this.providerBusy,
    required this.onToggleResource,
    required this.onToggleProvider,
    required this.onTap,
  });

  final ReservableOffer offer;
  final bool resourceSaved;
  final bool providerSaved;
  final bool resourceBusy;
  final bool providerBusy;
  final VoidCallback onToggleResource;
  final VoidCallback onToggleProvider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rating = offer.providerRating;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F4ED),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  _iconFor(offer.categorySlug),
                  color: WantokColors.primaryDark,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.resourceName,
                      style: const TextStyle(
                        color: WantokColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      offer.serviceTitle,
                      style: const TextStyle(
                        color: WantokColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 10,
                      runSpacing: 5,
                      children: [
                        _Meta(
                          icon: Icons.storefront_outlined,
                          text: offer.providerName,
                        ),
                        if (rating != null && rating > 0)
                          _Meta(
                            icon: Icons.star,
                            text:
                                '${rating.toStringAsFixed(1)} (${offer.providerRatingCount})',
                          ),
                        if (offer.capacity != null)
                          _Meta(
                            icon: Icons.groups_outlined,
                            text: 'Capacity ${offer.capacity}',
                          ),
                        if (offer.resourceAddress != null)
                          _Meta(
                            icon: Icons.location_on_outlined,
                            text: offer.resourceAddress!,
                          ),
                      ],
                    ),
                    if (offer.resourceDescription != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        offer.resourceDescription!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: WantokColors.muted),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      offer.priceLabel,
                      style: const TextStyle(
                        color: WantokColors.primaryDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: resourceSaved
                        ? 'Remove place from Saved'
                        : 'Save this place',
                    onPressed: resourceBusy ? null : onToggleResource,
                    icon: resourceBusy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            resourceSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: resourceSaved
                                ? WantokColors.primary
                                : WantokColors.muted,
                          ),
                  ),
                  IconButton(
                    tooltip: providerSaved
                        ? 'Remove provider from Saved'
                        : 'Save provider',
                    onPressed: providerBusy ? null : onToggleProvider,
                    icon: providerBusy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            providerSaved
                                ? Icons.storefront_rounded
                                : Icons.storefront_outlined,
                            color: providerSaved
                                ? WantokColors.primary
                                : WantokColors.muted,
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
        Icon(icon, size: 15, color: WantokColors.muted),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 210),
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: WantokColors.muted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _ReservationSheet extends StatefulWidget {
  const _ReservationSheet({required this.offer});

  final ReservableOffer offer;

  @override
  State<_ReservationSheet> createState() => _ReservationSheetState();
}

class _ReservationSheetState extends State<_ReservationSheet> {
  static const _repository = ReservationRepository();

  late DateTime _start;
  late DateTime _end;
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  String? _trustedPersonId;

  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    _start = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8);
    _end = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 17);
    _addressController.text =
        widget.offer.resourceAddress ?? widget.offer.serviceAddress ?? '';
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _chooseStart() async {
    final value = await _pickDateTime(_start);
    if (value == null) return;

    setState(() {
      _start = value;
      if (!_end.isAfter(_start)) {
        _end = _start.add(const Duration(hours: 8));
      }
      _error = null;
    });
  }

  Future<void> _chooseEnd() async {
    final value = await _pickDateTime(_end);
    if (value == null) return;

    setState(() {
      _end = value;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!_end.isAfter(_start)) {
      setState(() => _error = 'End time must be after the start time.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final available = await _repository.isResourceAvailable(
        resourceId: widget.offer.resourceId,
        startsAt: _start,
        endsAt: _end,
      );

      if (!available) {
        throw StateError(
          'This resource is not available for the selected time. Choose another time or option.',
        );
      }

      await _repository.createReservation(
        offer: widget.offer,
        startsAt: _start,
        endsAt: _end,
        serviceAddress: _addressController.text,
        notes: _notesController.text,
        trustedPersonId: _trustedPersonId,
      );

      if (mounted) Navigator.of(context).pop(true);
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
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.offer.resourceName,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            '${widget.offer.providerName} • ${widget.offer.priceLabel}',
            style: const TextStyle(
              color: WantokColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          _DateTimeTile(
            label: 'Start',
            value: _formatDateTime(_start),
            icon: Icons.play_circle_outline,
            onTap: _chooseStart,
          ),
          const SizedBox(height: 10),
          _DateTimeTile(
            label: 'End',
            value: _formatDateTime(_end),
            icon: Icons.stop_circle_outlined,
            onTap: _chooseEnd,
          ),
          const SizedBox(height: 12),
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
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Service / pickup location',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Notes for the vendor',
              hintText:
                  'Purpose, pickup details, setup needs, or special requests',
              prefixIcon: Icon(Icons.notes_outlined),
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
            icon: const Icon(Icons.event_available_outlined),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Text(
                _busy ? 'Checking availability...' : 'Request booking',
              ),
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Submitting a request does not charge you. The vendor must confirm the booking or send a quote.',
            textAlign: TextAlign.center,
            style: TextStyle(color: WantokColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: WantokColors.primary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(value),
        trailing: const Icon(Icons.edit_calendar_outlined),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(icon, size: 48, color: WantokColors.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: WantokColors.muted),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconFor(String slug) => switch (slug) {
  'vehicle-hire' => Icons.directions_car_outlined,
  'boat-hire' => Icons.directions_boat_outlined,
  'venue-booking' => Icons.meeting_room_outlined,
  _ => Icons.event_available_outlined,
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
