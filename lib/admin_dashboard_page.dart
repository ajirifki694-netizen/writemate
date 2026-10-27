
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Fitur ini akan dibuat pada langkah berikutnya.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WriteMate Admin'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.admin_panel_settings,
            size: 70,
            color: Colors.indigo,
          ),
          const SizedBox(height: 12),
          const Text(
            'Dashboard Admin',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Menu ini sekarang membuka halaman Seller.
          _menu(
            context,
            Icons.person_add_alt_1,
            'Pengajuan Seller',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const SellerApplicationsPage(),
                ),
              );
            },
          ),

          _menu(
            context,
            Icons.people_outline,
            'Pengguna',
          ),
          _menu(
            context,
            Icons.inventory_2_outlined,
            'Produk',
          ),
          _menu(
            context,
            Icons.receipt_long_outlined,
            'Pesanan',
          ),
          _menu(
            context,
            Icons.feedback_outlined,
            'Feedback',
          ),
          _menu(
            context,
            Icons.payments_outlined,
            'Pembayaran',
          ),
        ],
      ),
    );
  }

  Widget _menu(
    BuildContext context,
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap ?? () => _showComingSoon(context),
      ),
    );
  }
}

// =============================================
// HALAMAN PENGAJUAN SELLER
// =============================================

class SellerApplicationsPage extends StatelessWidget {
  const SellerApplicationsPage({super.key});

  Future<void> _processApplication({
    required BuildContext context,
    required String applicationId,
    required Map<String, dynamic> data,
    required String status,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final firestore = FirebaseFirestore.instance;

    try {
      final userId = data['userId']?.toString();

      if (userId == null || userId.isEmpty) {
        throw Exception('ID pengguna tidak ditemukan.');
      }

      final applicationRef = firestore
          .collection('seller_applications')
          .doc(applicationId);

      final userRef = firestore
          .collection('users')
          .doc(userId);

      final batch = firestore.batch();

      batch.update(applicationRef, {
        'status': status,
      });

      // Jika disetujui, ubah role pengguna menjadi seller.
      if (status == 'approved') {
        batch.update(userRef, {
          'role': 'seller',
        });
      }

      await batch.commit();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved'
                ? 'Pengajuan disetujui. Role Seller diberikan.'
                : 'Pengajuan Seller ditolak.',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memproses pengajuan: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('seller_applications')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan Seller'),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Gagal memuat pengajuan.\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada pengajuan Seller.',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final storeName =
                  data['storeName']?.toString() ??
                      'Tanpa nama toko';
              final email =
                  data['email']?.toString() ?? '-';
              final description =
                  data['description']?.toString() ?? '';
              final status =
                  data['status']?.toString() ?? 'pending';

              final isPending = status == 'pending';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Email: $email'),
                      const SizedBox(height: 12),
                      const Text(
                        'Deskripsi toko:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(description),
                      const SizedBox(height: 12),
                      Chip(
                        label: Text(
                          switch (status) {
                            'approved' => 'Disetujui',
                            'rejected' => 'Ditolak',
                            _ => 'Menunggu persetujuan',
                          },
                        ),
                      ),
                      if (isPending) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    _processApplication(
                                  context: context,
                                  applicationId: doc.id,
                                  data: data,
                                  status: 'rejected',
                                ),
                                child: const Text('Tolak'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: () =>
                                    _processApplication(
                                  context: context,
                                  applicationId: doc.id,
                                  data: data,
                                  status: 'approved',
                                ),
                                child: const Text('Setujui'),
                              ),
                            ),
                          ],
                        ),
                      ],
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
