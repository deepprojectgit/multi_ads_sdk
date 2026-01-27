import Flutter
import UIKit
import GoogleMobileAds
import FBAudienceNetwork
import Network

/// MultiAdsSdkPlugin - Main plugin class for iOS
///
/// Handles communication between Flutter and native iOS code.
/// Supports AdMob, AdX, and Facebook Audience Network.
/// Implements single-load and single-show pattern.
public class MultiAdsSdkPlugin: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel
    
    // AdMob/AdX instances (single instance per ad type)
    private var admobInterstitialAd: GADInterstitialAd?
    private var admobRewardedAd: GADRewardedAd?
    private var admobRewardedInterstitialAd: GADRewardedInterstitialAd?
    private var admobAppOpenAd: GADAppOpenAd?
    private var admobNativeAd: GADNativeAd?
    private var admobBannerAd: GADBannerView?
    
    // Facebook instances (single instance per ad type)
    private var facebookInterstitialAd: FBInterstitialAd?
    private var facebookRewardedAd: FBRewardedVideoAd?
    private var facebookBannerAd: FBAdView?
    private var facebookNativeAd: FBNativeAd?
    
    
    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "multi_ads_sdk", binaryMessenger: registrar.messenger())
        let instance = MultiAdsSdkPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initProvider":
            guard let args = call.arguments as? [String: Any],
                  let providerType = args["providerType"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            initProvider(providerType: providerType, result: result)
            
        case "loadAd":
            guard let args = call.arguments as? [String: Any],
                  let providerType = args["providerType"] as? String,
                  let adType = args["adType"] as? String,
                  let adUnitId = args["adUnitId"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments - adUnitId is required", details: nil))
                return
            }
            loadAd(providerType: providerType, adType: adType, adUnitId: adUnitId, result: result)
            
        case "showAd":
            guard let args = call.arguments as? [String: Any],
                  let providerType = args["providerType"] as? String,
                  let adType = args["adType"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            showAd(providerType: providerType, adType: adType, result: result)
            
        case "checkInternetConnectivity":
            checkInternetConnectivity(result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func initProvider(providerType: String, result: @escaping FlutterResult) {
        switch providerType {
        case "admob", "adx":
            GADMobileAds.sharedInstance().start(completionHandler: { _ in
                result(true)
            })
        case "facebook":
            // Facebook SDK initializes automatically
            result(true)
        default:
            result(FlutterError(code: "INVALID_PROVIDER", message: "Unknown provider type", details: nil))
        }
    }
    
    private func loadAd(providerType: String, adType: String, adUnitId: String, result: @escaping FlutterResult) {
        switch providerType {
        case "admob":
            loadAdMobAd(adType: adType, adUnitId: adUnitId, result: result)
        case "adx":
            loadAdXAd(adType: adType, adUnitId: adUnitId, result: result)
        case "facebook":
            loadFacebookAd(adType: adType, adUnitId: adUnitId, result: result)
        default:
            result(FlutterError(code: "INVALID_PROVIDER", message: "Unknown provider type", details: nil))
        }
    }
    
    private func loadAdMobAd(adType: String, adUnitId: String, result: @escaping FlutterResult) {
        switch adType {
        case "interstitial":
            if admobInterstitialAd != nil {
                result(true)
                return
            }
            let request = GADRequest()
            GADInterstitialAd.load(withAdUnitID: adUnitId, request: request) { [weak self] ad, error in
                guard let self = self else { return }
                if let error = error {
                    self.sendEvent(method: "onAdFailedToLoad", arguments: ["adType": "interstitial", "error": error.localizedDescription])
                    result(FlutterError(code: "LOAD_FAILED", message: error.localizedDescription, details: nil))
                    return
                }
                self.admobInterstitialAd = ad
                self.sendEvent(method: "onAdLoaded", arguments: ["adType": "interstitial"])
                result(true)
            }
            
        case "rewarded":
            if admobRewardedAd != nil {
                result(true)
                return
            }
            let request = GADRequest()
            GADRewardedAd.load(withAdUnitID: adUnitId, request: request) { [weak self] ad, error in
                guard let self = self else { return }
                if let error = error {
                    self.sendEvent(method: "onAdFailedToLoad", arguments: ["adType": "rewarded", "error": error.localizedDescription])
                    result(FlutterError(code: "LOAD_FAILED", message: error.localizedDescription, details: nil))
                    return
                }
                self.admobRewardedAd = ad
                self.sendEvent(method: "onAdLoaded", arguments: ["adType": "rewarded"])
                result(true)
            }
            
        case "rewardedInterstitial":
            if admobRewardedInterstitialAd != nil {
                result(true)
                return
            }
            let request = GADRequest()
            GADRewardedInterstitialAd.load(withAdUnitID: adUnitId, request: request) { [weak self] ad, error in
                guard let self = self else { return }
                if let error = error {
                    self.sendEvent(method: "onAdFailedToLoad", arguments: ["adType": "rewardedInterstitial", "error": error.localizedDescription])
                    result(FlutterError(code: "LOAD_FAILED", message: error.localizedDescription, details: nil))
                    return
                }
                self.admobRewardedInterstitialAd = ad
                self.sendEvent(method: "onAdLoaded", arguments: ["adType": "rewardedInterstitial"])
                result(true)
            }
            
        case "appOpen":
            if admobAppOpenAd != nil {
                result(true)
                return
            }
            let request = GADRequest()
            GADAppOpenAd.load(withAdUnitID: adUnitId, request: request, orientation: UIInterfaceOrientation.portrait) { [weak self] ad, error in
                guard let self = self else { return }
                if let error = error {
                    self.sendEvent(method: "onAdFailedToLoad", arguments: ["adType": "appOpen", "error": error.localizedDescription])
                    result(FlutterError(code: "LOAD_FAILED", message: error.localizedDescription, details: nil))
                    return
                }
                self.admobAppOpenAd = ad
                self.sendEvent(method: "onAdLoaded", arguments: ["adType": "appOpen"])
                result(true)
            }
            
        case "banner":
            if admobBannerAd != nil {
                result(true)
                return
            }
            admobBannerAd = GADBannerView(adSize: GADAdSizeBanner)
            admobBannerAd?.adUnitID = adUnitId
            admobBannerAd?.load(GADRequest())
            admobBannerAd?.delegate = self
            sendEvent(method: "onAdLoaded", arguments: ["adType": "banner"])
            result(true)
            
        case "native":
            if admobNativeAd != nil {
                result(true)
                return
            }
            let request = GADRequest()
            let loader = GADAdLoader(adUnitID: adUnitId, rootViewController: nil, adTypes: [.native], options: nil)
            loader.delegate = self
            loader.load(request)
            result(true)
            
        default:
            result(FlutterError(code: "INVALID_AD_TYPE", message: "Unknown ad type", details: nil))
        }
    }
    
    private func loadAdXAd(adType: String, adUnitId: String, result: @escaping FlutterResult) {
        // AdX uses same SDK as AdMob, just different ad unit IDs
        switch adType {
        case "interstitial":
            if admobInterstitialAd != nil {
                result(true)
                return
            }
            let request = GADRequest()
            GADInterstitialAd.load(withAdUnitID: adUnitId, request: request) { [weak self] ad, error in
                guard let self = self else { return }
                if let error = error {
                    self.sendEvent(method: "onAdFailedToLoad", arguments: ["adType": "interstitial", "error": error.localizedDescription])
                    result(FlutterError(code: "LOAD_FAILED", message: error.localizedDescription, details: nil))
                    return
                }
                self.admobInterstitialAd = ad
                self.sendEvent(method: "onAdLoaded", arguments: ["adType": "interstitial"])
                result(true)
            }
            
        case "rewarded":
            if admobRewardedAd != nil {
                result(true)
                return
            }
            let request = GADRequest()
            GADRewardedAd.load(withAdUnitID: adUnitId, request: request) { [weak self] ad, error in
                guard let self = self else { return }
                if let error = error {
                    self.sendEvent(method: "onAdFailedToLoad", arguments: ["adType": "rewarded", "error": error.localizedDescription])
                    result(FlutterError(code: "LOAD_FAILED", message: error.localizedDescription, details: nil))
                    return
                }
                self.admobRewardedAd = ad
                self.sendEvent(method: "onAdLoaded", arguments: ["adType": "rewarded"])
                result(true)
            }
            
        default:
            result(FlutterError(code: "INVALID_AD_TYPE", message: "AdX only supports interstitial and rewarded", details: nil))
        }
    }
    
    private func loadFacebookAd(adType: String, adUnitId: String, result: @escaping FlutterResult) {
        switch adType {
        case "interstitial":
            if facebookInterstitialAd != nil {
                result(true)
                return
            }
            facebookInterstitialAd = FBInterstitialAd(placementID: adUnitId)
            facebookInterstitialAd?.delegate = self
            facebookInterstitialAd?.load()
            result(true)
            
        case "rewarded":
            if facebookRewardedAd != nil {
                result(true)
                return
            }
            facebookRewardedAd = FBRewardedVideoAd(placementID: adUnitId)
            facebookRewardedAd?.delegate = self
            facebookRewardedAd?.load()
            result(true)
            
        case "banner":
            if facebookBannerAd != nil {
                result(true)
                return
            }
            facebookBannerAd = FBAdView(placementID: adUnitId, adSize: kFBAdSizeHeight50Banner, rootViewController: nil)
            facebookBannerAd?.delegate = self
            facebookBannerAd?.loadAd()
            result(true)
            
        case "native":
            if facebookNativeAd != nil {
                result(true)
                return
            }
            facebookNativeAd = FBNativeAd(placementID: adUnitId)
            facebookNativeAd?.delegate = self
            facebookNativeAd?.loadAd()
            result(true)
            
        default:
            result(FlutterError(code: "INVALID_AD_TYPE", message: "Unknown ad type", details: nil))
        }
    }
    
    private func showAd(providerType: String, adType: String, result: @escaping FlutterResult) {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            result(FlutterError(code: "NO_ROOT_VIEW_CONTROLLER", message: "Root view controller not available", details: nil))
            return
        }
        
        switch providerType {
        case "admob":
            showAdMobAd(adType: adType, rootViewController: rootViewController, result: result)
        case "adx":
            showAdXAd(adType: adType, rootViewController: rootViewController, result: result)
        case "facebook":
            showFacebookAd(adType: adType, rootViewController: rootViewController, result: result)
        default:
            result(FlutterError(code: "INVALID_PROVIDER", message: "Unknown provider type", details: nil))
        }
    }
    
    private func showAdMobAd(adType: String, rootViewController: UIViewController, result: @escaping FlutterResult) {
        switch adType {
        case "interstitial":
            guard let ad = admobInterstitialAd else {
                result(FlutterError(code: "AD_NOT_LOADED", message: "Interstitial ad not loaded", details: nil))
                return
            }
            ad.fullScreenContentDelegate = self
            ad.present(fromRootViewController: rootViewController)
            sendEvent(method: "onAdShown", arguments: ["adType": "interstitial"])
            result(true)
            
        case "rewarded":
            guard let ad = admobRewardedAd else {
                result(FlutterError(code: "AD_NOT_LOADED", message: "Rewarded ad not loaded", details: nil))
                return
            }
            ad.fullScreenContentDelegate = self
            ad.present(fromRootViewController: rootViewController) {
                self.sendEvent(method: "onRewarded", arguments: ["adType": "rewarded"])
            }
            sendEvent(method: "onAdShown", arguments: ["adType": "rewarded"])
            result(true)
            
        case "rewardedInterstitial":
            guard let ad = admobRewardedInterstitialAd else {
                result(FlutterError(code: "AD_NOT_LOADED", message: "Rewarded interstitial ad not loaded", details: nil))
                return
            }
            ad.fullScreenContentDelegate = self
            ad.present(fromRootViewController: rootViewController) {
                self.sendEvent(method: "onRewarded", arguments: ["adType": "rewardedInterstitial"])
            }
            sendEvent(method: "onAdShown", arguments: ["adType": "rewardedInterstitial"])
            result(true)
            
        case "appOpen":
            guard let ad = admobAppOpenAd else {
                result(FlutterError(code: "AD_NOT_LOADED", message: "App open ad not loaded", details: nil))
                return
            }
            ad.fullScreenContentDelegate = self
            ad.present(fromRootViewController: rootViewController)
            sendEvent(method: "onAdShown", arguments: ["adType": "appOpen"])
            result(true)
            
        case "banner":
            guard let banner = admobBannerAd else {
                result(FlutterError(code: "AD_NOT_LOADED", message: "Banner ad not loaded", details: nil))
                return
            }
            // Banner display is handled by Flutter widget
            sendEvent(method: "onAdShown", arguments: ["adType": "banner"])
            result(true)
            
        case "native":
            guard admobNativeAd != nil else {
                result(FlutterError(code: "AD_NOT_LOADED", message: "Native ad not loaded", details: nil))
                return
            }
            sendEvent(method: "onAdShown", arguments: ["adType": "native"])
            result(true)
            
        default:
            result(FlutterError(code: "INVALID_AD_TYPE", message: "Unknown ad type", details: nil))
        }
    }
    
    private func showAdXAd(adType: String, rootViewController: UIViewController, result: @escaping FlutterResult) {
        // AdX uses same implementation as AdMob
        showAdMobAd(adType: adType, rootViewController: rootViewController, result: result)
    }
    
    private func showFacebookAd(adType: String, rootViewController: UIViewController, result: @escaping FlutterResult) {
        switch adType {
        case "interstitial":
            guard let ad = facebookInterstitialAd, ad.isAdValid else {
                result(FlutterError(code: "AD_NOT_LOADED", message: "Interstitial ad not loaded", details: nil))
                return
            }
            ad.show(fromRootViewController: rootViewController)
            result(true)
            
        case "rewarded":
            guard let ad = facebookRewardedAd, ad.isAdValid else {
                result(FlutterError(code: "AD_NOT_LOADED", message: "Rewarded ad not loaded", details: nil))
                return
            }
            ad.show(fromRootViewController: rootViewController)
            result(true)
            
        case "banner":
            guard let banner = facebookBannerAd else {
                result(FlutterError(code: "AD_NOT_LOADED", message: "Banner ad not loaded", details: nil))
                return
            }
            sendEvent(method: "onAdShown", arguments: ["adType": "banner"])
            result(true)
            
        case "native":
            guard facebookNativeAd != nil else {
                result(FlutterError(code: "AD_NOT_LOADED", message: "Native ad not loaded", details: nil))
                return
            }
            sendEvent(method: "onAdShown", arguments: ["adType": "native"])
            result(true)
            
        default:
            result(FlutterError(code: "INVALID_AD_TYPE", message: "Unknown ad type", details: nil))
        }
    }
    
    private func checkInternetConnectivity(result: @escaping FlutterResult) {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "InternetConnectivityMonitor")
        
        monitor.pathUpdateHandler = { path in
            let hasInternet = path.status == .satisfied
            monitor.cancel()
            DispatchQueue.main.async {
                result(hasInternet)
            }
        }
        
        monitor.start(queue: queue)
        
        // Add a timeout to avoid waiting indefinitely
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let hasInternet = monitor.currentPath.status == .satisfied
            monitor.cancel()
            result(hasInternet)
        }
    }
    
    private func sendEvent(method: String, arguments: [String: Any]) {
        channel.invokeMethod(method, arguments: arguments)
    }
}

