# Otopark Giriş-Çıkış ve Ücretlendirme Sistemi

**Uygulama Adı:** ParkYönet  
**Öğrenci Adı:** Hacer Serbest  
**Öğrenci Numarası:** 243301005  
**Ders:** Mobil Programlama – Final Projesi  
**Teslim Tarihi:** 22 Mayıs 2026  

---

## Test Hesapları

> Araç Sahbi test bilgileri: aa@gmail.com / 123456
> Otopark görevlisi : A@gmail.com / 123456


---

## Gereksinim Karşılama Tablosu

| Gereksinim | Karşılandı mı? | Detay |
|------------|:--------------:|-------|
| En az 2 kullanıcı/rol | ✅ | `gorevli` + `arac_sahibi` |
| Firebase Auth | ✅ | E-posta/şifre ile kayıt, giriş, çıkış |
| Firebase veri saklama | ✅ | Cloud Firestore (`kullanicilar`, `araclar`, `loglar`) |
| Oturum kalıcılığı | ✅ | `authStateChanges()` ile uygulama kapanınca oturum korunur |
| En az 5 ekran | ✅ | 12 ekran mevcut (detay aşağıda) |
| Her işlemde log kaydı | ✅ | `LogService` → Firestore `loglar` koleksiyonu |

---

## Ekran Listesi (12 Ekran)

| # | Ekran | Rol |
|---|-------|-----|
| 1 | Giriş Ekranı | Ortak |
| 2 | Rol Seçim Ekranı | Ortak |
| 3 | Görevli Kayıt Ekranı | Görevli |
| 4 | Araç Sahibi Kayıt Ekranı | Araç Sahibi |
| 5 | Görevli Ana Liste | Görevli |
| 6 | Yeni Araç Girişi (Ekleme Formu) | Görevli |
| 7 | Araç Detay Ekranı | Görevli |
| 8 | Görevli Profil Ekranı | Görevli |
| 9 | Araç Sahibi Ana Liste (Geçmiş) | Araç Sahibi |
| 10 | Park Kaydı Detay Ekranı | Araç Sahibi |
| 11 | Araç Sahibi Profil Ekranı | Araç Sahibi |
| 12 | Bilgi Düzenleme Ekranı | Araç Sahibi |

---

## Kullanılan Paketler

### Bağımlılıklar

| Paket | Versiyon | Açıklama |
|-------|----------|----------|
| `firebase_core` | ^4.7.0 | Firebase başlatma ve yapılandırma |
| `firebase_auth` | ^6.4.0 | E-posta/şifre ile kimlik doğrulama |
| `cloud_firestore` | ^6.3.0 | Gerçek zamanlı NoSQL veritabanı |
| `supabase_flutter` | ^2.12.4 | Ek backend desteği |
| `logger` | ^2.7.0 | Konsol loglama |
| `font_awesome_flutter` | ^11.0.0 | Genişletilmiş ikon seti |
| `cupertino_icons` | ^1.0.8 | iOS tarzı ikonlar |

### Geliştirme Bağımlılıkları

| Paket | Versiyon | Açıklama |
|-------|----------|----------|
| `flutter_lints` | ^6.0.0 | Kod kalitesi kuralları |
| `flutter_launcher_icons` | ^0.14.3 | Uygulama ikonu oluşturma |

---

## Uygulama Özellikleri

### Görevli Rolü
- Otoparka giren araçları kayıt altına alır (plaka, sahip, telefon, araç tipi, park alanı, giriş saati, tahmini süre, saatlik ücret)
- Araç listesini anlık görüntüler; doluluk oranı gerçek zamanlı güncellenir
- Araç çıkışında geçen süre × saatlik ücret hesaplanır, onay sonrası kayıt kapanır
- Profil ve otopark bilgilerini güncelleyebilir

### Araç Sahibi Rolü
- Park geçmişini görüntüler (aktif / tamamlandı)
- Otopark doluluk oranını sorgulayabilir
- Araç bilgilerini (plaka, marka/model, yakıt tipi) güncelleyebilir
- Aktif parkın tahmini süresini uzatabilir

### Teknik Özellikler
- Firebase Authentication + Cloud Firestore
- `authStateChanges()` ile kalıcı oturum yönetimi
- Her işlemde Firestore `loglar` koleksiyonuna kayıt
- Gerçek zamanlı stream ile araç listesi ve doluluk güncellemesi
- Saatlik ücret görevli tarafından her araç için ayrı girilir

---

## Firestore Koleksiyon Yapısı

```
kullanicilar/{uid}
  adSoyad        : string
  email          : string
  telefon        : string
  rol            : "gorevli" | "arac_sahibi"
  kayitTarihi    : timestamp
  sehir          : string          (yalnızca arac_sahibi)
  aracBilgisi    : map             (yalnızca arac_sahibi)
    plaka        : string
    markaModel   : string
    yakit        : "Benzin" | "Dizel" | "Hibrit"
  otoparkBilgisi : map             (yalnızca gorevli)
    otoparkAdi   : string
    kapasite     : number
    otoparkTipi  : string

araclar/{docId}
  otoparkAdi       : string
  plaka            : string
  sahibiAdSoyad    : string
  telefon          : string
  aracTipi         : string
  parkAlani        : string
  girisSaati       : timestamp
  tahminiSureSaat  : number
  saatlikUcret     : number
  cikisYapildi     : boolean
  cikisSaati       : timestamp
  odenenUcret      : number
  eklenmeTarihi    : timestamp

loglar/{docId}
  kullaniciUid : string
  islem        : string
  detaylar     : map
  zaman        : timestamp
```

---

## Ekran Görüntüleri

| | | |
|:---:|:---:|:---:|
| ![](screenshots/Ekran%20görüntüsü%202026-05-22%20122156.png) | ![](screenshots/Ekran%20görüntüsü%202026-05-22%20122208.png) | ![](screenshots/Ekran%20görüntüsü%202026-05-22%20122217.png) |
| ![](screenshots/Ekran%20görüntüsü%202026-05-22%20122228.png) | ![](screenshots/Ekran%20görüntüsü%202026-05-22%20122238.png) | ![](screenshots/Ekran%20görüntüsü%202026-05-22%20122245.png) |
| ![](screenshots/Ekran%20görüntüsü%202026-05-22%20122256.png) | ![](screenshots/Ekran%20görüntüsü%202026-05-22%20122632.png) | ![](screenshots/Ekran%20görüntüsü%202026-05-22%20122701.png) |

