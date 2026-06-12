import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_realtime_chat_marketplace/features/chat/data/chat_repository.dart';
import 'package:flutter_realtime_chat_marketplace/features/chat/domain/models.dart';
import 'package:flutter_realtime_chat_marketplace/features/chat/presentation/providers.dart';
import 'package:flutter_realtime_chat_marketplace/features/chat/presentation/screens/threads_screen.dart';
import 'package:flutter_realtime_chat_marketplace/features/chat/presentation/screens/thread_screen.dart';

const myId = 'me-buyer';
const sellerId = 'seller-1';

DateTime _t(int minsAgo) =>
    DateTime.now().toUtc().subtract(Duration(minutes: minsAgo));

final _sneakers = ChatThread(
  id: 'th-1',
  listingId: 'l-1',
  listingTitle: 'Air Max 90 - Size 10 (like new)',
  buyerId: myId,
  sellerId: sellerId,
  unreadCount: 2,
  lastMessage: ChatMessage(
    id: 'm-1',
    threadId: 'th-1',
    senderId: sellerId,
    body: 'Yeah they fit true to size, barely worn.',
    kind: MessageKind.text,
    sentAt: _t(3),
  ),
);

final _threads = <ChatThread>[
  _sneakers,
  ChatThread(
    id: 'th-2',
    listingId: 'l-2',
    listingTitle: 'IKEA Markus office chair',
    buyerId: myId,
    sellerId: 'seller-2',
    unreadCount: 0,
    lastMessage: ChatMessage(
      id: 'm-2',
      threadId: 'th-2',
      senderId: myId,
      body: 'Could you do \$80?',
      kind: MessageKind.offer,
      sentAt: _t(40),
      offerAmount: 80,
      readAt: _t(38),
    ),
  ),
  ChatThread(
    id: 'th-3',
    listingId: 'l-3',
    listingTitle: 'Canon EF 50mm f/1.8 lens',
    buyerId: 'buyer-x',
    sellerId: myId,
    unreadCount: 1,
    lastMessage: ChatMessage(
      id: 'm-3',
      threadId: 'th-3',
      senderId: 'buyer-x',
      body: 'Is the lens still available?',
      kind: MessageKind.text,
      sentAt: _t(120),
    ),
  ),
  ChatThread(
    id: 'th-4',
    listingId: 'l-4',
    listingTitle: 'PS5 DualSense controller',
    buyerId: myId,
    sellerId: 'seller-4',
    unreadCount: 0,
    lastMessage: ChatMessage(
      id: 'm-4',
      threadId: 'th-4',
      senderId: 'seller-4',
      body: 'Deal! I can ship tomorrow.',
      kind: MessageKind.text,
      sentAt: _t(300),
      readAt: _t(295),
    ),
  ),
];

final _sneakerMessages = <ChatMessage>[
  // Newest first (ListView is reverse:true).
  ChatMessage(
    id: 'sm-7',
    threadId: 'th-1',
    senderId: myId,
    body: 'Great, sending payment now.',
    kind: MessageKind.text,
    sentAt: _t(1),
    readAt: _t(0),
  ),
  ChatMessage(
    id: 'sm-6',
    threadId: 'th-1',
    senderId: sellerId,
    body: 'Sure, \$95 works for me.',
    kind: MessageKind.offer,
    sentAt: _t(2),
    offerAmount: 95,
  ),
  ChatMessage(
    id: 'sm-5',
    threadId: 'th-1',
    senderId: myId,
    body: 'Would you take \$95?',
    kind: MessageKind.offer,
    sentAt: _t(3),
    offerAmount: 95,
    readAt: _t(2),
  ),
  ChatMessage(
    id: 'sm-4',
    threadId: 'th-1',
    senderId: sellerId,
    body: 'Yeah they fit true to size, barely worn.',
    kind: MessageKind.text,
    sentAt: _t(4),
  ),
  ChatMessage(
    id: 'sm-3',
    threadId: 'th-1',
    senderId: myId,
    body: 'Do they run true to size?',
    kind: MessageKind.text,
    sentAt: _t(5),
    readAt: _t(4),
  ),
  ChatMessage(
    id: 'sm-2',
    threadId: 'th-1',
    senderId: myId,
    body: 'Hi! Interested in the Air Max 90s.',
    kind: MessageKind.text,
    sentAt: _t(6),
    readAt: _t(5),
  ),
  ChatMessage(
    id: 'sm-1',
    threadId: 'th-1',
    senderId: 'system',
    body: 'Conversation started about Air Max 90 - Size 10',
    kind: MessageKind.system,
    sentAt: _t(7),
  ),
];

/// In-memory repository so screenshots render real content without Supabase.
class FakeChatRepository extends ChatRepository {
  // The base ctor only stores the client; no overridden method reads it.
  FakeChatRepository() : super(_fakeClient);

  @override
  Future<List<ChatThread>> listThreads(String userId) async => _threads;

  @override
  Future<List<ChatMessage>> fetchMessages(String threadId, {int limit = 50}) async {
    if (threadId == 'th-1') return _sneakerMessages;
    return const [];
  }

  @override
  Stream<ChatMessage> subscribeToThread(String threadId) =>
      const Stream<ChatMessage>.empty();

  @override
  Stream<TypingState> subscribeToTyping(String threadId) =>
      const Stream<TypingState>.empty();

  @override
  Future<void> markRead(String threadId, String userId) async {}

  @override
  void unsubscribe(String threadId) {}
}

// A non-initialized client; never touched because FakeChatRepository
// overrides every method that would use it.
final SupabaseClient _fakeClient =
    SupabaseClient('https://stub.supabase.co', 'stub-anon-key');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final overrides = <Override>[
    currentUserIdProvider.overrideWithValue(myId),
    chatRepositoryProvider.overrideWithValue(FakeChatRepository()),
  ];

  Future<void> shoot(WidgetTester tester, String name) async {
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot(name);
  }

  testWidgets('capture marketplace chat flow', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ThreadsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await shoot(tester, '01-threads');

    // Open the sneakers conversation directly.
    await tester.tap(find.text('Air Max 90 - Size 10 (like new)'));
    await tester.pumpAndSettle();
    await shoot(tester, '02-conversation');

    // Type into the composer to show the input filled in.
    await tester.enterText(find.byType(TextField), 'Sounds good, see you then!');
    await tester.pumpAndSettle();
    await shoot(tester, '03-composer');
  });
}
