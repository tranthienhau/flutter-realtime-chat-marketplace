import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/chat_repository.dart';
import '../domain/models.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(supabaseProvider)),
);

final currentUserIdProvider = Provider<String>((ref) {
  final user = ref.watch(supabaseProvider).auth.currentUser;
  return user?.id ?? 'anonymous';
});

final threadsProvider = FutureProvider.autoDispose<List<ChatThread>>((ref) async {
  final repo = ref.watch(chatRepositoryProvider);
  final me = ref.watch(currentUserIdProvider);
  return repo.listThreads(me);
});

class ThreadMessagesController extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  ThreadMessagesController(this._repo, this._threadId, this._myId) : super(const AsyncLoading()) {
    _bootstrap();
  }

  final ChatRepository _repo;
  final String _threadId;
  final String _myId;
  StreamSubscription<ChatMessage>? _sub;

  Future<void> _bootstrap() async {
    try {
      final history = await _repo.fetchMessages(_threadId);
      state = AsyncData(history);
      _sub = _repo.subscribeToThread(_threadId).listen(_onIncoming);
      await _repo.markRead(_threadId, _myId);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void _onIncoming(ChatMessage msg) {
    final current = state.value ?? const [];
    if (current.any((m) => m.id == msg.id)) return;
    state = AsyncData([msg, ...current]);
    if (msg.senderId != _myId) _repo.markRead(_threadId, _myId);
  }

  Future<void> sendText(String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;
    final optimistic = ChatMessage(
      id: 'tmp-${DateTime.now().microsecondsSinceEpoch}',
      threadId: _threadId,
      senderId: _myId,
      body: trimmed,
      kind: MessageKind.text,
      sentAt: DateTime.now().toUtc(),
    );
    state = AsyncData([optimistic, ...(state.value ?? const [])]);
    try {
      final saved = await _repo.sendText(_threadId, _myId, trimmed);
      final list = state.value ?? const [];
      state = AsyncData([saved, ...list.where((m) => m.id != optimistic.id)]);
    } catch (e) {
      final list = state.value ?? const [];
      state = AsyncData(list.where((m) => m.id != optimistic.id).toList());
      rethrow;
    }
  }

  Future<void> sendOffer(double amount, String note) async {
    await _repo.sendOffer(_threadId, _myId, amount, note);
  }

  Future<void> emitTyping() => _repo.emitTyping(_threadId, _myId);

  @override
  void dispose() {
    _sub?.cancel();
    _repo.unsubscribe(_threadId);
    super.dispose();
  }
}

final threadMessagesProvider = StateNotifierProvider.autoDispose
    .family<ThreadMessagesController, AsyncValue<List<ChatMessage>>, String>((ref, threadId) {
  final repo = ref.watch(chatRepositoryProvider);
  final me = ref.watch(currentUserIdProvider);
  return ThreadMessagesController(repo, threadId, me);
});

final typingProvider = StreamProvider.autoDispose.family<TypingState, String>((ref, threadId) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.subscribeToTyping(threadId);
});
