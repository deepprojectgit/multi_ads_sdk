package com.multiads.sdk

import android.app.Activity
import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.view.ViewGroup
import android.widget.FrameLayout
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
    private var admobBannerAd: AdView? = null

    // Facebook instances (single instance per ad type)
    private var facebookInterstitialAd: com.facebook.ads.InterstitialAd? = null
    private var facebookRewardedAd: RewardedVideoAd? = null
    private var facebookBannerAd: com.facebook.ads.AdView? = null
    private var facebookNativeAd: com.facebook.ads.NativeAd? = null


    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "multi_ads_sdk")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
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
            when (providerType) {
                "admob", "adx" -> {
                    MobileAds.initialize(context!!) {}
                    result.success(true)
                }
                "facebook" -> {
                    AudienceNetworkAds.initialize(context!!)
                    result.success(true)
                }
                else -> result.error("INVALID_PROVIDER", "Unknown provider type", null)
            }
        } catch (e: Exception) {
            result.error("INIT_ERROR", e.message, null)
        }
    }

    private fun loadAd(providerType: String?, adType: String?, adUnitId: String, result: Result) {
        try {
            when (providerType) {
                "admob" -> loadAdMobAd(adType, adUnitId, result)
                "adx" -> loadAdXAd(adType, adUnitId, result)
                "facebook" -> loadFacebookAd(adType, adUnitId, result)
                else -> result.error("INVALID_PROVIDER", "Unknown provider type", null)
            }
        } catch (e: Exception) {
            result.error("LOAD_ERROR", e.message, null)
        }
    }

    private fun loadAdMobAd(adType: String?, adUnitId: String, result: Result) {
        when (adType) {
            "interstitial" -> {
                if (admobInterstitialAd != null) {
                    result.success(true)
                    return
                }
                val adRequest = AdRequest.Builder().build()
                InterstitialAd.load(
                    context!!,
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
                    context!!,
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
                    context!!,
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
                    context!!,
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
                admobBannerAd = AdView(context!!)
                admobBannerAd?.adUnitId = adUnitId
                admobBannerAd?.setAdSize(AdSize.BANNER)
                val adRequest = AdRequest.Builder().build()
                admobBannerAd?.loadAd(adRequest)
                admobBannerAd?.adListener = object : AdListener() {
                    override fun onAdLoaded() {
                        sendEvent("onAdLoaded", mapOf("adType" to "banner"))
                        result.success(true)
                    }

                    override fun onAdFailedToLoad(error: LoadAdError) {
                        sendEvent("onAdFailedToLoad", mapOf("adType" to "banner", "error" to error.message))
                        result.error("LOAD_FAILED", error.message, null)
                    }
                }
            }
            "native" -> {
                if (admobNativeAd != null) {
                    result.success(true)
                    return
                }
                val adRequest = AdRequest.Builder().build()
                val builder = AdLoader.Builder(context!!, adUnitId)
                builder.forNativeAd { nativeAd ->
                    admobNativeAd = nativeAd
                    sendEvent("onAdLoaded", mapOf("adType" to "native"))
                    result.success(true)
                }.withAdListener(object : AdListener() {
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
        // AdX uses same SDK as AdMob, just different ad unit IDs
        when (adType) {
            "interstitial" -> {
                if (admobInterstitialAd != null) {
                    result.success(true)
                    return
                }
                val adRequest = AdRequest.Builder().build()
                InterstitialAd.load(
                    context!!,
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
                    context!!,
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
        when (adType) {
            "interstitial" -> {
                if (facebookInterstitialAd != null) {
                    result.success(true)
                    return
                }
                facebookInterstitialAd = com.facebook.ads.InterstitialAd(context!!, adUnitId)
                facebookInterstitialAd?.buildLoadAdConfig()
                    ?.withAdListener(object : InterstitialAdListener {
                        override fun onInterstitialDisplayed(ad: com.facebook.ads.Ad) {
                            sendEvent("onAdShown", mapOf("adType" to "interstitial"))
                        }

                        override fun onInterstitialDismissed(ad: com.facebook.ads.Ad) {
                            sendEvent("onAdDismissed", mapOf("adType" to "interstitial"))
                            facebookInterstitialAd = null
                        }

                        override fun onError(ad: com.facebook.ads.Ad, error: AdError) {
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
                facebookRewardedAd = RewardedVideoAd(context!!, adUnitId)
                facebookRewardedAd?.buildLoadAdConfig()
                    ?.withAdListener(object : RewardedVideoAdListener {
                        override fun onRewardedVideoCompleted() {
                            sendEvent("onRewarded", mapOf("adType" to "rewarded"))
                        }

                        override fun onRewardedVideoClosed() {
                            sendEvent("onAdDismissed", mapOf("adType" to "rewarded"))
                            facebookRewardedAd = null
                        }

                        override fun onError(ad: com.facebook.ads.Ad, error: AdError) {
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
                facebookBannerAd = com.facebook.ads.AdView(context!!, adUnitId, com.facebook.ads.AdSize.BANNER_HEIGHT_50)
                facebookBannerAd?.buildLoadAdConfig()
                    ?.withAdListener(object : AdListener {
                        override fun onError(ad: com.facebook.ads.Ad, error: AdError) {
                            sendEvent("onAdFailedToLoad", mapOf("adType" to "banner", "error" to error.errorMessage))
                            result.error("LOAD_FAILED", error.errorMessage, null)
                        }

                        override fun onAdLoaded(ad: com.facebook.ads.Ad) {
                            sendEvent("onAdLoaded", mapOf("adType" to "banner"))
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
                facebookNativeAd = com.facebook.ads.NativeAd(context!!, adUnitId)
                facebookNativeAd?.buildLoadAdConfig()
                    ?.withAdListener(object : NativeAdListener {
                        override fun onMediaDownloaded(ad: com.facebook.ads.Ad) {}
                        override fun onError(ad: com.facebook.ads.Ad, error: AdError) {
                            sendEvent("onAdFailedToLoad", mapOf("adType" to "native", "error" to error.errorMessage))
                            result.error("LOAD_FAILED", error.errorMessage, null)
                        }
                        override fun onAdLoaded(ad: com.facebook.ads.Ad) {
                            sendEvent("onAdLoaded", mapOf("adType" to "native"))
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
                admobInterstitialAd?.let { ad ->
                    ad.fullScreenContentCallback = object : FullScreenContentCallback() {
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
                    ad.show(activity)
                    result.success(true)
                } ?: result.error("AD_NOT_LOADED", "Interstitial ad not loaded", null)
            }
            "rewarded" -> {
                admobRewardedAd?.let { ad ->
                    ad.fullScreenContentCallback = object : FullScreenContentCallback() {
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
                    ad.show(activity) { rewardItem ->
                        sendEvent("onRewarded", mapOf("adType" to "rewarded"))
                    }
                    result.success(true)
                } ?: result.error("AD_NOT_LOADED", "Rewarded ad not loaded", null)
            }
            "rewardedInterstitial" -> {
                admobRewardedInterstitialAd?.let { ad ->
                    ad.fullScreenContentCallback = object : FullScreenContentCallback() {
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
                    ad.show(activity) { rewardItem ->
                        sendEvent("onRewarded", mapOf("adType" to "rewardedInterstitial"))
                    }
                    result.success(true)
                } ?: result.error("AD_NOT_LOADED", "Rewarded interstitial ad not loaded", null)
            }
            "appOpen" -> {
                admobAppOpenAd?.let { ad ->
                    ad.fullScreenContentCallback = object : FullScreenContentCallback() {
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
                    ad.show(activity)
                    result.success(true)
                } ?: result.error("AD_NOT_LOADED", "App open ad not loaded", null)
            }
            "banner" -> {
                admobBannerAd?.let { banner ->
                    val container = FrameLayout(activity)
                    container.addView(banner)
                    sendEvent("onAdShown", mapOf("adType" to "banner"))
                    result.success(true)
                } ?: result.error("AD_NOT_LOADED", "Banner ad not loaded", null)
            }
            "native" -> {
                admobNativeAd?.let {
                    sendEvent("onAdShown", mapOf("adType" to "native"))
                    result.success(true)
                } ?: result.error("AD_NOT_LOADED", "Native ad not loaded", null)
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
                facebookInterstitialAd?.show() ?: result.error("AD_NOT_LOADED", "Interstitial ad not loaded", null)
            }
            "rewarded" -> {
                facebookRewardedAd?.show() ?: result.error("AD_NOT_LOADED", "Rewarded ad not loaded", null)
            }
            "banner" -> {
                facebookBannerAd?.let { banner ->
                    val container = FrameLayout(activity)
                    container.addView(banner)
                    sendEvent("onAdShown", mapOf("adType" to "banner"))
                    result.success(true)
                } ?: result.error("AD_NOT_LOADED", "Banner ad not loaded", null)
            }
            "native" -> {
                facebookNativeAd?.let {
                    sendEvent("onAdShown", mapOf("adType" to "native"))
                    result.success(true)
                } ?: result.error("AD_NOT_LOADED", "Native ad not loaded", null)
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
