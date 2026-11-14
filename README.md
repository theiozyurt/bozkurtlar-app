# Android Studio ile açılış

Proje kökü: `/Users/ceviz/Developer/bozkurtlar-app`. Android Studio’da bu klasörü açın; `pubspec.yaml` doğrudan buradadır. Flutter SDK: `/Users/ceviz/development/flutter`. Çalıştırma yapılandırması: **Bozkurtlar** (`lib/main.dart`). Emülatör veya Android cihaz seçip Run düğmesine basın.

# Bozkurtlar · Su Takibi

Deneyap Bozkurtlar için Flutter tabanlı, Android öncelikli su seviyesi izleme uygulaması. Aynı mobil kaynak kodu iPhone hedefini de içerir. Kart: **Deneyap Kart 1A (ESP32)**. Harici Bluetooth modülü yerine kartın dahili **BLE** donanımı kullanılır. HC-05 gibi Bluetooth Classic seri modülleri bu protokolle uyumlu değildir.

## İlk deneme

1. Teslim edilen `bozkurtlar-android-arm64.apk` dosyasını Android telefona aktararak kurun. Bu geliştirme anahtarıyla imzalı, ARM64 telefonlar için deneme paketidir; mağaza yayını değildir.
2. Uygulamada **Demo ile keşfet** düğmesine basarak ekranları donanım olmadan deneyin. Sarı bant tüm değerlerin örnek olduğunu gösterir.
3. Gerçek kart için `firmware/bozkurtlar/bozkurtlar.ino` dosyasını Arduino IDE’de açın. Aşağıdaki kurulum bölümünü izleyin.
4. Uygulamada **Bağlan → Cihazları tara → Bozkurtlar-1A** yolunu izleyin. Android’de istenen Bluetooth/yakındaki cihaz izinlerini verin. Android 11 ve öncesinde tarama için konum servisi de açık olmalıdır.
5. Ayarlar’dan sensör kalibrasyonunu ve ölçtüğünüz pompa aktarım hızını girin. Bunlar olmadan litre veya seviye yüzdesi uydurulmaz.

## Özellikler

- Canlı ham sensör değeri, kalibrasyon varsa yaklaşık seviye yüzdesi.
- Gerçek kart bağlantısı, son veri zamanı, 5 saniyeyi aşınca eski veri uyarısı.
- Pompa **komutu**, kartın açık komutu süresi, başlatma sayısı, kritik seviyede geçirilen süre.
- Kalibre edilen aktarım hızına göre **tahmini** litre.
- Grafik, zaman aralığı filtreleri, ham değerlerin en düşük/ortalama/en yüksek değerleri.
- **Cihazın özel uygulama alanında SQLite geçmiş arşivi.** Uygulama yeniden açıldığında yüklenir; internet gerekmez.
- Gerçek veriler için CSV paylaşımı. Demo CSV’leri açıkça etiketlenir; gerçek arşive yazılmaz.
- Kaynakları ve araştırma sınırlarıyla üç bilimsel yayın.
- İsteğe bağlı Python/SQLite sunucu arşivi; yalnızca kullanıcının manuel eşitleme eylemiyle gönderilir.

## Yerel geçmişin davranışı

Her gerçek telemetri çerçevesi SQLite’a yazılır. Kayıt kimliği `cihaz + kart açılış kimliği + sıra numarası`dır. Aynı çerçeve tekrar geldiğinde çift kayıt oluşmaz. Telefonun aldığı zaman UTC olarak saklanır ve ekranda telefonun yerel saatine çevrilir.

Saklanan alanlar: cihaz kimliği, veri kaynağı, alınma zamanı, ham ADC, pompa komutu, kritik seviye durumu, pompa kilidi, eşikler, sensör yönü, kart çalışma süresi, toplam açık komutu süresi, kritik süre, başlatma sayısı.

Grafik için en son 3.000 gerçek ölçüm belleğe alınır. Veritabanındaki daha eski ölçümler silinmez; **Kayıtlar → Tüm geçmiş** ekranında 100’er kayıtlık sayfalarla açılır. CSV paylaşımı tüm gerçek arşivi içerir. Kayıtlar kullanıcı uygulamayı kaldırırsa veya işletim sisteminden uygulama verisini temizlerse kaybolur. Düzenli CSV dışa aktarımı yedek olarak kullanılabilir.

