import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../auth_service.dart';
import '../services/log_service.dart';
import 'giris_ekrani.dart';

class AracSahibiProfil extends StatefulWidget {
  const AracSahibiProfil({super.key});

  @override
  State<AracSahibiProfil> createState() => _AracSahibiProfilState();
}

class _AracSahibiProfilState extends State<AracSahibiProfil> {
  final _adController = TextEditingController();
  final _sehirController = TextEditingController();
  final _telController = TextEditingController();
  final _plakaController = TextEditingController();

  String _aracTipi = 'Benzinli';
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
    _sehirController.dispose();
    _telController.dispose();
    _plakaController.dispose();
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
      final aracBilgisi =
          (data['aracBilgisi'] as Map<String, dynamic>?) ?? {};
      setState(() {
        _adController.text = data['adSoyad'] ?? '';
        _telController.text = data['telefon'] ?? '';
        _sehirController.text = data['sehir'] ?? '';
        _plakaController.text = aracBilgisi['plaka'] ?? '';
        _aracTipi = (aracBilgisi['aracTipi'] as String?) ?? 'Benzinli';
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
      'sehir': _sehirController.text.trim(),
      'aracBilgisi': {
        'plaka': _plakaController.text.trim().toUpperCase(),
        'aracTipi': _aracTipi,
      },
    });
    await LogService.log('profil_guncellendi');
    if (!mounted) return;
    setState(() => _kaydediliyor = false);
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
        flexibleSpace: Container(decoration: AppTheme.gradientHeader()),
        title: const Text('Profilim',
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
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.blue,
                    child: Text(_initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  const Text('Araç Sahibi',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 24),

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
                          _alan('Bulunduğunuz Şehir', _sehirController,
                              Icons.location_city_outlined),
                          const SizedBox(height: 12),
                          _alan('Telefon', _telController,
                              Icons.phone_outlined,
                              keyboard: TextInputType.phone),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Araç Bilgileri',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.navy)),
                          const SizedBox(height: 12),
                          _alan('Araç Plakası', _plakaController,
                              Icons.badge_outlined,
                              caps: TextCapitalization.characters),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            key: ValueKey(_aracTipi),
                            initialValue: _aracTipi,
                            decoration: const InputDecoration(
                              labelText: 'Araç Tipi',
                              prefixIcon: Icon(Icons.directions_car_outlined,
                                  color: AppColors.blue),
                            ),
                            items: ['Benzinli', 'Dizel', 'Elektrikli', 'LPG']
                                .map((t) => DropdownMenuItem(
                                    value: t, child: Text(t)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _aracTipi = v!),
                          ),
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
                        backgroundColor: AppColors.blue,
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
      {TextInputType? keyboard,
      TextCapitalization caps = TextCapitalization.none}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      textCapitalization: caps,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(ikon, color: AppColors.blue),
      ),
    );
  }
}
