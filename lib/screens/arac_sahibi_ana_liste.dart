import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../auth_service.dart';
import '../services/log_service.dart';
import 'arac_sahibi_detay.dart';
import 'arac_bilgi_duzenle.dart';
import 'arac_sahibi_profil.dart';
import 'giris_ekrani.dart';

class AnaListeEkrani extends StatefulWidget {
  const AnaListeEkrani({super.key});

  @override
  State<AnaListeEkrani> createState() => _AnaListeEkraniState();
}

class _AnaListeEkraniState extends State<AnaListeEkrani> {
  final _aramaController = TextEditingController();
  String _arama = '';
  String? _telefon;
  bool _yukleniyor = true;
  Stream<QuerySnapshot>? _gecmisStream;

  @override
  void initState() {
    super.initState();
    _telefonuGetir();
  }

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  Future<void> _telefonuGetir() async {
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
    final tel = doc.data()?['telefon'] as String?;
    setState(() {
      _telefon = tel;
      _gecmisStream = (tel != null && tel.isNotEmpty)
          ? FirebaseFirestore.instance
              .collection('araclar')
              .where('telefon', isEqualTo: tel)
              .snapshots()
          : null;
      _yukleniyor = false;
    });
  }

  Future<String> _otoparkDoluluguGetir(String otoparkAdi) async {
    final gorevliSnap = await FirebaseFirestore.instance
        .collection('kullanicilar')
        .where('rol', isEqualTo: 'gorevli')
        .where('otoparkBilgisi.otoparkAdi', isEqualTo: otoparkAdi)
        .get();
    if (gorevliSnap.docs.isEmpty) return 'Otopark bulunamadı';
    final kapasite =
        gorevliSnap.docs.first['otoparkBilgisi']['kapasite'] ?? 0;
    final aracSnap = await FirebaseFirestore.instance
        .collection('araclar')
        .where('otoparkAdi', isEqualTo: otoparkAdi)
        .where('cikisYapildi', isEqualTo: false)
        .get();
    return '${aracSnap.docs.length}/$kapasite dolu';
  }

  Future<void> _cikisYap() async {
    await LogService.log('cikis_yapildi');
    await AuthService().cikisYap();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const GirisEkrani()),
        (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        flexibleSpace: Container(decoration: AppTheme.gradientHeader()),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Otopark Geçmişim',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Colors.white)),
            Text('Araç Sahibi Paneli',
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AracSahibiProfil())),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _cikisYap,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _aramaController,
              onChanged: (v) => setState(() => _arama = v.trim()),
              decoration: InputDecoration(
                hintText: 'Otopark adı ile doluluk sorgula...',
                prefixIcon: const Icon(Icons.search, color: AppColors.blue),
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

          if (_arama.isNotEmpty)
            FutureBuilder<String>(
              future: _otoparkDoluluguGetir(_arama),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: LinearProgressIndicator(),
                  );
                }
                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_parking_rounded,
                          color: AppColors.blue),
                      const SizedBox(width: 10),
                      Text('"$_arama" — ',
                          style: const TextStyle(
                              color: AppColors.textSecondary)),
                      Text(snap.data ?? '...',
                          style: const TextStyle(
                              color: AppColors.blue,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),

          Expanded(
            child: _yukleniyor
                ? const Center(child: CircularProgressIndicator())
                : _gecmisStream == null
                    ? const Center(
                        child: Text('Telefon bilgisi bulunamadı.',
                            style:
                                TextStyle(color: AppColors.textSecondary)))
                    : StreamBuilder<QuerySnapshot>(
                        stream: _gecmisStream,
                        builder: (context, snap) {
                          if (snap.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snap.hasError) {
                            return Center(
                              child: Text('Hata: ${snap.error}',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary)),
                            );
                          }

                          final docs = (snap.data?.docs ?? [])
                            ..sort((a, b) {
                              final ta = (a.data()
                                      as Map)['girisSaati'] as Timestamp?;
                              final tb = (b.data()
                                      as Map)['girisSaati'] as Timestamp?;
                              if (ta == null || tb == null) return 0;
                              return tb.compareTo(ta);
                            });

                          if (docs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history_rounded,
                                      size: 80,
                                      color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  const Text('Henüz park kaydınız yok.',
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 16)),
                                  const SizedBox(height: 6),
                                  const Text(
                                      'Otoparka girdiğinizde görevli kaydeder.',
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13)),
                                ],
                              ),
                            );
                          }

                          final aktif = docs
                              .where((d) => !((d.data()
                                      as Map)['cikisYapildi'] ??
                                  false))
                              .length;

                          return Column(
                            children: [
                              if (aktif > 0)
                                Container(
                                  margin: const EdgeInsets.fromLTRB(
                                      16, 4, 16, 0),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.green
                                        .withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    border: Border.all(
                                        color: AppColors.green
                                            .withValues(alpha: 0.4)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.circle,
                                          color: AppColors.green, size: 10),
                                      const SizedBox(width: 8),
                                      Text(
                                          '$aktif aktif park • Toplam ${docs.length} kayıt',
                                          style: const TextStyle(
                                              color: AppColors.green,
                                              fontWeight:
                                                  FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: docs.length,
                                  itemBuilder: (context, i) {
                                    final doc = docs[i];
                                    final v = doc.data()
                                        as Map<String, dynamic>;
                                    final aktifMi =
                                        !(v['cikisYapildi'] ?? false);
                                    final girisSaati =
                                        v['girisSaati'] as Timestamp?;

                                    String tarihStr = '-';
                                    if (girisSaati != null) {
                                      final dt = girisSaati.toDate();
                                      tarihStr =
                                          '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
                                    }

                                    return Card(
                                      margin: const EdgeInsets.only(
                                          bottom: 10),
                                      child: InkWell(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                AracSahibiDetay(
                                                    veri: v,
                                                    docId: doc.id),
                                          ),
                                        ),
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.all(14),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(
                                                        12),
                                                decoration: BoxDecoration(
                                                  color: aktifMi
                                                      ? AppColors.blue
                                                          .withValues(
                                                              alpha: 0.1)
                                                      : Colors
                                                          .grey.shade100,
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(12),
                                                ),
                                                child: Icon(
                                                  Icons
                                                      .local_parking_rounded,
                                                  color: aktifMi
                                                      ? AppColors.blue
                                                      : Colors.grey,
                                                  size: 26,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                  children: [
                                                    Text(
                                                      v['otoparkAdi'] ??
                                                          '-',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight
                                                                  .bold,
                                                          fontSize: 15,
                                                          color: AppColors
                                                              .navy),
                                                    ),
                                                    const SizedBox(
                                                        height: 3),
                                                    Text(
                                                      '${v['plaka'] ?? '-'}  •  $tarihStr',
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color: AppColors
                                                              .textSecondary),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 8,
                                                    vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: aktifMi
                                                      ? AppColors.green
                                                          .withValues(
                                                              alpha: 0.12)
                                                      : Colors
                                                          .grey.shade200,
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(20),
                                                ),
                                                child: Text(
                                                  aktifMi
                                                      ? 'Aktif'
                                                      : 'Tamamlandı',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: aktifMi
                                                          ? AppColors.green
                                                          : Colors.grey
                                                              .shade600),
                                                ),
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
              builder: (_) =>
                  AracBilgiDuzenle(kullaniciTelefonu: _telefon ?? '')),
        ),
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Düzenle',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
