# 🎮 Tabu - iOS Kelime Tahmin Oyunu

<div align="center">

![Platform](https://img.shields.io/badge/Platform-iOS-blue)
![Language](https://img.shields.io/badge/Language-Swift-orange)
![License](https://img.shields.io/badge/License-MIT-green)

**Türkçe kelime hazinesiyle zenginleştirilmiş, modern ve şık bir Tabu oyunu.**

</div>

---

## 📱 Uygulama Hakkında

Tabu, klasik kelime tahmin oyununun iOS platformu için geliştirilmiş modern bir versiyonudur. Oyuncular, yasaklı kelimeleri kullanmadan ekrandaki kelimeyi takım arkadaşlarına anlatmaya çalışırlar. Uygulama hem **tek başına pratik modu** hem de **takımlı rekabetçi mod** sunmaktadır.

### ✨ Temel Özellikler

- 🎯 **Tek Başına Mod**: Kendi başınıza pratik yapın ve skorunuzu yükseltin
- 👥 **Takımlı Mod**: 2 veya daha fazla takımla rekabetçi oyun deneyimi
- 📚 **Zengin Kelime Havuzu**: 400+ kelime içeren çeşitli kategoriler
- ⏱️ **Ayarlanabilir Süre**: Tur sürelerini özelleştirin
- 🎨 **Modern UI/UX**: Glassmorphism efektleri ve akıcı animasyonlar
- 📊 **Skor Takibi**: Detaylı tur özeti ve final skorları
- 🔄 **Pas Sistemi**: Sınırlı veya sınırsız pas hakkı
- 📱 **Haptic Feedback**: Dokunsal geri bildirimlerle zenginleştirilmiş deneyim

---

## 🎲 Oyun Modları

### Tek Başına Modu
- 60 saniyelik standart tur süresi
- Doğru cevap: +1 puan
- Tabu (yasaklı kelime kullanımı): -1 puan
- Pas: Ceza yok
- Süre bitiminde oyun sonu ekranı ve final skoru

### Takımlı Mod
- 2-4 takım desteği
- Özelleştirilebilir takım isimleri
- Ayarlanabilir tur süresi (varsayılan 60 saniye)
- Her takım için belirlenen sayıda tur
- Sınırlı veya sınırsız pas hakkı
- Her tur sonunda detaylı istatistik özeti
- Tüm turlar tamamlandığında kazananın ilanı

---

## 📂 Kelime Kategorileri

Uygulama, zengin ve çeşitli kelime kategorileri içermektedir:

| Kategori | Açıklama |
|----------|----------|
| 🎬 **Diziler & Filmler** | Popüler dizi ve film isimleri |
| 🔭 **Astronomi, Fizik & Mühendislik** | Bilimsel terimler ve kavramlar |
| 📚 **Genel Kültür** | Çeşitli genel kültür kelimeleri |

Her kart şunları içerir:
- **Ana Kelime**: Anlatılması gereken kelime
- **5 Yasaklı Kelime**: Anlatırken kullanılması yasak olan kelimeler

---


## 🏗️ Proje Yapısı

```
Tabu/
├── Tabu.xcodeproj/         # Xcode proje dosyaları
├── scripts/                # Veri üretimi ve yönetimi için Ruby scriptleri
│   ├── curate_catalog.rb   # Katalog düzenleme
│   ├── generate_catalog.rb # Wikidata'dan veri çekme ve işleme
│   └── validate_catalog.rb # Veri doğrulama
└── Tabu/
    ├── Assets.xcassets/    # Görsel varlıklar ve ikonlar
    ├── Base.lproj/         # Yerelleştirme dosyaları
    ├── Files/              # Çekirdek dosyalar ve Veri Kaynakları
    │   ├── AppDelegate.swift
    │   ├── SceneDelegate.swift
    │   ├── Kelimeler.json          # Uygulama içinde kullanılan kelime veritabanı
    │   ├── Kelimeler.sources.json  # Ham veri kaynağı (Wikidata sorgu bilgileri)
    │   └── WordsCatalog.swift      # JSON okuma ve kategori yönetimi
    ├── Settings/           # Ayarlar Modülü
    │   ├── Card.swift              # Kart UI bileşeni
    │   ├── SettingsManager.swift   # Ayarlar mantığı
    │   └── Controller/
    │       ├── MainMenuViewController.swift
    │       └── SettingsViewController.swift
    ├── SingleMode/         # Tek Kişilik Mod
    │   ├── Game.swift              # Oyun mantığı
    │   ├── FlowWrapView.swift      # Yasaklı kelime yerleşimi (Flow Layout)
    │   └── Controller/
    │       ├── GameViewController.swift
    │       └── GameOverViewController.swift
    └── TeamMode/           # Takımlı Mod
        ├── TeamModel.swift         # Takım veri modeli
        ├── TeamGame.swift          # Takım oyunu mantığı
        ├── TeamGameSettings.swift  # Oyun ayarları
        └── Controller/
            ├── TeamSetupViewController.swift
            ├── TeamGameViewController.swift
            └── TeamRoundSummaryViewController.swift
```

---

## 🛠️ Teknik Detaylar

### Gereksinimler
- **iOS**: 15.0+
- **Xcode**: 14.0+
- **Swift**: 5.0+

### Kullanılan Teknolojiler
- **UIKit**: Programatik UI geliştirme
- **Auto Layout**: Responsive tasarım
- **Core Animation**: Akıcı kart animasyonları
- **Timer**: Oyun sayacı yönetimi
- **JSON Parsing**: Kelime veritabanı işleme
- **UserDefaults**: Kategori tercihlerinin saklanması
- **Haptic Feedback**: UINotificationFeedbackGenerator, UIImpactFeedbackGenerator
- **Ruby & Wikidata**: Otomatik veri seti oluşturma (scripts klasörü)

### Tasarım Özellikleri
- **Glassmorphism**: Blur efektli cam görünümü kartlar
- **Gradient Borders**: Animasyonlu gradient kenarlıklar
- **Shadow Effects**: Derinlik hissi veren gölgeler
- **Spring Animations**: Doğal hissettiren animasyonlar
- **Swipe Animations**: Kart geçiş animasyonları

---

## 🚀 Kurulum

1. **Projeyi klonlayın:**
   ```bash
   git clone https://github.com/Mahmutakin99/Tabu.git
   cd Tabu
   ```

2. **Xcode ile açın:**
   ```bash
   open Tabu.xcodeproj
   ```

3. **Hedef cihazı seçin** (Simülatör veya gerçek cihaz)

4. **Çalıştırın** (⌘ + R)

---

## 🎮 Nasıl Oynanır?

### Tek Başına Mod
1. Ana menüden **"Tek Başına"** butonuna tıklayın
2. Ekranda görünen kelimeyi yasaklı kelimeleri kullanmadan tanımladığınızı hayal edin
3. **Doğru**: Kelimeyi doğru tahmin ettiyseniz
4. **Tabu**: Yasaklı kelime kullandıysanız
5. **Pas**: Kelimeyi geçmek istiyorsanız
6. 60 saniye dolduğunda skorunuz gösterilir

### Takımlı Mod
1. Ana menüden **"Takımlı"** butonuna tıklayın
2. Takım sayısını ve isimlerini belirleyin
3. Tur süresi ve pas limitini ayarlayın
4. Sırayla her takım kendi turunu oynar
5. Her tur sonunda özet istatistikler gösterilir
6. Tüm turlar bittiğinde en yüksek skorlu takım kazanır

---

## 📝 Yeni Kelime Ekleme

### Manuel Ekleme
`Tabu/Files/Kelimeler.json` dosyasına yeni kelimeler ekleyebilirsiniz:

```json
{
  "categories": {
    "Kategori Adı": {
      "fetchedRows": 100,
      "selectedRows": 10
    }
  },
  "items": {
    "Kategori Adı": [
      {
        "Kelime": "Yeni Kelime",
        "Yasaklılar": ["Yasak1", "Yasak2", "Yasak3", "Yasak4", "Yasak5"]
      }
    ]
  }
}
```

### Otomatik Veri Üretimi (Advanced)
`scripts/` klasöründeki Ruby scriptleri kullanılarak Wikidata üzerinden otomatik veri çekilebilir:
1. `Kelimeler.sources.json` dosyasındaki SPARQL sorgularını düzenleyin.
2. `ruby scripts/generate_catalog.rb` komutunu çalıştırın.

---

## 🔮 Gelecek Özellikler

- [ ] Online çok oyunculu mod
- [ ] Özel kelime listeleri oluşturma
- [ ] Liderlik tablosu (Game Center entegrasyonu)
- [ ] Tema seçenekleri (karanlık/aydınlık)
- [ ] Ses efektleri ve müzik
- [ ] iPad desteği ve optimizasyonu
- [ ] Daha fazla kelime kategorisi

---

## 👨‍💻 Geliştirici

**Mahmut Akın**  
📅 Proje Başlangıç: Ekim 2025  
🔄 Son Güncelleme: Şubat 2026

---

## 🙏 Teşekkürler

Oyunu test eden ve geri bildirim sağlayan herkese teşekkür ederiz!

---

<div align="center">

**Eğlenin! 🎉**

</div>
