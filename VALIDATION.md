# Doğrulama · 14 Kasım 2026

## Geçen kontroller

- `flutter analyze --no-pub`: hata ve uyarı yok.
- `flutter test --no-pub`: **11 test geçti**. BLE JSON çerçevelerinin 1–23 baytlık parçalardan birleşmesi, hatalı çerçeveden sonra toparlanma, geçersiz ADC/sayaçların reddi, kalibrasyonsuz değer uydurulmaması, ters sensör yönü, CSV kaynak etiketi, erişim anahtarının ayarlara yazılmaması test edildi.
- SQLite kalıcılık testi: veritabanı kapatılıp yeniden açılınca gerçek ölçüm korundu. Tekrar gelen kayıt çoğaltılmadı. Demo kaydı gerçek veritabanına alınmadı. Kart yeniden başladığında yeni açılış kimliğiyle kayıt saklandı. Eski sayfaya erişim doğrulandı.
- 360 px dar telefon ekranında demo, Bilim ve Ayarlar; boş durum ve görsel referans testi geçti. `test/goldens/dashboard.png` gerçek Flutter arayüzünün demo veriyle üretilen görüntüsüdür.
- Python API: **5 test geçti**. Kimlik doğrulama, idempotent arşivleme, yanlış ölçüm reddi ve demo içeren partinin tamamının reddi doğrulandı.
- C++ pompa mantığı: artan/azalan sensör yönleri ve histerezis sınırları için 7 doğrulama geçti.
- Deneyap gerçek kart çekirdeğiyle derleme: `deneyap:esp32:deneyapkart1A`, Deneyap ESP32 core **2.0.1**. 1.149.037 bayt program alanı, 39.764 bayt global RAM kullanımı. Bu satır ilk teslimdeki kilitli genel yazılımın derleme sonucudur; aşağıdaki gerçek cihaz testi ayrı uyumluluk yazılımıyla yapılmıştır.
- Android debug derlemesi ve ARM64 release derlemesi geçti. Son deneme APK’sı yaklaşık **20,4 MB** (dosya boyutunun ondalık gösterimi). Release yapılandırması geliştirme anahtarıyla imzalanır; mağaza yayını yapılmadı.
- Son APK yerel Pixel 10 Android emülatörüne kuruldu ve açıldı. Önceki debug paketinde cihazsız açılış, Ayarlar ve demo akışı görüntülenerek kontrol edildi. Son APK açılışında Flutter/AndroidRuntime hata günlüğü boştu.
- iOS **ARM64 simülatör** Xcode derlemesi geçti. Xcode 27.2 için uygulama ve eski pod hedefleri minimum iOS 15’e getirildi. Genel çoklu mimari Flutter simülatör komutu bir araç uyumsuzluğu verdi; aşağıdaki tek mimarili Xcode komutu başarılı oldu.

```sh
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO
```

## Gerçek cihaz testi · 14 Kasım 2026

- Redmi 8 / Android 10 üzerine release APK kuruldu ve açıldı. Konum servisi kullanıcının onayıyla açıldı; Android 10 BLE taraması çalıştı.
- Deneyap Kart 1A'nın 4 MB mevcut flash yedeği yerel olarak alındı. Kullanıcının açık onayıyla `firmware/bozkurtlar_uyumlu_bt` yazılımı yüklendi; yükleme hash kontrolleri geçti. Bu sürüm başlangıçta LOW, ham değer 700 ve altında LOW, 700 üstünde HIGH çıkışıyla mevcut kodun elektriksel kuralını korur. İki önceki durum için 0–4095 aralığında 8.192 karşılaştırma geçti. Yedek `firmware/backups/` altında tutulur ve paylaşım paketlerine alınmamalıdır.
- İlk bağlantılar Android GATT 133 hatası verdi. Uygulamada bağlantı öncesi tarama yapan `connectToAdvertisingDevice` kullanıldı; hata ayrıntısı ekrana eklendi. Güncel APK ile `Bozkurtlar-1A` bağlantısı ve TX bildirim aboneliği başarılı oldu. Canlı ham ADC, pompa komutu ve sayaçlar telefonda görüntülendi.
- Gerçek BLE ölçümleri SQLite'a kaydedildi. Uygulama `am force-stop` ile kapatılıp yeniden açıldı; **62 gerçek kayıt** geri yüklendi ve cihaz içi tüm geçmiş ekranında tarih/saat ve kart oturumu ile okundu.
- Denemede ham sensör değeri sürekli **0** idi. Bu, sensörün suya tepkisini veya gerçek su yüksekliğini doğrulamaz. Ekrandaki yüksek seviye ve pompa komutu mevcut LOW/HIGH kuralının yazılım yorumudur; fiziksel röle yönü ve pompanın çalıştığı doğrulanmadı.
- Bağlantı düzeltmesinden sonra `flutter analyze --no-pub` temiz, release APK derlemesi başarılı ve **11 Flutter testi** tekrar geçti.

## Donanımla yapılması gerekenler

Gerçek Android BLE bağlantısı ve telefon içi geçmiş yukarıda doğrulandı. Gerçek röle aktif seviyesi, sensörün suya tepkisi ve kalibrasyonu, pompa aktarım hızı, bağlantı menzili ve fiziksel pompa davranışı henüz doğrulanmadı. iOS için gerçek telefonda Apple imzasıyla kurulum ve BLE testi yapılmadı. Uygulamanın kapalıyken veri toplamayı sürdürdüğü iddia edilmez.

Genel `firmware/bozkurtlar` yazılımı pompa kilitli olarak gelir; bu testte karta yüklenen `firmware/bozkurtlar_uyumlu_bt` ise açık onayla mevcut röle kuralını uygular. Ayrıntılar ilgili README dosyalarındadır. Bilimsel ekranın verileri başka araştırmaların sonuçlarıdır; bu prototipte ölçülmüş ağaç gelişimi değildir.
