import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    if (message.kind == MessageKind.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Center(
          child: Text(
            message.body,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ),
      );
    }

    final align = isMine ? Alignment.centerRight : Alignment.centerLeft;
    final color = isMine ? const Color(0xFF7AAAFF) : const Color(0xFF1F1F1F);
    final textColor = isMine ? Colors.black : Colors.white;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMine ? 16 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 16),
    );

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(color: color, borderRadius: radius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.kind == MessageKind.offer && message.offerAmount != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'Offer: \$${message.offerAmount!.toStringAsFixed(2)}',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            Text(message.body, style: TextStyle(color: textColor, fontSize: 14)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat.jm().format(message.sentAt.toLocal()),
                  style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 10),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 12,
                    color: message.isRead ? const Color(0xFF22DD66) : textColor.withOpacity(0.5),
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
