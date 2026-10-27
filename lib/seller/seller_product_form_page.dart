
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SellerProductFormPage extends StatefulWidget {
  const SellerProductFormPage({super.key});

  @override
  State<SellerProductFormPage> createState() =>
      _SellerProductFormPageState();
}

class _SellerProductFormPageState
    extends State<SellerProductFormPage> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final categoryController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    titleController.dispose();
    categoryController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    super.dispose();
  }

  Future<void> saveProduct() async {
    if (!formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    setState(() => loading = true);

    try {
      final price = int.parse(priceController.text.trim());

      await FirebaseFirestore.instance.collection('products').add({
        'sellerId': user.uid,
        'title': titleController.text.trim(),
        'category': categoryController.text.trim(),
        'description': descriptionController.text.trim(),
        'price': price,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk berhasil ditambahkan.')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan produk: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String? requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Kolom ini wajib diisi.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Produk')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Nama Produk',
                border: OutlineInputBorder(),
              ),
              validator: requiredText,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
              ),
              validator: requiredText,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                border: OutlineInputBorder(),
              ),
              validator: requiredText,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Harga (angka saja)',
                hintText: 'Contoh: 25000',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null ||
                    int.tryParse(value.trim()) == null ||
                    int.parse(value.trim()) <= 0) {
                  return 'Masukkan harga berupa angka lebih dari 0.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: loading ? null : saveProduct,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  loading ? 'Menyimpan...' : 'Simpan Produk',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
