import 'wantok_backend.dart';

class MessagingRepository {
  const MessagingRepository();

  String get currentUserId {
    final user = WantokBackend.client.auth.currentUser;
    if (user == null) {
      throw StateError('Authentication required.');
    }
    return user.id;
  }

  Future<List<Map<String, dynamic>>> loadThreads() async {
    final rows = await WantokBackend.client.rpc(
      'list_my_booking_conversations',
    );
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<String> ensureForBooking(String bookingId) async {
    final threadId = await WantokBackend.client.rpc(
      'ensure_booking_conversation',
      params: {'p_booking_id': bookingId},
    );
    return threadId as String;
  }

  Stream<List<Map<String, dynamic>>> watchMessages(String threadId) {
    return WantokBackend.client
        .from('conversation_messages')
        .stream(primaryKey: ['id'])
        .eq('thread_id', threadId)
        .order('created_at');
  }

  Future<void> sendMessage(String threadId, String body) async {
    await WantokBackend.client.rpc(
      'send_conversation_message',
      params: {'p_thread_id': threadId, 'p_body': body},
    );
  }

  Future<void> markRead(String threadId) async {
    await WantokBackend.client.rpc(
      'mark_conversation_read',
      params: {'p_thread_id': threadId},
    );
  }
}