// MARK: - GADFullScreenContentDelegate
extension MultiAdsSdkPlugin: GADFullScreenContentDelegate {
    public func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        // Ad impression recorded
    }
    
    public func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        // Ad failed to present
    }
    
    public func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        // Ad will present
    }
    
    public func adWillDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        // Ad will dismiss
    }
    
    public func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        // Clear ad instance after dismissal
        if ad is GADInterstitialAd {
            admobInterstitialAd = nil
            sendEvent(method: "onAdDismissed", arguments: ["adType": "interstitial"])
        } else if ad is GADRewardedAd {
            admobRewardedAd = nil
            sendEvent(method: "onAdDismissed", arguments: ["adType": "rewarded"])
        } else if ad is GADRewardedInterstitialAd {
            admobRewardedInterstitialAd = nil
            sendEvent(method: "onAdDismissed", arguments: ["adType": "rewardedInterstitial"])
        } else if ad is GADAppOpenAd {
            admobAppOpenAd = nil
            sendEvent(method: "onAdDismissed", arguments: ["adType": "appOpen"])
        }
    }
}

// MARK: - GADBannerViewDelegate
extension MultiAdsSdkPlugin: GADBannerViewDelegate {
    public func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        sendEvent(method: "onAdLoaded", arguments: ["adType": "banner"])
    }
    
    public func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        sendEvent(method: "onAdFailedToLoad", arguments: ["adType": "banner", "error": error.localizedDescription])
    }
    
    public func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
        sendEvent(method: "onAdShown", arguments: ["adType": "banner"])
    }
    
    public func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
        sendEvent(method: "onAdClicked", arguments: ["adType": "banner"])
    }
}

