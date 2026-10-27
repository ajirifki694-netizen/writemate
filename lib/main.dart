import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'app_theme.dart';
import 'profile_pages.dart';
import 'order_request_page.dart';
import 'admin_dashboard_page.dart';
import 'seller_application_page.dart';
import 'seller/seller_dashboard_page.dart';
import 'chat/chat_list_page.dart';
import 'buyer_orders_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const WriteMateApp());
}

class WriteMateApp extends StatelessWidget {
  const WriteMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, currentMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'WriteMate',
          themeMode: currentMode,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  static const String adminUid = 'qGe0HuHDXoVh1pxV32G3ru7TBWl2';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginPage();
        }

        if (user.uid == adminUid) {
          return const AdminDashboardPage();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (profileSnapshot.hasError ||
                !profileSnapshot.hasData ||
                !profileSnapshot.data!.exists) {
              return const Scaffold(
                body: Center(
                  child: Text('Profil pengguna gagal dimuat.'),
                ),
              );
            }

            final role = profileSnapshot.data!.data()?['role'];
            if (role == 'seller') {
              return const SellerDashboardPage();
            }
            return const MainPage();
          },
        );
      },
    );
  }
}


class Product {
  final String title;
  final String category;
  final String description;
  final int price;
  final double rating;
  final String seller;
  final String sellerId; 
  final IconData icon;
  final String imageUrl;

  const Product({
    required this.title,
    required this.category,
    required this.description,
    required this.price,
    required this.rating,
    required this.seller,
    this.sellerId = '', 
    required this.icon,
    this.imageUrl = '',
  });
}


const String bannerImageUrl = '';

const products = [
  Product(
    title: 'Ebook',
    category: 'Ebook',
    description: 'Panduan dasar menyusun ide, tokoh, alur, dan konflik dalam cerita.',
    price: 25000,
    rating: 4.8,
    seller: 'WriteAcademy',
    icon: Icons.menu_book_rounded,
  ),
  Product(
    title: 'Jasa Penyuntingan Naskah',
    category: 'Penyuntingan',
    description: 'Penyuntingan ejaan, tata bahasa, alur, dan konsistensi naskah.',
    price: 75000,
    rating: 4.9,
    seller: 'EditorPro',
    icon: Icons.edit_note_rounded,
  ),
  Product(
    title: 'Cerpen',
    category: 'Ide Tulisan',
    description: 'ide cerita pendek untuk membantu memulai tulisan baru.',
    price: 15000,
    rating: 4.6,
    seller: 'RuangKata',
    icon: Icons.lightbulb_outline_rounded,
  ),
  Product(
    title: 'Jasa Penulisan Cerita',
    category: 'Penulisan',
    description: 'Layanan penulisan cerita sesuai tema dan kebutuhan pengguna.',
    price: 120000,
    rating: 4.7,
    seller: 'KataKreatif',
    icon: Icons.create_rounded,
  ),
  Product(
    title: 'Novel',
    category: 'Novel',
    description: 'Novel fiksi tentang persahabatan, impian, dan perjalanan hidup.',
    price: 45000,
    rating: 4.8,
    seller: 'PenaSenja',
    icon: Icons.auto_stories_rounded,
  ),
];

