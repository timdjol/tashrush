# Tash Rush

Tash Rush is an original Kyrgyz-inspired cross-platform 8×8 block puzzle built with Flutter and Flame. The repository contains the playable Classic loop, deterministic Daily Challenges, special cells, coin-powered boosters, local achievements and leaderboard, daily notifications, persisted settings and progress, rewarded continue, Remove Ads billing, test AdMob configuration, and optional Firebase Analytics/Crashlytics initialization.

Coins are earned from completed games and Daily Challenge rewards. They can be
spent on a single-cell piece, a board-aware tray shuffle, or a hammer that
removes one occupied cell. Spending and rewards are persisted locally.

## Requirements

- Flutter stable with Dart 3.5 or newer
- Android Studio, Android SDK 35, Java 17, and an Android emulator/device
- macOS with the current Xcode and CocoaPods for iOS 15 or newer
- A Firebase project and AdMob account only for production integrations

Check the toolchain:

```bash
flutter doctor -v
```

If Flutter is not installed, follow the official Flutter installation guide, add `flutter/bin` to `PATH`, accept Android licenses with `flutter doctor --android-licenses`, and run `flutter doctor` until the Android/iOS sections are ready.

## Install and run

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter run
```

Run a specific platform:

```bash
flutter run -d android
flutter run -d ios
```

On a fresh iOS environment, `flutter run` installs pods automatically. If needed:

```bash
cd ios
pod install
cd ..
```

## Architecture

The game rules do not depend on widgets or Flame rendering:

- `lib/game/board` owns the 8×8 board and line/special-cell resolution.
- `lib/game/pieces` contains immutable shapes and the board-aware generator.
- `lib/game/mechanics` owns sessions, game-over detection, continuation, and special-cell creation.
- `lib/game/scoring` contains scoring and combo rules.
- `lib/game/block_rush_game.dart` and `BoardComponent` render the board with Flame.
- `lib/screens` contains Flutter screens and drag-and-drop interaction.
- `lib/services` isolates storage, ads, analytics, audio, haptics, daily challenges, achievements, purchases, and leaderboard concerns.

New `CellType` values can be added to the model and handled in `BoardComponent`/`Board` without changing screen business logic. `LeaderboardService`, `PurchaseService`, and `ConsentService` are interfaces so remote providers can replace the local/placeholder implementations. The first leaderboard implementation shows only real personal game history; it contains no simulated players.

## Gameplay

- Drag one of the three pieces onto the 8×8 board.
- Every occupied block awards one point.
- Completed rows and columns clear together and award line, multi-line, and combo bonuses.
- A move without a clear resets combo.
- Frozen cells require two line hits; bombs clear a 3×3 area; gold cells award 250 bonus points.
- A line clear refreshes the available set. Otherwise the set refreshes after all three pieces are used.
- Game Over occurs only when none of the visible pieces fits anywhere.
- Rewarded continue is limited to one use per session and clears up to eight occupied cells.
- Pieces lift above the finger while dragging and snap from their visual center, including near board edges.
- The first game includes a localized tutorial, and interrupted Classic/Daily sessions restore from the latest move.

## Local persistence

`StorageService` uses SharedPreferences. It stores `bestScore`, `totalGames`, `totalLines`, `highestCombo`, achievements, audio/haptic/notification settings, locale, daily challenge and streak, game/ad counters, and the active Classic/Daily session. Daily challenge selection uses a stable calendar-date seed, changes automatically on the next date, and varies its target difficulty.

The interface is localized in English, Russian, and Kyrgyz.

## Firebase setup

The app intentionally contains no credentials. Development remains playable when Firebase initialization fails.

1. Create Android app `com.timdjol.tashrush` and an iOS app with the same bundle ID in Firebase Console.
2. Place `google-services.json` at `android/app/google-services.json`.
3. Place `GoogleService-Info.plist` at `ios/Runner/GoogleService-Info.plist` and add it to the Runner target in Xcode.
4. Re-run `flutter pub get`, then rebuild.
5. In Firebase Console, enable Analytics and Crashlytics. The Android Crashlytics Gradle plugin activates with the JSON file. For iOS, add the current Firebase Crashlytics symbol-upload run script to the Runner target as documented by Firebase, then verify dSYM upload with a test crash.

The Android Google Services plugin activates only when its JSON file exists. The following events are implemented: `game_started`, `game_finished`, `score_reached`, `rewarded_ad_opened`, `rewarded_ad_completed`, `interstitial_shown`, `daily_started`, `daily_completed`, and `achievement_unlocked`. `game_finished` sends score, duration, lines, and highest combo.

## AdMob

Development uses Google's official test IDs:

- Android app: `ca-app-pub-3940256099942544~3347511713`
- iOS app: `ca-app-pub-3940256099942544~1458002511`
- Rewarded and interstitial unit IDs are in `lib/services/ad_service.dart`.

Before release:

1. Create Android and iOS apps/ad units in AdMob.
2. Replace both app IDs in `AndroidManifest.xml` and `Info.plist`.
3. Replace rewarded/interstitial IDs in `AdService`.
4. Keep test IDs for debug builds or use an environment/config layer so real ads are never clicked during development.
5. Confirm app-ads.txt and store privacy declarations.

Interstitials are requested only after every third completed game, during the transition to restart. They are not shown during play or at launch. Rewarded ads remain voluntary even after future Remove Ads purchase support is added.

## Remove Ads purchase

The app uses Flutter's `in_app_purchase` API for a non-consumable product. Create
the same product in Google Play Console and App Store Connect with the ID
`tash_rush_remove_ads`, or provide another configured ID at build time:

```bash
flutter build appbundle --release \
  --dart-define=REMOVE_ADS_PRODUCT_ID=your_remove_ads_product_id
