# ParkYönet — Otopark Giriş-Çıkış ve Ücretlendirme Sistemi

## Proje Bağlamı

**Ders:** Selçuk Üniversitesi Teknoloji Fakültesi — Mobil Programlama (2025-2026)  
**Öğrenci:** Hacer Serbest — 243301005  
**Teslim:** 22 Mayıs 2026

---

## Kullanıcı Senaryosu — Selçuk Üniversitesi Teknoloji Fakültesi Otoparkı

**Konum:** Selçuk Üniversitesi Teknoloji Fakültesi, Selçuklu/Konya  
**Senaryo tarihi:** Pazartesi sabahı, 08:30

### Sabah — Görevli Tarafı (001)

Kampüs güvenlik görevlisi **Mehmet Yılmaz** vardiyasına başlar. Telefondaki **ParkYönet** uygulamasını açar, `gorevli001@parkyonet.com` ile giriş yapar. Ana ekranda Teknoloji Fakültesi otoparkının doluluk durumu görünür: **0 / 80 araç**, otopark boş.

08:47'de öğrenci **Ayşe Kaya** kampüs otoparkına girer. Mehmet "+" butonuna basar, araç girişini kaydeder:

- **Plaka:** 42 KON 007  
- **Sahibi:** Ayşe Kaya  
- **Telefon:** 0532 111 22 33  
- **Araç Tipi:** Benzinli  
- **Park Alanı:** Açık Otopark  
- **Giriş Saati:** 08:47  
- **Tahmini Süre:** 5 saat  

"Kaydı Tamamla" butonuna basılır, kayıt tamamlandı bildirimi gelir ve ana listeye dönülür. Doluluk **1 / 80** olarak güncellenir.

### Öğleden Sonra — Araç Sahibi Tarafı (002)

Ayşe, aralarında derse girmek için aracını uzun süre bırakmıştır. Kendi telefonunda **ParkYönet**'i açar, `arac002@parkyonet.com` ile giriş yapar. "Otopark Geçmişim" ekranında **Teknoloji Fakültesi Otoparkı — 42 KON 007 — Aktif** kaydını görür. Üzerine tıkladığında giriş saati, tahmini süre ve o ana kadar oluşan tahmini ücret görünür.

Dersi uzayacağını anlayınca "Düzenle → Otopark Süresini Güncelle" seçeneğiyle tahmini süreyi **7 saate** çıkarır.

### Akşam — Çıkış İşlemi

14:15'te Ayşe aracına gelir, çıkış yapmak ister. Mehmet ana listedeki **42 KON 007** kartının sağındaki **Çıkış** butonuna basar. Ekrana uyarı gelir:

> _"42 KON 007 plakalı araç için ödenecek tutar: **220 TL** (5 saat × 40 TL/saat)"_  
> **Ödeme Tamamlandı** | İptal

Mehmet ödemeyi onaylar. Araç listeden kalkar, otopark **0 / 80** olarak güncellenir.

Ayşe kendi uygulamasını yenilediğinde geçmiş kaydında artık "**Tamamlandı**" yazar, ödediği ücret ve park süresi görünür.

---

## Teknik Mimari

### Kullanıcı Rolleri

| Rol | Firestore Değeri | Açıklama |
|-----|-----------------|----------|
| Otopark Görevlisi | `gorevli` | Araç giriş-çıkış işlemleri |
| Araç Sahibi | `arac_sahibi` | Kişisel park geçmişi |

### Firestore Koleksiyonları

```
kullanicilar/{uid}
  adSoyad, email, telefon, rol, kayitTarihi
  otoparkBilgisi/  (sadece gorevli)
    otoparkAdi, kapasite, otoparkTipi
  sehir            (sadece arac_sahibi)

araclar/{docId}
  otoparkAdi, plaka, sahibiAdSoyad, telefon
  aracTipi, parkAlani, girisSaati, tahminiSureSaat
  cikisYapildi, cikisSaati, odenenUcret, eklenmeTarihi

loglar/{docId}
  kullaniciUid, islem, detaylar, zaman
```

### Araç-Kullanıcı Bağlantısı

Görevli araç eklerken telefon numarasını girer. Araç sahibi geçmişini görürken sistem, kendi kayıtlı telefon numarasıyla `araclar` koleksiyonundaki `telefon` alanını eşleştirir. Bu sayede araç sahibi hesabı olmadan da görevli kayıt yapabilir.

### Ücretlendirme Kuralı

`Ücret = giriş saatinden bu yana geçen tam saat × 40 TL`  
Minimum 1 saat uygulanır. Ücret detay ekranında her dakika otomatik güncellenir.

---

## Test Hesapları

| Rol | E-posta | Şifre |
|-----|---------|-------|
| Görevli (001) | gorevli001@parkyonet.com | gorevli123 |
| Araç Sahibi (002) | arac002@parkyonet.com | arac123456 |

> Firebase Console → Authentication → "Add user" ile elle oluşturulacak,  
> ardından uygulama üzerinden aynı bilgilerle "Kayıt Ol" yapılarak Firestore'a rol yazılacak.

---

## Kullanılan Paketler

- `firebase_core`, `firebase_auth`, `cloud_firestore` — Backend
- `logger`, `font_awesome_flutter`, `cupertino_icons` — Yardımcı

## Geliştirme Notları

- `lib/services/log_service.dart` — Tüm işlemler bu servis üzerinden loglanır
- `lib/app_theme.dart` — Renk sabitleri ve tema buradadır, değişiklik için tek nokta
- Navigasyon: `Navigator.pushReplacement` ile geri dönüş engellenir (giriş → ana liste)
- Çıkış: `AuthService().cikisYap()` çağrısından sonra `pushAndRemoveUntil` ile login'e dönülür
