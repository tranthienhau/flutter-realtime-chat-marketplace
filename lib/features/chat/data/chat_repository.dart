import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../domain/models.dart';

class ChatRepository {
  ChatRepository(this._client);

  final SupabaseClient _client;
  final _uuid = const Uuid();
  final Map<String, RealtimeChannel> _threadChannels = {};

  Future<List<ChatThread>> listThreads(String userId) async {
    final rows = await _client
        .from('chat_threads')
        .select('*, last_message:chat_messages!fk_last_message(*)')
        .or('buyer_id.eq.$userId,seller_id.eq.$userId')
        .order('updated_at', ascending: false);

    return (rows as List).map((r) {
      final last = (r['last_message'] as Map?)?.cast<String, dynamic>();
      return ChatThread(
        id: r['id'] as String,
        listingId: r['listing_id'] as String,
        listingTitle: r['listing_title'] as String? ?? '',
        listingImageUrl: r['listing_image_url'] as String?,
        buyerId: r['buyer_id'] as String,
        sellerId: r['seller_id'] as String,
        unreadCount: (r['unread_count_$userId'] as int?) ?? 0,
        lastMessage: last == null ? null : ChatMessage.fromMap(last),
      );
    }).toList();
  }

  Future<List<ChatMessage>> fetchMessages(String threadId, {int limit = 50}) async {
    final rows = await _client
        .from('chat_messages')
        .select()
        .eq('thread_id', threadId)
        .order('sent_at', ascending: false)
        .limit(limit);
    return (rows as List).map((r) => ChatMessage.fromMap(r as Map<String, dynamic>)).toList();
  }

  Stream<ChatMessage> subscribeToThread(String threadId) {
    final controller = StreamController<ChatMessage>();
    final channel = _client.channel('thread:$threadId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'thread_id',
            value: threadId,
          ),
          callback: (payload) {
            final msg = ChatMessage.fromMap(payload.newRecord);
            controller.add(msg);
          },
        )
        .subscribe();
    _threadChannels[threadId] = channel;
    controller.onCancel = () => unsubscribe(threadId);
    return controller.stream;
  }

  Future<ChatMessage> sendText(String threadId, String senderId, String body) async {
    final msg = ChatMessage(
      id: _uuid.v4(),
      threadId: threadId,
      senderId: senderId,
      body: body,
      kind: MessageKind.text,
      sentAt: DateTime.now().toUtc(),
    );
    await _client.from('chat_messages').insert(msg.toInsertMap());
    return msg;
  }

  Future<ChatMessage> sendOffer(String threadId, String senderId, double amount, String body) async {
    final msg = ChatMessage(
      id: _uuid.v4(),
      threadId: threadId,
      senderId: senderId,
      body: body,
      kind: MessageKind.offer,
      sentAt: DateTime.now().toUtc(),
      offerAmount: amount,
    );
    await _client.from('chat_messages').insert(msg.toInsertMap());
    return msg;
  }

  Future<void> markRead(String threadId, String userId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _client
        .from('chat_messages')
        .update({'read_at': now})
        .eq('thread_id', threadId)
        .neq('sender_id', userId)
        .filter('read_at', 'is', null);
  }

  Stream<TypingState> subscribeToTyping(String threadId) {
    final controller = StreamController<TypingState>();
    final channel = _client.channel('typing:$threadId');
    channel.onBroadcast(
      event: 'typing',
      callback: (payload) {
        final userId = payload['user_id'] as String?;
        if (userId == null) return;
        controller.add(
          TypingState(threadId: threadId, userId: userId, since: DateTime.now()),
        );
      },
    ).subscribe();
    controller.onCancel = () => channel.unsubscribe();
    return controller.stream;
  }

  Future<void> emitTyping(String threadId, String userId) async {
    final channel = _client.channel('typing:$threadId');
    await channel.sendBroadcastMessage(event: 'typing', payload: {'user_id': userId});
  }

  void unsubscribe(String threadId) {
    final ch = _threadChannels.remove(threadId);
    ch?.unsubscribe();
  }
}
