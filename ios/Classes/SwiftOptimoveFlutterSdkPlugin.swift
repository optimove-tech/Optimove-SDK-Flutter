import Flutter
import UIKit
import OptimoveSDK

public class SwiftOptimoveFlutterSdkPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "optimove_flutter_sdk", binaryMessenger: registrar.messenger())
        let optimoveFlutterPlugin = SwiftOptimoveFlutterSdkPlugin()
        optimoveFlutterPlugin.initOptimove(registrar: registrar)
        registrar.addMethodCallDelegate(optimoveFlutterPlugin, channel: channel)
    }
    
    private var eventSink: FlutterEventSink?

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
            case "pushRequestDeviceToken":
              Optimove.shared.pushRequestDeviceToken()
              result(nil)
            default:
              result(nil)
        }
    }
    
    fileprivate func initOptimove(registrar: FlutterPluginRegistrar) {
        //crash the app if the keys are not found
        let topPath = Bundle.main.path(forResource: registrar.lookupKey(forAsset: "optimove.json"), ofType: nil)!
        let jsonData = try! String(contentsOfFile: topPath).data(using: .utf8)
        let optimoveKeys = try! JSONDecoder().decode(OptimoveKeys.self, from: jsonData!)
        
        let flutterEventChannel: FlutterEventChannel = FlutterEventChannel(name: "optimove_flutter_sdk_events", binaryMessenger: registrar.messenger())
        flutterEventChannel.setStreamHandler(self)
        
        let config = OptimoveConfigBuilder(optimoveCredentials: optimoveKeys.optimoveCredentials, optimobileCredentials: optimoveKeys.optimobileCredentials)
                    .enableDeepLinking({ deepLinkResolution in
                                    let center = NotificationCenter.default
                                    let deepLinkDict = ["DeepLink" : deepLinkResolution]
                                    center.post(name: NSNotification.Name(rawValue: "DeepLinking"), object: nil, userInfo: deepLinkDict)
                                })
                                .setPushReceivedInForegroundHandler(pushReceivedInForegroundHandlerBlock: { notification , UNNotificationPresentationOptions -> Void in
                                    self.emitPushNotificationReceivedEvent(pushNotification: notification)
                                })
                                .setPushOpenedHandler(pushOpenedHandlerBlock: { notification in
                                    self.emitPushNotificationOpenedEvent(pushNotification: notification)
                                })
                                .enableInAppMessaging(inAppConsentStrategy: optimoveKeys.inAppConsentStrategy == "auto-enroll" ? .autoEnroll : .explicitByUser)
                                .setInAppDeepLinkHandler(inAppDeepLinkHandlerBlock: { inAppButtonPress in
                                    print("In app deeplink handler")
                                })
                                .build()

        Optimove.initialize(with: config)
    }
    
    private func emitPushNotificationReceivedEvent(pushNotification: PushNotification){
        var notificationMap = [String: Any?]()
        notificationMap["type"] = "push.received"
        notificationMap["data"] = getPushNotificatioMap(from: pushNotification)
        self.eventSink?(notificationMap)
    }
    
    private func emitPushNotificationOpenedEvent(pushNotification: PushNotification){
        var notificationMap = [String: Any?]()
        notificationMap["type"] = "push.opened"
        notificationMap["data"] = getPushNotificatioMap(from: pushNotification)
        self.eventSink?(notificationMap)
    }
    
    private func getPushNotificatioMap(from pushNotification: PushNotification) -> [String: Any?] {
        var data = [String: Any?]()
        data["id"] = pushNotification.id
        data["title"] = (pushNotification.aps["alert"] as? Dictionary)?["title"]
        data["message"] = (pushNotification.aps["alert"] as? Dictionary)?["body"]
        data["data"] = pushNotification.data
        data["url"] = pushNotification.url?.absoluteString
        data["actionId"] = pushNotification.actionIdentifier
        
        return data
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
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink =  events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}

struct OptimoveKeys: Codable {
    let optimoveCredentials: String
    let optimobileCredentials: String
    var inAppConsentStrategy: String?
    var enableDeferredDeepLinking: Bool?
}
