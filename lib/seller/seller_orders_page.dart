import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../email_service.dart';

class SellerOrdersPage extends StatelessWidget {
  const SellerOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Silakan login kembali.')),
      );
    }

    final query = FirebaseFirestore.instance
        .collectionGroup('orders')
        .where('sellerId', isEqualTo: user.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Masuk')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Gagal memuat pesanan: ${snapshot.error}'),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = (snapshot.data?.docs ?? [])
              .where((doc) {
                final status = doc.data()['status']?.toString();
                return status != 'Ditolak';
              })
              .toList();

          if (docs.isEmpty) {
            return const Center(child: Text('Belum ada pesanan masuk.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final order = doc.data();

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text(order['productTitle']?.toString() ?? 'Pesanan'),
                  subtitle: Text(
                    'Status: ${order['status'] ?? 'Menunggu Penjual'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SellerOrderDetailPage(
                          orderRef: doc.reference,
                          order: order,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class SellerOrderDetailPage extends StatelessWidget {
  final DocumentReference<Map<String, dynamic>> orderRef;
  final Map<String, dynamic> order;

  const SellerOrderDetailPage({
    super.key,
    required this.orderRef,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final createdAt = order['createdAt'];

    final dateText = createdAt is Timestamp
        ? createdAt.toDate().toLocal().toString().split('.').first
        : 'Belum tersedia';

    final status = order['status']?.toString() ?? 'Menunggu Penjual';
    final isPending = status == 'Menunggu Penjual';
    final isProcessing = status == 'Diproses' || status == 'Diterima';

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.receipt_long, size: 64),
          const SizedBox(height: 20),

          _detailRow('Nama produk', order['productTitle']?.toString() ?? '-'),
          _detailRow('Kategori', order['category']?.toString() ?? '-'),
          _detailRow('Judul permintaan', order['requestTitle']?.toString() ?? '-'),
          _detailRow('Genre', order['genre']?.toString() ?? '-'),
          _detailRow('Referensi', order['reference']?.toString() ?? '-'),
          _detailRow('Email Pembeli', order['buyerEmail']?.toString() ?? '-'),
          _detailRow('Status', status),
          _detailRow('Tanggal pesanan', dateText),

          const SizedBox(height: 20),

          if (isPending) ...[
            FilledButton.icon(
              onPressed: () => _acceptOrderAndSendPayment(context),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Terima & Kirim Pembayaran'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _decideOrder(context, newStatus: 'Ditolak'),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Tolak Pesanan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
          ] else if (isProcessing) ...[
            FilledButton.icon(
              onPressed: () => _completeOrderAndSendScript(context),
              icon: const Icon(Icons.send_outlined),
              label: const Text('Kirim Hasil Naskah via Email'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: status == 'Selesai'
                    ? Colors.blue.withValues(alpha: 0.10)
                    : status == 'Ditolak'
                        ? Colors.red.withValues(alpha: 0.10)
                        : Colors.grey.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status == 'Selesai'
                    ? 'Pesanan ini telah selesai dan naskah terkirim.'
                    : status == 'Ditolak'
                        ? 'Pesanan ini telah ditolak.'
                        : 'Pesanan ini sedang diproses.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
          ],

          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditSellerOrderPage(
                    orderRef: orderRef,
                    order: order,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('Ubah Status Pesanan'),
          ),

          const SizedBox(height: 12),

          if (status == 'Dibatalkan') ...[
            OutlinedButton.icon(
              onPressed: () => _deleteOrder(context),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Hapus Pesanan'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          SelectableText(value),
          const Divider(),
        ],
      ),
    );
  }

  // Dialog Terima Pesanan & Input Info Pembayaran QRIS/Rekening
  Future<void> _acceptOrderAndSendPayment(BuildContext context) async {
    final paymentController = TextEditingController(
      text: 'Silakan transfer/scan QRIS melalui link berikut:\nhttps://link-qris-atau-nomor-rekening-kamu.com',
    );

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Terima Pesanan & Kirim Pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Masukkan instruksi pembayaran / Link QRIS untuk pembeli:'),
            const SizedBox(height: 12),
            TextField(
              controller: paymentController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Contoh: Rekening BCA 12345678 a.n Penjual / Link QRIS',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Terima & Kirim Email'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      await orderRef.update({'status': 'Diterima'});

      final buyerEmail = order['buyerEmail']?.toString() ?? '';
      final buyerName = order['buyerName']?.toString() ?? 'Pembeli';
      final productTitle = order['productTitle']?.toString() ?? 'Pesanan Naskah';

      if (buyerEmail.isNotEmpty) {
        await EmailService.sendEmail(
          toEmail: buyerEmail,
          buyerName: buyerName,
          productTitle: productTitle,
          messageContent: 'Pesanan kamu telah diterima! Silakan lakukan pembayaran:\n\n${paymentController.text}',
        );
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan diterima & email pembayaran terkirim!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status: $e')),
      );
    }
  }

  // Dialog Selesaikan Pesanan & Input Link Berkas Naskah
  Future<void> _completeOrderAndSendScript(BuildContext context) async {
    final linkController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kirim Hasil Naskah'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Masukkan Link Berkas Naskah (Google Drive / Dropbox):'),
            const SizedBox(height: 12),
            TextField(
              controller: linkController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'https://drive.google.com/file/d/...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Kirim Naskah'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      await orderRef.update({
        'status': 'Selesai',
        'scriptLink': linkController.text.trim(),
      });

      final buyerEmail = order['buyerEmail']?.toString() ?? '';
      final buyerName = order['buyerName']?.toString() ?? 'Pembeli';
      final productTitle = order['productTitle']?.toString() ?? 'Pesanan Naskah';

      if (buyerEmail.isNotEmpty) {
        await EmailService.sendEmail(
          toEmail: buyerEmail,
          buyerName: buyerName,
          productTitle: productTitle,
          messageContent: 'Selamat! Pesanan naskah kamu telah selesai dikerjakan.',
          scriptLink: linkController.text.trim(),
        );
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan selesai & naskah berhasil dikirim ke email!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyelesaikan pesanan: $e')),
      );
    }
  }

  Future<void> _decideOrder(BuildContext context, {required String newStatus}) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tolak pesanan?'),
        content: const Text('Apakah kamu yakin ingin menolak pesanan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ya, Tolak'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      await orderRef.update({'status': newStatus});
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan berhasil ditolak.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status: $e')),
      );
    }
  }

  Future<void> _deleteOrder(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus pesanan?'),
        content: const Text('Pesanan ini akan dihapus secara permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      await orderRef.delete();
      if (!context.mounted) return;
      Navigator.of(context)..pop()..pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan berhasil dihapus.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus pesanan: $e')),
      );
    }
  }
}

class EditSellerOrderPage extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> orderRef;
  final Map<String, dynamic> order;

  const EditSellerOrderPage({
    super.key,
    required this.orderRef,
    required this.order,
  });

  @override
  State<EditSellerOrderPage> createState() => _EditSellerOrderPageState();
}

class _EditSellerOrderPageState extends State<EditSellerOrderPage> {
  late String _status;
  bool _saving = false;

  final List<String> _statuses = [
    'Menunggu Penjual',
    'Diterima',
    'Diproses',
    'Selesai',
    'Ditolak',
    'Dibatalkan',
  ];

  @override
  void initState() {
    super.initState();
    final currentStatus = widget.order['status']?.toString();
    _status = _statuses.contains(currentStatus) ? currentStatus! : 'Menunggu Penjual';
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      await widget.orderRef.update({'status': _status});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status pesanan berhasil diperbarui.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status pesanan: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestTitle = widget.order['requestTitle']?.toString() ?? '-';
    final reference = widget.order['reference']?.toString() ?? '-';

    return Scaffold(
      appBar: AppBar(title: const Text('Ubah Status Pesanan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            initialValue: requestTitle,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Judul permintaan',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: reference,
            readOnly: true,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Referensi',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(
              labelText: 'Status pesanan',
              border: OutlineInputBorder(),
            ),
            items: _statuses
                .map((status) => DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    ))
                .toList(),
            onChanged: _saving
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _status = value);
                    }
                  },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan Perubahan'),
          ),
        ],
      ),
    );
  }
}