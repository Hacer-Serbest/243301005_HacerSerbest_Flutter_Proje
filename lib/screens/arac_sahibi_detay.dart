import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';

class AracSahibiDetay extends StatelessWidget {
  final Map<String, dynamic> veri;
  final String docId;

  const AracSahibiDetay({super.key, required this.veri, required this.docId});

  @override
  Widget build(BuildContext context) {
    final cikisYapildi = veri['cikisYapildi'] ?? false;
    final girisSaatiTs = veri['girisSaati'] as Timestamp?;
    final cikisSaatiTs = veri['cikisSaati'] as Timestamp?;
    final odenenUcret = veri['odenenUcret'];

    String girisSaatiStr = '-';
    String kalinanSure = '-';
    String ucretStr = '-';

    if (girisSaatiTs != null) {
      final giris = girisSaatiTs.toDate();
      girisSaatiStr =
          '${giris.day.toString().padLeft(2, '0')}.${giris.month.toString().padLeft(2, '0')}.${giris.year}  '
          '${giris.hour.toString().padLeft(2, '0')}:${giris.minute.toString().padLeft(2, '0')}';

      if (cikisYapildi && cikisSaatiTs != null) {
        final fark = cikisSaatiTs.toDate().difference(giris);
        kalinanSure = '${fark.inHours} saat ${fark.inMinutes % 60} dk';
      } else {
        kalinanSure = 'Tahmini ${veri['tahminiSureSaat'] ?? 1} saat (Devam ediyor)';
      }
    }

    if (odenenUcret != null) {
      ucretStr = '$odenenUcret TL';
    } else if (!cikisYapildi && girisSaatiTs != null) {
      final gecenSaat =
          DateTime.now().difference(girisSaatiTs.toDate()).inHours;
      ucretStr = '~${(gecenSaat > 0 ? gecenSaat : 1) * 40} TL (tahmini)';
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        flexibleSpace: Container(decoration: AppTheme.gradientHeader()),
        title: Text(veri['otoparkAdi'] ?? 'Detay',
            style: const TextStyle(
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
            // Durum kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cikisYapildi
                          ? Colors.grey.shade100
                          : AppColors.blue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.local_parking_rounded,
                        size: 48,
                        color: cikisYapildi ? Colors.grey : AppColors.blue),
                  ),
                  const SizedBox(height: 12),
                  Text(veri['otoparkAdi'] ?? '-',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: cikisYapildi
                          ? Colors.grey.shade200
                          : AppColors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cikisYapildi ? 'Tamamlandı' : 'Aktif',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cikisYapildi
                              ? Colors.grey.shade700
                              : AppColors.green),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Ücret özeti
            if (odenenUcret != null)
              _ucretKarti(ucretStr),
            const SizedBox(height: 8),

            // Bilgi kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Detaylar',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.navy)),
                    const Divider(height: 20),
                    _satir(Icons.badge_outlined, 'Araç Plakası',
                        veri['plaka'] ?? '-'),
                    _satir(Icons.location_on_outlined, 'Park Alanı',
                        veri['parkAlani'] ?? '-'),
                    _satir(Icons.directions_car_outlined, 'Araç Tipi',
                        veri['aracTipi'] ?? '-'),
                    _satir(Icons.access_time_outlined, 'Giriş', girisSaatiStr),
                    _satir(Icons.timer_outlined, 'Kalınan Süre', kalinanSure),
                    if (odenenUcret == null)
                      _satir(Icons.payments_outlined, 'Tahmini Tutar',
                          ucretStr),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ucretKarti(String ucret) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.green.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.green),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ödenen Tutar',
                  style: TextStyle(
                      color: AppColors.green, fontSize: 12)),
              Text(ucret,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _satir(IconData ikon, String baslik, String deger) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(ikon, color: AppColors.blue, size: 20),
          const SizedBox(width: 10),
          Text(baslik,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
          const Spacer(),
          Flexible(
            child: Text(deger,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.navy)),
          ),
        ],
      ),
    );
  }
}
