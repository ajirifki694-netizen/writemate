import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() { super.initState(); loadProfile(); }

  Future<void> loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    emailController.text = user?.email ?? '-';
    if (user == null) { if (mounted) setState(() => isLoading = false); return; }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        usernameController.text = doc.data()?['username']?.toString() ?? '';
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat profil: $e')));
      }
    }
  }

  Future<void> saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final username = usernameController.text.trim();
    if (user == null) return;
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama pengguna tidak boleh kosong.')));
      return;
    }
    setState(() => isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'username': username});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil berhasil diperbarui!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan profil: $e')));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  void dispose() { usernameController.dispose(); emailController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(20), children: [
        Center(child: CircleAvatar(radius: 42, backgroundColor: colors.secondaryContainer, child: Icon(Icons.person, size: 48, color: colors.primary))),
        const SizedBox(height: 24),
        const Text('Nama Pengguna', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(controller: usernameController, decoration: InputDecoration(hintText: 'Masukkan nama pengguna', prefixIcon: const Icon(Icons.person_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
        const SizedBox(height: 20),
        const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(readOnly: true, controller: emailController, decoration: InputDecoration(prefixIcon: const Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), helperText: 'Email tidak dapat diubah dari halaman ini.')),
        const SizedBox(height: 28),
        FilledButton(onPressed: isSaving ? null : saveProfile, child: Padding(padding: const EdgeInsets.all(15), child: Text(isSaving ? 'Menyimpan...' : 'Simpan Perubahan'))),
      ]),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Apakah kamu yakin ingin keluar dari akun WriteMate?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Keluar')),
        ],
      ),
    );
    if (shouldLogout == true) await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Tampilan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ValueListenableBuilder<ThemeMode>(
          valueListenable: appThemeMode,
          builder: (context, currentMode, child) => Card(child: RadioGroup<ThemeMode>(
            groupValue: currentMode,
            onChanged: (mode) { if (mode != null) appThemeMode.value = mode; },
            child: const Column(children: [
              RadioListTile<ThemeMode>(title: Text('Mode terang'), subtitle: Text('Gunakan tampilan terang'), secondary: Icon(Icons.light_mode), value: ThemeMode.light),
              Divider(height: 1),
              RadioListTile<ThemeMode>(title: Text('Mode gelap'), subtitle: Text('Gunakan tampilan gelap'), secondary: Icon(Icons.dark_mode), value: ThemeMode.dark),
            ]),
          )),
        ),
        const SizedBox(height: 24),
        const Text('Akun', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(child: ListTile(leading: const Icon(Icons.email_outlined), title: const Text('Email akun'), subtitle: Text(user?.email ?? 'Belum login'))),
        const SizedBox(height: 24),
        Card(child: ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Keluar dari akun', style: TextStyle(color: Colors.red)), subtitle: const Text('Keluar dari akun WriteMate'), onTap: () => _confirmLogout(context))),
      ]),
    );
  }
}

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  Widget faq(BuildContext context, String question, String answer) {
    return Card(margin: const EdgeInsets.only(bottom: 10), child: ExpansionTile(
      leading: Icon(Icons.help_outline, color: Theme.of(context).colorScheme.primary),
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [Align(alignment: Alignment.centerLeft, child: Text(answer))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(appBar: AppBar(title: const Text('Pusat Bantuan')), body: ListView(padding: const EdgeInsets.all(16), children: [
      Icon(Icons.support_agent, size: 68, color: colors.primary),
      const SizedBox(height: 8),
      const Text('Ada yang bisa kami bantu?', textAlign: TextAlign.center, style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      faq(context, 'Bagaimana cara memesan produk?', 'Buka halaman Beranda atau Cari, pilih produk, lalu ikuti formulir permintaan pesanan sampai konfirmasi.'),
      faq(context, 'Di mana saya melihat riwayat pesanan?', 'Buka tab Pesanan untuk melihat pesanan yang tersimpan di akun kamu.'),
      faq(context, 'Apa arti status Menunggu Penjual?', 'Pesanan sudah tercatat dan masih menunggu tindak lanjut dari penjual.'),
      faq(context, 'Bagaimana jika pesanan tidak muncul?', 'Pastikan kamu login menggunakan akun yang membuat pesanan. Jika masih bermasalah, hubungi pengelola WriteMate.'),
      faq(context, 'Apakah riwayat pesanan hilang saat logout?', 'Pesanan yang sudah tersimpan di Firestore tetap ada. Login kembali menggunakan akun yang sama untuk melihatnya.'),
      Card(child: ListTile(leading: Icon(Icons.info_outline, color: colors.primary), title: const Text('Tentang WriteMate'), subtitle: const Text('WriteMate membantu pengguna menemukan produk dan mengelola permintaan pesanan.'))),
    ]));
  }
}
