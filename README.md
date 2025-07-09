# Neurograph Mobil Uygulaması

Bu proje, Flutter ile geliştirilmiş, sadece **Android** platformunu hedefleyen ve **Firebase** backend kullanan bir mobil uygulamadır. Uygulama, çeşitli bilişsel testler ve kullanıcı etkileşimleri sunar.

## Başlangıç

### Gereksinimler
- [Flutter](https://flutter.dev/docs/get-started/install) (en az 3.x sürümü önerilir)
- Android Studio veya VSCode (Flutter eklentisiyle)
- Android cihaz veya emülatör

### Kurulum
1. **Depoyu klonlayın:**
   ```sh
   git clone <bu-repo-linki>
   cd frontend
   ```
2. **Bağımlılıkları yükleyin:**
   ```sh
   flutter pub get
   ```
3. **Firebase ve API anahtarlarını ayarlayın:**
   - Proje kök dizinine `.env` dosyası oluşturun ve aşağıdaki gibi doldurun:
     ```
     GEMINI_API_KEY=buraya_anahtarınızı_yazın
     ```
   - `.env` dosyasını `pubspec.yaml` dosyanızda assets olarak ekleyin:
     ```yaml
     flutter:
       assets:
         - .env
     ```
4. **Uygulamayı başlatın:**
   ```sh
   flutter run
   ```

## Özellikler
- Kullanıcı girişi ve onboarding
- Bilişsel testler (çizim, ses, metin vb.)
- Firebase ile veri saklama
- Gemini API ile entegrasyon (anahtar .env ile yönetilir)

## Dizin Yapısı
- `lib/` : Tüm Flutter kaynak kodları
- `assets/` : Görseller ve medya dosyaları
- `.env` : Gizli anahtarlar (sürüm kontrolüne eklenmemeli)

## Notlar
- Sadece Android platformu desteklenmektedir.
- `.env` dosyanızı kimseyle paylaşmayın!
- Firebase kurulumu için ilgili dökümana bakınız: [FlutterFire](https://firebase.flutter.dev/docs/overview)

## Katkı
Katkıda bulunmak için lütfen bir fork oluşturun ve pull request gönderin.

---

Herhangi bir sorunla karşılaşırsanız, lütfen bir issue açın veya proje yöneticisiyle iletişime geçin.
