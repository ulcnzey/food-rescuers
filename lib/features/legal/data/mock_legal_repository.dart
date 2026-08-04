import '../domain/entities/legal_document.dart';

abstract class LegalRepository {
  Future<LegalDocument> getDocument(String docType);
}

class MockLegalRepository implements LegalRepository {
  @override
  Future<LegalDocument> getDocument(String docType) async {
    // Simulate network delay (600ms)
    await Future.delayed(const Duration(milliseconds: 600));

    if (docType == 'terms') {
      return LegalDocument(
        id: 'doc-terms-v1',
        docType: 'terms',
        version: 1,
        title: 'Kullanım Koşulları',
        effectiveAt: DateTime(2026, 8, 4),
        content: '''## 1. Giriş
FoodRescuers uygulamasına hoş geldiniz. Bu uygulama, fazla gıdaların israf edilmesini önlemek ve çevreye katkı sağlamak amacıyla geliştirilmiştir. Uygulamamızı kullanarak bu koşulları kabul etmiş sayılırsınız.

## 2. Hizmet Tanımı
FoodRescuers, üye işletmelerin gün sonunda ellerinde kalan taze ve yenilebilir durumdaki fazla gıdaları indirimli veya ücretsiz olarak listelediği, bireysel kullanıcıların ise bu gıdaları rezerve edip teslim aldığı bir platformdur.

## 3. Kullanıcı Yükümlülükleri
Kullanıcılar, yaptıkları rezervasyonları belirlenen saat aralığında almakla yükümlüdür. Üst üste teslim alınmayan rezervasyonlar durumunda kullanıcı hesabı askıya alınabilir.

## 4. Rezervasyon ve İptal
Rezervasyonlar tamamen ücretsiz veya belirtilen indirimli fiyat üzerinden yapılır. Rezervasyon iptalleri, teslimat saatinden en geç 30 dakika öncesine kadar yapılmalıdır.

## 5. Sağlık ve Hijyen Sorumluluğu
İşletmeler, sundukları gıdaların taze, hijyenik ve tüketime uygun olmasından doğrudan sorumludur. FoodRescuers, gıda kalitesi veya alerjen durumlarından sorumlu tutulamaz. Kullanıcılar teslim alırken gıdaları kontrol etmelidir.''',
      );
    } else if (docType == 'privacy') {
      return LegalDocument(
        id: 'doc-privacy-v1',
        docType: 'privacy',
        version: 1,
        title: 'Gizlilik Politikası',
        effectiveAt: DateTime(2026, 8, 4),
        content: '''## 1. Veri Sorumlusu
FoodRescuers olarak kişisel verilerinizin güvenliği bizim için son derece önemlidir. Bu metin, verilerinizin nasıl işlendiği ve korunduğu hakkında bilgilendirme amacıyla hazırlanmıştır.

## 2. Toplanan Veriler
Platformumuzu kullanabilmeniz için adınız, soyadınız, e-posta adresiniz ve konum bilgileriniz gibi temel veriler işlenmektedir. Konum bilgisi yalnızca yakındaki fırsatları listelemek amacıyla kullanılır.

## 3. Verilerin İşlenme Amacı
Kişisel verileriniz, rezervasyon süreçlerinin yönetilmesi, işletmelerle iletişim kurulması ve platformun geliştirilmesi amacıyla 6698 sayılı KVKK kapsamında işlenmektedir.

## 4. Veri Paylaşımı
Kişisel verileriniz yasal zorunluluklar haricinde üçüncü şahıslarla asla paylaşılmaz. Rezervasyon bilgileriniz (ad soyad) yalnızca paketi teslim alacağınız üye işletme ile paylaşılır.

## 5. Haklarınız
Kullanıcılar diledikleri zaman kişisel verilerinin silinmesini, güncellenmesini veya işlenip işlenmediğini öğrenmeyi talep edebilirler. Taleplerinizi destek e-posta adresimiz üzerinden iletebilirsiniz.''',
      );
    } else {
      throw Exception('Belge türü bulunamadı: $docType');
    }
  }
}
