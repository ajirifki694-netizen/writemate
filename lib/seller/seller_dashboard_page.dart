
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat/chat_list_page.dart';
import 'seller_products_page.dart';
import 'seller_orders_page.dart';

class SellerDashboardPage extends StatelessWidget {
  const SellerDashboardPage({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WriteMate Seller'),
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
  _menu(
    context,
    icon: Icons.inventory_2_outlined,
    title: 'Kelola Produk',
    subtitle: 'Tambah dan lihat produk toko',
    page: const SellerProductsPage(),
  ),

  _menu(
    context,
    icon: Icons.receipt_long_outlined,
    title: 'Pesanan Masuk',
    subtitle: 'Lihat permintaan pembeli',
    page: const SellerOrdersPage(),
  ),

  _menu(
    context,
    icon: Icons.chat_bubble_outline,
    title: 'Chat Pembeli',
    subtitle: 'Lihat dan balas pesan dari pembeli',
    page: const ChatListPage(isSeller: true),
  ),
],

      ),
    );
  }

  Widget _menu(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget page,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo, size: 30),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
    );
  }
}
