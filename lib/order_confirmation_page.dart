
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../chat/chat_page.dart';

class OrderConfirmationPage extends StatefulWidget {
  final String productTitle;
  final String category;
  final String requestTitle;
  final String genre;
  final String reference;
  final String sellerId;

  const OrderConfirmationPage({
    super.key,
    required this.productTitle,
    required this.category,
    required this.sellerId,
    required this.requestTitle,
    required this.genre,
    required this.reference,
  });

  @override
  State<OrderConfirmationPage> createState() =>
      _OrderConfirmationPageState();
}

class _OrderConfirmationPageState
    extends State<OrderConfirmationPage> {
  bool isConfirmed = false;
  bool isSaving = false;

  String? savedOrderId;
  String? savedBuyerId;

  Future<void> confirmOrder() async {
  if (isSaving || isConfirmed) return;

  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Silakan login terlebih dahulu.'),
      ),
    );
    return;
  }

  if (widget.sellerId.trim().isEmpty || widget.sellerId == user.uid) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Penjual tidak valid.'),
      ),
    );
    return;
  }

  setState(() => isSaving = true);

  try {
    final db = FirebaseFirestore.instance;

    final orderRef = db
        .collection('users')
        .doc(user.uid)
        .collection('orders')
        .doc();

    final orderId = orderRef.id;
    final chatRef = db.collection('chats').doc(orderId);
    final batch = db.batch();

    // Simpan pesanan pembeli lengkap dengan email & nama
    batch.set(orderRef, {
      'id': orderId,
      'buyerId': user.uid,
      'buyerEmail': user.email ?? '',
      'buyerName': user.displayName ?? user.email?.split('@').first ?? 'Pembeli',
      'sellerId': widget.sellerId,
      'productTitle': widget.productTitle,
      'category': widget.category,
      'requestTitle': widget.requestTitle,
      'genre': widget.genre,
      'reference': widget.reference,
      'status': 'Menunggu Penjual',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Buat ruang chat untuk pesanan yang sama
    batch.set(chatRef, {
      'orderId': orderId,
      'buyerId': user.uid,
      'sellerId': widget.sellerId,
      'productTitle': widget.productTitle,
      'status': 'active',
      'lastMessage': '',
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    if (!mounted) return;

    setState(() {
      savedOrderId = orderId;
      savedBuyerId = user.uid;
      isConfirmed = true;
      isSaving = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() => isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pesanan dan chat gagal dibuat. '
          'Periksa koneksi serta Firestore Rules. ($e)',
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }
}

  void openSellerChat() {
    if (savedOrderId == null || savedBuyerId == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          orderId: savedOrderId!,
          buyerId: savedBuyerId!,
          sellerId: widget.sellerId,
          productTitle: widget.productTitle,
        ),
      ),
    );
  }

  Widget detail(
    BuildContext context,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value.trim().isEmpty ? '-' : value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Pesanan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(
            isConfirmed
                ? Icons.check_circle_rounded
                : Icons.receipt_long_rounded,
            size: 72,
            color: colors.primary,
          ),
          const SizedBox(height: 12),
          Text(
            isConfirmed
                ? 'Pesanan Berhasil!'
                : 'Periksa Pesananmu',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isConfirmed
                ? 'Pesanan dan ruang chat berhasil dibuat.'
                : 'Pastikan informasi berikut sudah benar.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  detail(
                    context,
                    'Produk atau Jasa',
                    widget.productTitle,
                  ),
                  detail(
                    context,
                    'Kategori',
                    widget.category,
                  ),
                  detail(
                    context,
                    'Judul Permintaan',
                    widget.requestTitle,
                  ),
                  detail(context, 'Genre', widget.genre),
                  detail(
                    context,
                    'Referensi atau Catatan',
                    widget.reference,
                  ),
                  if (isConfirmed)
                    detail(
                      context,
                      'Status',
                      'Menunggu Penjual',
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (isConfirmed) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: openSellerChat,
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Chat Penjual'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil(
                    (route) => route.isFirst,
                  );
                },
                icon: const Icon(Icons.home_outlined),
                label: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Kembali ke Beranda'),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isSaving ? null : confirmOrder,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    isSaving
                        ? 'Menyimpan...'
                        : 'Konfirmasi Pesanan',
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: isSaving
                  ? null
                  : () => Navigator.pop(context),
              child: const Text('Kembali dan Edit'),
            ),
          ],
        ],
      ),
    );
  }
}