// MARK: - GADAdLoaderDelegate
extension MultiAdsSdkPlugin: GADAdLoaderDelegate, GADNativeAdLoaderDelegate {
    public func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        admobNativeAd = nativeAd
        sendEvent(method: "onAdLoaded", arguments: ["adType": "native"])
    }
    
    public func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        sendEvent(method: "onAdFailedToLoad", arguments: ["adType": "native", "error": error.localizedDescription])
    }
}

// MARK: - FBInterstitialAdDelegate
extension MultiAdsSdkPlugin: FBInterstitialAdDelegate {
    public func interstitialAdDidLoad(_ interstitialAd: FBInterstitialAd) {
        sendEvent(method: "onAdLoaded", arguments: ["adType": "interstitial"])
    }
    
    public func interstitialAd(_ interstitialAd: FBInterstitialAd, didFailWithError error: Error) {
        sendEvent(method: "onAdFailedToLoad", arguments: ["adType": "interstitial", "error": error.localizedDescription])
        facebookInterstitialAd = nil
    }
    
    public func interstitialAdWillLogImpression(_ interstitialAd: FBInterstitialAd) {
        sendEvent(method: "onAdShown", arguments: ["adType": "interstitial"])
    }
    
    public func interstitialAdDidClick(_ interstitialAd: FBInterstitialAd) {
        sendEvent(method: "onAdClicked", arguments: ["adType": "interstitial"])
    }
    
