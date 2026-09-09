# AdMob Mediation App (Flutter, iOS-ready)

Is app me:
- **App Open Ad** — app open hote hi show hota hai
  - Ad Unit: `ca-app-pub-3993277664656708/4770454794`
- **Banner Ad** — Home screen ke neeche hamesha show hota hai
  - Ad Unit: `ca-app-pub-3993277664656708/1893492511`
- **AdMob App ID**: `ca-app-pub-3993277664656708~3314385392`

Best UI: gradient splash, card-based home screen, grid layout.

---

## Setup Steps (Terminal me chalayein)

### 1. Naya Flutter project banayein (ya is code ko apne project me copy karein)
```bash
flutter create admob_mediation_app
cd admob_mediation_app
```

Is folder ki `lib/` files ko apne project ki `lib/` folder me copy kar dein,
aur `pubspec.yaml` ka `dependencies:` section merge kar dein.

### 2. Dependencies install karein
```bash
flutter pub get
```

### 3. iOS Configuration

`ios/Runner/Info.plist` file kholein aur `ios_setup/Info.plist.snippet.xml`
wali lines `<dict>` ke andar paste karein (App ID + tracking permission +
SKAdNetworkItems).

> ⚠️ **Zaroori:** SKAdNetworkItems list me sirf Google ki ID nahi — agar
> aap kisi third-party mediation network (Meta, Unity Ads, AppLovin, etc.)
> use kar rahe hain to unki SKAdNetwork IDs bhi add karni hongi. Har
> network ki apni list hoti hai, unke docs se copy karein.

### 4. Minimum iOS version
`ios/Podfile` me platform kam se kam 13.0 rakhein:
```ruby
platform :ios, '13.0'
```

### 5. Pods install karein
```bash
cd ios
pod install
cd ..
```

### 6. Run karein
```bash
flutter run
```

---

## Mediation Platform Setup (Aapke pehle message ke mutabiq)

Third-party mediation platform (jaise AppLovin MAX, ironSource, etc.) par:

1. Apne **AdMob account** se sign in karein us mediation platform par.
2. Ad unit mapping me ye values fill karein:
   - **AdMob App ID:** `ca-app-pub-3993277664656708~3314385392`
   - **AdMob Ad Unit ID:** `ca-app-pub-3993277664656708/1893492511` (banner)
   - App Open ke liye: `ca-app-pub-3993277664656708/4770454794`
3. Mediation platform ke docs check karke minimum SDK + adapter version
   match karein — har network ka apna requirement hota hai, isliye
   platform-specific documentation dekhna zaroori hai.
4. Agar partner bidding pehli dafa use kar rahe hain, to kam az kam
   **2 hafte** test run karein performance evaluate karne se pehle.

---

## Important Notes

- Real device par test karte waqt shuru me **test ads** use karein
  (Google ke test ad unit IDs) taake accidental invalid clicks se
  account suspend na ho. Jab app publish ke liye ready ho tab hi
  live/production ad unit IDs (jo upar diye hain) use karein.
- App Store submit karne se pehle Apple ka **App Tracking Transparency
  (ATT)** prompt properly implement karna hoga (iOS 14+ requirement),
  warna ads ki fill rate kam ho sakti hai.
- File structure:
  ```
  lib/
    main.dart                 -> App entry + Home UI
    app_open_ad_manager.dart  -> App Open Ad logic
    banner_ad_widget.dart     -> Banner Ad widget
  ios_setup/
    Info.plist.snippet.xml    -> iOS ke liye add karne wali lines
  ```