```

Use Play Console internal testing and an App Store sandbox tester to validate
purchase and restore flows. The included verifier checks the platform receipt
before granting the local entitlement. Before a wide production rollout,
replace `LocalReceiptVerifier` with server-side receipt verification to protect
the entitlement against tampered clients. A successful purchase disables only
interstitial ads; voluntary rewarded ads remain available.

A signed APK for testing the rewarded Continue flow with Google's test ad IDs
can be built with:

```bash
flutter build apk --release --target-platform android-arm64 \
  --dart-define=ALLOW_TEST_ADS=true
```

Never use `ALLOW_TEST_ADS` for a store build. Production releases must use the
real consent service described below.

## GDPR, consent, and privacy

`AdService.initializeAfterConsent()` is the only ad initialization entry point. Debug builds use `DevelopmentConsentService`; production builds use the included `UmpConsentService` and do not load an ad until UMP allows it. Settings exposes the UMP privacy-options form when required.

Production ad-unit IDs are supplied through `ADMOB_REWARDED_ANDROID`, `ADMOB_INTERSTITIAL_ANDROID`, `ADMOB_REWARDED_IOS`, and `ADMOB_INTERSTITIAL_IOS` dart defines. A release without IDs keeps ads unavailable instead of accidentally using test inventory. Native AdMob app IDs still need to be replaced in each platform file.

A publication draft is in `docs/PRIVACY_POLICY.md`; the owner must add the publication date/contact and host it at a public HTTPS URL. Use `docs/STORE_PRIVACY_CHECKLIST.md` for Google Play Data safety and App Store privacy preparation.

Do not initialize Mobile Ads before the consent service completes. Review Google Play Data safety and App Store privacy nutrition labels before release.

## Audio and haptics

`AudioService` expects optional MP3 files in `assets/audio`: `place.mp3`, `clear.mp3`, `combo.mp3`, `explosion.mp3`, `game_over.mp3`, `button.mp3`, and `music.mp3`. Missing placeholders are safely ignored. Haptics use selection/medium/heavy feedback and respect the vibration setting through the service integration point.

## Local notifications

Notifications are off by default and the system permission is requested only
when the player enables them. Tash Rush schedules localized Daily Challenge and
streak reminders using the device timezone. Android boot receivers restore the
schedule after a restart. Test delivery on physical Android and iOS devices;
simulator timing and power-saving behavior can differ from production devices.

## Android release

Create the upload key once. The generator uses a strong random password and
does not print it to the terminal:

```bash
./tool/create_android_upload_key.sh
```

Back up both `android/app/upload-keystore.jks` and `android/key.properties` in
a secure location. They are ignored by Git. Losing them can prevent future
updates from being signed with the same upload identity. A manual configuration
template is available at `android/key.properties.example`.

Increase the build number after every published build in `pubspec.yaml`, then run:

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

The bundle is written under `build/app/outputs/bundle/release/`. Release builds
use the upload key only when `android/key.properties` is present; they never
fall back to the debug certificate. Test every bundle on an internal Play
Console track before production.

## iOS archive

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select the correct Team, provisioning profile, bundle ID, version, and build number.
3. Confirm `GoogleService-Info.plist` is part of Runner.
4. Run:

```bash
flutter clean
flutter pub get
flutter build ipa --release
```

Alternatively select **Product → Archive** in Xcode and distribute from Organizer.

## Tests

The unit suite covers placement constraints, horizontal/vertical/multi-line clearing, frozen and bomb behavior, scoring, combo growth/reset, game-over detection, drag coordinate snapping, fair piece generation, and saved-session restoration:

```bash
flutter test
```

## Production checklist

Run the local readiness audit first:

```bash
./tool/check_release_readiness.sh
```

- Replace all AdMob test IDs and verify consent behavior in EEA test geography.
- Add Firebase configuration files and validate Analytics DebugView/Crashlytics test crash.
- Add real licensed audio, screenshots, and store metadata. Branded launch screens, Android adaptive/themed icons, and the iOS App Store icon are already included.
- Configure Android signing, iOS Team/profiles, bundle versions, and privacy manifests.
- Create and activate the Remove Ads non-consumable in both stores, then test purchases, cancellation, pending transactions, and restore with sandbox accounts.
- Replace local receipt checking with server-side verification before a broad production rollout.
- Replace local leaderboard with the chosen Firebase, Play Games, or Game Center adapter.
- Test low-end Android devices, different iPhone sizes, offline startup, date rollover, and interrupted ads.
- Run `flutter analyze`, `flutter test`, Android App Bundle build, and iOS archive with zero critical errors.
