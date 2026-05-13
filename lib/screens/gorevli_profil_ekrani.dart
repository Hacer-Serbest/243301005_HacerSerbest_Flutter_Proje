import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../auth_service.dart';
import '../services/log_service.dart';
import 'giris_ekrani.dart';

class ProfilEkrani extends StatefulWidget {
  const ProfilEkrani({super.key});

  @override
  State<ProfilEkrani> createState() => _ProfilEkraniState();
}

class _ProfilEkraniState extends State<ProfilEkrani> {
  final _adController = TextEditingController();
  final _otoparkController = TextEditingController();
  final _kapasiteController = TextEditingController();
  final _telController = TextEditingController();

  bool _yukleniyor = true;
  bool _kaydediliyor = false;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  @override
  void dispose() {
    _adController.dispose();
    _otoparkController.dispose();
    _kapasiteController.dispose();
    _telController.dispose();
    super.dispose();
  }

  Future<void> _verileriYukle() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('kullanicilar')
        .doc(uid)
        .get();
    if (doc.exists && mounted) {
      final data = doc.data()!;
      final otopark =
          (data['otoparkBilgisi'] as Map<String, dynamic>?) ?? {};
      setState(() {
        _adController.text = data['adSoyad'] ?? '';
        _telController.text = data['telefon'] ?? '';
        _otoparkController.text = otopark['otoparkAdi'] ?? '';
        _kapasiteController.text = (otopark['kapasite'] ?? 0).toString();
        _yukleniyor = false;
      });
    }
  }

  Future<void> _kaydet() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _kaydediliyor = true);
    await FirebaseFirestore.instance
        .collection('kullanicilar')
        .doc(uid)
        .update({
      'adSoyad': _adController.text.trim(),
      'telefon': _telController.text.trim(),
      'otoparkBilgisi.otoparkAdi': _otoparkController.text.trim(),
      'otoparkBilgisi.kapasite':
          int.tryParse(_kapasiteController.text.trim()) ?? 0,
    });
    await LogService.log('profil_guncellendi');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Profil güncellendi.'),
      backgroundColor: AppColors.green,
      behavior: SnackBarBehavior.floating,
    ));
    Navigator.pop(context);
  }

  Future<void> _cikisYap() async {
    await LogService.log('cikis_yapildi');
    await AuthService().cikisYap();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const GirisEkrani()), (_) => false);
  }

  String get _initials {
    final ad = _adController.text.trim();
    if (ad.isEmpty) return '?';
    final parts = ad.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return ad[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        flexibleSpace: Container(decoration: AppTheme.gradientHeader(dark: true)),
        title: const Text('Görevli Profili',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _cikisYap,
          ),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.navy,
                    child: Text(_initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  const Text('Otopark Görevlisi',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 24),

                  // Kişisel bilgiler kartı
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Kişisel Bilgiler',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.navy)),
                          const SizedBox(height: 12),
                          _alan('Ad Soyad', _adController,
                              Icons.person_outline),
                          const SizedBox(height: 12),
                          _alan('Telefon', _telController,
                              Icons.phone_outlined,
                              keyboard: TextInputType.phone),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Otopark bilgileri kartı
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Otopark Bilgileri',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.navy)),
                          const SizedBox(height: 12),
                          _alan('Otopark Adı', _otoparkController,
                              Icons.business_outlined),
                          const SizedBox(height: 12),
                          _alan('Toplam Kapasite', _kapasiteController,
                              Icons.layers_outlined,
                              keyboard: TextInputType.number),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _kaydediliyor ? null : _kaydet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                      ),
                      icon: _kaydediliyor
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_outlined),
                      label: const Text('Değişiklikleri Kaydet',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _alan(String label, TextEditingController ctrl, IconData ikon,
      {TextInputType? keyboard}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(ikon, color: AppColors.navy),
      ),
    );
  }
}
