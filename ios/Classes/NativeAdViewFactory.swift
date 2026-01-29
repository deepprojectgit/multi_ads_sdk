import Flutter
import UIKit

/// Factory for creating native ad platform views.
class NativeAdViewFactory: NSObject, FlutterPlatformViewFactory {
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
            fatalError("NativeAdViewFactory requires a plugin instance")
        }
        return NativeAdPlatformView(frame: frame, plugin: plugin)
    }
    
    func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
