import Flutter
import UIKit

/// Platform view that holds a container for the native ad.
/// The plugin adds the loaded GADNativeAdView/FBNativeAdView to this container.
class NativeAdPlatformView: NSObject, FlutterPlatformView {
    private let containerView: UIView
    
    init(frame: CGRect, plugin: MultiAdsSdkPlugin, size: String = "medium") {
        self.containerView = UIView(frame: frame)
        self.containerView.backgroundColor = .clear
        super.init()
        plugin.setNativeContainer(containerView, size: size)
    }
    
    func view() -> UIView {
        return containerView
    }
}
