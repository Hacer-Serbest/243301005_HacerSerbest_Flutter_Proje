import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/giris_ekrani.dart';
import 'screens/gorevli_ana_liste.dart';
import 'screens/arac_sahibi_ana_liste.dart';
import 'firebase_options.dart';
import 'app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const OtoparkApp());
}

class OtoparkApp extends StatelessWidget {
  const OtoparkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ParkYönet',
      theme: AppTheme.theme,
      home: const _OturumKontrol(),
    );
  }
}

class _OturumKontrol extends StatelessWidget {
  const _OturumKontrol();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnap.data;
        if (user == null) return const GirisEkrani();

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('kullanicilar')
              .doc(user.uid)
              .get(),
          builder: (context, docSnap) {
            if (!docSnap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final rol =
                (docSnap.data!.data() as Map<String, dynamic>?)?['rol'] ?? '';
            if (rol == 'gorevli') return const GorevliAnaListe();
            return const AnaListeEkrani();
          },
        );
      },
    );
  }
}
