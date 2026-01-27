import 'package:flutter/foundation.dart';
import 'package:multi_ads_sdk/multi_ads_sdk.dart';

/// Unified Ads Manager for multi-provider ad management
///
/// This class provides a single entry point for managing ads from different
/// providers (AdMob, AdX, Facebook). It enforces the single-load and
/// single-show pattern where:
/// - Only one instance of each ad type is kept in memory
/// - After showing, the instance is destroyed
/// - SDK can automatically reload after show if configured
///
/// Usage:
/// ```dart
/// await MultiAdsManager.init(AdProviderType.admob);
/// await MultiAdsManager.loadInterstitial();
/// await MultiAdsManager.showInterstitial();
/// ```
class MultiAdsManager {
  static BaseAdProvider? _currentProvider;
  static AdProviderType? _currentProviderType;

  /// Initialize the SDK with the specified provider
  ///
  /// [type] - The ad provider type to initialize
  ///
  /// Example:
  /// ```dart
  /// await MultiAdsManager.init(AdProviderType.admob);
  /// ```
  static Future<void> init(AdProviderType type) async {
    switch (type) {
      case AdProviderType.admob:
        _currentProvider = AdmobProvider();
        break;
      case AdProviderType.adx:
        _currentProvider = AdXProvider();
        break;
      case AdProviderType.facebook:
        _currentProvider = FacebookAdsProvider();
        break;
    }

    await _currentProvider?.init();
    _currentProviderType = type;

    // Set up event listeners for callbacks
    _setupEventListeners();
  }

  /// Load an ad of the specified type
  ///
  /// [type] - The type of ad to load
  /// [adUnitId] - The ad unit ID to use (required)
  ///
  /// Example:
  /// ```dart
  /// await MultiAdsManager.load(AdType.interstitial, adUnitId: 'ca-app-pub-xxx/xxx');
  /// ```
  static Future<void> load(AdType type, {required String adUnitId}) async {
    _ensureInitialized();
    await _currentProvider?.load(type, adUnitId: adUnitId);
  }

  /// Show an ad of the specified type
  ///
  /// [type] - The type of ad to show
  /// [onReward] - Optional callback for rewarded ads when user earns reward
  ///
  /// Example:
  /// ```dart
  /// await MultiAdsManager.show(AdType.rewarded, onReward: () {
  ///   print('User earned reward!');
  /// });
  /// ```
  static Future<void> show(AdType type, {Function()? onReward}) async {
    _ensureInitialized();
    await _currentProvider?.show(type, onReward: onReward);
  }

  /// Load an interstitial ad
  ///
  /// [adUnitId] - The ad unit ID to use (required)
  ///
  /// Shortcut method for loading interstitial ads.
  static Future<void> loadInterstitial({required String adUnitId}) async {
    await load(AdType.interstitial, adUnitId: adUnitId);
  }

  /// Show an interstitial ad
  ///
  /// Shortcut method for showing interstitial ads.
  static Future<void> showInterstitial() async {
    await show(AdType.interstitial);
  }

  /// Load a rewarded ad
  ///
  /// [adUnitId] - The ad unit ID to use (required)
  ///
  /// Shortcut method for loading rewarded ads.
  static Future<void> loadRewarded({required String adUnitId}) async {
    await load(AdType.rewarded, adUnitId: adUnitId);
  }

  /// Show a rewarded ad
  ///
  /// [onReward] - Callback when user earns reward
  ///
  /// Shortcut method for showing rewarded ads.
  static Future<void> showRewarded({Function()? onReward}) async {
    await show(AdType.rewarded, onReward: onReward);
  }

  /// Load an app open ad
  ///
  /// [adUnitId] - The ad unit ID to use (required)
  ///
  /// Shortcut method for loading app open ads.
  static Future<void> loadAppOpen({required String adUnitId}) async {
    await load(AdType.appOpen, adUnitId: adUnitId);
  }

  /// Show an app open ad
  ///
  /// Shortcut method for showing app open ads.
  static Future<void> showAppOpen() async {
    await show(AdType.appOpen);
  }

  /// Load a banner ad
  ///
  /// [adUnitId] - The ad unit ID to use (required)
  ///
  /// Shortcut method for loading banner ads.
  static Future<void> loadBanner({required String adUnitId}) async {
    await load(AdType.banner, adUnitId: adUnitId);
  }

  /// Show a banner ad
  ///
  /// Shortcut method for showing banner ads.
  static Future<void> showBanner() async {
    await show(AdType.banner);
  }

  /// Load a rewarded interstitial ad
  ///
  /// [adUnitId] - The ad unit ID to use (required)
  ///
  /// Shortcut method for loading rewarded interstitial ads.
  static Future<void> loadRewardedInterstitial(
      {required String adUnitId}) async {
    await load(AdType.rewardedInterstitial, adUnitId: adUnitId);
  }

  /// Show a rewarded interstitial ad
  ///
  /// [onReward] - Callback when user earns reward
  ///
  /// Shortcut method for showing rewarded interstitial ads.
  static Future<void> showRewardedInterstitial({Function()? onReward}) async {
    await show(AdType.rewardedInterstitial, onReward: onReward);
  }

  /// Load a native ad
  ///
  /// [adUnitId] - The ad unit ID to use (required)
  ///
  /// Shortcut method for loading native ads.
  static Future<void> loadNative({required String adUnitId}) async {
    await load(AdType.native, adUnitId: adUnitId);
  }

  /// Show a native ad
  ///
  /// Shortcut method for showing native ads.
  static Future<void> showNative() async {
    await show(AdType.native);
  }

  /// Ensure the SDK is initialized before operations
  static void _ensureInitialized() {
    if (_currentProvider == null || _currentProviderType == null) {
      throw Exception(
        'MultiAdsManager not initialized. Call MultiAdsManager.init() first.',
      );
    }
  }

  /// Set up event listeners for ad callbacks
  static void _setupEventListeners() {
    PlatformAdService.setupEventListeners(
      onAdLoaded: (adType) {
        if (kDebugMode) {
          print('[MultiAdsManager] Ad loaded: ${adType.name}');
        }
      },
      onAdFailedToLoad: (adType, error) {
        if (kDebugMode) {
          print(
              '[MultiAdsManager] Ad failed to load: ${adType.name}, Error: $error');
        }
      },
      onAdShown: (adType) {
        if (kDebugMode) {
          print('[MultiAdsManager] Ad shown: ${adType.name}');
        }
      },
      onAdDismissed: (adType) {
        if (kDebugMode) {
          print('[MultiAdsManager] Ad dismissed: ${adType.name}');
        }
      },
      onAdClicked: (adType) {
        if (kDebugMode) {
          print('[MultiAdsManager] Ad clicked: ${adType.name}');
        }
      },
      onRewarded: (adType) {
        if (kDebugMode) {
          print('[MultiAdsManager] Reward earned: ${adType.name}');
        }
      },
    );
  }
}
