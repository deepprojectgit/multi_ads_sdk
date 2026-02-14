# multi_ads_sdk

[![pub package](https://img.shields.io/pub/v/multi_ads_sdk.svg)](https://pub.dev/packages/multi_ads_sdk)

A comprehensive Flutter SDK for multi-provider ads (AdMob, AdX, Facebook) with single-load and single-show pattern. Built with clean architecture principles and supports Android & iOS.

## Features

- ✅ **Multi-Provider Support**: AdMob, AdX, and Facebook Audience Network
- ✅ **Single-Load & Single-Show Pattern**: Only one instance of each ad type in memory
- ✅ **Clean Architecture**: Core → Data → Platform layers
- ✅ **Dynamic Ad Unit IDs**: Pass ad unit IDs at runtime
- ✅ **Multiple Ad Formats**: App Open, Banner, Interstitial, Rewarded, Rewarded Interstitial, Native
- ✅ **Platform Support**: Android (Kotlin) & iOS (Swift)
- ✅ **MethodChannel Communication**: Efficient native bridge
- ✅ **Error Handling**: Comprehensive error handling and callbacks

## 📋 Features

- **Multi-Provider Support**: AdMob, AdX, and Facebook Audience Network
- **Single-Load & Single-Show Pattern**: Only one instance of each ad type in memory
- **Clean Architecture**: Core → Data → Platform layers
- **Multiple Ad Formats**:
  - App Open Ads
  - Banner Ads (inline + adaptive)
  - Interstitial Ads
  - Rewarded Ads
  - Rewarded Interstitial Ads
  - Native Ads
- **Platform Support**: Android (Kotlin) & iOS (Swift)
- **MethodChannel Communication**: Efficient native bridge
- **Error Handling**: Comprehensive error handling and callbacks

## 🚀 Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  multi_ads_sdk: ^1.0.8
```

Then run:

```bash
flutter pub get
```

Or install from the command line:

```bash
flutter pub add multi_ads_sdk
```

## 📱 Platform Setup

### Android Setup

1. **Update `android/app/build.gradle`**:

```gradle
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

2. **Update `android/app/src/main/AndroidManifest.xml`**:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <application>
        <!-- Add your AdMob App ID -->
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
    </application>
</manifest>
```

3. **Dependencies** (already included in the package):
   - Google Mobile Ads SDK
   - Facebook Audience Network SDK

### iOS Setup

1. **Update `ios/Podfile`**:

```ruby
platform :ios, '15.0'
```

2. **Update `ios/Runner/Info.plist`**:

Add your AdMob App ID:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>
```

3. **Install Pods**:

```bash
cd ios
pod install
cd ..
```

4. **Dependencies** (already included in the package):
   - Google-Mobile-Ads-SDK (~> 12.0, Firebase 11 compatible)
   - FBAudienceNetwork

## 💻 Usage

### Basic Initialization

```dart
import 'package:multi_ads_sdk/multi_ads_sdk.dart';

// Initialize with AdMob
await MultiAdsManager.init(AdProviderType.admob);

// Or use AdX
await MultiAdsManager.init(AdProviderType.adx);

// Or use Facebook
await MultiAdsManager.init(AdProviderType.facebook);
```

### Interstitial Ads

```dart
// Load interstitial with your ad unit ID
await MultiAdsManager.loadInterstitial(
  adUnitId: 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX',
);

// Show interstitial
await MultiAdsManager.showInterstitial();
```

### Rewarded Ads

```dart
// Load rewarded ad with your ad unit ID
await MultiAdsManager.loadRewarded(
  adUnitId: 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX',
);

// Show rewarded ad with reward callback
await MultiAdsManager.showRewarded(
  onReward: () {
    print('User earned reward!');
    // Give reward to user
  },
);
```

### App Open Ads

```dart
// Load app open ad with your ad unit ID
await MultiAdsManager.loadAppOpen(
  adUnitId: 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX',
);

// Show app open ad
await MultiAdsManager.showAppOpen();
```

### Banner Ads

```dart
// Load banner ad with your ad unit ID
await MultiAdsManager.loadBanner(
  adUnitId: 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX',
);

// Show banner ad
await MultiAdsManager.showBanner();
```

### Rewarded Interstitial Ads

```dart
// Load rewarded interstitial with your ad unit ID
await MultiAdsManager.loadRewardedInterstitial(
  adUnitId: 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX',
);

// Show rewarded interstitial
await MultiAdsManager.showRewardedInterstitial(
  onReward: () {
    print('User earned reward!');
  },
);
```

### Native Ads

```dart
// Load native ad with your ad unit ID
await MultiAdsManager.loadNative(
  adUnitId: 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX',
);

// Show native ad
await MultiAdsManager.showNative();
```

### Advanced Usage

You can also use the generic methods:

```dart
// Load any ad type with your ad unit ID
await MultiAdsManager.load(
  AdType.interstitial,
  adUnitId: 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX',
);

// Show any ad type
await MultiAdsManager.show(AdType.rewarded, onReward: () {
  print('Reward earned!');
});
```

## 🏗️ Architecture

The SDK follows Clean Architecture principles:

```
lib/
├── src/
│   ├── core/              # Domain layer
│   │   ├── ad_provider_type.dart
│   │   ├── ad_type.dart
│   │   └── base_ad_provider.dart
│   ├── data/              # Data layer
│   │   └── platform_ad_service.dart
│   ├── platform/          # Platform implementations
│   │   ├── admob_provider.dart
│   │   ├── adx_provider.dart
│   │   └── facebook_ads_provider.dart
│   └── multi_ads_manager.dart  # Unified API
```

## 📝 Single-Load & Single-Show Pattern

The SDK enforces a strict single-load and single-show pattern:

1. **Load**: Only one instance of each ad type is kept in memory
2. **Show**: After showing, the ad instance is automatically destroyed
3. **Reload**: You can reload the ad after it's been shown

This pattern ensures:
- Memory efficiency
- Predictable ad lifecycle
- No memory leaks from multiple ad instances

## 🔧 Configuration

### Dynamic Ad Unit IDs

The SDK now supports **dynamic ad unit IDs** - you pass them when loading ads. No need to hardcode them in native code!

Simply pass your ad unit ID when calling any `load*` method:

```dart
// AdMob/AdX ad unit ID format: ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX
await MultiAdsManager.loadInterstitial(
  adUnitId: 'ca-app-pub-1234567890123456/1234567890',
);

// Facebook placement ID format: YOUR_PLACEMENT_ID
await MultiAdsManager.loadInterstitial(
  adUnitId: 'YOUR_FACEBOOK_PLACEMENT_ID',
);
```

This allows you to:
- Use different ad unit IDs for different ad types
- Switch ad unit IDs dynamically based on app configuration
- Easily test with different ad units without code changes

## 📊 Callbacks

The SDK provides callbacks for ad events:

- `onAdLoaded`: Ad successfully loaded
- `onAdFailedToLoad`: Ad failed to load (with error message)
- `onAdShown`: Ad is shown
- `onAdDismissed`: Ad is dismissed
- `onAdClicked`: Ad is clicked
- `onRewarded`: User earned reward (for rewarded ads)

These callbacks are automatically logged to the console. You can customize them in `MultiAdsManager._setupEventListeners()`.

## 🧪 Testing

Run the example app:

```bash
cd example
flutter run
```

The example app includes:
- Material 3 UI
- Buttons for all ad types
- Provider selection (AdMob/AdX/Facebook)
- Status messages
- Console logging

## 📚 API Reference

### MultiAdsManager

Main entry point for the SDK.

#### Static Methods

- `init(AdProviderType type)`: Initialize the SDK with a provider
- `load(AdType type)`: Load an ad of the specified type
- `show(AdType type, {Function()? onReward})`: Show an ad of the specified type

#### Shortcut Methods

- `loadInterstitial({required String adUnitId})` / `showInterstitial()`
- `loadRewarded({required String adUnitId})` / `showRewarded({Function()? onReward})`
- `loadAppOpen({required String adUnitId})` / `showAppOpen()`
- `loadBanner({required String adUnitId})` / `showBanner()`
- `loadRewardedInterstitial({required String adUnitId})` / `showRewardedInterstitial({Function()? onReward})`
- `loadNative({required String adUnitId})` / `showNative()`

### Enums

#### AdProviderType

```dart
enum AdProviderType {
  admob,      // Google AdMob
  adx,        // Google AdX
  facebook,   // Facebook Audience Network
}
```

#### AdType

```dart
enum AdType {
  banner,              // Banner ads
  interstitial,        // Interstitial ads
  rewarded,           // Rewarded ads
  rewardedInterstitial, // Rewarded interstitial ads
  appOpen,            // App open ads
  native,             // Native ads
}
```

## 🐛 Troubleshooting

### Android Issues

1. **Build errors**: Ensure `minSdkVersion` is at least 21
2. **Ad not loading**: Check internet permissions in `AndroidManifest.xml`
3. **Facebook SDK errors**: Ensure Facebook SDK is properly initialized

### iOS Issues

1. **Pod install errors**: Run `pod repo update` then `pod install`
2. **Build errors**: Ensure iOS deployment target is 15.0 or higher
3. **Ad not loading**: Check `Info.plist` for AdMob App ID
4. **Firebase compatibility**: This SDK uses Google-Mobile-Ads-SDK 12.x for compatibility with Firebase 11.x. If you see dependency errors:
   - Run `cd ios`, remove `Podfile.lock` and `Pods`, then `pod install --repo-update`.

## 📋 Ads failure & exception logging

The SDK logs ad load failures and exceptions via **`AdsLogger`**:

- **Ad failed to load** (platform `onAdFailedToLoad`): logged with ad type and error message.
- **Exceptions** (init, load, show, connectivity): logged with message, exception, and stack trace.

In debug mode, all of these are printed to the console. You can set a **custom logger** (e.g. for Crashlytics) so failures are reported in production:

```dart
import 'package:multi_ads_sdk/multi_ads_sdk.dart';

void main() {
  AdsLogger.setLogger((adType, message, [error, stackTrace]) {
    // Send to your crash reporting / analytics
    FirebaseCrashlytics.instance.log('Ad: $adType - $message');
    if (error != null) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  });
  runApp(MyApp());
}
```

## 📦 Publishing to pub.dev

To clear the "2 checked-in files are ignored by .gitignore" warning when running `dart pub publish --dry-run`, stop tracking those files (they remain on disk and are already in `.gitignore`):

```bash
git rm --cached example/android/local.properties
git rm --cached "example/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java"
git commit -m "chore: stop tracking example Android generated/local files"
```

Then run `dart pub publish --dry-run` again; the warning should be gone.

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📞 Support

For issues and questions, please open an issue on [GitHub](https://github.com/yourusername/multi_ads_sdk/issues).

---

**Note**: This SDK requires you to pass ad unit IDs when loading ads. Use test ad unit IDs during development and replace them with your production ad unit IDs before publishing your app.
