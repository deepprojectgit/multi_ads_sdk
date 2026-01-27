import '../core/ad_type.dart';

/// Abstract base class for all ad providers
/// 
/// This class defines the contract that all ad providers (AdMob, AdX, Facebook)
/// must implement. It enforces the single-load and single-show pattern.
/// 
/// Each provider must:
/// - Initialize the SDK
/// - Load a single instance of an ad
/// - Show the ad once, then clear the cache
/// - Automatically reload after showing
abstract class BaseAdProvider {
  /// Initialize the ad provider SDK
  /// 
  /// This method should be called once before loading any ads.
  /// It sets up the SDK with necessary configuration.
  Future<void> init();

  /// Load a single instance of the specified ad type
  /// 
  /// This method loads only one instance of the ad. If an ad is already
  /// loaded, it should not load another instance.
  /// 
  /// [type] - The type of ad to load
  /// [adUnitId] - The ad unit ID to use (required)
  Future<void> load(AdType type, {required String adUnitId});

  /// Show the loaded ad of the specified type
  /// 
  /// After showing, the ad instance is destroyed and can be reloaded.
  /// 
  /// [type] - The type of ad to show
  /// [onReward] - Optional callback for rewarded ads when user earns reward
  Future<void> show(AdType type, {Function()? onReward});
}
