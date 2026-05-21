import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../auth_service.dart';
import '../services/log_service.dart';
import 'gorevli_arac_detay.dart';
import 'arac_ekle_ekrani.dart';
import 'gorevli_profil_ekrani.dart';
import 'giris_ekrani.dart';

class GorevliAnaListe extends StatefulWidget {
  const GorevliAnaListe({super.key});

  @override
  State<GorevliAnaListe> createState() => _GorevliAnaListeState();
}

class _GorevliAnaListeState extends State<GorevliAnaListe> {
  final _aramaController = TextEditingController();
  String _arama = '';
  String otoparkAdi = '';
  int kapasite = 0;
  bool _yukleniyor = true;
  Stream<QuerySnapshot>? _araclarStream;

  @override
  void initState() {
    super.initState();
    _otoparkBilgileriniGetir();
  }

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  Future<void> _otoparkBilgileriniGetir() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _yukleniyor = false);
      return;
    }
    final doc = await FirebaseFirestore.instance
        .collection('kullanicilar')
        .doc(uid)
        .get();
    if (!mounted) return;
    final otopark = doc.exists
        ? (doc.data()!['otoparkBilgisi'] as Map<String, dynamic>?) ?? {}
        : <String, dynamic>{};
    final yeniAd = (otopark['otoparkAdi'] as String?) ?? 'Otopark';
    setState(() {
      otoparkAdi = yeniAd;
      kapasite = (otopark['kapasite'] as num?)?.toInt() ?? 0;
      _araclarStream = FirebaseFirestore.instance
          .collection('araclar')
          .where('otoparkAdi', isEqualTo: yeniAd)
          .where('cikisYapildi', isEqualTo: false)
          .snapshots();
      _yukleniyor = false;
    });
  }

  Future<void> _cikisYap() async {
    await LogService.log('cikis_yapildi');
    await AuthService().cikisYap();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const GirisEkrani()), (_) => false);
  }

  void _cikisDialog(Map<String, dynamic> veri, String docId) {
    final girisSaati = veri['girisSaati'] as Timestamp?;
    final saatlikUcret = (veri['saatlikUcret'] as num?)?.toInt() ?? 40;
    int farkSaat = 1;
    if (girisSaati != null) {
      farkSaat = DateTime.now().difference(girisSaati.toDate()).inHours;
      if (farkSaat < 1) farkSaat = 1;
    }
    final ucret = farkSaat * saatlikUcret;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.exit_to_app, color: AppColors.red),
            const SizedBox(width: 8),
            const Text('Araç Çıkışı'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plaka: ${veri['plaka']}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Text('Ödenecek Tutar',
                      style: TextStyle(color: AppColors.textSecondary)),
                  Text('$ucret TL',
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.orange)),
                  Text('$farkSaat saat × $saatlikUcret TL',
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
                  .doc(docId)
                  .update({
                'cikisYapildi': true,
                'cikisSaati': FieldValue.serverTimestamp(),
                'odenenUcret': ucret,
              });
              await LogService.log('arac_cikisi',
                  detaylar: {'plaka': veri['plaka'], 'ucret': ucret});
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Araç çıkışı tamamlandı.'),
                backgroundColor: AppColors.green,
                behavior: SnackBarBehavior.floating,
              ));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Ödeme Alındı'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        flexibleSpace:
            Container(decoration: AppTheme.gradientHeader(dark: true)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_yukleniyor ? 'Yükleniyor...' : otoparkAdi,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Colors.white)),
            const Text('Görevli Paneli',
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilEkrani()),
            ).then((_) => _otoparkBilgileriniGetir()),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _cikisYap,
          ),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _aramaController,
                    onChanged: (v) =>
                        setState(() => _arama = v.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Plaka ara...',
                      prefixIcon:
                          const Icon(Icons.search, color: AppColors.blue),
                      suffixIcon: _arama.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _aramaController.clear();
                                setState(() => _arama = '');
                              })
                          : null,
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _araclarStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline,
                                    color: AppColors.red, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  'Veri yüklenemedi:\n${snapshot.error}',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final tumAraclar = (snapshot.data?.docs ?? [])
                        ..sort((a, b) {
                          final ta =
                              (a.data() as Map)['girisSaati'] as Timestamp?;
                          final tb =
                              (b.data() as Map)['girisSaati'] as Timestamp?;
                          if (ta == null || tb == null) return 0;
                          return tb.compareTo(ta);
                        });
                      final dolu = tumAraclar.length;
                      final bos = kapasite - dolu;
                      final dolulukOrani =
                          kapasite > 0 ? dolu / kapasite : 0.0;

                      final liste = tumAraclar.where((doc) {
                        final plaka = ((doc.data() as Map)['plaka'] ?? '')
                            .toString()
                            .toLowerCase();
                        return plaka.contains(_arama);
                      }).toList();

                      return Column(
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.navy, AppColors.blue],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(Icons.local_parking_rounded,
                                      color: Colors.white, size: 40),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text('$dolu',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 28,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text('/$kapasite araç',
                                                style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 14)),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: dolulukOrani,
                                            backgroundColor: Colors.white24,
                                            valueColor:
                                                AlwaysStoppedAnimation(
                                                    dolulukOrani > 0.8
                                                        ? AppColors.red
                                                        : AppColors.orange),
                                            minHeight: 8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    children: [
                                      Text('$bos',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold)),
                                      const Text('boş',
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          if (liste.isEmpty)
                            Expanded(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.no_crash_outlined,
                                        size: 72,
                                        color: Colors.grey.shade300),
                                    const SizedBox(height: 12),
                                    Text(
                                        _arama.isEmpty
                                            ? 'Otoparkta araç bulunmuyor.'
                                            : '"$_arama" ile eşleşen araç yok.',
                                        style: const TextStyle(
                                            color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: liste.length,
                                itemBuilder: (context, i) {
                                  final doc = liste[i];
                                  final veri =
                                      doc.data() as Map<String, dynamic>;
                                  final girisSaati =
                                      veri['girisSaati'] as Timestamp?;
                                  String saatStr = '--:--';
                                  if (girisSaati != null) {
                                    final dt = girisSaati.toDate();
                                    saatStr =
                                        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                                  }
                                  final tahminiSure =
                                      (veri['tahminiSureSaat'] as num?)
                                              ?.toInt() ??
                                          1;
                                  final saatlikUcret =
                                      (veri['saatlikUcret'] as num?)
                                              ?.toInt() ??
                                          40;
                                  final tahminiUcret =
                                      tahminiSure * saatlikUcret;

                                  return Card(
                                    margin:
                                        const EdgeInsets.only(bottom: 10),
                                    child: InkWell(
                                      borderRadius:
                                          BorderRadius.circular(16),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => GorevliAracDetay(
                                              veri: veri, docId: doc.id),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 4,
                                              height: 74,
                                              decoration: BoxDecoration(
                                                color: AppColors.blue,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    veri['plaka'] ?? '-',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18,
                                                      color: AppColors.navy,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                          Icons.person_outline,
                                                          size: 13,
                                                          color: AppColors
                                                              .textSecondary),
                                                      const SizedBox(width: 3),
                                                      Expanded(
                                                        child: Text(
                                                          veri['sahibiAdSoyad'] ??
                                                              '-',
                                                          style: const TextStyle(
                                                              color: AppColors
                                                                  .textSecondary,
                                                              fontSize: 12),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                          Icons
                                                              .access_time_outlined,
                                                          size: 13,
                                                          color: AppColors
                                                              .textSecondary),
                                                      const SizedBox(width: 3),
                                                      Text(saatStr,
                                                          style: const TextStyle(
                                                              color: AppColors
                                                                  .textSecondary,
                                                              fontSize: 12)),
                                                      const SizedBox(width: 8),
                                                      const Icon(
                                                          Icons
                                                              .payments_outlined,
                                                          size: 13,
                                                          color:
                                                              AppColors.orange),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        'Tahmini: $tahminiUcret TL',
                                                        style: const TextStyle(
                                                            color:
                                                                AppColors.orange,
                                                            fontSize: 12,
                                                            fontWeight: FontWeight
                                                                .w600),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  _cikisDialog(veri, doc.id),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.red,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 8),
                                                minimumSize: Size.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              child: const Text('Çıkış'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AracEkleEkrani(otoparkAdi: otoparkAdi)),
        ),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Araç Ekle',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
