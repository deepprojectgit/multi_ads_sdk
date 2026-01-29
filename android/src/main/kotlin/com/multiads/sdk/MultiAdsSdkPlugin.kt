package com.multiads.sdk

import android.app.Activity
import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.view.LayoutInflater
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.annotation.NonNull
import com.facebook.ads.*
import com.google.android.gms.ads.*
import com.google.android.gms.ads.interstitial.InterstitialAd
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback
import com.google.android.gms.ads.rewarded.RewardedAd
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback
import com.google.android.gms.ads.rewardedinterstitial.RewardedInterstitialAd
import com.google.android.gms.ads.rewardedinterstitial.RewardedInterstitialAdLoadCallback
import com.google.android.gms.ads.appopen.AppOpenAd
import com.google.android.gms.ads.appopen.AppOpenAd.AppOpenAdLoadCallback
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import com.multiads.sdk.R
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * MultiAdsSdkPlugin - Main plugin class for Android
 * 
 * Handles communication between Flutter and native Android code.
 * Supports AdMob, AdX, and Facebook Audience Network.
 * Implements single-load and single-show pattern.
 */
class MultiAdsSdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var context: Context? = null

    // AdMob/AdX instances (single instance per ad type)
    private var admobInterstitialAd: InterstitialAd? = null
    private var admobRewardedAd: RewardedAd? = null
    private var admobRewardedInterstitialAd: RewardedInterstitialAd? = null
    private var admobAppOpenAd: AppOpenAd? = null
    private var admobNativeAd: NativeAd? = null
    private var admobBannerAd: com.google.android.gms.ads.AdView? = null

    // Facebook instances (single instance per ad type)
    private var facebookInterstitialAd: com.facebook.ads.InterstitialAd? = null
    private var facebookRewardedAd: RewardedVideoAd? = null
    private var facebookBannerAd: com.facebook.ads.AdView? = null
    private var facebookNativeAd: com.facebook.ads.NativeAd? = null

    // Platform view container for banner (used when Flutter embeds the banner widget)
    private var bannerContainer: FrameLayout? = null
    // Platform view container for native ad (used when Flutter embeds the native ad widget)
    private var nativeContainer: FrameLayout? = null
    private var currentProviderType: String? = null

    /** Called by BannerAdViewFactory when the platform view is created or disposed. */
    fun setBannerContainer(container: FrameLayout?) {
        if (bannerContainer != null && bannerContainer != container) {
            // Remove current ad view from old container when switching
            bannerContainer?.removeAllViews()
        }
        bannerContainer = container
        if (container != null) {
            // If banner is already loaded, attach it to the new container
            attachBannerToContainer()
        }
    }

    private fun attachBannerToContainer() {
        val container = bannerContainer ?: return
        container.removeAllViews()
        when (currentProviderType) {
            "admob", "adx" -> admobBannerAd?.let { container.addView(it) }
            "facebook" -> facebookBannerAd?.let { container.addView(it) }
            else -> { }
        }
    }

    /** Called by NativeAdViewFactory when the platform view is created or disposed. */
    fun setNativeContainer(container: FrameLayout?) {
        if (nativeContainer != null && nativeContainer != container) {
            nativeContainer?.removeAllViews()
        }
        nativeContainer = container
        if (container != null) {
            attachNativeToContainer()
        }
    }

    private fun attachNativeToContainer() {
        val container = nativeContainer ?: return
        val ctx = context ?: return
        container.removeAllViews()
        when (currentProviderType) {
            "admob", "adx" -> {
                val ad = admobNativeAd ?: return
                val inflater = LayoutInflater.from(ctx)
                val adView = inflater.inflate(R.layout.native_ad_layout, container, false) as NativeAdView
                (adView.findViewById<TextView>(R.id.native_ad_headline)).text = ad.headline ?: ""
                adView.headlineView = adView.findViewById(R.id.native_ad_headline)
                adView.bodyView = adView.findViewById(R.id.native_ad_body)
                (adView.bodyView as? TextView)?.text = ad.body ?: ""
                adView.callToActionView = adView.findViewById(R.id.native_ad_call_to_action)
                (adView.callToActionView as? Button)?.text = ad.callToAction ?: ""
                adView.iconView = adView.findViewById(R.id.native_ad_icon)
                ad.icon?.drawable?.let { (adView.iconView as? ImageView)?.setImageDrawable(it) }
                adView.setNativeAd(ad)
                container.addView(adView)
            }
            "facebook" -> {
                val ad = facebookNativeAd ?: return
                val root = LinearLayout(ctx).apply {
                    orientation = LinearLayout.VERTICAL
                    setPadding(dpToPx(12), dpToPx(12), dpToPx(12), dpToPx(12))
                }
                val mediaView = com.facebook.ads.MediaView(ctx)
                root.addView(mediaView, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dpToPx(150)))
                val titleView = TextView(ctx).apply { text = ad.advertiserName; textSize = 16f; setPadding(0, dpToPx(8), 0, 0) }
                root.addView(titleView)
                val bodyView = TextView(ctx).apply { text = ad.adBodyText; textSize = 14f; setPadding(0, dpToPx(4), 0, 0) }
                root.addView(bodyView)
                val ctaButton = Button(ctx).apply { text = ad.adCallToAction; setPadding(dpToPx(16), dpToPx(8), dpToPx(16), dpToPx(8)) }
                root.addView(ctaButton, LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { topMargin = dpToPx(8) })
                ad.registerViewForInteraction(root, mediaView)
                container.addView(root)
            }
            else -> { }
        }
    }

    private fun dpToPx(dp: Int): Int {
        val density = context?.resources?.displayMetrics?.density ?: 1f
        return (dp * density).toInt()
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "multi_ads_sdk")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            "multi_ads_sdk/banner",
            BannerAdViewFactory(this)
        )
        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            "multi_ads_sdk/native",
            NativeAdViewFactory(this)
        )
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "initProvider" -> {
                val providerType = call.argument<String>("providerType")
                initProvider(providerType, result)
            }
            "loadAd" -> {
                val providerType = call.argument<String>("providerType")
                val adType = call.argument<String>("adType")
                val adUnitId = call.argument<String>("adUnitId")
                if (adUnitId == null) {
                    result.error("INVALID_ARGUMENT", "adUnitId is required", null)
                    return
                }
                loadAd(providerType, adType, adUnitId, result)
            }
            "showAd" -> {
                val providerType = call.argument<String>("providerType")
                val adType = call.argument<String>("adType")
                showAd(providerType, adType, result)
            }
            "checkInternetConnectivity" -> {
                checkInternetConnectivity(result)
            }
            else -> result.notImplemented()
        }
    }

    private fun initProvider(providerType: String?, result: Result) {
        try {
            val ctx = context
            if (ctx == null) {
                result.error("INIT_ERROR", "Context is null", null)
                return
            }
            currentProviderType = providerType
            when (providerType) {
                "admob", "adx" -> {
                    MobileAds.initialize(ctx) { initializationStatus ->
                        result.success(true)
                    }
                }
                "facebook" -> {
                    AudienceNetworkAds.initialize(ctx)
                    result.success(true)
                }
                else -> result.error("INVALID_PROVIDER", "Unknown provider type: $providerType", null)
            }
        } catch (e: Exception) {
            result.error("INIT_ERROR", "Initialization failed: ${e.message}", null)
        }
    }

    private fun loadAd(providerType: String?, adType: String?, adUnitId: String, result: Result) {
        try {
            if (context == null) {
                result.error("LOAD_ERROR", "Context is null", null)
                return
            }
            when (providerType) {
                "admob" -> loadAdMobAd(adType, adUnitId, result)
                "adx" -> loadAdXAd(adType, adUnitId, result)
                "facebook" -> loadFacebookAd(adType, adUnitId, result)
                else -> result.error("INVALID_PROVIDER", "Unknown provider type", null)
            }
        } catch (e: Exception) {
            result.error("LOAD_ERROR", "Failed to load ad: ${e.message}", null)
        }
    }

    private fun loadAdMobAd(adType: String?, adUnitId: String, result: Result) {
        val ctx = context
        if (ctx == null) {
            result.error("LOAD_ERROR", "Context is null", null)
            return
        }
        when (adType) {
            "interstitial" -> {
                if (admobInterstitialAd != null) {
                    result.success(true)
                    return
                }
                val adRequest = AdRequest.Builder().build()
                InterstitialAd.load(
                    ctx,
                    adUnitId,
                    adRequest,
                    object : InterstitialAdLoadCallback() {
                        override fun onAdLoaded(ad: InterstitialAd) {
                            admobInterstitialAd = ad
                            sendEvent("onAdLoaded", mapOf("adType" to "interstitial"))
                            result.success(true)
                        }

                        override fun onAdFailedToLoad(error: LoadAdError) {
                            sendEvent("onAdFailedToLoad", mapOf("adType" to "interstitial", "error" to error.message))
                            result.error("LOAD_FAILED", error.message, null)
                        }
                    }
                )
            }
            "rewarded" -> {
                if (admobRewardedAd != null) {
                    result.success(true)
                    return
                }
                val adRequest = AdRequest.Builder().build()
                RewardedAd.load(
                    ctx,
                    adUnitId,
                    adRequest,
                    object : RewardedAdLoadCallback() {
                        override fun onAdLoaded(ad: RewardedAd) {
                            admobRewardedAd = ad
                            sendEvent("onAdLoaded", mapOf("adType" to "rewarded"))
                            result.success(true)
                        }

                        override fun onAdFailedToLoad(error: LoadAdError) {
                            sendEvent("onAdFailedToLoad", mapOf("adType" to "rewarded", "error" to error.message))
                            result.error("LOAD_FAILED", error.message, null)
                        }
                    }
                )
            }
            "rewardedInterstitial" -> {
                if (admobRewardedInterstitialAd != null) {
                    result.success(true)
                    return
                }
                val adRequest = AdRequest.Builder().build()
                RewardedInterstitialAd.load(
                    ctx,
                    adUnitId,
                    adRequest,
                    object : RewardedInterstitialAdLoadCallback() {
                        override fun onAdLoaded(ad: RewardedInterstitialAd) {
                            admobRewardedInterstitialAd = ad
                            sendEvent("onAdLoaded", mapOf("adType" to "rewardedInterstitial"))
                            result.success(true)
                        }

                        override fun onAdFailedToLoad(error: LoadAdError) {
                            sendEvent("onAdFailedToLoad", mapOf("adType" to "rewardedInterstitial", "error" to error.message))
                            result.error("LOAD_FAILED", error.message, null)
                        }
                    }
                )
            }
            "appOpen" -> {
                if (admobAppOpenAd != null) {
                    result.success(true)
                    return
                }
                val adRequest = AdRequest.Builder().build()
                AppOpenAd.load(
                    ctx,
                    adUnitId,
                    adRequest,
                    AppOpenAd.APP_OPEN_AD_ORIENTATION_PORTRAIT,
                    object : AppOpenAdLoadCallback() {
                        override fun onAdLoaded(ad: AppOpenAd) {
                            admobAppOpenAd = ad
                            sendEvent("onAdLoaded", mapOf("adType" to "appOpen"))
                            result.success(true)
                        }

                        override fun onAdFailedToLoad(error: LoadAdError) {
                            sendEvent("onAdFailedToLoad", mapOf("adType" to "appOpen", "error" to error.message))
                            result.error("LOAD_FAILED", error.message, null)
                        }
                    }
                )
            }
            "banner" -> {
                if (admobBannerAd != null) {
                    result.success(true)
                    return
                }
                admobBannerAd = com.google.android.gms.ads.AdView(ctx)
                admobBannerAd?.adUnitId = adUnitId
                admobBannerAd?.setAdSize(com.google.android.gms.ads.AdSize.BANNER)
                admobBannerAd?.adListener = object : com.google.android.gms.ads.AdListener() {
                    override fun onAdLoaded() {
                        sendEvent("onAdLoaded", mapOf("adType" to "banner"))
                        attachBannerToContainer()
                        result.success(true)
                    }

                    override fun onAdFailedToLoad(error: LoadAdError) {
                        sendEvent("onAdFailedToLoad", mapOf("adType" to "banner", "error" to error.message))
                        result.error("LOAD_FAILED", error.message, null)
                    }
                }
                val adRequest = AdRequest.Builder().build()
                admobBannerAd?.loadAd(adRequest)
            }
            "native" -> {
                if (admobNativeAd != null) {
                    result.success(true)
                    return
                }
                val adRequest = AdRequest.Builder().build()
                val builder = AdLoader.Builder(ctx, adUnitId)
                builder.forNativeAd { nativeAd ->
                    admobNativeAd = nativeAd
                    sendEvent("onAdLoaded", mapOf("adType" to "native"))
                    attachNativeToContainer()
                    result.success(true)
                }.withAdListener(object : com.google.android.gms.ads.AdListener() {
                    override fun onAdFailedToLoad(error: LoadAdError) {
                        sendEvent("onAdFailedToLoad", mapOf("adType" to "native", "error" to error.message))
                        result.error("LOAD_FAILED", error.message, null)
                    }
                }).build().loadAd(adRequest)
            }
            else -> result.error("INVALID_AD_TYPE", "Unknown ad type", null)
        }
    }

    private fun loadAdXAd(adType: String?, adUnitId: String, result: Result) {
        val ctx = context
        if (ctx == null) {
            result.error("LOAD_ERROR", "Context is null", null)
            return
        }
        // AdX uses same SDK as AdMob, just different ad unit IDs
        when (adType) {
            "interstitial" -> {
                if (admobInterstitialAd != null) {
                    result.success(true)
                    return
                }
                val adRequest = AdRequest.Builder().build()
                InterstitialAd.load(
                    ctx,
                    adUnitId,
                    adRequest,
                    object : InterstitialAdLoadCallback() {
                        override fun onAdLoaded(ad: InterstitialAd) {
                            admobInterstitialAd = ad
                            sendEvent("onAdLoaded", mapOf("adType" to "interstitial"))
                            result.success(true)
                        }

                        override fun onAdFailedToLoad(error: LoadAdError) {
                            sendEvent("onAdFailedToLoad", mapOf("adType" to "interstitial", "error" to error.message))
                            result.error("LOAD_FAILED", error.message, null)
                        }
                    }
                )
            }
            "rewarded" -> {
                if (admobRewardedAd != null) {
                    result.success(true)
                    return
                }
                val adRequest = AdRequest.Builder().build()
                RewardedAd.load(
                    ctx,
                    adUnitId,
                    adRequest,
                    object : RewardedAdLoadCallback() {
                        override fun onAdLoaded(ad: RewardedAd) {
                            admobRewardedAd = ad
                            sendEvent("onAdLoaded", mapOf("adType" to "rewarded"))
                            result.success(true)
                        }

                        override fun onAdFailedToLoad(error: LoadAdError) {
                            sendEvent("onAdFailedToLoad", mapOf("adType" to "rewarded", "error" to error.message))
                            result.error("LOAD_FAILED", error.message, null)
                        }
                    }
                )
            }
            else -> result.error("INVALID_AD_TYPE", "AdX only supports interstitial and rewarded", null)
        }
    }

    private fun loadFacebookAd(adType: String?, adUnitId: String, result: Result) {
        val ctx = context
        if (ctx == null) {
            result.error("LOAD_ERROR", "Context is null", null)
            return
        }
        when (adType) {
            "interstitial" -> {
                if (facebookInterstitialAd != null) {
                    result.success(true)
                    return
                }
                facebookInterstitialAd = com.facebook.ads.InterstitialAd(ctx, adUnitId)
                facebookInterstitialAd?.buildLoadAdConfig()
                    ?.withAdListener(object : InterstitialAdListener {
                        override fun onInterstitialDisplayed(ad: com.facebook.ads.Ad) {
                            sendEvent("onAdShown", mapOf("adType" to "interstitial"))
                        }

                        override fun onInterstitialDismissed(ad: com.facebook.ads.Ad) {
                            sendEvent("onAdDismissed", mapOf("adType" to "interstitial"))
                            facebookInterstitialAd = null
                        }

                        override fun onError(ad: com.facebook.ads.Ad, error: com.facebook.ads.AdError) {
                            sendEvent("onAdFailedToLoad", mapOf("adType" to "interstitial", "error" to error.errorMessage))
                            result.error("LOAD_FAILED", error.errorMessage, null)
                        }

                        override fun onAdLoaded(ad: com.facebook.ads.Ad) {
                            sendEvent("onAdLoaded", mapOf("adType" to "interstitial"))
                            result.success(true)
                        }

                        override fun onAdClicked(ad: com.facebook.ads.Ad) {
                            sendEvent("onAdClicked", mapOf("adType" to "interstitial"))
                        }

                        override fun onLoggingImpression(ad: com.facebook.ads.Ad) {}
                    })
                    ?.build()
                facebookInterstitialAd?.loadAd()
            }
            "rewarded" -> {
                if (facebookRewardedAd != null) {
                    result.success(true)
                    return
                }
                facebookRewardedAd = RewardedVideoAd(ctx, adUnitId)
                facebookRewardedAd?.buildLoadAdConfig()
                    ?.withAdListener(object : RewardedVideoAdListener {
                        override fun onRewardedVideoCompleted() {
                            sendEvent("onRewarded", mapOf("adType" to "rewarded"))
                        }

                        override fun onRewardedVideoClosed() {
                            sendEvent("onAdDismissed", mapOf("adType" to "rewarded"))
                            facebookRewardedAd = null
                        }

                        override fun onError(ad: com.facebook.ads.Ad, error: com.facebook.ads.AdError) {
                            sendEvent("onAdFailedToLoad", mapOf("adType" to "rewarded", "error" to error.errorMessage))
                            result.error("LOAD_FAILED", error.errorMessage, null)
                        }

                        override fun onAdLoaded(ad: com.facebook.ads.Ad) {
                            sendEvent("onAdLoaded", mapOf("adType" to "rewarded"))
                            result.success(true)
                        }

                        override fun onAdClicked(ad: com.facebook.ads.Ad) {
                            sendEvent("onAdClicked", mapOf("adType" to "rewarded"))
                        }

                        override fun onLoggingImpression(ad: com.facebook.ads.Ad) {}
                    })
                    ?.build()
                facebookRewardedAd?.loadAd()
            }
            "banner" -> {
                if (facebookBannerAd != null) {
                    result.success(true)
                    return
                }
                facebookBannerAd = com.facebook.ads.AdView(ctx, adUnitId, com.facebook.ads.AdSize.BANNER_HEIGHT_50)
                facebookBannerAd?.buildLoadAdConfig()
                    ?.withAdListener(object : com.facebook.ads.AdListener {
                        override fun onError(ad: com.facebook.ads.Ad, error: com.facebook.ads.AdError) {
                            sendEvent("onAdFailedToLoad", mapOf("adType" to "banner", "error" to error.errorMessage))
                            result.error("LOAD_FAILED", error.errorMessage, null)
                        }

                        override fun onAdLoaded(ad: com.facebook.ads.Ad) {
                            sendEvent("onAdLoaded", mapOf("adType" to "banner"))
                            attachBannerToContainer()
                            result.success(true)
                        }

                        override fun onAdClicked(ad: com.facebook.ads.Ad) {
                            sendEvent("onAdClicked", mapOf("adType" to "banner"))
                        }

                        override fun onLoggingImpression(ad: com.facebook.ads.Ad) {}
                    })
                    ?.build()
                facebookBannerAd?.loadAd()
            }
            "native" -> {
                if (facebookNativeAd != null) {
                    result.success(true)
                    return
                }
                facebookNativeAd = com.facebook.ads.NativeAd(ctx, adUnitId)
                facebookNativeAd?.buildLoadAdConfig()
                    ?.withAdListener(object : com.facebook.ads.NativeAdListener {
                        override fun onMediaDownloaded(ad: com.facebook.ads.Ad) {}
                        override fun onError(ad: com.facebook.ads.Ad, error: com.facebook.ads.AdError) {
                            sendEvent("onAdFailedToLoad", mapOf("adType" to "native", "error" to error.errorMessage))
                            result.error("LOAD_FAILED", error.errorMessage, null)
                        }
                        override fun onAdLoaded(ad: com.facebook.ads.Ad) {
                            sendEvent("onAdLoaded", mapOf("adType" to "native"))
                            attachNativeToContainer()
                            result.success(true)
                        }
                        override fun onAdClicked(ad: com.facebook.ads.Ad) {
                            sendEvent("onAdClicked", mapOf("adType" to "native"))
                        }
                        override fun onLoggingImpression(ad: com.facebook.ads.Ad) {}
                    })
                    ?.build()
                facebookNativeAd?.loadAd()
            }
            else -> result.error("INVALID_AD_TYPE", "Unknown ad type", null)
        }
    }

    private fun showAd(providerType: String?, adType: String?, result: Result) {
        try {
            when (providerType) {
                "admob" -> showAdMobAd(adType, result)
                "adx" -> showAdXAd(adType, result)
                "facebook" -> showFacebookAd(adType, result)
                else -> result.error("INVALID_PROVIDER", "Unknown provider type", null)
            }
        } catch (e: Exception) {
            result.error("SHOW_ERROR", e.message, null)
        }
    }

    private fun showAdMobAd(adType: String?, result: Result) {
        val activity = this.activity ?: run {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        when (adType) {
            "interstitial" -> {
                if (admobInterstitialAd != null) {
                    admobInterstitialAd?.fullScreenContentCallback = object : FullScreenContentCallback() {
                        override fun onAdDismissedFullScreenContent() {
                            sendEvent("onAdDismissed", mapOf("adType" to "interstitial"))
                            admobInterstitialAd = null
                        }

                        override fun onAdShowedFullScreenContent() {
                            sendEvent("onAdShown", mapOf("adType" to "interstitial"))
                        }

                        override fun onAdClicked() {
                            sendEvent("onAdClicked", mapOf("adType" to "interstitial"))
                        }
                    }
                    admobInterstitialAd?.show(activity)
                    result.success(true)
                } else {
                    result.error("AD_NOT_LOADED", "Interstitial ad not loaded", null)
                }
            }
            "rewarded" -> {
                if (admobRewardedAd != null) {
                    admobRewardedAd?.fullScreenContentCallback = object : FullScreenContentCallback() {
                        override fun onAdDismissedFullScreenContent() {
                            sendEvent("onAdDismissed", mapOf("adType" to "rewarded"))
                            admobRewardedAd = null
                        }

                        override fun onAdShowedFullScreenContent() {
                            sendEvent("onAdShown", mapOf("adType" to "rewarded"))
                        }

                        override fun onAdClicked() {
                            sendEvent("onAdClicked", mapOf("adType" to "rewarded"))
                        }
                    }
                    admobRewardedAd?.show(activity) { rewardItem ->
                        sendEvent("onRewarded", mapOf("adType" to "rewarded"))
                    }
                    result.success(true)
                } else {
                    result.error("AD_NOT_LOADED", "Rewarded ad not loaded", null)
                }
            }
            "rewardedInterstitial" -> {
                if (admobRewardedInterstitialAd != null) {
                    admobRewardedInterstitialAd?.fullScreenContentCallback = object : FullScreenContentCallback() {
                        override fun onAdDismissedFullScreenContent() {
                            sendEvent("onAdDismissed", mapOf("adType" to "rewardedInterstitial"))
                            admobRewardedInterstitialAd = null
                        }

                        override fun onAdShowedFullScreenContent() {
                            sendEvent("onAdShown", mapOf("adType" to "rewardedInterstitial"))
                        }

                        override fun onAdClicked() {
                            sendEvent("onAdClicked", mapOf("adType" to "rewardedInterstitial"))
                        }
                    }
                    admobRewardedInterstitialAd?.show(activity) { rewardItem ->
                        sendEvent("onRewarded", mapOf("adType" to "rewardedInterstitial"))
                    }
                    result.success(true)
                } else {
                    result.error("AD_NOT_LOADED", "Rewarded interstitial ad not loaded", null)
                }
            }
            "appOpen" -> {
                if (admobAppOpenAd != null) {
                    admobAppOpenAd?.fullScreenContentCallback = object : FullScreenContentCallback() {
                        override fun onAdDismissedFullScreenContent() {
                            sendEvent("onAdDismissed", mapOf("adType" to "appOpen"))
                            admobAppOpenAd = null
                        }

                        override fun onAdShowedFullScreenContent() {
                            sendEvent("onAdShown", mapOf("adType" to "appOpen"))
                        }

                        override fun onAdClicked() {
                            sendEvent("onAdClicked", mapOf("adType" to "appOpen"))
                        }
                    }
                    admobAppOpenAd?.show(activity)
                    result.success(true)
                } else {
                    result.error("AD_NOT_LOADED", "App open ad not loaded", null)
                }
            }
            "banner" -> {
                if (admobBannerAd != null) {
                    attachBannerToContainer()
                    sendEvent("onAdShown", mapOf("adType" to "banner"))
                    result.success(true)
                } else {
                    result.error("AD_NOT_LOADED", "Banner ad not loaded", null)
                }
            }
            "native" -> {
                if (admobNativeAd != null) {
                    attachNativeToContainer()
                    sendEvent("onAdShown", mapOf("adType" to "native"))
                    result.success(true)
                } else {
                    result.error("AD_NOT_LOADED", "Native ad not loaded", null)
                }
            }
            else -> result.error("INVALID_AD_TYPE", "Unknown ad type", null)
        }
    }

    private fun showAdXAd(adType: String?, result: Result) {
        // AdX uses same implementation as AdMob
        showAdMobAd(adType, result)
    }

    private fun showFacebookAd(adType: String?, result: Result) {
        val activity = this.activity ?: run {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        when (adType) {
            "interstitial" -> {
                if (facebookInterstitialAd != null) {
                    facebookInterstitialAd?.show()
                    result.success(true)
                } else {
                    result.error("AD_NOT_LOADED", "Interstitial ad not loaded", null)
                }
            }
            "rewarded" -> {
                if (facebookRewardedAd != null) {
                    facebookRewardedAd?.show()
                    result.success(true)
                } else {
                    result.error("AD_NOT_LOADED", "Rewarded ad not loaded", null)
                }
            }
            "banner" -> {
                if (facebookBannerAd != null) {
                    attachBannerToContainer()
                    sendEvent("onAdShown", mapOf("adType" to "banner"))
                    result.success(true)
                } else {
                    result.error("AD_NOT_LOADED", "Banner ad not loaded", null)
                }
            }
            "native" -> {
                if (facebookNativeAd != null) {
                    attachNativeToContainer()
                    sendEvent("onAdShown", mapOf("adType" to "native"))
                    result.success(true)
                } else {
                    result.error("AD_NOT_LOADED", "Native ad not loaded", null)
                }
            }
            else -> result.error("INVALID_AD_TYPE", "Unknown ad type", null)
        }
    }

    private fun checkInternetConnectivity(result: Result) {
        try {
            val connectivityManager = context?.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
            if (connectivityManager == null) {
                result.success(false)
                return
            }
            
            val network = connectivityManager.activeNetwork ?: run {
                result.success(false)
                return
            }
            
            val networkCapabilities = connectivityManager.getNetworkCapabilities(network) ?: run {
                result.success(false)
                return
            }
            
            val hasInternet = networkCapabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                    networkCapabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
            
            result.success(hasInternet)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun sendEvent(method: String, arguments: Map<String, Any>) {
        try {
            channel.invokeMethod(method, arguments)
        } catch (e: Exception) {
            // Ignore if channel is not available
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
