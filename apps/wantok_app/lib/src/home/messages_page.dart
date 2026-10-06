import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

import 'png_visuals.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  static const _repository = MessagingRepository();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.loadThreads();
  }

  Future<void> _reload() async {
    final next = _repository.loadThreads();
    setState(() {
      _future = next;
    });
    try {
      await next;
    } catch (_) {
      // The FutureBuilder presents the retryable error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
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
                    title: const Text('Could not load messages'),
                    subtitle: const Text(
                      'Check your connection and try again.',
                    ),
                    trailing: IconButton(
                      tooltip: 'Retry messages',
                      onPressed: _reload,
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
                _InboxHeader(),
                SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 50,
                          color: WantokColors.primary,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No conversations yet',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'When a provider is assigned to a booking, the conversation will appear here.',
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
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
            itemCount: rows.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index == 0) return const _InboxHeader();
              final row = rows[index - 1];
              final unread = _toInt(row['unread_count']);
              final title =
                  row['other_display_name'] as String? ?? 'Wantok user';
              final category = row['category_name'] as String? ?? 'Service';
              final status = row['booking_status'] as String? ?? 'booking';
              final lastMessage = row['last_message'] as String?;

              return Card(
                child: ListTile(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => ConversationPage(
                          threadId: row['thread_id'] as String,
                          title: title,
                          subtitle:
                              '$category • ${status.replaceAll('_', ' ')}',
                        ),
                      ),
                    );
                    if (mounted) await _reload();
                  },
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE7F4ED),
                    child: Icon(
                      Icons.person_outline,
                      color: WantokColors.primaryDark,
                    ),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: unread > 0
                          ? FontWeight.w900
                          : FontWeight.w700,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      lastMessage?.trim().isNotEmpty == true
                          ? '$category · $lastMessage'
                          : '$category · No messages yet',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: unread > 0
                      ? Container(
                          constraints: const BoxConstraints(minWidth: 26),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
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
                      : const Icon(Icons.chevron_right),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _InboxHeader extends StatelessWidget {
  const _InboxHeader();

  @override
  Widget build(BuildContext context) {
    return PngScenicBackdrop(
      height: 136,
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
            'Talk with providers about active Wantok bookings.',
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
              Text(
                'Booking-linked conversations',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
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

String _formatMessageTime(dynamic value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (parsed == null) return '';
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _friendlyError(Object error) =>
    error.toString().replaceFirst('StateError: ', '');
