import Flutter
import UIKit

/// Platform view that holds a container for the banner ad.
/// The plugin adds the loaded GADBannerView/FBAdView to this container.
class BannerAdPlatformView: NSObject, FlutterPlatformView {
    private let containerView: UIView
    
    init(frame: CGRect, plugin: MultiAdsSdkPlugin) {
        self.containerView = UIView(frame: frame)
        self.containerView.backgroundColor = .clear
        super.init()
        plugin.setBannerContainer(containerView)
    }
    
    func view() -> UIView {
        return containerView
    }
}
