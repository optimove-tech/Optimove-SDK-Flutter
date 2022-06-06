import 'package:flutter/services.dart';

import 'optimove_flutter_sdk_platform_interface.dart';

class Optimove {
  static const MethodChannel _channel = MethodChannel('optimove_flutter_sdk');

  Future<String?> getPlatformVersion() {
    return OptimoveFlutterSdkPlatform.instance.getPlatformVersion();
  }

  static Future<void> registerUser({required String userId, required String email}) async {
    return _channel.invokeMethod('registerUser', {'userId': userId, 'email': email});
  }

  static Future<void> setUserId({required String userId}) async {
    return _channel.invokeMethod('setUserId', {'userId': userId});
  }

  static Future<void> setUserEmail({required String email}) async {
    return _channel.invokeMethod('setUserEmail', {'email': email});
  }

  static Future<String> getVisitorId() async {
    String visitorId = await _channel.invokeMethod('getVisitorId');
    return visitorId;
  }

  static Future<void> reportEvent({required String event, Map<String, dynamic>? parameters}) async {
    return _channel.invokeMethod('reportEvent', {'event': event, 'parameters': parameters});
  }

  static Future<void> reportScreenVisit({required String screenName, String? screenCategory}) async {
    return _channel.invokeMethod('reportScreenVisit', {'screenName': screenName, 'screenCategory': screenCategory});
  }

  static Future<String> getCurrentUserIdentifier() async {
    String userIdentifier = await _channel.invokeMethod('getCurrentUserIdentifier');
    return userIdentifier;
  }
}
