import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'optimove_flutter_sdk_platform_interface.dart';

/// An implementation of [OptimoveFlutterSdkPlatform] that uses method channels.
class MethodChannelOptimoveFlutterSdk extends OptimoveFlutterSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('optimove_flutter_sdk');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
