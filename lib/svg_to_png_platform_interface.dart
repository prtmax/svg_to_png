import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'svg_to_png_method_channel.dart';

abstract class SvgToPngPlatform extends PlatformInterface {
  /// Constructs a SvgToPngPlatform.
  SvgToPngPlatform() : super(token: _token);

  static final Object _token = Object();

  static SvgToPngPlatform _instance = MethodChannelSvgToPng();

  /// The default instance of [SvgToPngPlatform] to use.
  ///
  /// Defaults to [MethodChannelSvgToPng].
  static SvgToPngPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SvgToPngPlatform] when
  /// they register themselves.
  static set instance(SvgToPngPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<Uint8List?> fromBytes(Uint8List svgBytes, {double? width, double? height}) {
    throw UnimplementedError('fromBytes(Uint8List svgBytes, {int width = 512, int height = 512}) has not been implemented.');
  }

  Future<Uint8List?> fromUrl(String url, {double? width, double? height}) {
    throw UnimplementedError('fromUrl(String url, {int width = 512, int height = 512}) has not been implemented.');
  }
}
