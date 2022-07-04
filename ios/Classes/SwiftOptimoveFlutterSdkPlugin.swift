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
      case "registerUser":
          Optimove.registerUser(sdkId: (call.arguments as! Dictionary<String, Any>)["userId"] as! String, email: (call.arguments as! Dictionary<String, Any>)["email"] as! String)
          result(nil)
      case "setUserId":
          Optimove.setUserId((call.arguments as! Dictionary<String, Any>)["userId"] as! String)
          result(nil)
      case "setUserEmail":
          Optimove.setUserEmail(email: (call.arguments as! Dictionary<String, Any>)["email"] as! String)
          result(nil)
      case "reportEvent":
          handleReportEvent(call)
          result(nil)
      case "reportScreenVisit":
          handleReportScreenVisit(call)
          result(nil)
      case "getCurrentUserIdentifier":
          result(nil)
      case "getVisitorId":
          result(Optimove.getVisitorID())

      default:
          result(nil)
      }
  }
    
    private func handleReportEvent(_ call: FlutterMethodCall){
        let event: String = (call.arguments as! Dictionary<String, Any>)["event"] as! String
        let parameters: Dictionary<String, Any>? = (call.arguments as! Dictionary<String, Any>)["parameters"] as? Dictionary<String, Any>

        if let parameters = parameters {
            Optimove.reportEvent(name: event, parameters: parameters)
        } else {
            Optimove.reportEvent(name: event)
        }
    }
    
    private func handleReportScreenVisit(_ call: FlutterMethodCall){
        let screenName: String = (call.arguments as! Dictionary<String, Any>)["screenName"] as! String
        let screenCategory: String? = (call.arguments as! Dictionary<String, Any>)["screenCategory"] as? String

        Optimove.reportScreenVisit(screenTitle: screenName, screenCategory: screenCategory)
    }
    
    private static func initOptimove(assetKey: String) {
        //crash the app if the keys are not found
        let topPath = Bundle.main.path(forResource: assetKey, ofType: nil)!
        let jsonData = try! String(contentsOfFile: topPath).data(using: .utf8)
        let optimoveKeys = try! JSONDecoder().decode(OptimoveKeys.self, from: jsonData!)
        
        let flutterEventChannel: FlutterEventChannel = FlutterEventChannel("kumulos_sdk_flutter_events")
        let config = OptimoveConfigBuilder(optimoveCredentials: optimoveKeys.optimoveCredentials, optimobileCredentials: optimoveKeys.optimobileCredentials)
                    .enableDeepLinking({ deepLinkResolution in
                                    let center = NotificationCenter.default
                                    let deepLinkDict = ["DeepLink" : deepLinkResolution]
                                    center.post(name: NSNotification.Name(rawValue: "DeepLinking"), object: nil, userInfo: deepLinkDict)
                                    print(deepLinkResolution)
                                })
                                .setInAppDeepLinkHandler(inAppDeepLinkHandlerBlock: { inAppButtonPress in
                                    print("dsfgdfgd")
                                })
                                .setPushOpenedHandler(pushOpenedHandlerBlock: { notification in
                                    flutterEventChannel.call(notification) and  put type here to be "push.opened"
                                })
                                .enableInAppMessaging(inAppConsentStrategy: optimoveKeys.inAppConsentStrategy == "auto-enroll" ? .autoEnroll : .explicitByUser)
                                .build()

        Optimove.initialize(with: config)
        Optimove.shared.pushRequestDeviceToken()

    }
}

struct OptimoveKeys: Codable {
    let optimoveCredentials: String
    let optimobileCredentials: String
    var inAppConsentStrategy: String?
    var enableDeferredDeepLinking: Bool?
}

