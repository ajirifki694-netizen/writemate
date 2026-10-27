import 'package:flutter/material.dart';
import 'product_detail_page.dart';

class SearchPage extends StatefulWidget {
  final String? initialKeyword;

  const SearchPage({
    super.key,
    this.initialKeyword,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController searchController = TextEditingController();

  final List<Map<String, dynamic>> products = [
    {
      'title': 'Jasa Editing Novel',
      'category': 'Editing',
      'price': 'Rp75.000',
      'rating': 4.9,
    },
    {
      'title': 'Jasa Penulisan Cerpen',
      'category': 'Cerpen',
      'price': 'Rp50.000',
      'rating': 4.8,
    },
    {
      'title': 'Ebook Belajar Menulis',
      'category': 'Ebook',
      'price': 'Rp25.000',
      'rating': 4.7,
    },
    {
      'title': 'Jasa Penulisan Novel',
      'category': 'Novel',
      'price': 'Rp100.000',
      'rating': 4.9,
    },
  ];

  List<Map<String, dynamic>> filteredProducts = [];

  
@override
void initState() {
  super.initState();

  final keyword = widget.initialKeyword;

  if (keyword != null && keyword.isNotEmpty) {
    searchController.text = keyword;
    filteredProducts = products.where((product) {
      return product['category']
          .toString()
          .toLowerCase() == keyword.toLowerCase();
    }).toList();
  } else {
    filteredProducts = products;
  }
}
  // =========================
  // FUNGSI PENCARIAN
  // =========================

  void searchProduct(String keyword) {
    final searchKeyword = keyword.trim().toLowerCase();

    setState(() {
      if (searchKeyword.isEmpty) {
        filteredProducts = products;
        return;
      }

      filteredProducts = products.where((product) {
        final title = product['title'].toString().toLowerCase();
        final category = product['category'].toString().toLowerCase();

        return title.contains(searchKeyword) ||
            category.contains(searchKeyword);
      }).toList();
    });
  }

  // =========================
  // HALAMAN UTAMA
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FC),

      // =========================
      // APP BAR
      // =========================

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
          'Pencarian',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF5A4052),
          ),
        ),
      ),

      // =========================
      // BODY
      // =========================

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // =========================
            // SEARCH BAR
            // =========================

            TextField(
              controller: searchController,

              onChanged: searchProduct,

              decoration: InputDecoration(
                hintText: 'Cari produk atau jasa...',

                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFFD77A9B),
                ),

                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          searchController.clear();
                          searchProduct('');
                        },
                        icon: const Icon(Icons.close),
                      )
                    : null,

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 25),

            // =========================
            // KATEGORI
            // =========================

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
              height: 45,

              child: ListView(
                scrollDirection: Axis.horizontal,

                children: [
                  _categoryButton('Semua'),
                  _categoryButton('Novel'),
                  _categoryButton('Cerpen'),
                  _categoryButton('Editing'),
                  _categoryButton('Ebook'),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // =========================
            // HASIL PENCARIAN
            // =========================

            Text(
              'Hasil Pencarian (${filteredProducts.length})',

              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A4052),
              ),
            ),

            const SizedBox(height: 12),

            // =========================
            // LIST PRODUK
            // =========================

            Expanded(
              child: filteredProducts.isEmpty

                  // JIKA TIDAK ADA PRODUK
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          Icon(
                            Icons.search_off,
                            size: 60,
                            color: Color(0xFFD77A9B),
                          ),

                          SizedBox(height: 12),

                          Text(
                            'Produk tidak ditemukan',

                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            'Coba gunakan kata kunci lain',

                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )

                  // JIKA ADA PRODUK
                  : ListView.builder(
                      itemCount: filteredProducts.length,

                      itemBuilder: (context, index) {
                        return _productItem(
                          filteredProducts[index],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // TOMBOL KATEGORI
  // =========================

  Widget _categoryButton(String title) {
    return Container(
      margin: const EdgeInsets.only(right: 10),

      child: ElevatedButton(
        
        onPressed: () {
          if (title == 'Semua') {
            searchController.clear();
            searchProduct('');
          } else {
            searchController.text = title;
            searchProduct(title);
          }

          setState(() {});
        },

        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFEAF2),
          foregroundColor: const Color(0xFF5A4052),
          elevation: 0,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        child: Text(title),
      ),
    );
  }

  // =========================
  // ITEM PRODUK
  // =========================

  Widget _productItem(Map<String, dynamic> product) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,

          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
            productId: (product['id'] ?? '').toString(),
            title: product['title'],
            category: product['category'],
            price: product['price'],
            rating: product['rating'],
            seller: 'Writer WriteMate',
            sellerId: product['sellerId'] ?? '',
          ),
          ),
        );
      },

      borderRadius: BorderRadius.circular(15),

      child: Container(
        margin: const EdgeInsets.only(bottom: 12),

        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(15),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        child: Row(
          children: [

            // =========================
            // ICON PRODUK
            // =========================

            Container(
              width: 70,
              height: 70,

              decoration: BoxDecoration(
                color: const Color(0xFFFFEAF2),
                borderRadius: BorderRadius.circular(12),
              ),

              child: const Icon(
                Icons.menu_book,
                size: 35,
                color: Color(0xFFD77A9B),
              ),
            ),

            const SizedBox(width: 15),

            // =========================
            // INFORMASI PRODUK
            // =========================

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  // KATEGORI
                  Text(
                    product['category'],

                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFD77A9B),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // JUDUL
                  Text(
                    product['title'],

                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF5A4052),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // RATING
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber,
                      ),

                      const SizedBox(width: 4),

                      Text(
                        product['rating'].toString(),

                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  // HARGA
                  Text(
                    product['price'],

                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5A4052),
                    ),
                  ),
                ],
              ),
            ),

            // =========================
            // ICON PANAH
            // =========================

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