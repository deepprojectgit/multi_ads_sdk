package com.multiads.sdk

import android.content.Context
import android.view.View
import android.widget.FrameLayout
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * Platform view factory for embedding banner ads in Flutter.
 * Creates a container that the plugin fills with the loaded banner AdView.
 */
class BannerAdViewFactory(
    private val plugin: MultiAdsSdkPlugin
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val container = FrameLayout(context).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT
            )
        }
        plugin.setBannerContainer(container)
        return object : PlatformView {
            override fun getView(): View = container
            override fun dispose() {
                plugin.setBannerContainer(null)
            }
        }
    }
}
