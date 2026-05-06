import 'package:flutter_realtime_chat_marketplace/features/chat/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ChatMessage.fromMap parses kind and offer', () {
    final m = ChatMessage.fromMap({
      'id': 'a',
      'thread_id': 't',
      'sender_id': 'u',
      'body': 'take \$50',
      'kind': 'offer',
      'sent_at': '2026-05-06T00:00:00Z',
      'offer_amount': 50.0,
    });
    expect(m.kind, MessageKind.offer);
    expect(m.offerAmount, 50.0);
    expect(m.isRead, false);
  });

  test('unknown kind falls back to text', () {
    final m = ChatMessage.fromMap({
      'id': 'a',
      'thread_id': 't',
      'sender_id': 'u',
      'body': 'hi',
      'kind': 'gibberish',
      'sent_at': '2026-05-06T00:00:00Z',
    });
    expect(m.kind, MessageKind.text);
  });
}
