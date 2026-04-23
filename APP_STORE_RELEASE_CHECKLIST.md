# App Store Release Checklist

## 1. Xcode İçinde Signing Doğrulaması

1. `Tabu.xcodeproj` aç.
2. `Tabu` target'ını seç.
3. `Signing & Capabilities` altında doğru Apple Developer Team'i seç.
4. `Bundle Identifier` değerinin App Store Connect'te kullanılacak App ID ile birebir aynı olduğundan emin ol.
5. `Automatically manage signing` açık kalsın ya da manuel profile kullanıyorsan Release profile'ı bağla.

## 2. Archive Alma

1. Xcode'da destination'ı `Any iOS Device (arm64)` seç.
2. `Product > Archive` çalıştır.
3. Archive bittikten sonra Organizer açılacak.
4. `Validate App` ile ön doğrulama yap.
5. Hata yoksa `Distribute App > App Store Connect > Upload` ile yükle.

## 3. App Store Connect Alanları

1. Uygulama adı, açıklama ve anahtar kelimeleri doldur.
2. Gizlilik beyanını doldur.
3. Destek URL'si ve gerekliyse gizlilik politikası URL'si ekle.
4. Yaş derecelendirmesini tamamla.
5. Fiyatlandırma ve dağıtım bölgelerini seç.

## 4. Screenshot Seti

Gerekli minimum set:

1. 6.9" iPhone ekran görüntüleri
2. 6.5" veya 6.3" iPhone ekran görüntüleri
3. iPad yayınlayacaksan iPad ekran görüntüleri

Önerilen akışlar:

1. Ana menü
2. Tek kişilik oyun ekranı
3. Takım kurulumu
4. Takımlı oyun ekranı
5. Ayarlar ekranı

## 5. Son Smoke Test

TestFlight veya fiziksel cihaz üzerinde şunları doğrula:

1. Uygulama açılışı
2. Tek kişilik oyun başlangıcı
3. Oyun bitişi ve `Tekrar Oyna`
4. Takımlı kurulum > tur akışı > özet > oyun sonu
5. Ayar kaydetme ve tekrar açınca korunması
6. Arka plan / ön plan geçişinde timer davranışı
7. İkon ve launch screen görünümü

## 6. Yükleme Öncesi Komutlar

```bash
cd /Users/gladius/Desktop/Tabu
bash scripts/run_catalog_quality_gate.sh
```

Bu komut geçmeden archive alma.
