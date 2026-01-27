/// Enum representing different ad format types
///
/// Supported ad formats:
/// - [banner]: Banner ads (inline and adaptive)
/// - [interstitial]: Full-screen interstitial ads
/// - [rewarded]: Rewarded video ads
/// - [rewardedInterstitial]: Rewarded interstitial ads
/// - [appOpen]: App open ads
/// - [native]: Native ads
enum AdType {
  /// Banner ads (inline and adaptive)
  banner,

  /// Full-screen interstitial ads
  interstitial,

  /// Rewarded video ads
  rewarded,

  /// Rewarded interstitial ads
  rewardedInterstitial,

  /// App open ads
  appOpen,

  /// Native ads
  native,
}
