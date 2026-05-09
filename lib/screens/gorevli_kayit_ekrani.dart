import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';
import '../auth_service.dart';

class GorevliKayitEkrani extends StatefulWidget {
  const GorevliKayitEkrani({super.key});

  @override
  State<GorevliKayitEkrani> createState() => _GorevliKayitEkraniState();
}

class _GorevliKayitEkraniState extends State<GorevliKayitEkrani> {
  final _adCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _sifreCtrl = TextEditingController();
  final _otoparkAdiCtrl = TextEditingController();
  final _kapasiteCtrl = TextEditingController();

  String _otoparkTipi = 'Açık Otopark';
  bool _isLoading = false;

  @override
  void dispose() {
    _adCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _sifreCtrl.dispose();
    _otoparkAdiCtrl.dispose();
    _kapasiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _kayitOl() async {
    if (_adCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _sifreCtrl.text.isEmpty ||
        _otoparkAdiCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Lütfen tüm zorunlu alanları doldurun.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isLoading = true);

    final user = await AuthService()
        .kayitOl(_emailCtrl.text.trim(), _sifreCtrl.text.trim());

    if (user != null) {
      await FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(user.uid)
          .set({
        'adSoyad': _adCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'telefon': _telCtrl.text.trim(),
        'rol': 'gorevli',
        'otoparkBilgisi': {
          'otoparkAdi': _otoparkAdiCtrl.text.trim(),
          'kapasite': int.tryParse(_kapasiteCtrl.text.trim()) ?? 0,
          'otoparkTipi': _otoparkTipi,
        },
        'kayitTarihi': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Kayıt başarılı! Giriş yapabilirsiniz.'),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.popUntil(context, (r) => r.isFirst);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Kayıt başarısız. E-posta kullanımda veya şifre çok kısa (min 6 karakter).'),
        behavior: SnackBarBehavior.floating,
      ));
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        flexibleSpace: Container(decoration: AppTheme.gradientHeader(dark: true)),
        title: const Text('Görevli Kayıt',
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
                    _input(_adCtrl, 'İsim Soyisim', Icons.person_outline),
                    const SizedBox(height: 12),
                    _input(_emailCtrl, 'E-posta', Icons.email_outlined,
                        keyboard: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _input(_telCtrl, 'Telefon', Icons.phone_outlined,
                        keyboard: TextInputType.phone),
                    const SizedBox(height: 12),
                    _input(_sifreCtrl, 'Şifre (min 6 karakter)',
                        Icons.lock_outline,
                        gizli: true),
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
                    const Text('Otopark Bilgileri',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy)),
                    const SizedBox(height: 12),
                    _input(_otoparkAdiCtrl, 'Otopark Adı',
                        Icons.local_parking_outlined),
                    const SizedBox(height: 12),
                    _input(_kapasiteCtrl, 'Kapasite (araç sayısı)',
                        Icons.format_list_numbered,
                        keyboard: TextInputType.number),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _otoparkTipi,
                      decoration: const InputDecoration(
                        labelText: 'Otopark Tipi',
                        prefixIcon:
                            Icon(Icons.domain, color: AppColors.navy),
                      ),
                      items: ['Açık Otopark', 'Kapalı Otopark']
                          .map((t) =>
                              DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setState(() => _otoparkTipi = v!),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _kayitOl,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Kayıt Ol & Otoparkı Kur',
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
      {TextInputType? keyboard, bool gizli = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      obscureText: gizli,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(ikon, color: AppColors.navy),
      ),
    );
  }
}
