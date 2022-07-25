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

    fileprivate var eventSink: FlutterEventSink?
    
    fileprivate func initOptimove(registrar: FlutterPluginRegistrar) {
        //crash the app if the keys are not found
        let topPath = Bundle.main.path(forResource: registrar.lookupKey(forAsset: "optimove.json"), ofType: nil)!
        let jsonData = try! String(contentsOfFile: topPath).data(using: .utf8)
        let optimoveKeys = try! JSONDecoder().decode(OptimoveKeys.self, from: jsonData!)
        
        let flutterEventChannel: FlutterEventChannel = FlutterEventChannel(name: "optimove_flutter_sdk_events", binaryMessenger: registrar.messenger())
        flutterEventChannel.setStreamHandler(self)
        self.initOptimove(from: optimoveKeys)
    }
    
    fileprivate func initOptimove(from optimoveKeys: OptimoveKeys){
        let config = OptimoveConfigBuilder(optimoveCredentials: optimoveKeys.optimoveCredentials, optimobileCredentials: optimoveKeys.optimobileCredentials)
        
        if (optimoveKeys.enableDeferredDeepLinking) {
            let dlHandler: DeepLinkHandler = { deepLinkResolution in
                self.emitDeeplinkResolved(deepLinkResolution: deepLinkResolution)
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
        
        config.setInAppDeepLinkHandler { inAppButtonPress in
            self.emitInappButtonPress(inAppButtonPress: inAppButtonPress)
        }

        Optimove.initialize(with: config.build())
        setAdditionalListeners()
    }
    
    fileprivate func setAdditionalListeners(){
        OptimoveInApp.setOnInboxUpdated {
            self.emitInboxUpdated()
        }
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
            case "pushRequestDeviceToken":
              Optimove.shared.pushRequestDeviceToken()
              result(nil)
            case "inAppMarkAllInboxItemsAsRead":
              result(OptimoveInApp.markAllInboxItemsAsRead());
            case "inAppGetInboxSummary":
              handleInAppInboxSummary(result)
            case "inAppUpdateConsent":
              OptimoveInApp.updateConsent(forUser: (call.arguments as! Dictionary<String, Any>)["consentGiven"] as! Bool)
              result(nil)
            case "inAppMarkAsRead":
              inAppMarkAsRead(call, result)
            case "inAppDeleteMessageFromInbox":
              inAppDeleteMessageFromInbox(call, result)
            case "inAppGetInboxItems":
              inAppGetInboxItems(result)
            case "inAppPresentInboxMessage":
              inAppPresentInboxMessage(call, result)
            default:
              result(nil)
        }
    }
    
    fileprivate func inAppPresentInboxMessage(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let id = (call.arguments as! Dictionary<String, Any>)["id"] as! Int
        
        let inboxItems: [InAppInboxItem] = OptimoveInApp.getInboxItems()
        var presentationResult: InAppMessagePresentationResult = .FAILED

        for item in inboxItems {
            if item.id == id {
                presentationResult = OptimoveInApp.presentInboxMessage(item: item)
                break
            }
        }
        
        switch presentationResult {
        case .PRESENTED:
            result(0)
        case .EXPIRED:
            result(1)
        case .FAILED:
            result(2)
        }
    }
    
    fileprivate func inAppMarkAsRead(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let id = (call.arguments as! Dictionary<String, Any>)["id"] as! Int
        
        let inboxItems: [InAppInboxItem] = OptimoveInApp.getInboxItems()
        var marked = false
        inboxItems.forEach { item in
            if item.id == id {
                marked = OptimoveInApp.markAsRead(item: item)
            }
        }
        
        result(marked)
    }
    
    fileprivate func inAppGetInboxItems(_ result: @escaping FlutterResult) {
        let inboxItems: [InAppInboxItem] = OptimoveInApp.getInboxItems()
        
        var inboxItemsMaps: [[String: Any?]] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
        inboxItems.forEach { item in
            var inboxItemMap = [String: Any?]()
            
            inboxItemMap["id"] = item.id
            inboxItemMap["title"] = item.title
            inboxItemMap["subtitle"] = item.subtitle
            inboxItemMap["sentAt"] = dateFormatter.string(from:  item.sentAt)
            inboxItemMap["availableFrom"] = item.availableFrom != nil ? dateFormatter.string(from:  item.availableFrom!) : nil
            inboxItemMap["availableTo"] = item.availableTo != nil ? dateFormatter.string(from:  item.availableTo!) : nil
            inboxItemMap["dismissedAt"] = item.dismissedAt != nil ? dateFormatter.string(from:  item.dismissedAt!) : nil
            inboxItemMap["isRead"] = item.isRead()
            inboxItemMap["imageUrl"] = item.getImageUrl()?.absoluteString
            inboxItemMap["data"] = item.data
            
            inboxItemsMaps.append(inboxItemMap)
        }
        
        result(inboxItemsMaps)
    }
    
    fileprivate func inAppDeleteMessageFromInbox(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let id = (call.arguments as! Dictionary<String, Any>)["id"] as! Int
        
        let inboxItems: [InAppInboxItem] = OptimoveInApp.getInboxItems()
        var deleted = false
        inboxItems.forEach { item in
            if item.id == id {
                deleted = OptimoveInApp.deleteMessageFromInbox(item: item)
            }
        }
        
        result(deleted)
    }
    
    fileprivate func handleInAppInboxSummary(_ result: @escaping FlutterResult) {
        OptimoveInApp.getInboxSummaryAsync(inboxSummaryBlock: { inAppInboxSummary in
            var inAppInboxSummaryMap = [String: Any?]()
            inAppInboxSummaryMap["totalCount"] = inAppInboxSummary?.totalCount
            inAppInboxSummaryMap["unreadCount"] = inAppInboxSummary?.unreadCount
            result(inAppInboxSummaryMap)
        })
    }
    
    
    fileprivate func emitPushNotificationReceivedEvent(pushNotification: PushNotification){
        var notificationMap = [String: Any?]()
        notificationMap["type"] = EventTypes.pushReceived.rawValue
        notificationMap["data"] = getPushNotificatioMap(from: pushNotification)
        self.eventSink?(notificationMap)
    }
    
    fileprivate func emitPushNotificationOpenedEvent(pushNotification: PushNotification){
        var notificationMap = [String: Any?]()
        notificationMap["type"] = EventTypes.pushOpened.rawValue
        notificationMap["data"] = getPushNotificatioMap(from: pushNotification)
        self.eventSink?(notificationMap)
    }
    
    fileprivate func emitDeeplinkResolved(deepLinkResolution: DeepLinkResolution){
        var deeplinkResolvedMap = [String: Any?]()
        deeplinkResolvedMap["type"] = EventTypes.pushDeepLinkResolved.rawValue
        
        var data = [String: Any?]()
        var urlString: String
        
        switch deepLinkResolution {
        case .lookupFailed(let dl):
            urlString = dl.absoluteString
        case .linkNotFound(let dl):
            urlString = dl.absoluteString
        case .linkExpired(let dl):
            urlString = dl.absoluteString
        case .linkLimitExceeded(let dl):
            urlString = dl.absoluteString
        case .linkMatched(let dl):
            urlString = dl.url.absoluteString
        }
        data["url"] = urlString
        deeplinkResolvedMap["data"] = data
        self.eventSink?(deeplinkResolvedMap)
    }
    
    fileprivate func emitInappButtonPress(inAppButtonPress: InAppButtonPress){
        var inAppButtonPressMap = [String: Any?]()
        inAppButtonPressMap["type"] = EventTypes.inAppDeepLinkPressed.rawValue
        inAppButtonPressMap["data"] = getInappButtonPressMap(from: inAppButtonPress)
        self.eventSink?(inAppButtonPressMap)
    }
    
    fileprivate func emitInboxUpdated(){
        var inAppButtonPressMap = [String: Any?]()
        inAppButtonPressMap["type"] = EventTypes.inAppInboxUpdated.rawValue
        self.eventSink?(inAppButtonPressMap)
    }
    
    
    fileprivate func getPushNotificatioMap(from pushNotification: PushNotification) -> [String: Any?] {
        var data = [String: Any?]()
        data["id"] = pushNotification.id
        data["title"] = (pushNotification.aps["alert"] as? Dictionary)?["title"]
        data["message"] = (pushNotification.aps["alert"] as? Dictionary)?["body"]
        data["data"] = pushNotification.data
        data["url"] = pushNotification.url?.absoluteString
        data["actionId"] = pushNotification.actionIdentifier
        
        return data
    }
    
    fileprivate func getInappButtonPressMap(from inAppButtonPress: InAppButtonPress) -> [String: Any?] {
        var data = [String: Any?]()
        data["deepLinkData"] = inAppButtonPress.deepLinkData
        data["messageData"] = inAppButtonPress.messageData
        data["messageId"] = inAppButtonPress.messageId
        
        return data
    }
    
    fileprivate func handleReportEvent(_ call: FlutterMethodCall){
        let event: String = (call.arguments as! Dictionary<String, Any>)["event"] as! String
        let parameters: Dictionary<String, Any>? = (call.arguments as! Dictionary<String, Any>)["parameters"] as? Dictionary<String, Any>

        if let parameters = parameters {
            Optimove.reportEvent(name: event, parameters: parameters)
        } else {
            Optimove.reportEvent(name: event)
        }
    }
    
    fileprivate func handleReportScreenVisit(_ call: FlutterMethodCall){
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

enum EventTypes: String {
    case pushReceived = "push.received"
    case pushOpened = "push.opened"
    case pushDeepLinkResolved = "deep-linking.linkResolved"
    case inAppInboxUpdated = "inbox.updated"
    case inAppDeepLinkPressed = "in-app.deepLinkPressed"
}
