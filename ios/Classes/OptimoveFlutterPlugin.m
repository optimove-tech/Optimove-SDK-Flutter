#import "OptimoveFlutterPlugin.h"
#if __has_include(<optimove_flutter/optimove_flutter-Swift.h>)
#import <optimove_flutter/optimove_flutter-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "optimove_flutter-Swift.h"
#endif

@implementation OptimoveFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftOptimoveFlutterPlugin registerWithRegistrar:registrar];
}
@end
