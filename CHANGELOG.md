# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.3] - 2026-01-29

### Added
- **AdsLogger**: `logAdFailedToLoad`, `logException`, `logAdNotLoaded`, and `setLogger()` for optional custom logging (e.g. Crashlytics). Exported from `multi_ads_sdk.dart`; see README for usage.
- Native ad layouts: Small and Medium variants with full-width INSTALL button, media-on-top (medium), and transparent background option.

### Changed
- **Native ads**: Layout matches reference (media → details row → body for medium → full-width INSTALL button). Transparent background for native ad containers on Android and iOS.
- **AD_NOT_LOADED**: When show is called before load, SDK throws a clear message ("Ad not loaded. Load the ad first, then tap Show.") and logs without full stack trace. Example app shows "Load the native ad first, then tap Show." when this occurs.

### Fixed
- Lint: Removed unnecessary braces in string interpolation in `ads_logger.dart`.

## [1.0.2] - 2026-01-29

### Fixed
- **Native ads**: Native ads now display correctly via platform views (Android and iOS). Previously only load/show events fired; the ad content is now rendered in the Flutter-embedded native slot.
- **Android**: Added `NativeAdViewFactory` and native ad layout; AdMob and Facebook native ads are attached to the platform view container when loaded or shown.
- **iOS**: Retained `GADAdLoader` so native ad load completes; added native ad platform view and `attachNativeToContainer()` for AdMob and Facebook native display.
- **Example**: Native ad slot uses `AndroidView`/`UiKitView` with `multi_ads_sdk/native` so the loaded native ad appears in the UI.
- **App open ads**: Example app open ad unit ID updated to the correct test ID for app open format (`9257395921`) to fix "Ad unit doesn't match format" when using test ads.

## [1.0.1] - 2026-01-27

### Added
- Internet connectivity check functionality
- `checkInternetConnectivity()` method in `MultiAdsManager` to verify internet availability
- Native platform implementations for connectivity checking on Android and iOS
- Automatic error handling with "No internet available" message when connectivity is unavailable

### Features
- Cross-platform internet connectivity detection using native APIs
- Android implementation using `ConnectivityManager` and `NetworkCapabilities`
- iOS implementation using `Network` framework with `NWPathMonitor`

## [1.0.0] - 2026-01-27

### Added
- Initial release of multi_ads_sdk
- Support for Google AdMob ads
- Support for Google AdX ads
- Support for Facebook Audience Network (Meta Ads)
- Single-load and single-show pattern for all ad types
- Support for multiple ad formats:
  - App Open Ads
  - Banner Ads (inline and adaptive)
  - Interstitial Ads
  - Rewarded Ads
  - Rewarded Interstitial Ads
  - Native Ads
- Clean Architecture implementation (Core → Data → Platform)
- MethodChannel communication for Android and iOS
- Dynamic ad unit ID support
- Comprehensive error handling and callbacks
- Example Flutter app with Material 3 UI
- Full documentation and integration guide

### Features
- Unified API through `MultiAdsManager`
- Provider abstraction with `BaseAdProvider`
- Platform-specific implementations for Android (Kotlin) and iOS (Swift)
- Automatic ad lifecycle management
- Reward callbacks for rewarded ad types
- Event listeners for ad lifecycle events (loaded, shown, dismissed, clicked, rewarded)
