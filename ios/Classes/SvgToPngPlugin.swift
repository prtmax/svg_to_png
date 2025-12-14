import Flutter
import UIKit
import SVGKit

public class SvgToPngPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "svg_to_png", binaryMessenger: registrar.messenger())
        let instance = SvgToPngPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "fromBytes":
            guard let args = call.arguments as? [String: Any],
                  let svgBytes = args["svgBytes"] as? FlutterStandardTypedData,
                  let width = args["width"] as? CGFloat,
                  let height = args["height"] as? CGFloat else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            renderSvg(data: svgBytes.data, width: width, height: height, result: result)

        case "fromUrl":
            guard let args = call.arguments as? [String: Any],
                  let urlStr = args["url"] as? String,
                  let width = args["width"] as? CGFloat,
                  let height = args["height"] as? CGFloat,
                  let url = URL(string: urlStr) else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }

            // 网络请求在后台线程
            URLSession.shared.dataTask(with: url) { data, _, error in
                if let error = error {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "HTTP_ERROR", message: error.localizedDescription, details: nil))
                    }
                    return
                }
                guard let data = data else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "NO_DATA", message: "No data from URL", details: nil))
                    }
                    return
                }

                // 渲染 SVG
                self.renderSvg(data: data, width: width, height: height, result: result)
            }.resume()

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func renderSvg(data: Data, width: CGFloat, height: CGFloat, result: @escaping FlutterResult) {
        // 渲染放在后台线程，避免主线程阻塞
        DispatchQueue.global(qos: .userInitiated).async {
            guard let svgImage = SVGKImage(data: data) else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "SVG_ERROR", message: "Cannot parse SVG", details: nil))
                }
                return
            }

            svgImage.size = CGSize(width: width, height: height)

            let renderer = UIGraphicsImageRenderer(size: svgImage.size)
            let pngImage = renderer.image { ctx in
                svgImage.uiImage.draw(in: CGRect(origin: .zero, size: svgImage.size))
            }

            guard let pngData = pngImage.pngData() else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "PNG_ERROR", message: "Failed to convert PNG", details: nil))
                }
                return
            }

            // 回主线程通知 Flutter
            DispatchQueue.main.async {
                result(pngData)
            }
        }
    }
}
