# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
