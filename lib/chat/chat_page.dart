
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const Color _dark = Color(0xFF5A4052);
const Color _pink = Color(0xFFD77A9B);
const Color _lightPink = Color(0xFFFFEAF2);
const Color _background = Color(0xFFFFF9FC);
const Color _border = Color(0xFFE8CEDB);

class ChatPage extends StatefulWidget {
  final String orderId;
  final String buyerId;
  final String sellerId;
  final String productTitle;

  const ChatPage({
    super.key,
    required this.orderId,
    required this.buyerId,
    required this.sellerId,
    required this.productTitle,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _sending = false;

  CollectionReference<Map<String, dynamic>> get _messages =>
      FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.orderId)
          .collection('messages');

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _messageController.text.trim();

    if (user == null ||
        text.isEmpty ||
        _sending ||
        (user.uid != widget.buyerId &&
            user.uid != widget.sellerId)) {
      return;
    }

    setState(() => _sending = true);
    _messageController.clear();

    try {
      final db = FirebaseFirestore.instance;
      final chatRef = db.collection('chats').doc(widget.orderId);

      await db.runTransaction((transaction) async {
        final chatSnapshot = await transaction.get(chatRef);

        if (!chatSnapshot.exists) {
          throw Exception('Ruang chat belum tersedia.');
        }

        final chatData = chatSnapshot.data()!;

        if (chatData['buyerId'] != widget.buyerId ||
            chatData['sellerId'] != widget.sellerId ||
            chatData['status'] != 'active') {
          throw Exception(
            'Ruang chat tidak valid atau sudah ditutup.',
          );
        }

        final messageRef = _messages.doc();

        transaction.set(messageRef, {
          'senderId': user.uid,
          'text': text,
          'createdAt': FieldValue.serverTimestamp(),
        });

        transaction.update(chatRef, {
          'lastMessage': text,
          'lastMessageAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      if (!mounted) return;

      _messageController.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pesan gagal dikirim: $e'),
          backgroundColor: _dark,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null ||
        (currentUser.uid != widget.buyerId &&
            currentUser.uid != widget.sellerId)) {
      return Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _lightPink,
          foregroundColor: _dark,
          elevation: 0,
          title: const Text('Chat'),
        ),
        body: const Center(
          child: Text(
            'Kamu tidak memiliki akses ke chat ini.',
            style: TextStyle(color: _dark),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _lightPink,
        foregroundColor: _dark,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chat Pesanan',
              style: TextStyle(
                color: _dark,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              widget.productTitle,
              style: const TextStyle(
                color: _dark,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: _messages
                  .orderBy('createdAt', descending: true)
                  .limit(100)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Gagal memuat pesan. Periksa koneksi.',
                      style: TextStyle(color: _dark),
                    ),
                  );
                }

                if (snapshot.connectionState ==
                        ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: _pink,
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: _lightPink,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline,
                              color: _pink,
                              size: 42,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Belum ada pesan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _dark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Mulai percakapan di sini.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final isMine =
                        data['senderId'] == currentUser.uid;
                    final messageText =
                        data['text'] as String? ?? '';
                    final createdAt = data['createdAt'];

                    String timeText = '';
                    if (createdAt is Timestamp) {
                      final date = createdAt.toDate();
                      final hour =
                          date.hour.toString().padLeft(2, '0');
                      final minute =
                          date.minute.toString().padLeft(2, '0');
                      timeText = '$hour:$minute';
                    }

                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth:
                              MediaQuery.of(context).size.width * 0.78,
                        ),
                        margin: const EdgeInsets.symmetric(
                          vertical: 5,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: isMine ? _lightPink : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(
                              isMine ? 16 : 4,
                            ),
                            bottomRight: Radius.circular(
                              isMine ? 4 : 16,
                            ),
                          ),
                          border: Border.all(
                            color: _border,
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _dark.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              messageText,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.4,
                                color: _dark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  isMine ? 'Kamu' : 'Lawan chat',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black54,
                                  ),
                                ),
                                if (timeText.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    timeText,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.black45,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: _border),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      textCapitalization:
                          TextCapitalization.sentences,
                      style: const TextStyle(
                        color: _dark,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tulis pesan...',
                        hintStyle: const TextStyle(
                          color: Colors.black45,
                        ),
                        counterText: '',
                        filled: true,
                        fillColor: _background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: _border,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: _border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: _pink,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: IconButton(
                      onPressed: _sending ? null : _sendMessage,
                      style: IconButton.styleFrom(
                        backgroundColor: _pink,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            _pink.withValues(alpha: 0.5),
                        shape: const CircleBorder(),
                      ),
                      icon: _sending
                          ? const SizedBox(
                              width: 21,
                              height: 21,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
