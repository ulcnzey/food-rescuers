# 🥖 FoodRescuers — Fazla Gıda Kurtarma Platformu

> İşletmelerin gün sonunda elinde kalan gıdayı indirimli veya ücretsiz
> listelediği, yakındaki kullanıcıların rezerve edip yerinden teslim
> aldığı bir mobil platform.

**Flutter · Supabase (PostgreSQL + PostGIS) · Riverpod · OpenStreetMap**

---

## 🎯 Problem

Gün sonunda satılamayan gıda çöpe gidiyor. İşletme için zarar,
kullanıcı için kaçırılmış fırsat. FoodRescuers ikisini eşleştiriyor:
işletme kalan ürünü listeliyor, yakındaki kullanıcı rezerve ediyor,
teslim yüz yüze yapılıyor.

---

## 🏗️ Mimari

```
lib/
├── core/              # Ortak altyapı: tema, router, hata tipleri
└── features/
    ├── auth/          # Kimlik doğrulama ve onboarding
    ├── discover/      # Keşfet — yakındaki teklifler
    ├── map/           # Harita görünümü
    ├── orders/        # Siparişlerim
    └── profile/       # Profil ve yetkiler
```

**Feature-first + Clean Architecture.** Her özellik kendi `data`,
`domain` ve `presentation` katmanlarını içerir. Klasörler teknik
role göre değil, iş özelliğine göre bölünmüştür — bir özellik
üzerinde çalışırken tek klasörde kalınır, projeye yeni katılan biri
"rezervasyon nerede?" sorusunun cevabını dizin adından bulur.

**Durum yönetimi:** Riverpod 2.6, kod üretimi kullanılmadan.
Build-runner adımı olmadığı için değişiklik–çalıştır döngüsü kısa
kalıyor; provider tanımları da açıkça okunabiliyor.

**Yönlendirme:** go_router. Derin bağlantı ve kimlik durumuna göre
yönlendirme tek yerden yönetiliyor.

---

## 🗄️ Backend Kararları

### Neden Supabase, Firebase değil?

Uygulamanın çekirdek sorgusu şu: *"Bana 3 km içindeki teklifleri
mesafeye göre sıralı ver."* Bu coğrafi bir sorgudur.

PostGIS bunu veritabanı içinde, indeks kullanarak çözer. Firebase'de
aynı işi yapmak için ya tüm kayıtları çekip istemcide filtrelemek ya
da geohash tabanlı bir çözüm elle kurmak gerekirdi. İkisi de daha
pahalı ve daha kırılgan.

İkinci sebep **Row Level Security**: erişim kuralları verinin yanında
yaşıyor. Web, Android ve iOS istemcilerinin her birinde aynı kuralı
yeniden yazmak gerekmiyor.

### Eşzamanlı rezervasyon problemi

Bir teklifin son porsiyonunu iki kullanıcı aynı anda rezerve etmeye
kalkarsa ne olur?

Kontrol ve yazma işlemi ayrı adımlarda yapılırsa ikisi de "stok var"
görüp ikisi de yazar — stok eksiye düşer. Bu klasik bir **race
condition**.

Çözüm: rezervasyon işlemi bir PostgreSQL stored function içinde,
`SELECT FOR UPDATE` ile satır kilidi alınarak yapılıyor. Kilidi alan
işlem bitene kadar diğeri bekliyor, sonra güncel stoğu görüp temiz
bir ret alıyor. Kontrol ve yazma atomik olarak gerçekleşiyor.

### Yetki modeli

Satış yapabilme, sabit bir rol değil, profil üzerinde bir **yetki
bayrağı** (`can_sell`). Bir kullanıcı hem teklif rezerve edebilir hem
de kendisine satış yetkisi verilebilir.

Katı rol tabanlı bir yapı (`user` / `seller`) kurulsaydı, ikisini de
yapan biri iki ayrı hesap açmak zorunda kalırdı. Yetkiler roller
kadar sabit değildir; bayrak modeli değişime açık kalıyor.

### Neden OpenStreetMap?

Harita neredeyse her ekranda kullanılıyor. Google Maps'in istek başı
ücretlendirmesi, henüz geliri olmayan bir üründe öngörülemeyen bir
maliyet kalemi yaratırdı. `flutter_map` + OSM ile bu bağımlılık ve
maliyet ortadan kalkıyor.

---

## ⚖️ Ürün Kısıtları

- **Bireysel satıcılar yalnızca ücretsiz listeleme yapabilir.**
  Ücretli satış, gıda ticareti mevzuatı ve vergilendirme kapsamına
  girdiği için platform dışında tutuldu.
- Teslim yüz yüze; platform kargo veya ödeme aracılığı yapmıyor.

---

## 🛠️ Teknoloji Stack

| Katman        | Teknoloji                          |
| ------------- | ---------------------------------- |
| Mobil         | Flutter, Dart                      |
| Durum Yönetimi| Riverpod 2.6                       |
| Yönlendirme   | go_router                          |
| Backend       | Supabase                           |
| Veritabanı    | PostgreSQL + PostGIS               |
| Harita        | flutter_map + OpenStreetMap        |

---

## 🚀 Kurulum

```bash
git clone https://github.com/ulcnzey/food-rescuers.git
cd food-rescuers

flutter pub get

# Supabase bağlantı bilgilerini tanımlayın
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

---

## 📊 Durum

| Modül                        | Durum |
| ---------------------------- | ----- |
| Kimlik doğrulama & onboarding| ✅    |
| Yetki tabanlı rol yönetimi   | ✅    |
| Veritabanı şeması & fonksiyonlar | ✅ |
| Keşfet ekranı                | 🔄    |
| Harita görünümü              | 🔄    |
| Teklif detayı & rezervasyon  | 🔄    |
| QR teslim fişi               | ⏳    |

---

## 🗺️ Yol Haritası

- [ ] QR tabanlı teslim doğrulama akışı
- [ ] Veri toplama altyapısı (fiyat önerisi modeli için)
- [ ] Cihaz üzerinde çalışan fiyat önerisi (lineer regresyon)
- [ ] Bildirimler

---

## 📄 Lisans

MIT