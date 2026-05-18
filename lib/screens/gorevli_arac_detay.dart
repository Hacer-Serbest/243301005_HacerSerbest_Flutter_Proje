import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';
import '../services/log_service.dart';

class GorevliAracDetay extends StatefulWidget {
  final Map<String, dynamic> veri;
  final String docId;

  const GorevliAracDetay({super.key, required this.veri, required this.docId});

  @override
  State<GorevliAracDetay> createState() => _GorevliAracDetayState();
}

class _GorevliAracDetayState extends State<GorevliAracDetay> {
  late int _saatlikUcret;
  late Timer _timer;
  int _gecenSaat = 1;
  int _toplamUcret = 0;

  @override
  void initState() {
    super.initState();
    _saatlikUcret = (widget.veri['saatlikUcret'] as num?)?.toInt() ?? 40;
    _hesapla();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) _hesapla();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _hesapla() {
    final ts = widget.veri['girisSaati'] as Timestamp?;
    if (ts != null) {
      final fark = DateTime.now().difference(ts.toDate()).inHours;
      setState(() {
        _gecenSaat = fark > 0 ? fark : 1;
        _toplamUcret = _gecenSaat * _saatlikUcret;
      });
    }
  }

  String get _girisSaatiStr {
    final ts = widget.veri['girisSaati'] as Timestamp?;
    if (ts == null) return '-';
    final dt = ts.toDate();
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _cikisDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Çıkış Onayı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('Tahsil Edilecek',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('$_toplamUcret TL',
                      style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.orange)),
                  Text('$_gecenSaat saat × $_saatlikUcret TL',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('İptal')),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await FirebaseFirestore.instance
                  .collection('araclar')
                  .doc(widget.docId)
                  .update({
                'cikisYapildi': true,
                'cikisSaati': FieldValue.serverTimestamp(),
                'odenenUcret': _toplamUcret,
              });
              await LogService.log('arac_cikisi', detaylar: {
                'plaka': widget.veri['plaka'],
                'ucret': _toplamUcret,
                'sure': _gecenSaat,
              });
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Çıkış tamamlandı.'),
                backgroundColor: AppColors.green,
                behavior: SnackBarBehavior.floating,
              ));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green, foregroundColor: Colors.white),
            icon: const Icon(Icons.check),
            label: const Text('Ödeme Alındı'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.veri;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        flexibleSpace: Container(decoration: AppTheme.gradientHeader(dark: true)),
        title: Text(v['plaka'] ?? 'Araç Detayı',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
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
            // Ücret kartı
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6D00), Color(0xFFFF8F00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.orange.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  const Text('Güncel Ödenecek Tutar',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('$_toplamUcret TL',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold)),
                  Text('$_gecenSaat saatlik park',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bilgi kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Araç & Sürücü Bilgileri',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.navy)),
                    const Divider(height: 20),
                    _bilgiSatiri(Icons.badge_outlined, 'Plaka',
                        v['plaka'] ?? '-'),
                    _bilgiSatiri(Icons.person_outline, 'Sürücü',
                        v['sahibiAdSoyad'] ?? '-'),
                    _bilgiSatiri(Icons.phone_outlined, 'Telefon',
                        v['telefon'] ?? '-'),
                    _bilgiSatiri(Icons.access_time_outlined, 'Giriş',
                        _girisSaatiStr),
                    _bilgiSatiri(Icons.timer_outlined, 'Tahmini Süre',
                        '${v['tahminiSureSaat'] ?? 1} saat'),
                    _bilgiSatiri(Icons.directions_car_outlined, 'Araç Tipi',
                        v['aracTipi'] ?? '-'),
                    _bilgiSatiri(Icons.location_on_outlined, 'Park Alanı',
                        v['parkAlani'] ?? '-'),
                    _bilgiSatiri(Icons.payments_outlined, 'Saatlik Ücret',
                        '${(v['saatlikUcret'] as num?)?.toInt() ?? 40} TL'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _cikisDialog,
                icon: const Icon(Icons.exit_to_app),
                label: const Text('Çıkış Yap & Tahsil Et',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bilgiSatiri(IconData ikon, String baslik, String deger) {
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
          Text(deger,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.navy)),
        ],
      ),
    );
  }
}
