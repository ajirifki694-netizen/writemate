
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_page.dart';

class ChatListPage extends StatelessWidget {
  final bool isSeller;

  const ChatListPage({
    super.key,
    this.isSeller = false,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pesan')),
        body: const Center(
          child: Text('Silakan login untuk melihat percakapan.'),
        ),
      );
    }

    final chats = FirebaseFirestore.instance.collection('chats');

    final chatQuery = chats
        .where(
          isSeller ? 'sellerId' : 'buyerId',
          isEqualTo: user.uid,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Pesan')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: chatQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Gagal memuat percakapan: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final allChats = snapshot.data?.docs ?? [];

          // Tampilkan hanya chat yang statusnya aktif.
          final chatDocs = allChats.where((doc) {
            final data = doc.data();
            return data['status'] == 'active';
          }).toList();

          chatDocs.sort((a, b) {
            final aTime = a.data()['lastMessageAt'] as Timestamp?;
            final bTime = b.data()['lastMessageAt'] as Timestamp?;

            return (bTime?.millisecondsSinceEpoch ?? 0).compareTo(
              aTime?.millisecondsSinceEpoch ?? 0,
            );
          });

          if (chatDocs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Belum ada percakapan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Percakapan aktif akan muncul di sini.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: chatDocs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = chatDocs[index];
              final data = doc.data();

              final buyerId = data['buyerId'] as String? ?? '';
              final sellerId = data['sellerId'] as String? ?? '';
              final productTitle =
                  data['productTitle'] as String? ?? 'Pesanan';
              final lastMessage =
                  data['lastMessage'] as String? ?? '';

              final isBuyer = buyerId == user.uid;
              final otherParty = isBuyer ? 'Penjual' : 'Pembeli';

              final timestamp =
                  data['lastMessageAt'] as Timestamp?;

              final dateText = timestamp == null
                  ? ''
                  : _formatDate(timestamp.toDate());

              return ListTile(
                leading: CircleAvatar(
                  child: Icon(
                    isBuyer
                        ? Icons.storefront_outlined
                        : Icons.person_outline,
                  ),
                ),
                title: Text(
                  productTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherParty,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lastMessage.isEmpty
                          ? 'Mulai percakapan'
                          : lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (dateText.isNotEmpty)
                      Text(
                        dateText,
                        style: const TextStyle(fontSize: 11),
                      ),
                    const SizedBox(height: 5),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                isThreeLine: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        orderId: doc.id,
                        buyerId: buyerId,
                        sellerId: sellerId,
                        productTitle: productTitle,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();

    final sameDay = now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;

    if (sameDay) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}
