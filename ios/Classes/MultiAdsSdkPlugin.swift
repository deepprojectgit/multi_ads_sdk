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
    private var admobInterstitialAd: InterstitialAd?
    private var admobRewardedAd: RewardedAd?
    private var admobRewardedInterstitialAd: RewardedInterstitialAd?
    private var admobAppOpenAd: AppOpenAd?
    private var admobNativeAd: NativeAd?
    private var admobBannerAd: BannerView?
    
    // Facebook instances (single instance per ad type)
    private var facebookInterstitialAd: FBInterstitialAd?
    private var facebookRewardedAd: FBRewardedVideoAd?
    private var facebookBannerAd: FBAdView?
    private var facebookNativeAd: FBNativeAd?
    
    // Platform view container for banner (used when Flutter embeds the banner widget)
    private var bannerContainer: UIView?
    // Platform view containers for native ad (small and medium layouts)
    private var nativeContainerSmall: UIView?
    private var nativeContainerMedium: UIView?
    private var currentProviderType: String?
    private var bannerLoadResult: FlutterResult?
    private var nativeLoadResult: FlutterResult?
    // Retain AdLoader so it is not deallocated before native ad load completes
    private var admobNativeAdLoader: AdLoader?
    
    /// Called by BannerAdViewFactory when the platform view is created or disposed.
    func setBannerContainer(_ view: UIView?) {
        bannerContainer?.subviews.forEach { $0.removeFromSuperview() }
        bannerContainer = view
        if view != nil {
            attachBannerToContainer()
        }
    }
    
    private func attachBannerToContainer() {
        guard let container = bannerContainer else { return }
        container.subviews.forEach { $0.removeFromSuperview() }
        if let banner = admobBannerAd, (currentProviderType == "admob" || currentProviderType == "adx") {
            banner.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(banner)
            NSLayoutConstraint.activate([
                banner.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                banner.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                banner.topAnchor.constraint(equalTo: container.topAnchor),
                banner.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])
        } else if let banner = facebookBannerAd, currentProviderType == "facebook" {
            banner.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(banner)
            NSLayoutConstraint.activate([
                banner.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                banner.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                banner.topAnchor.constraint(equalTo: container.topAnchor),
                banner.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])
        }
    }
    
    /// Called by NativeAdPlatformView when the platform view is created or disposed.
    func setNativeContainer(_ view: UIView?, size: String) {
        switch size {
        case "small":
            nativeContainerSmall?.subviews.forEach { $0.removeFromSuperview() }
            nativeContainerSmall = view
        default:
            nativeContainerMedium?.subviews.forEach { $0.removeFromSuperview() }
            nativeContainerMedium = view
        }
        if view != nil { attachNativeToContainer() }
    }
    
    private func attachNativeToContainer() {
        if currentProviderType == "admob" || currentProviderType == "adx", let ad = admobNativeAd {
            if let c = nativeContainerSmall { buildAdMobNativeView(container: c, ad: ad, size: "small") }
            if let c = nativeContainerMedium { buildAdMobNativeView(container: c, ad: ad, size: "medium") }
        } else if currentProviderType == "facebook", let ad = facebookNativeAd {
            let container = nativeContainerMedium ?? nativeContainerSmall
            guard let c = container else { return }
            c.subviews.forEach { $0.removeFromSuperview() }
            let root = UIView()
            root.translatesAutoresizingMaskIntoConstraints = false
            root.backgroundColor = .systemBackground
            let mediaView = FBMediaView()
            mediaView.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview(mediaView)
            let titleLabel = UILabel()
            titleLabel.text = ad.advertiserName ?? ""
            titleLabel.font = .boldSystemFont(ofSize: 16)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview(titleLabel)
            let bodyLabel = UILabel()
            bodyLabel.text = ad.bodyText ?? ""
            bodyLabel.font = .systemFont(ofSize: 14)
            bodyLabel.numberOfLines = 2
            bodyLabel.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview(bodyLabel)
            let ctaButton = UIButton(type: .system)
            ctaButton.setTitle(ad.callToAction ?? "Learn More", for: .normal)
            ctaButton.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview(ctaButton)
            NSLayoutConstraint.activate([
                mediaView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
                mediaView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
                mediaView.topAnchor.constraint(equalTo: root.topAnchor),
                mediaView.heightAnchor.constraint(equalToConstant: 150),
                titleLabel.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12),
                titleLabel.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -12),
                titleLabel.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 8),
                bodyLabel.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12),
                bodyLabel.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -12),
                bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
                ctaButton.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12),
                ctaButton.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 8),
                ctaButton.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -12)
            ])
            ad.registerView(forInteraction: root, mediaView: mediaView, iconView: nil, viewController: nil)
            c.addSubview(root)
            NSLayoutConstraint.activate([
                root.leadingAnchor.constraint(equalTo: c.leadingAnchor),
                root.trailingAnchor.constraint(equalTo: c.trailingAnchor),
                root.topAnchor.constraint(equalTo: c.topAnchor),
                root.bottomAnchor.constraint(equalTo: c.bottomAnchor)
            ])
        }
    }
    
    private func buildAdMobNativeView(container: UIView, ad: NativeAd, size: String) {
        container.subviews.forEach { $0.removeFromSuperview() }
        let nativeAdView = NativeAdView()
        nativeAdView.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.backgroundColor = .clear
        var lastAnchor = nativeAdView.topAnchor
        let padding: CGFloat = 12
        let isSmall = (size == "small")
        
        // Media at top (medium: show; small: optional / hidden if no media)
        if !isSmall {
            let mediaView = MediaView()
            mediaView.translatesAutoresizingMaskIntoConstraints = false
            nativeAdView.mediaView = mediaView
            nativeAdView.addSubview(mediaView)
            let hasMedia = ad.mediaContent != nil
            let mediaHeight: CGFloat = hasMedia ? 140 : 0
            mediaView.isHidden = !hasMedia
            NSLayoutConstraint.activate([
                mediaView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: padding),
                mediaView.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -padding),
                mediaView.topAnchor.constraint(equalTo: lastAnchor, constant: padding),
                mediaView.heightAnchor.constraint(equalToConstant: mediaHeight)
            ])
            if hasMedia { lastAnchor = mediaView.bottomAnchor }
        }
        
        // Row: Icon + Ad badge + Headline + Star rating (matches reference)
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.spacing = 8
        rowStack.alignment = .center
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        if let icon = ad.icon, let image = icon.image {
            let iconView = UIImageView(image: image)
            iconView.contentMode = .scaleAspectFit
            iconView.widthAnchor.constraint(equalToConstant: 48).isActive = true
            iconView.heightAnchor.constraint(equalToConstant: 48).isActive = true
            nativeAdView.iconView = iconView
            rowStack.addArrangedSubview(iconView)
        }
        let adBadge = UILabel()
        adBadge.text = "Ad"
        adBadge.font = .boldSystemFont(ofSize: 11)
        adBadge.textColor = UIColor(red: 0.18, green: 0.49, blue: 0.20, alpha: 1)
        adBadge.backgroundColor = UIColor(red: 0.91, green: 0.96, blue: 0.91, alpha: 1)
        adBadge.layer.cornerRadius = 2
        adBadge.clipsToBounds = true
        adBadge.textAlignment = .center
        adBadge.translatesAutoresizingMaskIntoConstraints = false
        adBadge.widthAnchor.constraint(equalToConstant: 24).isActive = true
        rowStack.addArrangedSubview(adBadge)
        let titleStack = UIStackView()
        titleStack.axis = .vertical
        titleStack.spacing = 4
        let headlineLabel = UILabel()
        headlineLabel.text = ad.headline ?? ""
        headlineLabel.font = .boldSystemFont(ofSize: isSmall ? 15 : 16)
        headlineLabel.numberOfLines = 1
        nativeAdView.headlineView = headlineLabel
        titleStack.addArrangedSubview(headlineLabel)
        let starRatingLabel = UILabel()
        starRatingLabel.font = .systemFont(ofSize: 12)
        starRatingLabel.textColor = .systemGray
        if let rating = ad.starRating?.doubleValue, rating > 0 {
            let full = Int(rating)
            let half = (rating - Double(full)) >= 0.5 ? 1 : 0
            let empty = 5 - full - half
            starRatingLabel.text = String(repeating: "★", count: full) + (half > 0 ? "½" : "") + String(repeating: "☆", count: empty)
            nativeAdView.starRatingView = starRatingLabel
        } else {
            starRatingLabel.isHidden = true
        }
        titleStack.addArrangedSubview(starRatingLabel)
        rowStack.addArrangedSubview(titleStack)
        nativeAdView.addSubview(rowStack)
        NSLayoutConstraint.activate([
            rowStack.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: padding),
            rowStack.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -padding),
            rowStack.topAnchor.constraint(equalTo: lastAnchor, constant: padding)
        ])
        lastAnchor = rowStack.bottomAnchor
        
        // Body (medium only) - "Stay up to date with your Ads..."
        if !isSmall {
            let bodyLabel = UILabel()
            bodyLabel.text = ad.body ?? ""
            bodyLabel.font = .systemFont(ofSize: 14)
            bodyLabel.numberOfLines = 2
            nativeAdView.bodyView = bodyLabel
            bodyLabel.translatesAutoresizingMaskIntoConstraints = false
            nativeAdView.addSubview(bodyLabel)
            NSLayoutConstraint.activate([
                bodyLabel.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: padding),
                bodyLabel.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -padding),
                bodyLabel.topAnchor.constraint(equalTo: lastAnchor, constant: 8)
            ])
            lastAnchor = bodyLabel.bottomAnchor
        }
        
        // Full-width INSTALL button at bottom (matches reference for both platforms)
        let ctaButton = UIButton(type: .system)
        ctaButton.setTitle(ad.callToAction ?? "Learn More", for: .normal)
        ctaButton.titleLabel?.font = .systemFont(ofSize: isSmall ? 15 : 16, weight: .medium)
        ctaButton.backgroundColor = UIColor(red: 0.10, green: 0.45, blue: 0.91, alpha: 1)
        ctaButton.setTitleColor(.white, for: .normal)
        ctaButton.layer.cornerRadius = 8
        nativeAdView.callToActionView = ctaButton
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(ctaButton)
        NSLayoutConstraint.activate([
            ctaButton.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: padding),
            ctaButton.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -padding),
            ctaButton.topAnchor.constraint(equalTo: lastAnchor, constant: 12),
            ctaButton.heightAnchor.constraint(equalToConstant: isSmall ? 48 : 52),
            ctaButton.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor, constant: -padding)
        ])
        nativeAdView.nativeAd = ad
        container.addSubview(nativeAdView)
        NSLayoutConstraint.activate([
            nativeAdView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            nativeAdView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            nativeAdView.topAnchor.constraint(equalTo: container.topAnchor),
            nativeAdView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }
    
    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "multi_ads_sdk", binaryMessenger: registrar.messenger())
        let instance = MultiAdsSdkPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.register(
            BannerAdViewFactory(plugin: instance),
            withId: "multi_ads_sdk/banner"
        )
        registrar.register(
            NativeAdViewFactory(plugin: instance, size: "medium"),
            withId: "multi_ads_sdk/native"
        )
        registrar.register(
            NativeAdViewFactory(plugin: instance, size: "small"),
            withId: "multi_ads_sdk/native_small"
        )
        registrar.register(
            NativeAdViewFactory(plugin: instance, size: "medium"),
            withId: "multi_ads_sdk/native_medium"
        )
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
        currentProviderType = providerType
        switch providerType {
        case "admob", "adx":
            MobileAds.shared.start(completionHandler: { _ in
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
        currentProviderType = providerType
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
            let request = Request()
            InterstitialAd.load(with: adUnitId, request: request) { [weak self] ad, error in
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
            let request = Request()
            RewardedAd.load(with: adUnitId, request: request) { [weak self] ad, error in
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
            let request = Request()
            RewardedInterstitialAd.load(with: adUnitId, request: request) { [weak self] ad, error in
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
            let request = Request()
            AppOpenAd.load(with: adUnitId, request: request) { [weak self] ad, error in
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
                attachBannerToContainer()
                result(true)
                return
            }
            bannerLoadResult = result
            admobBannerAd = BannerView(adSize: AdSizeBanner)
            admobBannerAd?.adUnitID = adUnitId
            admobBannerAd?.delegate = self
            admobBannerAd?.load(Request())
            
        case "native":
            if admobNativeAd != nil {
                result(true)
                return
            }
            nativeLoadResult = result
            let request = Request()
            let rootVC = getRootViewController()
            let loader = AdLoader(adUnitID: adUnitId, rootViewController: rootVC, adTypes: [.native], options: nil)
            loader.delegate = self
            admobNativeAdLoader = loader
            loader.load(request)
            
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
            let request = Request()
            InterstitialAd.load(with: adUnitId, request: request) { [weak self] ad, error in
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
            let request = Request()
            RewardedAd.load(with: adUnitId, request: request) { [weak self] ad, error in
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
                attachBannerToContainer()
                result(true)
                return
            }
            bannerLoadResult = result
            let rootVC = getRootViewController()
            facebookBannerAd = FBAdView(placementID: adUnitId, adSize: kFBAdSizeHeight50Banner, rootViewController: rootVC)
            facebookBannerAd?.delegate = self
            facebookBannerAd?.loadAd()
            
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
    
    /// Gets the root view controller for presenting ads. Works on iOS 13+ (scene-based) and fallback to windows.
    private func getRootViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        let window = scene?.windows.first { $0.isKeyWindow } ?? scene?.windows.first
        var root = window?.rootViewController
        while let presented = root?.presentedViewController {
            root = presented
        }
        if root == nil {
            root = UIApplication.shared.windows.first { $0.isKeyWindow }?.rootViewController
                ?? UIApplication.shared.windows.first?.rootViewController
        }
        return root
    }

    private func showAd(providerType: String, adType: String, result: @escaping FlutterResult) {
        guard let rootViewController = getRootViewController() else {
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
            ad.present(from: rootViewController)
            sendEvent(method: "onAdShown", arguments: ["adType": "interstitial"])
            result(true)
            
        case "rewarded":
            guard let ad = admobRewardedAd else {
                result(FlutterError(code: "AD_NOT_LOADED", message: "Rewarded ad not loaded", details: nil))
                return
            }
            ad.fullScreenContentDelegate = self
            ad.present(from: rootViewController) {
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
            ad.present(from: rootViewController) {
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
            ad.present(from: rootViewController)
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
            attachNativeToContainer()
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
            attachNativeToContainer()
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

// MARK: - FullScreenContentDelegate
extension MultiAdsSdkPlugin: FullScreenContentDelegate {
    public func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        // Ad impression recorded
    }
    
    public func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        // Ad failed to present
    }
    
    public func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        // Ad will present
    }
    
    public func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        // Ad will dismiss
    }
    
    public func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        // Clear ad instance after dismissal
        if ad is InterstitialAd {
            admobInterstitialAd = nil
            sendEvent(method: "onAdDismissed", arguments: ["adType": "interstitial"])
        } else if ad is RewardedAd {
            admobRewardedAd = nil
            sendEvent(method: "onAdDismissed", arguments: ["adType": "rewarded"])
        } else if ad is RewardedInterstitialAd {
            admobRewardedInterstitialAd = nil
            sendEvent(method: "onAdDismissed", arguments: ["adType": "rewardedInterstitial"])
        } else if ad is AppOpenAd {
            admobAppOpenAd = nil
            sendEvent(method: "onAdDismissed", arguments: ["adType": "appOpen"])
        }
    }
}

// MARK: - BannerViewDelegate
extension MultiAdsSdkPlugin: BannerViewDelegate {
    public func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        sendEvent(method: "onAdLoaded", arguments: ["adType": "banner"])
        attachBannerToContainer()
        bannerLoadResult?(true)
        bannerLoadResult = nil
    }
    
    public func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        sendEvent(method: "onAdFailedToLoad", arguments: ["adType": "banner", "error": error.localizedDescription])
        bannerLoadResult?(FlutterError(code: "LOAD_FAILED", message: error.localizedDescription, details: nil))
        bannerLoadResult = nil
    }
    
    public func bannerViewDidRecordImpression(_ bannerView: BannerView) {
        sendEvent(method: "onAdShown", arguments: ["adType": "banner"])
    }
    
    public func bannerViewWillPresentScreen(_ bannerView: BannerView) {
        sendEvent(method: "onAdClicked", arguments: ["adType": "banner"])
    }
}

// MARK: - AdLoaderDelegate
extension MultiAdsSdkPlugin: AdLoaderDelegate, NativeAdLoaderDelegate {
    public func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        admobNativeAd = nativeAd
        admobNativeAdLoader = nil
        sendEvent(method: "onAdLoaded", arguments: ["adType": "native"])
        attachNativeToContainer()
        nativeLoadResult?(true)
        nativeLoadResult = nil
    }
    
    public func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        admobNativeAdLoader = nil
        sendEvent(method: "onAdFailedToLoad", arguments: ["adType": "native", "error": error.localizedDescription])
        nativeLoadResult?(FlutterError(code: "LOAD_FAILED", message: error.localizedDescription, details: nil))
        nativeLoadResult = nil
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
        attachBannerToContainer()
        bannerLoadResult?(true)
        bannerLoadResult = nil
    }
    
    public func adView(_ adView: FBAdView, didFailWithError error: Error) {
        sendEvent(method: "onAdFailedToLoad", arguments: ["adType": "banner", "error": error.localizedDescription])
        bannerLoadResult?(FlutterError(code: "LOAD_FAILED", message: error.localizedDescription, details: nil))
        bannerLoadResult = nil
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
        attachNativeToContainer()
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
