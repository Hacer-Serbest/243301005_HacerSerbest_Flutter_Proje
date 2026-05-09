import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth_service.dart';
import '../app_theme.dart';
import 'rol_secim_ekrani.dart';
import 'gorevli_ana_liste.dart';
import 'arac_sahibi_ana_liste.dart';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _sifreGorunur = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _girisYap() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _snackbar('E-posta ve şifre boş bırakılamaz.');
      return;
    }

    setState(() => _isLoading = true);

    final user = await _authService.girisYap(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('kullanicilar')
            .doc(user.uid)
            .get();

        if (!mounted) return;

        if (doc.exists) {
          final rol = doc.get('rol') as String;
          if (rol == 'gorevli') {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const GorevliAnaListe()));
          } else if (rol == 'arac_sahibi') {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const AnaListeEkrani()));
          } else {
            _snackbar('Rol bulunamadı. Lütfen tekrar kayıt olun.');
          }
        } else {
          _snackbar('Kullanıcı bilgileri veritabanında bulunamadı.');
        }
      } catch (_) {
        if (mounted) _snackbar('Bir hata oluştu, tekrar deneyin.');
      }
    } else {
      if (mounted) _snackbar('E-posta veya şifre hatalı.');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _snackbar(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mesaj), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // Üst gradient bölgesi
          Container(
            height: MediaQuery.of(context).size.height * 0.38,
            decoration: AppTheme.gradientHeader(),
            child: const SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.local_parking_rounded,
                          size: 44, color: Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'ParkYönet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Otopark Yönetim Sistemi',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Alt form bölgesi
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Giriş Yap',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Devam etmek için hesabınıza giriş yapın.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-posta',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_sifreGorunur,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_sifreGorunur
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () =>
                              setState(() => _sifreGorunur = !_sifreGorunur),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _girisYap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Giriş Yap',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Hesabın yok mu?',
                            style: TextStyle(color: AppColors.textSecondary)),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RolSecimEkrani()),
                          ),
                          child: const Text('Kayıt Ol',
                              style: TextStyle(
                                  color: AppColors.blue,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