    public func interstitialAdWillClose(_ interstitialAd: FBInterstitialAd) {
        sendEvent(method: "onAdDismissed", arguments: ["adType": "interstitial"])
        facebookInterstitialAd = nil
    }
}

// MARK: - FBRewardedVideoAdDelegate
extension MultiAdsSdkPlugin: FBRewardedVideoAdDelegate {
    public func rewardedVideoAdDidLoad(_ rewardedVideoAd: FBRewardedVideoAd) {
        sendEvent(method: "onAdLoaded", arguments: ["adType": "rewarded"])
    }
    
    public func rewardedVideoAd(_ rewardedVideoAd: FBRewardedVideoAd, didFailWithError error: Error) {
        sendEvent(method: "onAdFailedToLoad", arguments: ["adType": "rewarded", "error": error.localizedDescription])
        facebookRewardedAd = nil
    }
    
    public func rewardedVideoAdWillLogImpression(_ rewardedVideoAd: FBRewardedVideoAd) {
        sendEvent(method: "onAdShown", arguments: ["adType": "rewarded"])
    }
    
    public func rewardedVideoAdDidClick(_ rewardedVideoAd: FBRewardedVideoAd) {
        sendEvent(method: "onAdClicked", arguments: ["adType": "rewarded"])
    }
    
