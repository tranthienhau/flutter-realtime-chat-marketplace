enum MessageKind { text, image, system, offer }

class ChatMessage {
  final String id;
  final String threadId;
  final String senderId;
  final String body;
  final MessageKind kind;
  final DateTime sentAt;
  final DateTime? readAt;
  final String? attachmentUrl;
  final double? offerAmount;

  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.body,
    required this.kind,
    required this.sentAt,
    this.readAt,
    this.attachmentUrl,
    this.offerAmount,
  });

  bool get isRead => readAt != null;

  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
        id: m['id'] as String,
        threadId: m['thread_id'] as String,
        senderId: m['sender_id'] as String,
        body: (m['body'] as String?) ?? '',
        kind: MessageKind.values.firstWhere(
          (k) => k.name == (m['kind'] as String? ?? 'text'),
          orElse: () => MessageKind.text,
        ),
        sentAt: DateTime.parse(m['sent_at'] as String),
        readAt: m['read_at'] == null ? null : DateTime.parse(m['read_at'] as String),
        attachmentUrl: m['attachment_url'] as String?,
        offerAmount: (m['offer_amount'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toInsertMap() => {
        'id': id,
        'thread_id': threadId,
        'sender_id': senderId,
        'body': body,
        'kind': kind.name,
        'sent_at': sentAt.toIso8601String(),
        if (attachmentUrl != null) 'attachment_url': attachmentUrl,
        if (offerAmount != null) 'offer_amount': offerAmount,
      };
}

class ChatThread {
  final String id;
  final String listingId;
  final String listingTitle;
  final String? listingImageUrl;
  final String buyerId;
  final String sellerId;
  final ChatMessage? lastMessage;
  final int unreadCount;

  const ChatThread({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.buyerId,
    required this.sellerId,
    this.listingImageUrl,
    this.lastMessage,
    this.unreadCount = 0,
  });

  String otherParty(String myId) => myId == buyerId ? sellerId : buyerId;
}

class TypingState {
  final String threadId;
  final String userId;
  final DateTime since;
  const TypingState({required this.threadId, required this.userId, required this.since});

  bool isStale(DateTime now) => now.difference(since).inSeconds > 4;
}
