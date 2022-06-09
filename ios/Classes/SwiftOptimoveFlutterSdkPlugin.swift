import Flutter
import UIKit
import OptimoveSDK

public class SwiftOptimoveFlutterSdkPlugin: NSObject, FlutterPlugin {
    

    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "optimove_flutter_sdk", binaryMessenger: registrar.messenger())
    initOptimove(assetKey: registrar.lookupKey(forAsset: "optimove.json"))
    let optimoveFlutterPlugin = SwiftOptimoveFlutterSdkPlugin()
      
    registrar.addMethodCallDelegate(optimoveFlutterPlugin, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      switch call.method {
      case "setUserId":
          Optimove.setUserId((call.arguments as! Dictionary<String, Any>)["userId"] as! String)
          result(nil)
      default:
          result(nil)
      }
  }
    
    private static func initOptimove(assetKey: String) {
        //crash the app if the keys are not found
        let topPath = Bundle.main.path(forResource: assetKey, ofType: nil)!
        let jsonData = try! String(contentsOfFile: topPath).data(using: .utf8)
        let optimoveKeys = try! JSONDecoder().decode(OptimoveKeys.self, from: jsonData!)
        
        let config = OptimoveConfigBuilder(optimoveCredentials: optimoveKeys.optimoveCredentials, optimobileCredentials: optimoveKeys.optimobileCredentials)
                    .build()

        Optimove.initialize(with: config)
    }
}

struct OptimoveKeys: Codable {
    let optimoveCredentials: String
    let optimobileCredentials: String
}

