import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

import 'png_visuals.dart';
import 'wantok_agent_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({this.loadThreads, this.loadSupportRequests, super.key});

  final Future<List<Map<String, dynamic>>> Function()? loadThreads;
  final Future<List<Map<String, dynamic>>> Function()? loadSupportRequests;

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

enum InboxCategory { services, support }

class _MessagesPageState extends State<MessagesPage> {
  static const _repository = MessagingRepository();
  static const _supportRepository = WantokAiAgentRepository();

  late Future<_InboxData> _future;
  InboxCategory _category = InboxCategory.services;

  @override
  void initState() {
    super.initState();
    _future = _loadInbox();
  }

  Future<_InboxData> _loadInbox() async {
    var threads = const <Map<String, dynamic>>[];
    var supportRequests = const <Map<String, dynamic>>[];
    Object? threadsError;
    Object? supportError;

    try {
      threads = await (widget.loadThreads ?? _repository.loadThreads)();
    } catch (error) {
      threadsError = error;
    }

    try {
      supportRequests =
          await (widget.loadSupportRequests ??
              _supportRepository.loadMyHandoffs)();
    } catch (error) {
      supportError = error;
    }

    return _InboxData(
      threads: threads,
      supportRequests: supportRequests,
      threadsError: threadsError,
      supportError: supportError,
    );
  }

  Future<void> _reload() async {
    final next = _loadInbox();
    setState(() {
      _future = next;
    });
    await next;
  }