Veriler **uygulama açık ve BLE bağlantısı varken** kaydedilir. Ekran kilitliyken/uygulama kapalıyken kesintisiz arka plan toplama bu sürümün kapsamına dahil değildir. Telefon bağlantısı yokken kartın otomatik pompa denetimi bağımsız çalışır. Kart sayaçları açılışından itibaren artar, kart yeniden başlarsa sıfırlanır; önceki telefon kayıtları korunur. Bağlantı yokken ayrıntılı ölçümler kartta saklanmaz ve sonradan geri getirilemez.

## Flutter ile geliştirme

Doğrulama ortamı: Flutter 3.44 / Dart 3.12, Android SDK 36, Java 21. Android minimum API 24; iOS hedefi minimum 15.0 (bağımlılık araçları daha yeni Xcode gerektirebilir).

```sh
flutter pub get
flutter run -d <android-cihaz-kimligi>
flutter build apk --debug
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

iPhone için Mac/Xcode ve gerçek telefona yüklemek için kendi Apple geliştirme imzanız gerekir:

```sh
flutter run -d <iphone-kimligi>
```

Tasarım önizlemesi web’de de açılabilir; web sürümü gerçek BLE ve SQLite cihaz kaydı için hedef değildir:

```sh
flutter run -d chrome --dart-define=DEMO_START=true
```

Bluetooth paketleri Android SDK uyumluluğu için 5.5.0 sürümüne sabitlenmiştir. `android/build.gradle.kts` Android kütüphanelerinin `compileSdk` değerini 36’ya getirir; indirilen paket dosyaları değiştirilmez. Sürüm yükseltirken Android ve iOS derlemelerini yeniden doğrulayın.

## Deneyap Kart kurulumu

Arduino IDE’nin ek kart yöneticisi URL’si:

```text
https://raw.githubusercontent.com/deneyapkart/deneyapkart-arduino-core/master/package_deneyapkart_index.json
```

Kart yöneticisinden **Deneyap Geliştirme Kartları** paketini kurup **Deneyap Kart 1A** seçin. Pinler başlangıç kodunuzdaki gibi `A0` (sensör) ve `D0` (mevcut röle/sürücü) olarak ayarlanmıştır. Pompa doğrudan kart pininden beslenmez; mevcut uygun röle/sürücü ve pompa beslemesi kullanılır.

Kod ilk teslimde `ENABLE_PUMP = false` ile pompa denetimini kilitli tutar; sensör ve Bluetooth çalışır. Bunun nedeni başlangıç kodunda LOW’un hem açık hem kapalı olarak açıklanmasıdır. Mevcut devrede rölenin aktif seviyesini ve sensörün su artınca artan mı azalan mı değer verdiğini doğrulayın:

```cpp
constexpr bool RELAY_ACTIVE_LOW = true;           // Sizin rölenize göre
constexpr bool LEVEL_INCREASES_WITH_WATER = true; // Sizin sensörünüze göre
constexpr int THRESHOLD_ON = 700;                 // Deneyle belirleyin
constexpr int THRESHOLD_OFF = 650;                // Sensör yönüne göre sıra değişir
constexpr bool ENABLE_PUMP = true;               // Devre ayarları doğrulandıktan sonra
```

Değer su arttıkça yükseliyorsa pompa 700’de açılır ve 650’de kapanır. Aradaki bant sürekli aç/kapa yapmayı önler. Değer su arttıkça azalıyorsa `LEVEL_INCREASES_WITH_WATER=false` ve açma eşiğinden büyük kapatma eşiği seçilir; ters sıralama derleme zamanında yakalanır.

Kalibrasyon ve eşikler farklı kavramlardır. Telefonda kalibrasyonu değiştirmek kartın fiziksel pompa eşiklerini değiştirmez. Bu sürüm izleme içindir; telefondan pompa açma komutu göndermez.

## Litre ve bilimsel veri

`Tahmini litre = pompanın açık komutu süresi / 60000 × aktarım hızı (L/dk)`.

Pompanın akışını gerçek hortum ve yükseklikte ölçülü kapla ölçün. Bu hesap fiziksel akışı, tıkanmayı, suyun ağaca ulaşmasını veya su kalitesini doğrulamaz. Kalibrasyon sonradan değişirse ekrandaki oturum tahmini yeni hızla yeniden hesaplanır; ham sayaçlar CSV’de değişmeden saklanır. Seviye yüzdesi iki noktalı yaklaşık bir göstergedir; tankın hacim yüzdesi değildir.

Bilim ekranı yayınlanmış **başka araştırmaların** sonuçlarını gösterir. Yayın oranları bizim ağaçlarımızın sonucu veya litre başına büyüme katsayısı olarak kullanılmaz. Ham kanalizasyon suyunun sulamaya uygun olduğu iddia edilmez. Fiziksel prototip temiz suyla gösterilir; çevresel yeniden kullanım senaryosu sulamaya uygunluğu doğrulanmış arıtılmış suya dayanır.

## İsteğe bağlı sunucu

Mobil takip ve cihaz içi geçmiş için sunucu gerekmez. `backend/server.py` Python 3.10+ ile ek paket istemeden çalışır. Kullanıcı anahtarını kendi terminalinde oluşturur; gerçek anahtarı kaynak koduna yazmayın:

```sh
export BOZKURTLAR_API_TOKEN="$(python3 -c 'import secrets; print(secrets.token_urlsafe(32))')"
python3 backend/server.py
```

Varsayılan yalnızca `127.0.0.1:8080` üzerinde dinler. Android Emulator’de debug uygulamasına `http://10.0.2.2:8080` girilebilir. Gerçek telefonda HTTPS üzerinden erişilebilen kendi sunucu adresinizi kullanın. Telefon anahtarı bellekte tutar, diske kaydetmez. API, token doğrulaması, sınırlı istek boyutu, alan doğrulaması ve kimliğe göre tekilleştirme içerir. Python geliştirme sunucusunu doğrudan herkese açık üretim sunucusu olarak yayınlamayın; HTTPS reverse proxy arkasında çalıştırın.

