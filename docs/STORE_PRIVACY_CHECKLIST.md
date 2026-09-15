# Store privacy and release checklist

This checklist is a preparation aid, not a substitute for reviewing the final
enabled SDKs and current store forms.

## Required owner input

- [ ] Replace `[PUBLISH_DATE]` and `[CONTACT_EMAIL]` in `PRIVACY_POLICY.md`.
- [ ] Publish the policy at a stable public HTTPS URL.
- [ ] Add Android and iOS apps to the production Firebase project.
- [ ] Add `android/app/google-services.json`.
- [ ] Add `ios/Runner/GoogleService-Info.plist` to the Runner target.
- [ ] Create production AdMob app and ad-unit IDs for both platforms.
- [ ] Replace native AdMob app IDs in AndroidManifest.xml and Info.plist.
- [ ] Configure the UMP messages and privacy options in AdMob.
- [ ] Decide whether iOS tracking is used; add ATT text only if it is actually
      required by the selected ad configuration.

## Google Play Data safety review

- [ ] Declare Analytics and Crashlytics data used by the final Firebase setup.
- [ ] Declare advertising/device identifiers used by the final AdMob setup.
- [ ] Confirm whether data is shared with Google service providers.
- [ ] Confirm encryption in transit and deletion/request handling.
- [ ] Add the public privacy-policy URL and complete internal testing.

## App Store privacy review

- [ ] Match App Privacy answers to Firebase Analytics, Crashlytics, and AdMob.
- [ ] Review identifiers, usage data, diagnostics, and advertising data.
- [ ] Confirm tracking status matches the production ad configuration.
- [ ] Verify the privacy manifest output in the final archive.
- [ ] Add the privacy-policy URL and support contact in App Store Connect.

## Production ad build

Supply platform-specific ad-unit IDs as compile-time values:

```bash
flutter build appbundle --release \
  --dart-define=ADMOB_REWARDED_ANDROID=ca-app-pub-OWNER/REWARDED \
  --dart-define=ADMOB_INTERSTITIAL_ANDROID=ca-app-pub-OWNER/INTERSTITIAL
```

For iOS use `ADMOB_REWARDED_IOS` and `ADMOB_INTERSTITIAL_IOS`. Never pass
`ALLOW_TEST_ADS=true` to a store build.
