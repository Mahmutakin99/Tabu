# Tabu (iOS)

Tabu, UIKit ile geliştirilmiş bir iOS kelime tahmin oyunudur. Uygulama tek kişilik ve takımlı oyun modlarını, kategori/zorluk filtrelerini ve yerel JSON tabanlı kelime kataloğunu destekler.

## İçindekiler
- [Özellikler](#özellikler)
- [Teknik Mimari](#teknik-mimari)
- [Proje Yapısı](#proje-yapısı)
- [Gereksinimler](#gereksinimler)
- [Kurulum ve Çalıştırma](#kurulum-ve-çalıştırma)
- [Oyun Kuralları](#oyun-kuralları)
- [Kelime Kataloğu](#kelime-kataloğu)
- [Veri Scriptleri](#veri-scriptleri)
- [App Store Yayın Kontrol Listesi](#app-store-yayın-kontrol-listesi)
- [Sorun Giderme](#sorun-giderme)

## Özellikler
- Tek kişilik oyun modu
- Takımlı oyun modu (2-6 takım)
- Kategori bazlı kart filtreleme
- Zorluk bazlı kart filtreleme (`easy`, `medium`, `hard`)
- Ayarlarda canlı uygun kart sayısı gösterimi
- Takımlı modda ayarlanabilir tur süresi, pas limiti ve tur sayısı
- Haptic feedback destekli oyun etkileşimleri
- Offline çalışma (yerel JSON katalog)
- Açılışta katalog preload ve oyun içinde cache kullanımı

## Teknik Mimari
- `WordProvider`:
  - `Kelimeler.json` dosyasını tek sefer decode + prepare eder
  - `warmupIfNeeded` ile açılışta ön-yükleme yapar
  - `CardSelection` bazlı kart/adet sorgusu verir
  - Kategori + zorluk filtre sonuçlarını provider cache'inde tutar
  - Kart/forbidden veri temizliği ve güvenlik filtreleri uygular
- `SettingsManager`:
  - Seçili kategori ve zorlukları `UserDefaults` ile saklar
  - `CardSelection` üretir ve provider üstünden kart/adet sorgular
- Oyun motorları:
  - `Game`: tek kişilik modun skor/süre/deck akışı
  - `TeamGame`: takımlı modun tur, skor ve takım rotasyonu akışı
- UI katmanı:
  - Programatik UIKit + Auto Layout
- `FlowWrapView` ile yasaklı kelime etiketlerinin dinamik yerleşimi
- Yaşam döngüsü:
  - Arka plana geçişte timer durdurma, geri dönüşte güvenli devam
  - `SceneDelegate` içinde tek seferlik warmup

## Proje Yapısı

```text
Tabu/
├── README.md
├── scripts/
│   ├── curate_catalog.rb
│   ├── generate_catalog.rb
│   ├── validate_catalog.rb
│   ├── verify_sources_alignment.rb
│   └── run_catalog_quality_gate.sh
├── Tabu.xcodeproj/
└── Tabu/
    ├── Files/
    │   ├── AppDelegate.swift
    │   ├── SceneDelegate.swift
    │   ├── WordsCatalog.swift
    │   ├── Kelimeler.json
    │   ├── Kelimeler.sources.json
    │   └── PrivacyInfo.xcprivacy
    ├── Settings/
    │   ├── Card.swift
    │   ├── SettingsManager.swift
    │   └── Controller/
    │       ├── MainMenuViewController.swift
    │       └── SettingsViewController.swift
    ├── SingleMode/
    │   ├── Game.swift
    │   ├── FlowWrapView.swift
    │   └── Controller/
    │       ├── GameViewController.swift
    │       └── GameOverViewController.swift
    └── TeamMode/
        ├── TeamModel.swift
        ├── TeamGame.swift
        ├── TeamGameSettings.swift
        └── Controller/
            ├── TeamSetupViewController.swift
            ├── TeamGameViewController.swift
            └── TeamRoundSummaryViewController.swift
```

## Gereksinimler
- Xcode 15+
- iOS Deployment Target: `15.0`
- Swift `5.0`
- Ruby (veri scriptleri için)

## Kurulum ve Çalıştırma
1. Proje dizinine girin:

```bash
cd /Users/gladius/Desktop/Tabu
```

2. Xcode projesini açın:

```bash
open /Users/gladius/Desktop/Tabu/Tabu.xcodeproj
```

3. Xcode içinde bir simulator veya fiziksel cihaz seçip `Run` (`⌘R`) çalıştırın.

## Oyun Kuralları

### Tek Kişilik Mod
- Varsayılan süre: 60 saniye
- Doğru cevap: `+1`
- Tabu: `-1`
- Pas: ayara bağlı ceza (tek kişilikte varsayılan cezasız)

### Takımlı Mod
- Takım sayısı: 2-6
- Tur süresi: 20-180 saniye (10 saniye adım)
- Pas: sınırlı/sınırsız
- Tur sayısı: takım başına 2-5

## Kelime Kataloğu
- Ana dosya: `/Users/gladius/Desktop/Tabu/Tabu/Files/Kelimeler.json`
- Kaynak manifest: `/Users/gladius/Desktop/Tabu/Tabu/Files/Kelimeler.sources.json`
- Kategori seti:
  - Diziler & Filmler
  - Astronomi, Fizik & Mühendislik
  - Spor
  - Tarih
  - Coğrafya
  - Müzik
  - Teknoloji
  - Yemek
  - Doğa
  - Sanat

Kart şeması:

```json
{
  "Kelime": "Örnek",
  "Yasaklılar": ["kelime1", "kelime2", "kelime3", "kelime4", "kelime5"],
  "Zorluk": "medium"
}
```

## Veri Scriptleri

### 1) Kataloğu düzenleme
Mevcut JSON içeriğini temizler/düzenler:

```bash
ruby /Users/gladius/Desktop/Tabu/scripts/curate_catalog.rb \
  /Users/gladius/Desktop/Tabu/Tabu/Files/Kelimeler.json \
  /Users/gladius/Desktop/Tabu/Tabu/Files/Kelimeler.json
```

### 2) Kataloğu doğrulama
Kategori, tekrar, yasaklı sayısı, zorluk, kalite kurallarını kontrol eder:

```bash
ruby /Users/gladius/Desktop/Tabu/scripts/validate_catalog.rb \
  /Users/gladius/Desktop/Tabu/Tabu/Files/Kelimeler.json
```

### 3) Kaynak hizalama doğrulama
`Kelimeler.json` ile `Kelimeler.sources.json` eşleşmesini kontrol eder:

```bash
ruby /Users/gladius/Desktop/Tabu/scripts/verify_sources_alignment.rb \
  /Users/gladius/Desktop/Tabu/Tabu/Files/Kelimeler.json \
  /Users/gladius/Desktop/Tabu/Tabu/Files/Kelimeler.sources.json
```

### 4) Tek komutta quality gate

```bash
/Users/gladius/Desktop/Tabu/scripts/run_catalog_quality_gate.sh
```

### 5) Wikidata'dan yeniden üretim
Ağ erişimi gerektirir; yeni katalog ve kaynak manifest üretir:

```bash
ruby /Users/gladius/Desktop/Tabu/scripts/generate_catalog.rb \
  /Users/gladius/Desktop/Tabu/Tabu/Files/Kelimeler.json \
  /Users/gladius/Desktop/Tabu/Tabu/Files/Kelimeler.sources.json
```

## App Store Yayın Kontrol Listesi
- Bundle ID, Team ve signing ayarlarını doğrula
- Archive + Validate + Upload akışını Xcode üzerinden tamamla
- `PrivacyInfo.xcprivacy` dosyasının target'a dahil olduğunu doğrula
- `TabuTests` ve `TabuUITests` target'ları varsa testleri release öncesi çalıştır
- Katalog release gate:
  - `scripts/run_catalog_quality_gate.sh` mutlaka başarılı olmalı
- App Store Connect metadata alanlarını doldur:
  - açıklama
  - ekran görüntüleri
  - yaş derecelendirmesi
  - gizlilik beyanları
- TestFlight üzerinde smoke test yap:
  - tek kişilik akış
  - takımlı akış
  - ayarlar (kategori/zorluk)
  - arka plan/ön plan timer davranışı

## Sorun Giderme
- `xcodebuild` çalışmıyorsa aktif geliştirici dizinini kontrol et:

```bash
xcode-select -p
```

- Script doğrulaması başarısızsa:
  1. `curate_catalog.rb` çalıştır
  2. `validate_catalog.rb` ve `verify_sources_alignment.rb` çalıştır
  3. gerekiyorsa `generate_catalog.rb` ile dataset'i yeniden üret

---

Bu README, depo içindeki güncel klasör yapısı ve kod akışına göre hazırlanmıştır.
