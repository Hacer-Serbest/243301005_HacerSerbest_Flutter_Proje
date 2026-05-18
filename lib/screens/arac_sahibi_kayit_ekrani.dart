import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';
import '../auth_service.dart';

class AracSahibiKayitEkrani extends StatefulWidget {
  const AracSahibiKayitEkrani({super.key});

  @override
  State<AracSahibiKayitEkrani> createState() => _AracSahibiKayitEkraniState();
}

class _AracSahibiKayitEkraniState extends State<AracSahibiKayitEkrani> {
  final _adCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _sifreCtrl = TextEditingController();
  final _plakaCtrl = TextEditingController();
  final _markaModelCtrl = TextEditingController();

  String _yakit = 'Benzin';
  bool _isLoading = false;
  bool _sifreGizli = true;

  @override
  void dispose() {
    _adCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _sifreCtrl.dispose();
    _plakaCtrl.dispose();
    _markaModelCtrl.dispose();
    super.dispose();
  }

  Future<void> _kayitOl() async {
    if (_adCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _sifreCtrl.text.isEmpty) {
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
        'rol': 'arac_sahibi',
        'aracBilgisi': {
          'plaka': _plakaCtrl.text.trim().toUpperCase(),
          'markaModel': _markaModelCtrl.text.trim(),
          'yakit': _yakit,
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
        flexibleSpace: Container(decoration: AppTheme.gradientHeader()),
        title: const Text('Araç Sahibi Kayıt',
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
            // Kişisel bilgiler
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
                    TextField(
                      controller: _sifreCtrl,
                      obscureText: _sifreGizli,
                      decoration: InputDecoration(
                        labelText: 'Şifre (min 6 karakter)',
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: AppColors.blue),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _sifreGizli
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () =>
                              setState(() => _sifreGizli = !_sifreGizli),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Araç bilgileri
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
                    const SizedBox(height: 4),
                    const Text(
                        'Sonradan profil ekranından güncelleyebilirsiniz.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    _input(_plakaCtrl, 'Araç Plakası (opsiyonel)',
                        Icons.badge_outlined,
                        caps: TextCapitalization.characters),
                    const SizedBox(height: 12),
                    _input(_markaModelCtrl, 'Marka / Model (opsiyonel)',
                        Icons.directions_car_outlined),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _yakit,
                      decoration: const InputDecoration(
                        labelText: 'Yakıt Tipi',
                        prefixIcon: Icon(Icons.local_gas_station_outlined,
                            color: AppColors.blue),
                      ),
                      items: ['Benzin', 'Dizel', 'Hibrit']
                          .map((t) =>
                              DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setState(() => _yakit = v!),
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
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Kayıt Ol',
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
