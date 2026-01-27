import 'package:flutter/services.dart';
import '../core/ad_provider_type.dart';
import '../core/ad_type.dart';

/// Platform service for communicating with native code via MethodChannel
///
/// This service handles all communication between Dart and native platforms
/// (Android/iOS) for ad operations.
class PlatformAdService {
  /// MethodChannel name for communication
  static const String _channelName = 'multi_ads_sdk';

  /// MethodChannel instance
  static const MethodChannel _channel = MethodChannel(_channelName);

  /// Initialize the ad provider on the native platform
  ///
  /// [providerType] - The ad provider to initialize
  static Future<void> initProvider(AdProviderType providerType) async {
    try {
      await _channel.invokeMethod('initProvider', {
        'providerType': providerType.name,
      });
    } on PlatformException catch (e) {
      throw Exception('Failed to initialize provider: ${e.message}');
    }
  }

  /// Load an ad on the native platform
  ///
  /// [providerType] - The ad provider to use
  /// [adType] - The type of ad to load
  /// [adUnitId] - The ad unit ID to use
  static Future<void> loadAd(
    AdProviderType providerType,
    AdType adType,
    String adUnitId,
  ) async {
    try {
      await _channel.invokeMethod('loadAd', {
        'providerType': providerType.name,
        'adType': adType.name,
        'adUnitId': adUnitId,
      });
    } on PlatformException catch (e) {
      throw Exception('Failed to load ad: ${e.message}');
    }
  }

  /// Show an ad on the native platform
  ///
  /// [providerType] - The ad provider to use
  /// [adType] - The type of ad to show
  static Future<void> showAd(
    AdProviderType providerType,
    AdType adType,
  ) async {
    try {
      await _channel.invokeMethod('showAd', {
        'providerType': providerType.name,
        'adType': adType.name,
      });
    } on PlatformException catch (e) {
      throw Exception('Failed to show ad: ${e.message}');
    }
  }

  /// Check internet connectivity
  ///
  /// Returns true if internet is available, false otherwise.
  /// Throws an exception with "No internet available" if internet is not available.
  static Future<bool> checkInternetConnectivity() async {
    try {
      final bool isConnected = await _channel.invokeMethod('checkInternetConnectivity');
      if (!isConnected) {
        throw Exception('No internet available');
      }
      return isConnected;
    } on PlatformException {
      throw Exception('No internet available');
    }
  }

  /// Set up event listeners for ad callbacks
  ///
  /// [onAdLoaded] - Called when an ad is successfully loaded
  /// [onAdFailedToLoad] - Called when an ad fails to load
  /// [onAdShown] - Called when an ad is shown
  /// [onAdDismissed] - Called when an ad is dismissed
  /// [onAdClicked] - Called when an ad is clicked
  /// [onRewarded] - Called when user earns a reward
  static void setupEventListeners({
    Function(AdType)? onAdLoaded,
    Function(AdType, String)? onAdFailedToLoad,
    Function(AdType)? onAdShown,
    Function(AdType)? onAdDismissed,
    Function(AdType)? onAdClicked,
    Function(AdType)? onRewarded,
  }) {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onAdLoaded':
          final adTypeStr = call.arguments['adType'] as String;
          final adType = AdType.values.firstWhere(
            (e) => e.name == adTypeStr,
            orElse: () => AdType.banner,
          );
          onAdLoaded?.call(adType);
          break;
        case 'onAdFailedToLoad':
          final adTypeStr = call.arguments['adType'] as String;
          final error = call.arguments['error'] as String;
          final adType = AdType.values.firstWhere(
            (e) => e.name == adTypeStr,
            orElse: () => AdType.banner,
          );
          onAdFailedToLoad?.call(adType, error);
          break;
        case 'onAdShown':
          final adTypeStr = call.arguments['adType'] as String;
          final adType = AdType.values.firstWhere(
            (e) => e.name == adTypeStr,
            orElse: () => AdType.banner,
          );
          onAdShown?.call(adType);
          break;
        case 'onAdDismissed':
          final adTypeStr = call.arguments['adType'] as String;
          final adType = AdType.values.firstWhere(
            (e) => e.name == adTypeStr,
            orElse: () => AdType.banner,
          );
          onAdDismissed?.call(adType);
          break;
        case 'onAdClicked':
          final adTypeStr = call.arguments['adType'] as String;
          final adType = AdType.values.firstWhere(
            (e) => e.name == adTypeStr,
            orElse: () => AdType.banner,
          );
          onAdClicked?.call(adType);
          break;
        case 'onRewarded':
          final adTypeStr = call.arguments['adType'] as String;
          final adType = AdType.values.firstWhere(
            (e) => e.name == adTypeStr,
            orElse: () => AdType.banner,
          );
          onRewarded?.call(adType);
          break;
      }
    });
  }
}
