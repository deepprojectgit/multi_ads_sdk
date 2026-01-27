import '../core/ad_provider_type.dart';
import '../core/ad_type.dart';
import '../core/base_ad_provider.dart';
import '../data/platform_ad_service.dart';

/// AdMob provider implementation
///
/// This class implements the BaseAdProvider interface for Google AdMob.
/// It handles initialization, loading, and showing of AdMob ads with
/// single-load and single-show pattern.
class AdmobProvider implements BaseAdProvider {
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;

    await PlatformAdService.initProvider(AdProviderType.admob);
    _initialized = true;
  }

  @override
  Future<void> load(AdType type, {required String adUnitId}) async {
    if (!_initialized) {
      throw Exception('AdMob provider not initialized. Call init() first.');
    }

    await PlatformAdService.loadAd(AdProviderType.admob, type, adUnitId);
  }

  @override
  Future<void> show(AdType type, {Function()? onReward}) async {
    if (!_initialized) {
      throw Exception('AdMob provider not initialized. Call init() first.');
    }

    // Set up reward callback if provided
    if (onReward != null &&
        (type == AdType.rewarded || type == AdType.rewardedInterstitial)) {
      PlatformAdService.setupEventListeners(
        onRewarded: (adType) {
          if (adType == type) {
            onReward();
          }
        },
      );
    }

    await PlatformAdService.showAd(AdProviderType.admob, type);
  }
}
