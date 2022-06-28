#import "OptimoveFlutterSdkPlugin.h"
#if __has_include(<optimove_sdk_flutter/optimove_sdk_flutter-Swift.h>)
#import <optimove_sdk_flutter/optimove_sdk_flutter-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "optimove_sdk_flutter-Swift.h"
#endif

@implementation OptimoveFlutterSdkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftOptimoveFlutterSdkPlugin registerWithRegistrar:registrar];
}
@end
