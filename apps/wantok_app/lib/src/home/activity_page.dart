import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

import '../services/commerce_orders_page.dart';
import '../services/event_registrations_page.dart';
import '../services/taxi_ride_page.dart';
import '../services/water_trip_bookings_page.dart';
import 'messages_page.dart';
import 'png_visuals.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  static const _repository = ReservationRepository();
  static const _messaging = MessagingRepository();
  static const _experience = ClientExperienceRepository();
  late Future<List<Map<String, dynamic>>> _future;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _future = _repository.loadMyReservations();
  }

  Future<void> _refresh() async {
    final next = _repository.loadMyReservations();
    setState(() {
      _future = next;
    });
    try {
      await next;
    } catch (_) {
      // The FutureBuilder presents the retryable error state.
    }
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

  Future<void> _reviewBooking({
    required String bookingId,
    required String providerName,
    Map<String, dynamic>? existingReview,
  }) async {
    final draft = await showDialog<_ReviewDraft>(
      context: context,
      builder: (context) => _ReviewDialog(
        providerName: providerName,
        existingReview: existingReview,
      ),
    );
    if (draft == null) return;

    final existingPhotoRefs = _stringList(existingReview?['photo_urls']);
    final uploadedRefs = <String>[];

    setState(() => _busyId = bookingId);
    try {
      var photoRefs = existingPhotoRefs;
      if (draft.replacePhotos) {
        final uploads = <ClientMediaUpload>[];
        for (final file in draft.photos) {
          uploads.add(
            ClientMediaUpload(
              bytes: await file.readAsBytes(),
              fileName: file.name,
              mimeType: file.mimeType,
            ),
          );
        }
        uploadedRefs.addAll(
          await _experience.uploadReviewPhotos(
            bookingId: bookingId,
            uploads: uploads,
          ),
        );
        photoRefs = uploadedRefs;
      }

      await _experience.submitServiceReview(
        bookingId: bookingId,
        rating: draft.rating,
        title: draft.title,
        comment: draft.comment,
        photoUrls: photoRefs,
        visibility: draft.visibility,
      );

      if (draft.replacePhotos && existingPhotoRefs.isNotEmpty) {
        try {
          await _experience.removeMediaReferences(existingPhotoRefs);
        } catch (_) {
          // Review save succeeded; stale media cleanup is best-effort.
        }
      }

      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review saved. Thank you.')),
        );
      }
    } catch (error) {
      if (uploadedRefs.isNotEmpty) {
        try {
          await _experience.removeMediaReferences(uploadedRefs);
        } catch (_) {
          // Preserve the primary review-save error.
        }
      }
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
                const _TrackHeader(),
                const SizedBox(height: 12),
                const _TrackJourneyLinks(),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.error_outline,
                      color: WantokColors.coral,
                    ),
                    title: const Text('Could not load your activity'),
                    subtitle: const Text(
                      'Check your connection and try again.',
                    ),
                    trailing: IconButton(
                      tooltip: 'Retry activity',
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
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
              children: const [
                _TrackHeader(),
                SizedBox(height: 12),
                _TrackJourneyLinks(),
                SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.route_outlined,
                          size: 50,
                          color: WantokColors.primary,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No requests or reservations yet',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          'Your service requests, quotes and reservations will appear here. Use the shortcuts above for rides, orders, events and water trips.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: WantokColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            itemCount: rows.length + 2,
            separatorBuilder: (_, _) => const SizedBox(height: 11),
            itemBuilder: (context, index) {
              if (index == 0) return const _TrackHeader();
              if (index == 1) return const _TrackJourneyLinks();
              final row = rows[index - 2];
              final id = row['id'] as String;
              final status = row['status'] as String? ?? 'unknown';
              final category = _asMap(row['service_categories']);
              final provider = _asMap(row['provider_profiles']);
              final resource = _asMap(row['provider_resources']);
              final quotes = _asList(row['service_quotes']);
              final reviews = _asList(row['service_reviews']);
              final existingReview = reviews.isEmpty
                  ? null
                  : _asMap(reviews.first);
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
                              category['name'] as String? ?? 'Wantok Services',
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
                      if (row['beneficiary_name'] != null)
                        Text(
                          row['beneficiary_relationship'] != null &&
                                  row['beneficiary_relationship']
                                      .toString()
                                      .trim()
                                      .isNotEmpty
                              ? 'For: ${row['beneficiary_name']} (${row['beneficiary_relationship']})'
                              : 'For: ${row['beneficiary_name']}',
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
                      if (amount != null)
                        Text(
                          'Amount: ${_kina(row['currency'], amount)}',
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
                                  'Vendor quote: ${_kina(pendingQuote['currency'], pendingQuote['amount'])}',
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
                                        'Wantok Services',
                                  ),
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Message provider'),
                          ),
                        ),
                      ],
                      if (status == 'completed' && provider.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: busy
                                ? null
                                : () => _reviewBooking(
                                    bookingId: id,
                                    providerName:
                                        provider['display_name'] as String? ??
                                        'Wantok Provider',
                                    existingReview: existingReview,
                                  ),
                            icon: Icon(
                              existingReview == null
                                  ? Icons.star_outline_rounded
                                  : Icons.rate_review_outlined,
                            ),
                            label: Text(
                              existingReview == null
                                  ? 'Review service'
                                  : 'Edit review',
                            ),
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

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({
    required this.providerName,
    required this.existingReview,
  });

  final String providerName;
  final Map<String, dynamic>? existingReview;

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final ImagePicker _picker = ImagePicker();

  late int _rating;
  late final TextEditingController _title;
  late final TextEditingController _comment;
  late String _visibility;
  late final List<String> _existingPhotos;
  List<XFile> _selectedPhotos = const <XFile>[];
  bool _replacePhotos = false;
  bool _pickingPhotos = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingReview;
    _rating = existing?['rating'] as int? ?? 5;
    _title = TextEditingController(text: existing?['title'] as String? ?? '');
    _comment = TextEditingController(
      text: existing?['comment'] as String? ?? '',
    );
    _visibility = existing?['visibility'] as String? ?? 'default';
    _existingPhotos = _stringList(existing?['photo_urls']);
  }

  Future<void> _pickPhotos() async {
    if (_pickingPhotos) return;
    setState(() => _pickingPhotos = true);
    try {
      final files = await _picker.pickMultiImage(
        maxWidth: 1920,
        imageQuality: 88,
      );
      if (!mounted || files.isEmpty) return;

      final selected = files.take(5).toList(growable: false);
      setState(() {
        _selectedPhotos = selected;
        _replacePhotos = true;
      });

      if (files.length > 5 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only the first five photos were kept.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _pickingPhotos = false);
    }
  }

  void _removePhotos() {
    setState(() {
      _selectedPhotos = const <XFile>[];
      _replacePhotos = true;
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _comment.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      _ReviewDraft(
        rating: _rating,
        title: _emptyToNull(_title.text),
        comment: _emptyToNull(_comment.text),
        visibility: _visibility == 'default' ? null : _visibility,
        photos: _selectedPhotos,
        replacePhotos: _replacePhotos,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Review ${widget.providerName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How was the service?',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: List.generate(5, (index) {
                final value = index + 1;
                return IconButton(
                  tooltip: '$value star',
                  onPressed: () => setState(() => _rating = value),
                  icon: Icon(
                    value <= _rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: const Color(0xFFE6A100),
                    size: 30,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              maxLength: 160,
              decoration: const InputDecoration(
                labelText: 'Review title',
                hintText: 'Helpful, fast, reliable...',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _comment,
              minLines: 3,
              maxLines: 6,
              maxLength: 4000,
              decoration: const InputDecoration(
                labelText: 'Tell other Wantoks about your experience',
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: const Color(0xFFF7FAF8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Photos',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _replacePhotos
                          ? _selectedPhotos.isEmpty
                                ? 'No photos selected'
                                : '${_selectedPhotos.length} photo(s) selected'
                          : _existingPhotos.isEmpty
                          ? 'No photos'
                          : '${_existingPhotos.length} existing photo(s)',
                      style: const TextStyle(
                        color: WantokColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickingPhotos ? null : _pickPhotos,
                          icon: _pickingPhotos
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.photo_library_outlined),
                          label: Text(
                            _pickingPhotos
                                ? 'Opening...'
                                : _existingPhotos.isEmpty && !_replacePhotos
                                ? 'Add photos'
                                : 'Replace photos',
                          ),
                        ),
                        if ((_existingPhotos.isNotEmpty && !_replacePhotos) ||
                            (_replacePhotos && _selectedPhotos.isNotEmpty))
                          TextButton.icon(
                            onPressed: _pickingPhotos ? null : _removePhotos,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Remove photos'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _visibility,
              decoration: const InputDecoration(
                labelText: 'Who can see this review?',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'default',
                  child: Text('Use my privacy setting'),
                ),
                DropdownMenuItem(value: 'private', child: Text('Only me')),
                DropdownMenuItem(
                  value: 'registered',
                  child: Text('Signed-in Wantok users'),
                ),
                DropdownMenuItem(value: 'public', child: Text('Public')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _visibility = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save review')),
      ],
    );
  }
}

class _ReviewDraft {
  const _ReviewDraft({
    required this.rating,
    required this.title,
    required this.comment,
    required this.visibility,
    required this.photos,
    required this.replacePhotos,
  });

  final int rating;
  final String? title;
  final String? comment;
  final String? visibility;
  final List<XFile> photos;
  final bool replacePhotos;
}

class _TrackHeader extends StatelessWidget {
  const _TrackHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: PngScenicBackdrop(
        minHeight: 150,
        colors: const [Color(0xFF7B2D3A), Color(0xFFC85536), Color(0xFF0B79A8)],
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Track your Wantok',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.7,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Open your service records or review requests and reservations below.',
              style: TextStyle(
                color: Color(0xFFFFECE6),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackJourneyLinks extends StatelessWidget {
  const _TrackJourneyLinks();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (label, icon, page) in <(String, IconData, Widget)>[
          ('Taxi rides', Icons.local_taxi_outlined, const TaxiRidePage()),
          (
            'Food & shop orders',
            Icons.shopping_bag_outlined,
            const CommerceOrdersPage(),
          ),
          (
            'Event registrations',
            Icons.event_outlined,
            const EventRegistrationsPage(),
          ),
          (
            'Water trips',
            Icons.sailing_outlined,
            const WaterTripBookingsPage(),
          ),
        ])
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (context) => page)),
            icon: Icon(icon),
            label: Text(label),
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

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList(growable: false);
  }
  return const <String>[];
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

String _kina(dynamic currency, dynamic amount) {
  final code = currency?.toString().toUpperCase();
  if (code == null || code == 'PGK' || code == 'K' || code == 'KINA') {
    return 'K$amount';
  }
  return '$code $amount';
}

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _friendlyError(Object error) =>
    error.toString().replaceFirst('StateError: ', '');
