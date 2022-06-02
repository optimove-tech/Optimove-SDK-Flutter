
import 'package:flutter/services.dart';

import 'optimove_flutter_sdk_platform_interface.dart';

class OptimoveFlutterSdk {
  static const MethodChannel _channel = const MethodChannel('optimove_flutter_sdk');
  Future<String?> getPlatformVersion() {
    return OptimoveFlutterSdkPlatform.instance.getPlatformVersion();
  }
  static Future<void> setUserId(
      {required String userId}) async {
    return _channel.invokeMethod(
        'setUserId', {'userId': userId});
  }
}
