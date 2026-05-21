import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LogService {
  static Future<void> log(String islem, {Map<String, dynamic>? detaylar}) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance.collection('loglar').add({
        'kullaniciUid': uid ?? 'anonim',
        'islem': islem,
        'detaylar': detaylar ?? {},
        'zaman': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}
