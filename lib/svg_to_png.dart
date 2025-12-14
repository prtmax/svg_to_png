import 'dart:typed_data';

import 'svg_to_png_platform_interface.dart';

class SvgToPng {
  static Future<Uint8List?> fromBytes(Uint8List svgBytes, {double? width, double? height}) async {
    final imageBytes = await SvgToPngPlatform.instance.fromBytes(
      svgBytes,
      width: width ?? 512,
      height: height ?? 512,
    );
    return imageBytes;
  }

  static Future<Uint8List?> fromUrl(String url, {double? width, double? height}) async {
    final imageBytes = await SvgToPngPlatform.instance.fromUrl(
      url,
      width: width ?? 512,
      height: height ?? 512,
    );
    return imageBytes;
  }
}
