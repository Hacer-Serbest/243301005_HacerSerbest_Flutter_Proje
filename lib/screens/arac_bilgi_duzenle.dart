import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../services/log_service.dart';

class AracBilgiDuzenle extends StatefulWidget {
  final String kullaniciTelefonu;

  const AracBilgiDuzenle({super.key, required this.kullaniciTelefonu});

  @override
  State<AracBilgiDuzenle> createState() => _AracBilgiDuzenleState();
}

class _AracBilgiDuzenleState extends State<AracBilgiDuzenle> {
  int _sekme = 0; // 0: seçim, 1: araç güncelle, 2: süre güncelle

  final _plakaCtrl = TextEditingController();
  final _sureCtrl = TextEditingController();
  String _aracTipi = 'Benzinli';

  String? _aktifDocId;
  bool _isLoading = false;
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  @override
  void dispose() {
    _plakaCtrl.dispose();
    _sureCtrl.dispose();
    super.dispose();
  }

  Future<void> _verileriYukle() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // Kullanıcı profilinden araç bilgilerini yükle
    if (uid != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(uid)
          .get();
      if (userDoc.exists && mounted) {
        final aracBilgisi =
            (userDoc.data()!['aracBilgisi'] as Map<String, dynamic>?) ?? {};
        setState(() {
          _plakaCtrl.text = (aracBilgisi['plaka'] as String?) ?? '';
          _aracTipi = (aracBilgisi['aracTipi'] as String?) ?? 'Benzinli';
        });
      }
    }

    // Aktif park kaydını süre güncellemesi için yükle
    if (widget.kullaniciTelefonu.isNotEmpty) {
      final snap = await FirebaseFirestore.instance
          .collection('araclar')
          .where('telefon', isEqualTo: widget.kullaniciTelefonu)
          .where('cikisYapildi', isEqualTo: false)
          .get();
      if (snap.docs.isNotEmpty && mounted) {
        setState(() {
          _aktifDocId = snap.docs.first.id;
          _sureCtrl.text =
              (snap.docs.first.data()['tahminiSureSaat'] ?? 1).toString();
        });
      }
    }

    if (mounted) setState(() => _yukleniyor = false);
  }

  Future<void> _aracGuncelle() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _isLoading = true);
    await FirebaseFirestore.instance
        .collection('kullanicilar')
        .doc(uid)
        .update({
      'aracBilgisi': {
        'plaka': _plakaCtrl.text.trim().toUpperCase(),
        'aracTipi': _aracTipi,
      }
    });
    await LogService.log('arac_bilgisi_guncellendi',
        detaylar: {'plaka': _plakaCtrl.text.trim(), 'aracTipi': _aracTipi});
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Araç bilgileri güncellendi.'),
      backgroundColor: AppColors.green,
      behavior: SnackBarBehavior.floating,
    ));
    Navigator.pop(context);
  }

  Future<void> _sureyiGuncelle() async {
    if (_aktifDocId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Şu an aktif park kaydınız bulunmuyor.'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final sure = int.tryParse(_sureCtrl.text.trim());
    if (sure == null || sure <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Geçerli bir süre girin.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _isLoading = true);
    await FirebaseFirestore.instance
        .collection('araclar')
        .doc(_aktifDocId)
        .update({'tahminiSureSaat': sure});
    await LogService.log('park_suresi_guncellendi', detaylar: {'sure': sure});
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Park süresi güncellendi.'),
      backgroundColor: AppColors.green,
      behavior: SnackBarBehavior.floating,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        flexibleSpace: Container(decoration: AppTheme.gradientHeader()),
        title: const Text('Bilgileri Güncelle',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Colors.white)),
        leading: _sekme == 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() {
                  _sekme = 0;
                  _isLoading = false;
                }),
              ),
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _sekme == 0
                  ? _secimEkrani()
                  : _sekme == 1
                      ? _aracFormu()
                      : _sureFormu(),
            ),
    );
  }

  Widget _secimEkrani() {
    return Padding(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_aktifDocId == null)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Aktif park kaydınız yok. Süre güncellemesi yalnızca aktif kayıtlar için yapılabilir.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          _secimKarti(
            Icons.directions_car_outlined,
            'Araç Bilgilerini Güncelle',
            'Plaka veya araç tipini değiştirin.',
            AppColors.blue,
            () => setState(() => _sekme = 1),
          ),
          const SizedBox(height: 16),
          _secimKarti(
            Icons.more_time,
            'Otopark Süresini Güncelle',
            'Aktif park sürenizi uzatın.',
            AppColors.navy,
            () => setState(() => _sekme = 2),
          ),
        ],
      ),
    );
  }

  Widget _aracFormu() {
    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Araç Bilgileriniz',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.navy)),
              const SizedBox(height: 4),
              const Text('Profilinizde kayıtlı araç bilgileri güncellenecek.',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _plakaCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Araç Plakası',
                  prefixIcon:
                      Icon(Icons.badge_outlined, color: AppColors.blue),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(_aracTipi),
                initialValue: _aracTipi,
                decoration: const InputDecoration(
                  labelText: 'Araç Tipi',
                  prefixIcon:
                      Icon(Icons.settings_outlined, color: AppColors.blue),
                ),
                items: ['Benzinli', 'Dizel', 'Elektrikli', 'LPG']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _aracTipi = v!),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _aracGuncelle,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: Colors.white),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_outlined),
                  label: const Text('Kaydet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sureFormu() {
    return SingleChildScrollView(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tahmini Park Süresi',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.navy)),
              const SizedBox(height: 8),
              const Text(
                  'Aktif park halindeki aracınız için yeni tahmini süreyi saat olarak girin.',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sureCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Yeni Tahmini Süre (Saat)',
                  prefixIcon:
                      Icon(Icons.timer_outlined, color: AppColors.blue),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _sureyiGuncelle,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: Colors.white),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.update),
                  label: const Text('Süreyi Güncelle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secimKarti(IconData ikon, String baslik, String aciklama,
      Color renk, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 3,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: renk.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(ikon, color: renk, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(baslik,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: renk)),
                    Text(aciklama,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: renk),
            ],
          ),
        ),
      ),
    );
  }
}
