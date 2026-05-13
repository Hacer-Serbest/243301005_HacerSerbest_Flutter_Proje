import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';
import '../services/log_service.dart';

class AracEkleEkrani extends StatefulWidget {
  final String otoparkAdi;

  const AracEkleEkrani({super.key, required this.otoparkAdi});

  @override
  State<AracEkleEkrani> createState() => _AracEkleEkraniState();
}

class _AracEkleEkraniState extends State<AracEkleEkrani> {
  final _plakaCtrl = TextEditingController();
  final _sahipCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _sureCtrl = TextEditingController(text: '1');
  final _ucretCtrl = TextEditingController(text: '40');

  String _aracTipi = 'Benzinli';
  String _parkAlani = 'Açık Otopark';
  TimeOfDay _girisSaati = TimeOfDay.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _plakaCtrl.dispose();
    _sahipCtrl.dispose();
    _telCtrl.dispose();
    _sureCtrl.dispose();
    _ucretCtrl.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (_plakaCtrl.text.isEmpty ||
        _sahipCtrl.text.isEmpty ||
        _telCtrl.text.isEmpty ||
        _sureCtrl.text.isEmpty ||
        _ucretCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Lütfen tüm alanları doldurun.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isLoading = true);

    final now = DateTime.now();
    final giris = DateTime(
        now.year, now.month, now.day, _girisSaati.hour, _girisSaati.minute);
    final plaka = _plakaCtrl.text.trim().toUpperCase();

    await FirebaseFirestore.instance.collection('araclar').add({
      'otoparkAdi': widget.otoparkAdi,
      'plaka': plaka,
      'sahibiAdSoyad': _sahipCtrl.text.trim(),
      'telefon': _telCtrl.text.trim(),
      'aracTipi': _aracTipi,
      'parkAlani': _parkAlani,
      'girisSaati': Timestamp.fromDate(giris),
      'tahminiSureSaat': int.tryParse(_sureCtrl.text) ?? 1,
      'saatlikUcret': int.tryParse(_ucretCtrl.text) ?? 40,
      'cikisYapildi': false,
      'eklenmeTarihi': FieldValue.serverTimestamp(),
    });

    await LogService.log('arac_girisi', detaylar: {
      'plaka': plaka,
      'otoparkAdi': widget.otoparkAdi,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Kayıt tamamlandı! Araç listeye eklendi.'),
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
        flexibleSpace: Container(decoration: AppTheme.gradientHeader(dark: true)),
        title: const Text('Yeni Araç Girişi',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Araç ve sürücü kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_add_outlined,
                            color: AppColors.navy),
                        const SizedBox(width: 8),
                        const Text('Sürücü Bilgileri',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _input(_plakaCtrl, 'Araç Plakası', Icons.badge_outlined,
                        caps: TextCapitalization.characters),
                    const SizedBox(height: 12),
                    _input(_sahipCtrl, 'Sahibi Adı Soyadı',
                        Icons.person_outline),
                    const SizedBox(height: 12),
                    _input(_telCtrl, 'Telefon Numarası', Icons.phone_outlined,
                        keyboard: TextInputType.phone),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Araç detayları kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_car_outlined,
                            color: AppColors.navy),
                        const SizedBox(width: 8),
                        const Text('Araç & Park Detayları',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _aracTipi,
                      decoration: _deko('Araç Tipi',
                          Icons.directions_car_filled_outlined),
                      items: ['Benzinli', 'Dizel', 'Elektrikli', 'LPG']
                          .map((t) =>
                              DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setState(() => _aracTipi = v!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _parkAlani,
                      decoration:
                          _deko('Park Alanı', Icons.location_on_outlined),
                      items: ['Açık Otopark', 'Kapalı Otopark']
                          .map((k) =>
                              DropdownMenuItem(value: k, child: Text(k)))
                          .toList(),
                      onChanged: (v) => setState(() => _parkAlani = v!),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              final p = await showTimePicker(
                                  context: context,
                                  initialTime: _girisSaati);
                              if (p != null) {
                                setState(() => _girisSaati = p);
                              }
                            },
                            child: InputDecorator(
                              decoration:
                                  _deko('Giriş Saati', Icons.access_time),
                              child: Text(_girisSaati.format(context),
                                  style: const TextStyle(fontSize: 15)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _input(
                              _sureCtrl, 'Tahmini Süre (Saat)',
                              Icons.timer_outlined,
                              keyboard: TextInputType.number),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _input(_ucretCtrl, 'Saatlik Ücret (TL)',
                        Icons.attach_money_outlined,
                        keyboard: TextInputType.number),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _kaydet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline),
                label: const Text('Kaydı Tamamla',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(TextEditingController ctrl, String label, IconData ikon,
      {TextInputType? keyboard,
      TextCapitalization caps = TextCapitalization.none}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      textCapitalization: caps,
      decoration: _deko(label, ikon),
    );
  }

  InputDecoration _deko(String label, IconData ikon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(ikon, color: AppColors.navy),
      );
}
