import 'package:flutter/services.dart';

import 'optimove_flutter_sdk_platform_interface.dart';

class Optimove {
  static const MethodChannel _channel =
      MethodChannel('optimove_flutter_sdk');

  Future<String?> getPlatformVersion() {
    return OptimoveFlutterSdkPlatform.instance.getPlatformVersion();
  }

  static Future<void> setUserId({required String userId}) async {
    return _channel.invokeMethod('setUserId', {'userId': userId});
  }
}
