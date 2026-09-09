# Tash Rush

Tash Rush is an original Kyrgyz-inspired cross-platform 8×8 block puzzle built with Flutter and Flame. The repository contains the playable Classic loop, deterministic Daily Challenges, special cells, local achievements and leaderboard, persisted settings and progress, rewarded continue, test AdMob configuration, and optional Firebase Analytics/Crashlytics initialization.

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

New `CellType` values can be added to the model and handled in `BoardComponent`/`Board` without changing screen business logic. `LeaderboardService`, `PurchaseService`, and `ConsentService` are interfaces so remote providers can replace the local/placeholder implementations.

## Gameplay

- Drag one of the three pieces onto the 8×8 board.
- Every occupied block awards one point.
- Completed rows and columns clear together and award line, multi-line, and combo bonuses.
- A move without a clear resets combo.
- Frozen cells require two line hits; bombs clear a 3×3 area; gold cells award 250 bonus points.
- A line clear refreshes the available set. Otherwise the set refreshes after all three pieces are used.
- Game Over occurs only when none of the visible pieces fits anywhere.
- Rewarded continue is limited to one use per session and clears up to eight occupied cells.

## Local persistence

`StorageService` uses SharedPreferences. It stores `bestScore`, `totalGames`, `totalLines`, `highestCombo`, achievements, audio/haptic/notification settings, locale, daily challenge and streak, and game/ad counters. Daily challenge selection is seeded with the local calendar date and changes automatically on the next date.

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

## GDPR, consent, and privacy

`AdService.initializeAfterConsent()` is the only ad initialization entry point. The included `DevelopmentConsentService` allows test ads only outside release builds; release ad initialization stays disabled until this service is replaced. Before production, replace it with a service backed by Google UMP:

1. Request/update consent information at startup.
2. Present the UMP form when required.
3. Return `true` from `mayRequestAds()` only when ads may be requested.
4. Add a privacy-options entry point in Settings when UMP reports it as required.
5. Configure ATT messaging and `NSUserTrackingUsageDescription` only if the chosen iOS ad strategy requires tracking.

Do not initialize Mobile Ads before the consent service completes. Review Google Play Data safety and App Store privacy nutrition labels before release.

## Audio and haptics

`AudioService` expects optional MP3 files in `assets/audio`: `place.mp3`, `clear.mp3`, `combo.mp3`, `explosion.mp3`, `game_over.mp3`, `button.mp3`, and `music.mp3`. Missing placeholders are safely ignored. Haptics use selection/medium/heavy feedback and respect the vibration setting through the service integration point.

## Android release

Create an upload keystore and replace the debug signing configuration in `android/app/build.gradle` with a secure release signing configuration. Never commit passwords or keystores. Then run:

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

The bundle is written under `build/app/outputs/bundle/release/`. Test it on an internal Play Console track before production.

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

The unit suite covers placement constraints, horizontal/vertical/multi-line clearing, frozen and bomb behavior, scoring, combo growth/reset, and game-over detection:

```bash
flutter test
```

## Production checklist

- Replace all AdMob test IDs and verify consent behavior in EEA test geography.
- Add Firebase configuration files and validate Analytics DebugView/Crashlytics test crash.
- Add real licensed audio, production icon, launch screen, screenshots, and store metadata.
- Configure Android signing, iOS Team/profiles, bundle versions, and privacy manifests.
- Connect `PlaceholderPurchaseService` to Google Play Billing and StoreKit for Remove Ads.
- Replace local leaderboard with the chosen Firebase, Play Games, or Game Center adapter.
- Test low-end Android devices, different iPhone sizes, offline startup, date rollover, and interrupted ads.
- Run `flutter analyze`, `flutter test`, Android App Bundle build, and iOS archive with zero critical errors.
