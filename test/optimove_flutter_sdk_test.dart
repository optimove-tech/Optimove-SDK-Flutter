import 'package:flutter_test/flutter_test.dart';
import 'package:optimove_sdk_flutter/optimove_flutter_sdk_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockOptimoveFlutterSdkPlatform 
    with MockPlatformInterfaceMixin
    implements OptimoveFlutterSdkPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {}
