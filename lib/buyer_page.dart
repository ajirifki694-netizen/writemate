import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'search_page.dart';
import 'product_detail_page.dart';
import 'buyer_orders_page.dart';

class BuyerPage extends StatefulWidget {
  const BuyerPage({super.key});

  @override
  State<BuyerPage> createState() => _BuyerPageState();
}

class _BuyerPageState extends State<BuyerPage> {
  int selectedIndex = 0;

  void openSearchPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchPage()),
    );
  }

  void openProductDetail(Map<String, dynamic> product) {
    final title = (product['title'] ?? 'Produk tanpa judul').toString();
    final category = (product['category'] ?? 'Lainnya').toString();
    final rawPrice = product['price'];
    final price = rawPrice is num
        ? 'Rp${rawPrice.toStringAsFixed(0)}'
        : 'Rp${rawPrice ?? 0}';
    final rawRating = product['rating'];
    final rating = rawRating is num ? rawRating.toDouble() : 0.0;
    final sellerId = (product['sellerId'] ?? '').toString();

    if (sellerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID Seller produk ini belum tersedia.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(
        productId: (product['id'] ?? '').toString(),
        title: title,
        category: category,
        price: price,
        rating: rating,
        seller: 'Writer WriteMate',
        sellerId: sellerId,
      ),
      ),
    );
  }

  void openCategory(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchPage(initialKeyword: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFEAF2),
        elevation: 0,
        title: const Text(
          'WriteMate',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF5A4052),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Belum ada notifikasi baru')),
              );
            },
            icon: const Icon(
              Icons.notifications_none,
              color: Color(0xFF5A4052),
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Halaman profil akan dibuat selanjutnya'),
                ),
              );
            },
            icon: const Icon(
              Icons.person_outline,
              color: Color(0xFF5A4052),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Halo, Pembeli! 👋',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A4052),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Mau menulis atau mencari apa hari ini?',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // SEARCH BAR
            GestureDetector(
              onTap: openSearchPage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Color(0xFFD77A9B)),
                    SizedBox(width: 12),
                    Text(
                      'Cari produk atau jasa...',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // KATEGORI
            const Text(
              'Kategori',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A4052),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _categoryItem(Icons.menu_book, 'Novel'),
                  _categoryItem(Icons.article, 'Cerpen'),
                  _categoryItem(Icons.edit, 'Editing'),
                  _categoryItem(Icons.book, 'Ebook'),
                  _categoryItem(Icons.more_horiz, 'Lainnya'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // REKOMENDASI
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '✨ Rekomendasi Untukmu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A4052),
                  ),
                ),
                TextButton(
                  onPressed: openSearchPage,
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // PRODUK DARI FIRESTORE
            SizedBox(
              height: 245,
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Gagal memuat produk. Periksa koneksi atau izin Firestore.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('Belum ada produk dari Seller.'),
                    );
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      return _productCard({
                        ...data,
                        'id': docs[index].id,
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 25),

            // PRODUK POPULER (CONTOH STATIS)
            const Text(
              '🔥 Produk Populer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A4052),
              ),
            ),
            const SizedBox(height: 12),
            _popularProduct('Jasa Editing Novel', 'Editing', 'Rp75.000', 4.9),
            _popularProduct('Jasa Penulisan Cerpen', 'Cerpen', 'Rp50.000', 4.8),
            _popularProduct('Ebook Belajar Menulis', 'Ebook', 'Rp25.000', 4.7),
            const SizedBox(height: 25),

            // PRODUK TERBARU (CONTOH STATIS)
            const Text(
              '🆕 Produk Terbaru',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A4052),
              ),
            ),
            const SizedBox(height: 12),
            _popularProduct('Jasa Penulisan Novel', 'Novel', 'Rp100.000', 4.9),
            _popularProduct('Ebook Panduan Menulis', 'Ebook', 'Rp30.000', 4.8),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          if (index == 0) {
            setState(() => selectedIndex = 0);
          } else if (index == 1) {
            openSearchPage();
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BuyerOrdersPage(),
              ),
            );
          } else if (index == 3) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Halaman Profil akan dibuat selanjutnya'),
              ),
            );
          }
        },
        selectedItemColor: const Color(0xFFD77A9B),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Cari',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _categoryItem(IconData icon, String title) {
    return GestureDetector(
      onTap: () => openCategory(title),
      child: Container(
        width: 85,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFD77A9B), size: 30),
            const SizedBox(height: 7),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> product) {
    final category = (product['category'] ?? 'Lainnya').toString();
    final title = (product['title'] ?? 'Produk tanpa judul').toString();
    final rawPrice = product['price'];
    final price = rawPrice is num
        ? 'Rp${rawPrice.toStringAsFixed(0)}'
        : 'Rp${rawPrice ?? 0}';
    final rawRating = product['rating'];
    final rating = rawRating is num ? rawRating.toString() : '0';

    return GestureDetector(
      onTap: () => openProductDetail(product),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEAF2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.menu_book,
                    size: 45,
                    color: Color(0xFFD77A9B),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFD77A9B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF5A4052),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(rating, style: const TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                price,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5A4052),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Produk populer/terbaru masih berupa contoh statis, bukan data Seller.
  Widget _popularProduct(
    String title,
    String category,
    String price,
    double rating,
  ) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk contoh ini belum terhubung ke data Seller.'),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEAF2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.book,
                color: Color(0xFFD77A9B),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5A4052),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 15, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        rating.toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    price,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD77A9B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