Uçlar: `GET /health`, kimlik doğrulamalı `POST /v1/samples`, `GET /v1/samples?limit=100&offset=0`, `GET /v1/research`. Demo kayıtları API tarafından da reddedilir. Sunucudan otomatik geri yükleme veya otomatik bulut yedeği bu sürümde yoktur.

## Testler

```sh
flutter analyze
flutter test
# Görsel tasarım değişirse referans görüntüsünü bilinçli olarak güncelleyin:
flutter test --update-goldens
```

```sh
cd backend
python3 -m unittest -v test_server.py
```

```sh
g++ -std=c++17 firmware/test_control.cpp -o /tmp/bozkurtlar-control-test
/tmp/bozkurtlar-control-test
```

Fiziksel Deneyap Kart ile sensör/relay kalibrasyonu, BLE menzil testi ve gerçek iPhone kurulumu ayrıca yapılmalıdır. Donanım olmadan bunların doğrulandığı iddia edilmez.

## Kaynaklar

- [Deneyap Kart 1A resmî özellikleri](https://www.deneyapkart.org/docs/deneyap-kart-1a)
- [Deneyap Arduino çekirdeği](https://github.com/deneyapkart/deneyapkart-arduino-core)
- [Espressif BLE UART örneği](https://docs.espressif.com/projects/arduino-esp32/en/latest/api/ble.html)
- [Flutter Reactive BLE 5.5.0](https://pub.dev/packages/flutter_reactive_ble/versions/5.5.0)
- [Joshi ve Coleman, 2023](https://doi.org/10.3390/f14020266)
- [Nackley ve arkadaşları, 2015](https://doi.org/10.1093/aobpla/plv035)
- [Fdil ve arkadaşları, 2023](https://doi.org/10.3390/w15162988)
- [DSÖ: Atık suyun tarımda güvenli kullanımı](https://www.who.int/publications/i/item/9241546832)