Product productFromFirestore(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  final data = doc.data();
  final rawPrice = data['price'];
  final price = rawPrice is num
      ? rawPrice.toInt()
      : int.tryParse(rawPrice?.toString() ?? '') ?? 0;

  
return Product(
  title: data['title']?.toString() ?? 'Produk tanpa judul',
  category: data['category']?.toString() ?? 'Lainnya',
  description: data['description']?.toString() ?? '',
  price: price,
  rating: data['rating'] is num
      ? (data['rating'] as num).toDouble()
      : 0.0,
  seller: data['sellerName']?.toString() ??
      data['seller']?.toString() ??
      'Seller WriteMate',
  sellerId: data['sellerId']?.toString() ?? '',
  icon: Icons.auto_stories_rounded,
  imageUrl: data['imageUrl']?.toString() ?? '',
);
}


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan kata sandi wajib diisi.')),
      );
      return;
    }
    setState(() => loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      var message = 'Login gagal. Periksa koneksi dan data akunmu.';
      if (['invalid-credential', 'wrong-password', 'user-not-found']
          .contains(e.code)) {
        message = 'Email atau kata sandi salah.';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid.';
      } else if (e.code == 'too-many-requests') {
        message = 'Terlalu banyak percobaan. Coba lagi nanti.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terjadi kesalahan. Coba lagi.')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.menu_book_rounded,
                      size: 58, color: colors.primary),
                ),
                const SizedBox(height: 20),
                const Text('WriteMate',
                    style:
                        TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Temukan inspirasi dan layanan menulis',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.onSurfaceVariant)),
                const SizedBox(height: 32),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Kata Sandi',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => loading ? null : login(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading ? null : login,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Masuk'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                  child: const Text('Belum punya akun? Daftar di sini'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua kolom wajib diisi.')),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kata sandi minimal 6 karakter.')),
      );
      return;
    }
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi kata sandi tidak cocok.')),
      );
      return;
    }
    setState(() => loading = true);
    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw Exception('Data pengguna kosong.');
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'username': username,
        'email': email,
        'role': 'buyer',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Registrasi berhasil! Selamat datang di WriteMate.')),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      var message = 'Registrasi gagal. Silakan coba lagi.';
      if (e.code == 'email-already-in-use') {
        message = 'Email ini sudah terdaftar. Silakan login.';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid.';
      } else if (e.code == 'weak-password') {
        message = 'Kata sandi terlalu lemah.';
      } else if (e.code == 'operation-not-allowed') {
        message =
            'Login email dan kata sandi belum diaktifkan di Firebase.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Akun mungkin sudah dibuat, tetapi profil gagal disimpan. Periksa koneksi dan Firestore.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Akun')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.person_add_alt_1_rounded,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  const Text('Gabung dengan WriteMate',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: usernameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Kata Sandi (minimal 6 karakter)',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Konfirmasi Kata Sandi',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: loading ? null : register,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Daftar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;
  String selectedCategory = 'Semua';
  final List<String> categories = const [
    'Semua',
    'Novel',
    'Cerpen',
    'Ebook',
    'Ide Tulisan',
    'Penulisan',
    'Penyuntingan'
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final firestoreProducts = snapshot.hasData
            ? snapshot.data!.docs.map(productFromFirestore).toList()
            : <Product>[];

        // Produk dummy lama tetap menjadi fallback agar tampilan lama tidak kosong.
        final visibleProducts =
            firestoreProducts.isNotEmpty ? firestoreProducts : products;

        final pages = <Widget>[
          HomeTab(
            categories: categories,
            onProductTap: showProduct,
            onCategoryTap: (category) => setState(() {
              selectedCategory = category;
              currentIndex = 1;
            }),
            productList: visibleProducts,
          ),
          SearchTab(
            onProductTap: showProduct,
            initialCategory: selectedCategory,
            productList: visibleProducts,
          ),
          const BuyerOrdersPage(),
          const ChatListPage(),
          const ProfileTab(),
        ];

        return Scaffold(
          body: IndexedStack(index: currentIndex, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) =>
                setState(() => currentIndex = index),
            destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.search),
              label: 'Cari',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              label: 'Pesanan',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Pesan',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'Profil',
            ),
          ],
          ),
        );
      },
    );
  }

  void showProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(
          product: product,
          onOrder: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => OrderRequestPage(
                    productTitle: product.title,
                    category: product.category,
                    sellerId: product.sellerId,
                  ),
              ),
            );
          },
        ),
      ),
    );
  }

  void showFeedback(Product product) {
    showDialog(
      context: context,
      builder: (_) => FeedbackDialog(product: product),
    );
  }
}

class HomeTab extends StatelessWidget {
  final List<String> categories;
  final void Function(Product) onProductTap;
  final void Function(String) onCategoryTap;
  final List<Product> productList;

