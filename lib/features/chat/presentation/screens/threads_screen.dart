import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/models.dart';
import '../providers.dart';
import 'thread_screen.dart';

class ThreadsScreen extends ConsumerWidget {
  const ThreadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(threadsProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, title: const Text('Messages')),
      body: threads.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('No conversations yet.', style: TextStyle(color: Colors.white38)),
            );
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) => _ThreadTile(thread: list[i]),
          );
        },
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.thread});
  final ChatThread thread;

  @override
  Widget build(BuildContext context) {
    final last = thread.lastMessage;
    final preview = last == null
        ? '...'
        : last.kind == MessageKind.offer
            ? 'Offer: \$${last.offerAmount?.toStringAsFixed(2) ?? '?'}'
            : last.body;
    return ListTile(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ThreadScreen(thread: thread)),
      ),
      leading: thread.listingImageUrl == null
          ? const CircleAvatar(backgroundColor: Color(0xFF222222), child: Icon(Icons.shopping_bag, color: Colors.white))
          : CircleAvatar(backgroundImage: CachedNetworkImageProvider(thread.listingImageUrl!)),
      title: Text(thread.listingTitle, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        preview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white54),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (last != null)
            Text(
              DateFormat.jm().format(last.sentAt.toLocal()),
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          if (thread.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(
                color: Color(0xFF7AAAFF),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Text(
                thread.unreadCount.toString(),
                style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}
