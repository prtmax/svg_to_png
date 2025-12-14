import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'svg_to_png_platform_interface.dart';

/// An implementation of [SvgToPngPlatform] that uses method channels.
class MethodChannelSvgToPng extends SvgToPngPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('svg_to_png');

  @override
  Future<Uint8List?> fromBytes(Uint8List svgBytes, {double? width, double? height}) async {
    final imageBytes = await methodChannel.invokeMethod<Uint8List>('fromBytes', {
      'svgBytes': svgBytes,
      'width': width,
      'height': height,
    });
    return imageBytes;
  }

  @override
  Future<Uint8List?> fromUrl(String url, {double? width, double? height}) async {
    final imageBytes = await methodChannel.invokeMethod<Uint8List>('fromUrl', {
      'svgUrl': url,
      'width': width,
      'height': height,
    });
    return imageBytes;
  }
}