  Future<void> _openServiceConversation(Map<String, dynamic> row) async {
    final title = row['other_display_name'] as String? ?? 'Wantok user';
    final category = row['category_name'] as String? ?? 'Service';
    final status = row['booking_status'] as String? ?? 'booking';

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ConversationPage(
          threadId: row['thread_id'] as String,
          title: title,
          subtitle: '$category | ${status.replaceAll('_', ' ')}',
        ),
      ),
    );

    if (mounted) await _reload();
  }

  void _openSupportRequest(Map<String, dynamic> row) {
    final status = row['status']?.toString() ?? 'open';
    final summary = row['summary']?.toString() ?? '';
    final resolution = row['resolution_note']?.toString().trim();
    final createdAt = _formatInboxDateTime(row['created_at']);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFF0E8F7),
                      child: Icon(
                        Icons.support_agent_rounded,
                        color: WantokColors.purplePay,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Wantok help request',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _SupportStatusChip(status: status),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  summary,
                  style: const TextStyle(fontSize: 14, height: 1.35),
                ),
                if (createdAt.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Submitted $createdAt',
                    style: const TextStyle(
                      color: WantokColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (resolution != null && resolution.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Text(
                    'Response',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(resolution),
                ],
                const SizedBox(height: 18),
                const Card(
                  color: Color(0xFFF7FAF8),
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: WantokColors.primaryDark,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Live human chat is not enabled yet. This request remains owner-private and can be handled by authorised Wantok support or operations staff.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAgent() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const WantokAgentPage()),
    );
    if (mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<_InboxData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? const _InboxData();
          final showingServices = _category == InboxCategory.services;
          final error = showingServices ? data.threadsError : data.supportError;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
            children: [
              const _InboxHeader(),
              const SizedBox(height: 14),
              _InboxCategorySelector(
                selected: _category,
                serviceCount: data.threads.length,
                supportCount: data.supportRequests.length,
                onSelected: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 14),
              if (error != null)
                _InboxStateCard(
                  icon: Icons.cloud_off_outlined,
                  title: showingServices
                      ? 'Could not load service conversations'
                      : 'Could not load help requests',
                  body: 'This Inbox section is temporarily unavailable. Other Inbox categories can still be used.',
                  actionLabel: 'Retry',
                  onAction: _reload,
                )
              else if (showingServices && data.threads.isEmpty)
                const _InboxStateCard(
                  icon: Icons.forum_outlined,
                  title: 'No service conversations yet',
                  body: 'When a provider is assigned to a booking, that booking-linked conversation will appear here.',
                )
              else if (!showingServices && data.supportRequests.isEmpty)
                _InboxStateCard(
                  icon: Icons.support_agent_outlined,
                  title: 'No help requests',
                  body: 'Use Wantok Agent when normal search cannot solve a problem or when you want human follow-up.',
                  actionLabel: 'Open Wantok Agent',
                  onAction: _openAgent,
                )
              else if (showingServices) ...[
                for (var index = 0; index < data.threads.length; index++) ...[
                  _ServiceThreadCard(
                    row: data.threads[index],
                    onTap: () => _openServiceConversation(data.threads[index]),
                  ),
                  if (index != data.threads.length - 1)
                    const SizedBox(height: 8),
                ],
              ] else ...[
                for (
                  var index = 0;
                  index < data.supportRequests.length;
                  index++
                ) ...[
                  _SupportRequestCard(
                    row: data.supportRequests[index],
                    onTap: () =>
                        _openSupportRequest(data.supportRequests[index]),
                  ),
                  if (index != data.supportRequests.length - 1)
                    const SizedBox(height: 8),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _InboxData {
  const _InboxData({
    this.threads = const <Map<String, dynamic>>[],
    this.supportRequests = const <Map<String, dynamic>>[],
    this.threadsError,
    this.supportError,
  });

  final List<Map<String, dynamic>> threads;
  final List<Map<String, dynamic>> supportRequests;
  final Object? threadsError;
  final Object? supportError;
}

class _InboxCategorySelector extends StatelessWidget {
  const _InboxCategorySelector({
    required this.selected,
    required this.serviceCount,
    required this.supportCount,
    required this.onSelected,
  });

  final InboxCategory selected;
  final int serviceCount;
  final int supportCount;
  final ValueChanged<InboxCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final compact = MediaQuery.sizeOf(context).width < 420 || textScale > 1.2;

    Widget chip({
      required InboxCategory value,
      required String label,
      required IconData icon,
    }) {
      return SizedBox(
        width: double.infinity,
        child: ChoiceChip(
          label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          avatar: Icon(icon, size: 18),
          selected: selected == value,
          showCheckmark: false,
          onSelected: (_) => onSelected(value),
        ),
      );
    }

    final services = chip(
      value: InboxCategory.services,
      label: 'Services ($serviceCount)',
      icon: Icons.forum_outlined,
    );
    final support = chip(
      value: InboxCategory.support,
      label: 'Help & support ($supportCount)',
      icon: Icons.support_agent_outlined,
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [services, const SizedBox(height: 7), support],
      );
    }

    return Row(
      children: [
        Expanded(child: services),
        const SizedBox(width: 8),
        Expanded(child: support),
      ],
    );
  }
}

class _ServiceThreadCard extends StatelessWidget {
  const _ServiceThreadCard({required this.row, required this.onTap});

  final Map<String, dynamic> row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = _toInt(row['unread_count']);
    final title = row['other_display_name'] as String? ?? 'Wantok user';
    final category = row['category_name'] as String? ?? 'Service';
    final status = row['booking_status'] as String? ?? 'booking';
    final lastMessage = row['last_message'] as String?;

    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE7F4ED),
          child: Icon(
            Icons.chat_bubble_outline,
            color: WantokColors.primaryDark,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: unread > 0 ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            lastMessage?.trim().isNotEmpty == true
                ? '$category · $lastMessage'
                : '$category · ${status.replaceAll('_', ' ')}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: unread > 0
            ? Container(
                constraints: const BoxConstraints(minWidth: 26),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: WantokColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
            : const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _SupportRequestCard extends StatelessWidget {
  const _SupportRequestCard({required this.row, required this.onTap});

  final Map<String, dynamic> row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final summary = row['summary']?.toString() ?? 'Wantok help request';
    final status = row['status']?.toString() ?? 'open';
    final createdAt = _formatInboxDateTime(row['created_at']);

    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFF0E8F7),
          child: Icon(
            Icons.support_agent_rounded,
            color: WantokColors.purplePay,
          ),
        ),
        title: const Text(
          'Wantok help request',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(summary, maxLines: 2, overflow: TextOverflow.ellipsis),
              if (createdAt.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  createdAt,
                  style: const TextStyle(
                    color: WantokColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: _SupportStatusChip(status: status),
      ),
    );
  }
}

class _SupportStatusChip extends StatelessWidget {
  const _SupportStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalised = status.toLowerCase();
    final (background, foreground) = switch (normalised) {
      'resolved' ||
      'closed' => (const Color(0xFFDFF2E7), WantokColors.primaryDark),
      'assigned' => (const Color(0xFFE7F0FF), const Color(0xFF2456A6)),
      _ => (const Color(0xFFFFF2D2), const Color(0xFF7A5400)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        normalised.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: foreground,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InboxStateCard extends StatelessWidget {
  const _InboxStateCard({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final FutureOr<void> Function()? onAction;

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
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: WantokColors.muted),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () => onAction!(),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InboxHeader extends StatelessWidget {
  const _InboxHeader();

  @override
  Widget build(BuildContext context) {
    return PngScenicBackdrop(
      minHeight: 150,
      colors: const [Color(0xFF075C3A), Color(0xFF087A4B), Color(0xFF5A3421)],
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Inbox',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Service conversations and Wantok help in one place.',
            style: TextStyle(color: Color(0xFFE4F6EE), fontSize: 12.5),
          ),
          SizedBox(height: 11),
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: WantokColors.gold,
                size: 17,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Booking-linked and owner-private support',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ConversationPage extends StatefulWidget {
  const ConversationPage({
    required this.threadId,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String threadId;
  final String title;
  final String subtitle;

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  static const _repository = MessagingRepository();
  final _controller = TextEditingController();

  bool _sending = false;
  String? _lastMarkedMessageId;

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    try {
      await _repository.markRead(widget.threadId);
    } catch (error) {
      debugPrint('Could not mark conversation read: $error');
    }
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await _repository.sendMessage(widget.threadId, body);
      _controller.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _markNewestIncomingRead(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return;

    final currentUserId = _repository.currentUserId;
    Map<String, dynamic>? newestUnreadIncoming;
    for (final message in rows.reversed) {
      if (message['sender_id'] != currentUserId && message['read_at'] == null) {
        newestUnreadIncoming = message;
        break;
      }
    }

    final messageId = newestUnreadIncoming?['id'] as String?;
    if (messageId == null || messageId == _lastMarkedMessageId) return;

    _lastMarkedMessageId = messageId;
    unawaited(_markRead());
  }

  @override
  Widget build(BuildContext context) {
    final myUserId = _repository.currentUserId;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(
              widget.subtitle,
              style: const TextStyle(
                color: WantokColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _repository.watchMessages(widget.threadId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _friendlyError(snapshot.error!),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final rows = snapshot.data ?? const <Map<String, dynamic>>[];
                  _markNewestIncomingRead(rows);

                  if (rows.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Text(
                          'Start the conversation about this booking.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: WantokColors.muted),
                        ),
                      ),
                    );
                  }

                  final reversed = rows.reversed.toList(growable: false);
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                    itemCount: reversed.length,
                    itemBuilder: (context, index) {
                      final message = reversed[index];
                      final mine = message['sender_id'] == myUserId;
                      return _MessageBubble(
                        mine: mine,
                        body: message['body'] as String? ?? '',
                        createdAt: message['created_at'],
                        read: message['read_at'] != null,
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE0E8E3))),
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 2000,
                      buildCounter: (
                        context, {
                        required currentLength,
                        required isFocused,
                        required maxLength,
                      }) => null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Message about this booking',
                        prefixIcon: Icon(Icons.chat_bubble_outline),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send message',
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.mine,
    required this.body,
    required this.createdAt,
    required this.read,
  });

  final bool mine;
  final String body;
  final dynamic createdAt;
  final bool read;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(13, 10, 13, 7),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFFDFF2E7) : Colors.white,
          border: Border.all(color: const Color(0xFFDCE6E0)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Align(alignment: Alignment.centerLeft, child: Text(body)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatMessageTime(createdAt),
                  style: const TextStyle(
                    color: WantokColors.muted,
                    fontSize: 10,
                  ),
                ),
                if (mine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    read ? Icons.done_all : Icons.done,
                    size: 13,
                    color: read ? WantokColors.primary : WantokColors.muted,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _formatInboxDateTime(dynamic value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (parsed == null) return '';
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  return '$day/$month/${parsed.year} $hour:$minute';
}

String _formatMessageTime(dynamic value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (parsed == null) return '';
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _friendlyError(Object error) =>
    error.toString().replaceFirst('StateError: ', '');
