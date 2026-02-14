import Flutter
import UIKit

/// Factory for creating native ad platform views.
/// - Parameter size: "small" or "medium" for the native ad layout.
class NativeAdViewFactory: NSObject, FlutterPlatformViewFactory {
    private weak var plugin: MultiAdsSdkPlugin?
    private let size: String
    
    init(plugin: MultiAdsSdkPlugin, size: String = "medium") {
        self.plugin = plugin
        self.size = size
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
        return NativeAdPlatformView(frame: frame, plugin: plugin, size: size)
    }
}
