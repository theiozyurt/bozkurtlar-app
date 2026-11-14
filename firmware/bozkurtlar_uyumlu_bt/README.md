# Mevcut devreyi koruyan Bluetooth test sürümü

Bu sürüm, kullanıcının verdiği çalışan kodun röle davranışını korur:

- Başlangıçta D0 = LOW.
- A0 <= 700 ise D0 = LOW; orijinal mesajdaki gibi açık komutu.
- A0 > 700 ise D0 = HIGH; orijinal mesajdaki gibi kapalı komutu.
- Sensör 500 ms aralıklarla okunur; BLE telemetri eklidir.

Rölenin fiziksel olarak hangi seviyede çalıştığı veya sensörün suyla artan/azalan yönde olduğu bu testte doğrulanmış sayılmaz. Uygulamadaki pompa bilgisi yalnızca orijinal kodun komutudur. Su seviyesi yorumunu kalibrasyonla doğrulayın.

Asıl `firmware/bozkurtlar` sürümü ilk kurulumda kilitli kalır. Bu ayrı sürüm, bağlı mevcut devrede orijinal LOW/HIGH kararlarını değiştirmeden BLE testi içindir.