  const HomeTab({
    super.key,
    required this.categories,
    required this.onProductTap,
    required this.onCategoryTap,
    required this.productList,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;
          final crossAxisCount = constraints.maxWidth >= 1000
              ? 4
              : (constraints.maxWidth >= 600 ? 3 : 2);
          final recommendedProducts = productList.take(3).toList();
          final latestProducts = productList.skip(3).toList();

          return ListView(
            padding: EdgeInsets.symmetric(
                horizontal: isWide ? 28 : 16, vertical: 18),
            children: [
              Text('Halo, Penulis! 👋',
                  style:
                      TextStyle(fontSize: 16, color: colors.onSurfaceVariant)),
              const SizedBox(height: 4),
              const Text('Apa yang ingin kamu tulis hari ini?',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              Container(
                padding: EdgeInsets.all(isWide ? 26 : 20),
                decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(24)),
                child: Row(children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Temukan produk dan jasa kepenulisan favoritmu.',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSecondaryContainer)),
                          const SizedBox(height: 8),
                          Text(
                              'Jelajahi ebook, novel, ide tulisan, dan layanan menulis.',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: colors.onSecondaryContainer
                                      .withValues(alpha: 0.82))),
                        ]),
                  ),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: bannerImageUrl.trim().isNotEmpty
                        ? Image.network(
                            bannerImageUrl,
                            width: isWide ? 150 : 92,
                            height: isWide ? 110 : 78,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                                Icons.broken_image_outlined,
                                size: isWide ? 76 : 58,
                                color: colors.primary),
                          )
                        : Icon(Icons.auto_stories_rounded,
                            size: isWide ? 76 : 58, color: colors.primary),
                  ),
                ]),
              ),
              const SizedBox(height: 22),
              const Text('Kategori',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final selected = category == 'Semua';
                    return ActionChip(
                      label: Text(category),
                      backgroundColor: selected
                          ? colors.secondaryContainer
                          : colors.surfaceContainerHighest,
                      side: BorderSide(color: colors.outlineVariant),
                      labelStyle: TextStyle(
                          color: selected
                              ? colors.onSecondaryContainer
                              : colors.onSurface),
                      onPressed: () => onCategoryTap(category),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Rekomendasi untukmu',
                        style: TextStyle(
                            fontSize: 19, fontWeight: FontWeight.bold)),
                    TextButton(
                        onPressed: () => onCategoryTap('Semua'),
                        child: const Text('Lihat semua')),
                  ]),
              const SizedBox(height: 8),
              if (recommendedProducts.isEmpty)
                const Text('Belum ada produk yang tersedia.')
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recommendedProducts.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: isWide ? 270 : 245,
                  ),
                  itemBuilder: (context, index) {
                    final product = recommendedProducts[index];
                    return _HomeProductCard(
                        product: product,
                        onTap: () => onProductTap(product));
                  },
                ),
              const SizedBox(height: 24),
              const Text('Produk Terbaru',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (latestProducts.isEmpty)
                const Text('Belum ada produk lainnya.')
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: latestProducts.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: isWide ? 270 : 245,
                  ),
                  itemBuilder: (context, index) {
                    final product = latestProducts[index];
                    return _HomeProductCard(
                        product: product,
                        onTap: () => onProductTap(product));
                  },
                ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}

class _HomeProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const _HomeProductCard({required this.product, required this.onTap});

  String formatPrice(int value) =>
      'Rp${value.toString().replaceAllMapped(RegExp(r'(\\d)(?=(\\d{3})+(?!\\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.outlineVariant)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(12)),
                child: product.imageUrl.trim().isNotEmpty
                    ? Image.network(
                        product.imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(product.icon, size: 48, color: colors.primary),
                      )
                    : Icon(product.icon, size: 48, color: colors.primary),
              ),
            ),
            const SizedBox(height: 9),
            Text(product.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: colors.primary)),
            const SizedBox(height: 4),
            Text(product.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.star, size: 15, color: Colors.amber),
              const SizedBox(width: 3),
              Text(product.rating.toString(),
                  style: TextStyle(
                      fontSize: 12, color: colors.onSurfaceVariant)),
              const Spacer(),
              Icon(Icons.add_circle, color: colors.primary, size: 23),
            ]),
            const SizedBox(height: 5),
            Text(formatPrice(product.price),
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: colors.onSurface)),
          ]),
        ),
      ),
    );
  }
}

class SearchTab extends StatefulWidget {
  final void Function(Product) onProductTap;
  final String initialCategory;
  final List<Product> productList;

  const SearchTab({
    super.key,
    required this.onProductTap,
    required this.initialCategory,
    required this.productList,
  });

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  late String query;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    query = widget.initialCategory == 'Semua' ? '' : widget.initialCategory;
    searchController.text = query;
  }

  @override
  void didUpdateWidget(covariant SearchTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategory != widget.initialCategory) {
      query = widget.initialCategory == 'Semua' ? '' : widget.initialCategory;
      searchController.text = query;
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.productList.where((p) {
      final q = query.toLowerCase();
      return p.title.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
    }).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Cari Produk atau Jasa',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: searchController,
            onChanged: (value) => setState(() => query = value),
            decoration: const InputDecoration(
              hintText: 'Cari novel, ebook, jasa...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          if (filtered.isEmpty)
            const Center(child: Text('Produk tidak ditemukan.'))
          else
            ...filtered.map((p) => ProductCard(
                  product: p,
                  onTap: () => widget.onProductTap(p),
                )),
        ],
      ),
    );
  }
}

