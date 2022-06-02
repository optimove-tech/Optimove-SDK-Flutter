import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'optimove_flutter_sdk_method_channel.dart';

abstract class OptimoveFlutterSdkPlatform extends PlatformInterface {
  /// Constructs a OptimoveFlutterSdkPlatform.
  OptimoveFlutterSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static OptimoveFlutterSdkPlatform _instance = MethodChannelOptimoveFlutterSdk();

  /// The default instance of [OptimoveFlutterSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelOptimoveFlutterSdk].
  static OptimoveFlutterSdkPlatform get instance => _instance;
  
  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [OptimoveFlutterSdkPlatform] when
  /// they register themselves.
  static set instance(OptimoveFlutterSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
