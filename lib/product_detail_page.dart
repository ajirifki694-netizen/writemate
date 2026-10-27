import 'package:flutter/material.dart';
import 'order_request_page.dart';

class ProductDetailPage extends StatelessWidget {
  final String title;
  final String category;
  final String price;
  final double rating;
  final String seller;
  final String sellerId;
  final String productId;

  const ProductDetailPage({
    super.key,
    required this.title,
    required this.category,
    required this.price,
    required this.rating,
    required this.seller,
    required this.sellerId,
    required this.productId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FC),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFFEAF2),
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF5A4052),
          ),
        ),
        title: const Text(
          'Detail Produk',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF5A4052),
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // GAMBAR PRODUK
            Container(
              width: double.infinity,
              height: 230,
              color: const Color(0xFFFFEAF2),
              child: const Center(
                child: Icon(
                  Icons.menu_book,
                  size: 90,
                  color: Color(0xFFD77A9B),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // KATEGORI
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFD77A9B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // JUDUL
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5A4052),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // RATING
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        rating.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Rating Produk',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // HARGA
                  const Text(
                    'Harga',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD77A9B),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // PENJUAL
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEAF2),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFFD77A9B),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Writer / Penjual',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              seller,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // DESKRIPSI
                  const Text(
                    'Deskripsi Produk',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5A4052),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Produk ini merupakan layanan atau produk digital '
                    'yang berkaitan dengan dunia menulis. Pembeli dapat '
                    'memesan produk sesuai kebutuhan dan mendapatkan '
                    'hasil sesuai dengan deskripsi yang diberikan oleh writer.',
                    style: TextStyle(
                      height: 1.6,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // TOMBOL
                  Row(
                    children: [

                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Produk ditambahkan ke keranjang',
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFD77A9B),
                            side: const BorderSide(
                              color: Color(0xFFD77A9B),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Icon(
                            Icons.shopping_cart_outlined,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        flex: 3,
                        child: ElevatedButton(
                          onPressed: () {
                         Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => OrderRequestPage(
                            productTitle: title,
                            category: category,
                            sellerId: sellerId,
                          ),
                        ),
                      );
                    },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD77A9B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Pesan Sekarang',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}