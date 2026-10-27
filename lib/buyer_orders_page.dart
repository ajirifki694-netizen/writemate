import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BuyerOrdersPage extends StatelessWidget {
  const BuyerOrdersPage({super.key});

  String formatDate(dynamic value) {
    DateTime? date;
    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }
    if (date == null) return '-';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)}';
  }

  Color statusColor(String status, BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    switch (status) {
      case 'Diterima':
        return Colors.green;
      case 'Ditolak':
        return colors.error;
      case 'Menunggu Penjual':
        return Colors.orange.shade800;
      default:
        return colors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Riwayat Pesanan')),
      body: user == null
          ? const Center(child: Text('Silakan login untuk melihat pesanan.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('orders')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Gagal memuat riwayat pesanan. Periksa koneksi dan Rules Firestore.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final documents = snapshot.data?.docs ?? [];
                if (documents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: colors.primary),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum ada pesanan',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text('Pesananmu akan muncul di sini.'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final doc = documents[index];
                    final order = doc.data();
                    final productTitle = order['productTitle']?.toString() ?? '-';
                    final requestTitle = order['requestTitle']?.toString() ?? '-';
                    final genre = order['genre']?.toString() ?? '-';
                    final category = order['category']?.toString() ?? '-';
                    final status = order['status']?.toString() ?? 'Menunggu Penjual';
                    final currentStatusColor = statusColor(status, context);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.receipt_long, color: colors.primary, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    productTitle,
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('Permintaan: $requestTitle'),
                            const SizedBox(height: 5),
                            Text('Genre: $genre'),
                            const SizedBox(height: 5),
                            Text('Kategori: $category'),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: currentStatusColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Status: $status',
                                style: TextStyle(color: currentStatusColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => BuyerOrderDetailPage(orderId: doc.id, order: order),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.visibility_outlined),
                                label: const Text('Lihat Detail Pesanan'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: colors.primary,
                                  foregroundColor: colors.onPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  minimumSize: const Size(double.infinity, 48),
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class BuyerOrderDetailPage extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> order;

  const BuyerOrderDetailPage({
    super.key,
    required this.orderId,
    required this.order,
  });

  String formatDate(dynamic value) {
    DateTime? date;
    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }
    if (date == null) return 'Belum tersedia';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)}';
  }

  Color statusColor(String status, BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    switch (status) {
      case 'Diterima':
        return Colors.green;
      case 'Ditolak':
        return colors.error;
      case 'Menunggu Penjual':
        return Colors.orange.shade800;
      default:
        return colors.primary;
    }
  }

  String statusMessage(String status) {
    switch (status) {
      case 'Diterima':
        return 'Penjual telah menerima pesananmu.';
      case 'Ditolak':
        return 'Maaf, penjual menolak pesanan ini.';
      case 'Menunggu Penjual':
        return 'Pesananmu sedang menunggu respons penjual.';
      default:
        return 'Status pesanan: $status';
    }
  }

  Widget detailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 5),
          SelectableText(
            value.isEmpty ? '-' : value,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Divider(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = order['status']?.toString() ?? 'Menunggu Penjual';
    final reference = order['reference']?.toString() ?? '';
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final currentStatusColor = statusColor(status, context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: Icon(Icons.receipt_long, size: 64, color: colors.primary)),
          const SizedBox(height: 12),
          Text(
            'Informasi Pesanan',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: currentStatusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: currentStatusColor.withValues(alpha: 0.35)),
            ),
            child: Column(
              children: [
                Icon(
                  status == 'Diterima'
                      ? Icons.check_circle
                      : status == 'Ditolak'
                          ? Icons.cancel
                          : Icons.hourglass_top,
                  color: currentStatusColor,
                  size: 36,
                ),
                const SizedBox(height: 8),
                Text(
                  status,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: currentStatusColor),
                ),
                const SizedBox(height: 6),
                Text(statusMessage(status), textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 24),
          detailRow(context, 'Nama produk', order['productTitle']?.toString() ?? '-'),
          detailRow(context, 'Kategori', order['category']?.toString() ?? '-'),
          detailRow(context, 'Judul permintaan', order['requestTitle']?.toString() ?? '-'),
          detailRow(context, 'Genre', order['genre']?.toString() ?? '-'),
          detailRow(context, 'Referensi / catatan', reference),
          detailRow(context, 'Tanggal pesanan', formatDate(order['createdAt'])),
          detailRow(context, 'ID pesanan', orderId),
        ],
      ),
    );
  }
}
