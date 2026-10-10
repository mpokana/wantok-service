import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

/// Read-only CX1I Operations surface for owner-private Wantok Agent handoffs.
/// All database access uses the signed-in user and existing Supabase RLS.
/// Status updates, responses and live messaging are intentionally not exposed.
class SupportInquiriesPage extends StatefulWidget {
  const SupportInquiriesPage({super.key, this.loadRequests});

  final Future<List<Map<String, dynamic>>> Function()? loadRequests;

  @override
  State<SupportInquiriesPage> createState() => _SupportInquiriesPageState();
}

class _SupportInquiriesPageState extends State<SupportInquiriesPage> {
  late Future<List<Map<String, dynamic>>> _future;
  String _status = 'all';

  static const _statusOptions = [
    'all',
    'open',
    'assigned',
    'resolved',
    'closed',
  ];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final loader = widget.loadRequests;
    if (loader != null) return loader();
    final rows = await WantokBackend.client
        .from('ai_agent_handoff_requests')
        .select(
          'id, summary, status, created_at, resolution_note',
        )
        .order('created_at', ascending: false)
        .limit(150);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  String _date(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return 'Date unavailable';
    final utc = date.toUtc();
    return '${utc.year}-${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')} '
        '${utc.hour.toString().padLeft(2, '0')}:'
        '${utc.minute.toString().padLeft(2, '0')} UTC';
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, area) {
      final side = area.maxWidth >= 960 ? 28.0 : 14.0;
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1340),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snapshot) {
              final data = snapshot.data ?? const <Map<String, dynamic>>[];
              final visible = data
                  .where((row) => _status == 'all' || row['status'] == _status)
                  .toList();
              final openCount = data
                  .where(
                    (row) =>
                        row['status'] == 'open' || row['status'] == 'assigned',
                  )
                  .length;
              return ListView(
                key: const ValueKey('cx1-support-queue'),
                padding: EdgeInsets.fromLTRB(side, 20, side, 32),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF06432D), Color(0xFF086847)],
                      ),
                    ),
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WANTOK OPERATIONS',
                          style: TextStyle(
                            color: WantokColors.gold,
                            letterSpacing: 1.3,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Support & Inquiries',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Wantok Agent requests awaiting human follow-up. '
                          'Read-only triage; live chat and staff replies are not yet enabled.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      Text(
                        snapshot.connectionState == ConnectionState.done
                            ? '${data.length} recent requests · $openCount open or assigned'
                            : 'Loading requests…',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _statusOptions.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final option = _statusOptions[index];
                        return ChoiceChip(
                          key: ValueKey('support-status-$option'),
                          selected: _status == option,
                          label: Text(
                            option == 'all' ? 'All' : _capitalised(option),
                          ),
                          onSelected: (_) => setState(() => _status = option),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (snapshot.connectionState != ConnectionState.done)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(25),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (snapshot.hasError)
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.error_outline,
                          color: WantokColors.coral,
                        ),
                        title: const Text('Could not load support requests'),
                        subtitle: const Text(
                          'The authorised request queue is unavailable. '
                          'Check your connection and try again.',
                        ),
                        trailing: IconButton(
                          tooltip: 'Retry support queue',
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ),
                    )
                  else if (visible.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(25),
                        child: Text('No requests match this filter.'),
                      ),
                    )
                  else
                    ...visible.map((row) => _requestCard(row)),
                  const SizedBox(height: 10),
                  const Text(
                    'Showing up to 150 recent authorised requests. '
                    'Staff response, assignment and status mutation are '
                    'separate CX1I acceptance steps.',
                    style: TextStyle(color: WantokColors.muted, fontSize: 11),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );

  Widget _requestCard(Map<String, dynamic> row) {
    final status = row['status']?.toString() ?? 'unknown';
    final summary = row['summary']?.toString() ?? '';
    final note = row['resolution_note']?.toString().trim();
    final active = status == 'open' || status == 'assigned';
    return Card(
      key: ValueKey('support-request-${row['id']}'),
      margin: const EdgeInsets.only(bottom: 11),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 7,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  avatar: Icon(
                    active ? Icons.schedule : Icons.task_alt,
                    size: 16,
                    color: WantokColors.primary,
                  ),
                  label: Text(_capitalised(status)),
                  backgroundColor: active
                      ? const Color(0xFFFFF1D0)
                      : const Color(0xFFDDF3E6),
                ),
                Text(
                  'Submitted ${_date(row['created_at'])}',
                  style: const TextStyle(
                    color: WantokColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            SelectableText(
              summary,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Resolution note',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              SelectableText(note),
            ],
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.lock_outline, size: 15, color: WantokColors.muted),
                SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'Private request · only authorised staff and its owner',
                    style: TextStyle(fontSize: 11, color: WantokColors.muted),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _capitalised(String raw) => raw.isEmpty
      ? raw
      : '${raw.substring(0, 1).toUpperCase()}${raw.substring(1)}';
}
