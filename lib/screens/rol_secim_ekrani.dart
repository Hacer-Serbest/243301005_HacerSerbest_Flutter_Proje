import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'arac_sahibi_kayit_ekrani.dart';
import 'gorevli_kayit_ekrani.dart';

class RolSecimEkrani extends StatelessWidget {
  const RolSecimEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Kayıt Türü'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.navy,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.how_to_reg_outlined,
                size: 64, color: AppColors.navy),
            const SizedBox(height: 16),
            const Text(
              'Nasıl kayıt olmak\nistiyorsunuz?',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy),
            ),
            const SizedBox(height: 8),
            const Text(
              'Rolünüze göre farklı özellikler sunulmaktadır.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 48),
            _RolKarti(
              ikon: Icons.admin_panel_settings_outlined,
              baslik: 'Otopark Görevlisi',
              aciklama:
                  'Araç giriş-çıkış kayıtlarını yönetin, ücret hesaplayın.',
              renk: AppColors.navy,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GorevliKayitEkrani()),
              ),
            ),
            const SizedBox(height: 16),
            _RolKarti(
              ikon: Icons.directions_car_outlined,
              baslik: 'Araç Sahibi',
              aciklama: 'Otopark geçmişinizi görüntüleyin, bilgilerinizi güncelleyin.',
              renk: AppColors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AracSahibiKayitEkrani()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RolKarti extends StatelessWidget {
  final IconData ikon;
  final String baslik;
  final String aciklama;
  final Color renk;
  final VoidCallback onTap;

  const _RolKarti({
    required this.ikon,
    required this.baslik,
    required this.aciklama,
    required this.renk,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: renk.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(ikon, color: renk, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(baslik,
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: renk)),
                    const SizedBox(height: 4),
                    Text(aciklama,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: renk),
            ],
          ),
        ),
      ),
    );
  }
}
