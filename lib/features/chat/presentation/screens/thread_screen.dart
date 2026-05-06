import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../providers.dart';
import '../widgets/message_bubble.dart';

class ThreadScreen extends ConsumerStatefulWidget {
  const ThreadScreen({super.key, required this.thread});
  final ChatThread thread;

  @override
  ConsumerState<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends ConsumerState<ThreadScreen> {
  final _input = TextEditingController();
  Timer? _typingDebounce;

  @override
  void dispose() {
    _input.dispose();
    _typingDebounce?.cancel();
    super.dispose();
  }

  void _onChange(String _) {
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 600), () {
      ref.read(threadMessagesProvider(widget.thread.id).notifier).emitTyping();
    });
  }

  Future<void> _send() async {
    final text = _input.text;
    _input.clear();
    await ref.read(threadMessagesProvider(widget.thread.id).notifier).sendText(text);
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserIdProvider);
    final state = ref.watch(threadMessagesProvider(widget.thread.id));
    final typing = ref.watch(typingProvider(widget.thread.id));

    final theyTyping = typing.maybeWhen(
      data: (t) => t.userId != me && !t.isStale(DateTime.now()),
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.thread.listingTitle, style: const TextStyle(fontSize: 14)),
            if (theyTyping)
              const Text('typing...', style: TextStyle(fontSize: 11, color: Color(0xFF7AAAFF))),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
              data: (messages) => ListView.builder(
                reverse: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: messages.length,
                itemBuilder: (_, i) {
                  final m = messages[i];
                  return MessageBubble(message: m, isMine: m.senderId == me);
                },
              ),
            ),
          ),
          _Composer(controller: _input, onSend: _send, onChanged: _onChange),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend, required this.onChanged});
  final TextEditingController controller;
  final VoidCallback onSend;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: const Color(0xFF111111),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Message...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            IconButton(icon: const Icon(Icons.send, color: Color(0xFF7AAAFF)), onPressed: onSend),
          ],
        ),
      ),
    );
  }
}
