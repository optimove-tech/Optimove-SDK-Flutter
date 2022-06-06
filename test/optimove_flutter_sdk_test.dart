import 'package:flutter_test/flutter_test.dart';
import 'package:optimove_flutter_sdk/optimove_flutter_sdk_platform_interface.dart';
import 'package:optimove_flutter_sdk/optimove_flutter_sdk_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockOptimoveFlutterSdkPlatform 
    with MockPlatformInterfaceMixin
    implements OptimoveFlutterSdkPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final OptimoveFlutterSdkPlatform initialPlatform = OptimoveFlutterSdkPlatform.instance;

  test('$MethodChannelOptimoveFlutterSdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelOptimoveFlutterSdk>());
  });
}
