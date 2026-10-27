import 'package:flutter/material.dart';
import 'order_confirmation_page.dart';

class OrderRequestPage extends StatefulWidget {
  final String productTitle;
  final String category;
  final String sellerId;

  const OrderRequestPage({
  super.key,
  required this.productTitle,
  required this.category,
  required this.sellerId,
});

  @override
  State<OrderRequestPage> createState() => _OrderRequestPageState();
}

class _OrderRequestPageState extends State<OrderRequestPage> {
  final titleController = TextEditingController();
  final genreController = TextEditingController();
  final referenceController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    genreController.dispose();
    referenceController.dispose();
    super.dispose();
  }

  void continueToConfirmation() {
    final title = titleController.text.trim();
    final genre = genreController.text.trim();
    final reference = referenceController.text.trim();

    if (title.isEmpty || genre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul permintaan dan genre wajib diisi.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderConfirmationPage(
        productTitle: widget.productTitle,
        category: widget.category,
        sellerId: widget.sellerId,
        requestTitle: title,
        genre: genre,
        reference: reference,
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Form Permintaan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.productTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Kategori: ${widget.category}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Judul Permintaan *',
              hintText: 'Contoh: Cerita persahabatan',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: genreController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Genre *',
              hintText: 'Contoh: Fantasi, romantis, misteri',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: referenceController,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Referensi atau Catatan',
              hintText: 'Ceritakan ide atau kebutuhanmu...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: continueToConfirmation,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Lanjut ke Konfirmasi'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