class OrdersTab extends StatelessWidget {
  final void Function(Product) onFeedback;
  const OrdersTab({super.key, required this.onFeedback});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text('Riwayat Pesanan',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: user == null
                ? const Center(child: Text('Silakan login terlebih dahulu.'))
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('orders')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                            child: Text(
                                'Gagal memuat pesanan: ${snapshot.error}',
                                textAlign: TextAlign.center));
                      }
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final documents = snapshot.data?.docs ?? [];
                      if (documents.isEmpty) {
                        return const Center(child: Text('Belum ada pesanan.'));
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: documents.length,
                        itemBuilder: (context, index) {
                          final order = documents[index].data();
                          return Card(
                            child: ListTile(
                              leading: const Icon(
                                  Icons.receipt_long_outlined,
                                  color: Color(0xFF8C6598)),
                              title: Text(
                                  order['productTitle']?.toString() ??
                                      'Pesanan'),
                              subtitle: Text(
                                'Permintaan: ${order['requestTitle'] ?? '-'}\n'
                                'Genre: ${order['genre'] ?? '-'}\n'
                                'Kategori: ${order['category'] ?? '-'}\n'
                                'Status: ${order['status'] ?? 'Menunggu Penjual'}',
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Future<Map<String, dynamic>?> loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: FutureBuilder<Map<String, dynamic>?>(
        future: loadProfile(),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final username = profile?['username'] as String? ?? 'Pengguna WriteMate';
          final email = user?.email ?? '-';
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Profil Pengguna',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: colors.secondaryContainer,
                  child: Icon(Icons.person, size: 52, color: colors.primary),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                  child: Text(username,
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.bold))),
              Center(
                  child: Text(email,
                      style: TextStyle(color: colors.onSurfaceVariant))),
              const SizedBox(height: 28),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator()),
              if (snapshot.hasError)
                const Text('Profil belum bisa dimuat. Coba lagi nanti.'),
              Card(
                child: Column(children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Edit Profil'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfilePage()),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Pengaturan'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsPage()),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Bantuan'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HelpPage()),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.storefront_outlined),
                    title: const Text('Daftar Menjadi Seller'),
                    subtitle:
                        const Text('Ajukan toko untuk ditinjau Admin'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SellerApplicationPage(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Keluar'),
                    onTap: () async => FirebaseAuth.instance.signOut(),
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const ProductCard({super.key, required this.product, required this.onTap});

  String formatPrice(int value) =>
      'Rp${value.toString().replaceAllMapped(RegExp(r'(\\d)(?=(\\d{3})+(?!\\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
              color: colors.secondaryContainer,
              borderRadius: BorderRadius.circular(14)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: product.imageUrl.trim().isNotEmpty
                ? Image.network(
                    product.imageUrl,
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(product.icon, color: colors.primary, size: 30),
                  )
                : Icon(product.icon, color: colors.primary, size: 30),
          ),
        ),
        title: Text(product.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            '${product.category}\n⭐ ${product.rating} • ${formatPrice(product.price)}'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class ProductDetailPage extends StatelessWidget {
  final Product product;
  final VoidCallback onOrder;
  const ProductDetailPage({super.key, required this.product, required this.onOrder});

  String formatPrice(int value) =>
      'Rp${value.toString().replaceAllMapped(RegExp(r'(\\d)(?=(\\d{3})+(?!\\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Produk')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 190,
            decoration: BoxDecoration(
                color: colors.secondaryContainer,
                borderRadius: BorderRadius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: product.imageUrl.trim().isNotEmpty
                ? Image.network(
                    product.imageUrl,
                    width: double.infinity,
                    height: 190,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(product.icon, size: 100, color: colors.primary),
                  )
                : Icon(product.icon, size: 100, color: colors.primary),
          ),
          const SizedBox(height: 24),
          Text(product.title,
              style:
                  const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(product.category,
              style: TextStyle(color: colors.onSurfaceVariant)),
          const SizedBox(height: 12),
          Text('⭐ ${product.rating}   •   Penyedia: ${product.seller}'),
          const SizedBox(height: 20),
          Text(product.description,
              style: const TextStyle(fontSize: 16, height: 1.5)),
          const SizedBox(height: 24),
          Text(formatPrice(product.price),
              style:
                  const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onOrder,
              icon: const Icon(Icons.shopping_cart_outlined),
              label: const Padding(
                padding: EdgeInsets.all(14),
                child: Text('Buat Pesanan'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FeedbackDialog extends StatefulWidget {
  final Product product;
  const FeedbackDialog({super.key, required this.product});
  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  double rating = 5;
  final commentController = TextEditingController();

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Berikan Feedback'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.product.title),
          const SizedBox(height: 12),
          Text('Rating: ${rating.toInt()} / 5'),
          Slider(
            value: rating,
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (value) => setState(() => rating = value),
          ),
          TextField(
            controller: commentController,
            maxLines: 3,
            decoration: const InputDecoration(
                hintText: 'Tulis komentar...', border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Feedback berhasil disimpan.')),
            );
          },
          child: const Text('Kirim'),
        ),
      ],
    );
  }
}
