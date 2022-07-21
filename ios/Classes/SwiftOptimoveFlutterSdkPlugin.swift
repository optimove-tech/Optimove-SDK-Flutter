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
            case "inAppMarkAllInboxItemsAsRead":
              result(OptimoveInApp.markAllInboxItemsAsRead());
            case "getInboxSummary":
              OptimoveInApp.getInboxSummaryAsync(inboxSummaryBlock: { inAppInboxSummary in
                  result(inAppInboxSummary)
              })
            case "inAppUpdateConsent":
              OptimoveInApp.updateConsent(forUser: call.arguments as! Bool)
              result(nil)
            default:
              result(nil)
        }
    }
    
    private func initOptimove(registrar: FlutterPluginRegistrar) {
        //crash the app if the keys are not found
        let topPath = Bundle.main.path(forResource: registrar.lookupKey(forAsset: "optimove.json"), ofType: nil)!
        let jsonData = try! String(contentsOfFile: topPath).data(using: .utf8)
        let optimoveKeys = try! JSONDecoder().decode(OptimoveKeys.self, from: jsonData!)
        
        let flutterEventChannel: FlutterEventChannel = FlutterEventChannel(name: "optimove_flutter_sdk_events", binaryMessenger: registrar.messenger())
        flutterEventChannel.setStreamHandler(self)
        self.initOptimove(from: optimoveKeys)
    }
    
    private func initOptimove(from optimoveKeys: OptimoveKeys){
        let config = OptimoveConfigBuilder(optimoveCredentials: optimoveKeys.optimoveCredentials, optimobileCredentials: optimoveKeys.optimobileCredentials)
        
        if (optimoveKeys.enableDeferredDeepLinking) {
            let dlHandler: DeepLinkHandler = { deepLinkResolution in
                let center = NotificationCenter.default
                let deepLinkDict = ["DeepLink" : deepLinkResolution]
                center.post(name: NSNotification.Name(rawValue: "DeepLinking"), object: nil, userInfo: deepLinkDict)
            }
            if let cname = optimoveKeys.cname {
                config.enableDeepLinking(cname: cname, dlHandler)
            } else {
                config.enableDeepLinking(dlHandler)
            }
        }
        
        if #available(iOS 10, *) {
            config.setPushReceivedInForegroundHandler(pushReceivedInForegroundHandlerBlock: { notification , UNNotificationPresentationOptions -> Void in
                self.emitPushNotificationReceivedEvent(pushNotification: notification)
            })
        }
        
        config.setPushOpenedHandler(pushOpenedHandlerBlock: { notification in
            self.emitPushNotificationOpenedEvent(pushNotification: notification)
        })
        
        if optimoveKeys.inAppConsentStrategy != .disabled {
            config.enableInAppMessaging(inAppConsentStrategy: optimoveKeys.inAppConsentStrategy == .autoEnroll ? .autoEnroll : .explicitByUser)
        }
        
        config.setInAppDeepLinkHandler(inAppDeepLinkHandlerBlock: { inAppButtonPress in
            print("In app deeplink handler")
        })

        Optimove.initialize(with: config.build())
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
        
enum InAppConsentStrategy: String {
    case autoEnroll = "auto-enroll"
    case explicitByUser = "explicit-by-user"
    case disabled = "in-app-disabled"
}

class OptimoveKeys: Decodable {
    let optimoveCredentials: String
    let optimobileCredentials: String
    var inAppConsentStrategy: InAppConsentStrategy
    var enableDeferredDeepLinking: Bool
    var cname: String?
    
    enum CodingKeys: CodingKey {
        case optimoveCredentials, optimobileCredentials, inAppConsentStrategy, enableDeferredDeepLinking
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        optimoveCredentials = try container.decode(String.self, forKey: .optimoveCredentials)
        optimobileCredentials = try container.decode(String.self, forKey: .optimobileCredentials)
        let inAppConsentStrategyString: String? = try? container.decode(String.self, forKey: .inAppConsentStrategy)
        
        switch inAppConsentStrategyString {
        case InAppConsentStrategy.explicitByUser.rawValue:
            inAppConsentStrategy = .explicitByUser
        case InAppConsentStrategy.autoEnroll.rawValue:
            inAppConsentStrategy = .autoEnroll
        default:
            inAppConsentStrategy = .disabled
        }
        
        if let enableDeferredDeepLinkingBoolean = try? container.decode(Bool.self, forKey: .enableDeferredDeepLinking) {
            enableDeferredDeepLinking = enableDeferredDeepLinkingBoolean
        } else if let enableDeferredDeepLinkingString = try? container.decode(String.self, forKey: .enableDeferredDeepLinking) {
            enableDeferredDeepLinking = true
            cname = enableDeferredDeepLinkingString
        } else {
            enableDeferredDeepLinking = false
        }
    }
}
