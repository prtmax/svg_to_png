package com.aiyin.svg_to_png

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import androidx.annotation.NonNull
import com.caverock.androidsvg.SVG
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import kotlinx.coroutines.*
import java.io.ByteArrayOutputStream
import java.net.URL
import kotlin.math.roundToInt

/** SvgToPngPlugin */
class SvgToPngPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private val pluginScope = CoroutineScope(Dispatchers.IO)
    private lateinit var context: Context

    // 定义一个 Float 类型的默认尺寸
    private val defaultSize = 512f

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "svg_to_png")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "fromBytes" -> {
                val svgBytes = call.argument<ByteArray>("svgBytes")
                val width = (call.argument<Number>("width")?.toFloat() ?: defaultSize).roundToInt()
                val height = (call.argument<Number>("height")?.toFloat() ?: defaultSize).roundToInt()

                if (svgBytes == null) {
                    result.error("INVALID_ARGS", "svgBytes is null", null)
                    return
                }

                pluginScope.launch {
                    try {
                        val png = renderSvg(svgBytes, width, height)
                        withContext(Dispatchers.Main) {
                            result.success(png)
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("RENDER_ERROR", e.message, null)
                        }
                    }
                }
            }

            "fromUrl" -> {
                val urlStr = call.argument<String>("svgUrl") ?: ""
                val width = (call.argument<Number>("width")?.toFloat() ?: defaultSize).roundToInt()
                val height = (call.argument<Number>("height")?.toFloat() ?: defaultSize).roundToInt()

                pluginScope.launch {
                    try {
                        val bytes = URL(urlStr).readBytes()
                        val png = renderSvg(bytes, width, height)
                        withContext(Dispatchers.Main) {
                            result.success(png)
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("HTTP_ERROR", e.message, null)
                        }
                    }
                }
            }

            else -> result.notImplemented()
        }
    }

    // SvgToPngPlugin.kt

// ... (onMethodCall 和其他方法不变) ...

    private fun renderSvg(svgBytes: ByteArray, width: Int, height: Int): ByteArray {
        val svg = SVG.getFromInputStream(svgBytes.inputStream())

        // 1. 确定 SVG 内容的原始大小（用户空间单位）
        // 优先使用 viewBox 或 documentSize，这是 SVG 内部的“逻辑”尺寸。
        val viewBox = svg.documentViewBox

        // 如果 viewBox 存在，使用 viewBox 的宽高；否则使用 documentWidth/Height
        val sourceWidth = viewBox?.width() ?: svg.documentWidth
        val sourceHeight = viewBox?.height() ?: svg.documentHeight

        // 如果 SVG 没有任何尺寸信息（sourceWidth/Height <= 0），则使用传入的物理宽度作为源尺寸。
        // 这种情况很少见，但为了防止除以零，需要处理。
        val effectiveSourceWidth = if (sourceWidth > 0) sourceWidth else width.toFloat()
        val effectiveSourceHeight = if (sourceHeight > 0) sourceHeight else height.toFloat()

        // 2. 计算缩放因子：我们需要将 SVG 从其内部尺寸 (source) 缩放到目标物理尺寸 (width/height)
        val scaleX = width.toFloat() / effectiveSourceWidth
        val scaleY = height.toFloat() / effectiveSourceHeight

        // 3. 创建高分辨率的 Bitmap
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        // 4. 关键步骤：应用缩放矩阵
        // 我们不需要 Picture，直接使用 renderToCanvas 并在 Canvas 上应用缩放。

        canvas.save()
        // 关键：对 Canvas 应用缩放，强制 SVG 内容拉伸或压缩到整个 Bitmap 空间
        canvas.scale(scaleX, scaleY)

        // 5. 渲染 SVG 到已缩放的 Canvas
        svg.renderToCanvas(canvas)

        canvas.restore()

        // 6. 压缩和返回
        val output = ByteArrayOutputStream()
        // 使用 PNG 格式，质量 100
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)
        return output.toByteArray()
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        pluginScope.cancel() // 清理协程
    }
}
