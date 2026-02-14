import Flutter
import UIKit

/// Factory for creating banner ad platform views.
class BannerAdViewFactory: NSObject, FlutterPlatformViewFactory {
    private weak var plugin: MultiAdsSdkPlugin?
    
    init(plugin: MultiAdsSdkPlugin) {
        self.plugin = plugin
        super.init()
    }
    
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        guard let plugin = plugin else {
            fatalError("BannerAdViewFactory requires a plugin instance")
        }
        return BannerAdPlatformView(frame: frame, plugin: plugin)
    }
}
