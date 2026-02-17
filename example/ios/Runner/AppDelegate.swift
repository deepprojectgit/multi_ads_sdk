import Flutter
import UIKit
import GoogleMobileAds

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Google Mobile Ads SDK before any ad-related code runs (required to prevent crash)
    MobileAds.shared.start(completionHandler: { _ in })
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