    public func rewardedVideoAdVideoComplete(_ rewardedVideoAd: FBRewardedVideoAd) {
        sendEvent(method: "onRewarded", arguments: ["adType": "rewarded"])
    }
    
    public func rewardedVideoAdWillClose(_ rewardedVideoAd: FBRewardedVideoAd) {
        sendEvent(method: "onAdDismissed", arguments: ["adType": "rewarded"])
        facebookRewardedAd = nil
    }
}

// MARK: - FBAdViewDelegate
extension MultiAdsSdkPlugin: FBAdViewDelegate {
    public func adViewDidLoad(_ adView: FBAdView) {
        sendEvent(method: "onAdLoaded", arguments: ["adType": "banner"])
    }
    
    public func adView(_ adView: FBAdView, didFailWithError error: Error) {
        sendEvent(method: "onAdFailedToLoad", arguments: ["adType": "banner", "error": error.localizedDescription])
    }
    
    public func adViewWillLogImpression(_ adView: FBAdView) {
        sendEvent(method: "onAdShown", arguments: ["adType": "banner"])
    }
    
    public func adViewDidClick(_ adView: FBAdView) {
        sendEvent(method: "onAdClicked", arguments: ["adType": "banner"])
    }
}

// MARK: - FBNativeAdDelegate
extension MultiAdsSdkPlugin: FBNativeAdDelegate {
    public func nativeAdDidLoad(_ nativeAd: FBNativeAd) {
        sendEvent(method: "onAdLoaded", arguments: ["adType": "native"])
    }
    
    public func nativeAd(_ nativeAd: FBNativeAd, didFailWithError error: Error) {
        sendEvent(method: "onAdFailedToLoad", arguments: ["adType": "native", "error": error.localizedDescription])
        facebookNativeAd = nil
    }
    
    public func nativeAdWillLogImpression(_ nativeAd: FBNativeAd) {
        sendEvent(method: "onAdShown", arguments: ["adType": "native"])
    }
    
    public func nativeAdDidClick(_ nativeAd: FBNativeAd) {
        sendEvent(method: "onAdClicked", arguments: ["adType": "native"])
    }
}
