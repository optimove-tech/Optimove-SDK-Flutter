import Flutter
import UIKit
import OptimoveSDK

public class SwiftOptimoveFlutterPlugin: NSObject, FlutterPlugin {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "optimove_flutter_sdk", binaryMessenger: registrar.messenger())
        let optimoveFlutterPlugin = SwiftOptimoveFlutterPlugin()
        optimoveFlutterPlugin.initOptimove(registrar: registrar)
        registrar.addMethodCallDelegate(optimoveFlutterPlugin, channel: channel)
        registrar.addApplicationDelegate(optimoveFlutterPlugin)
    }

    private var eventSinkImmediate = QueueStreamHandler()
    private var eventSinkDelayed = QueueStreamHandler()
    
    private let sdkVersion = "3.0.0"
    private let sdkType = 105
    private let runtimeType = 9
    private let runtimeVersion = "Unknown";

    fileprivate func initOptimove(registrar: FlutterPluginRegistrar) {
        //crash the app if the keys are not found
        let topPath = Bundle.main.path(forResource: registrar.lookupKey(forAsset: "optimove.json"), ofType: nil)!
        let jsonData = try! String(contentsOfFile: topPath).data(using: .utf8)
        let optimoveKeys = try! JSONDecoder().decode(OptimoveKeys.self, from: jsonData!)
        
        let flutterEventChannel: FlutterEventChannel = FlutterEventChannel(name: "optimove_flutter_sdk_events", binaryMessenger: registrar.messenger())
        flutterEventChannel.setStreamHandler(eventSinkImmediate)
        
        let flutterEventChannelDelayed: FlutterEventChannel = FlutterEventChannel(name: "optimove_flutter_sdk_events_delayed", binaryMessenger: registrar.messenger())
        flutterEventChannelDelayed.setStreamHandler(eventSinkDelayed)
        self.initOptimove(from: optimoveKeys)
    }
    
    private func initOptimove(from optimoveKeys: OptimoveKeys){
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
            config.setPushReceivedInForegroundHandler(pushReceivedInForegroundHandlerBlock: { notification , completionHandler in
                self.emitPushNotificationReceivedEvent(pushNotification: notification)
                completionHandler(UNNotificationPresentationOptions.alert)
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
        
        overrideInstallInfo(builder: config)

        Optimove.initialize(with: config.build())
        setAdditionalListeners()
    }
    
    private func overrideInstallInfo(builder: OptimoveConfigBuilder) -> Void {
        let runtimeInfo: [String : AnyObject] = [
            "id": runtimeType as AnyObject,
            "version": runtimeVersion as AnyObject,
        ]

        let sdkInfo: [String : AnyObject] = [
            "id": sdkType as AnyObject,
            "version": sdkVersion as AnyObject,
        ]

        builder.setRuntimeInfo(runtimeInfo: runtimeInfo);
        builder.setSdkInfo(sdkInfo: sdkInfo);

        var isRelease = true
        #if DEBUG
            isRelease = false
        #endif
        builder.setTargetType(isRelease: isRelease);
    }
    
    private func setAdditionalListeners(){
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
            case "signOutUser":
              Optimove.signOutUser()
              result(nil)
            case "reportEvent":
              handleReportEvent(call)
              result(nil)
            case "reportScreenVisit":
              handleReportScreenVisit(call)
              result(nil)
            case "getVisitorId":
              result(Optimove.getVisitorID())
            case "pushRequestDeviceToken":
              Optimove.shared.pushRequestDeviceToken()
              result(nil)
            case "pushUnregister":
              Optimove.shared.pushUnregister()
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
    
    private func inAppPresentInboxMessage(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
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
    
    private func inAppMarkAsRead(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
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
    
    private func inAppGetInboxItems(_ result: @escaping FlutterResult) {
        let inboxItems: [InAppInboxItem] = OptimoveInApp.getInboxItems()
        
        var inboxItemsMaps: [[String: Any?]] = []
        let dateFormatter = ISO8601DateFormatter()
        
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
    
    private func inAppDeleteMessageFromInbox(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
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
    
    private func handleInAppInboxSummary(_ result: @escaping FlutterResult) {
        OptimoveInApp.getInboxSummaryAsync(inboxSummaryBlock: { inAppInboxSummary in
            var inAppInboxSummaryMap = [String: Any?]()
            inAppInboxSummaryMap["totalCount"] = inAppInboxSummary?.totalCount
            inAppInboxSummaryMap["unreadCount"] = inAppInboxSummary?.unreadCount
            result(inAppInboxSummaryMap)
        })
    }
    
    
    private func emitPushNotificationReceivedEvent(pushNotification: PushNotification){
        var notificationMap = [String: Any?]()
        notificationMap["type"] = EventTypes.pushReceived.rawValue
        notificationMap["data"] = getPushNotificatioMap(from: pushNotification)
        self.eventSinkImmediate.send(notificationMap)
    }
    
    private func emitPushNotificationOpenedEvent(pushNotification: PushNotification){
        var notificationMap = [String: Any?]()
        notificationMap["type"] = EventTypes.pushOpened.rawValue
        notificationMap["data"] = getPushNotificatioMap(from: pushNotification)
        self.eventSinkDelayed.send(notificationMap)
    }
    
    private func emitDeeplinkResolved(deepLinkResolution: DeepLinkResolution){
        var deeplinkResolvedMap = [String: Any?]()
        deeplinkResolvedMap["type"] = EventTypes.pushDeepLinkResolved.rawValue
        
        var data = [String: Any?]()
        var urlString: String
        
        switch deepLinkResolution {
        case .lookupFailed(let dl):
            urlString = dl.absoluteString
            data["resolution"] = 0
        case .linkNotFound(let dl):
            urlString = dl.absoluteString
            data["resolution"] = 1
        case .linkExpired(let dl):
            urlString = dl.absoluteString
            data["resolution"] = 2
        case .linkLimitExceeded(let dl):
            urlString = dl.absoluteString
            data["resolution"] = 3
        case .linkMatched(let dl):
            urlString = dl.url.absoluteString
            data["resolution"] = 4
            var content = [String: Any?]()
            content["title"] = dl.content.title
            content["description"] = dl.content.description
            
            var link = [String: Any?]()
            link["content"] = content
            link["data"] = dl.data
            
            data["link"] = link
        }
        data["url"] = urlString
        deeplinkResolvedMap["data"] = data
        self.eventSinkDelayed.send(deeplinkResolvedMap)
    }
    
    private func emitInappButtonPress(inAppButtonPress: InAppButtonPress){
        var inAppButtonPressMap = [String: Any?]()
        inAppButtonPressMap["type"] = EventTypes.inAppDeepLinkPressed.rawValue
        inAppButtonPressMap["data"] = getInappButtonPressMap(from: inAppButtonPress)
        self.eventSinkImmediate.send(inAppButtonPressMap)
    }
    
    private func emitInboxUpdated(){
        var inAppInboxUpdatedMap = [String: Any?]()
        inAppInboxUpdatedMap["type"] = EventTypes.inAppInboxUpdated.rawValue
        self.eventSinkImmediate.send(inAppInboxUpdatedMap)
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
    
    private func getInappButtonPressMap(from inAppButtonPress: InAppButtonPress) -> [String: Any?] {
        var data = [String: Any?]()
        data["deepLinkData"] = inAppButtonPress.deepLinkData
        data["messageData"] = inAppButtonPress.messageData
        data["messageId"] = inAppButtonPress.messageId
        
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
    
    public func application(_ application: UIApplication,
                                  didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                                  fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
        return false
    }
    
}
        
enum InAppConsentStrategy: String {
    case autoEnroll = "auto-enroll"
    case explicitByUser = "explicit-by-user"
    case disabled = "in-app-disabled"
}

class OptimoveKeys: Decodable {
    let optimoveCredentials: String?
    let optimobileCredentials: String?
    var inAppConsentStrategy: InAppConsentStrategy
    var enableDeferredDeepLinking: Bool
    var cname: String?
    
    enum CodingKeys: CodingKey {
        case optimoveCredentials, optimobileCredentials, inAppConsentStrategy, enableDeferredDeepLinking
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        optimoveCredentials = try? container.decode(String.self, forKey: .optimoveCredentials)
        optimobileCredentials = try? container.decode(String.self, forKey: .optimobileCredentials)
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

class QueueStreamHandler: NSObject, FlutterStreamHandler {
    
    private var eventSink: FlutterEventSink?
    private var eventQueue: [Any] = []
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        while !eventQueue.isEmpty {
            self.eventSink?(eventQueue.removeFirst())
        }
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        self.eventQueue.removeAll()
        return nil
    }
    
    func send(_ event: Any) {
        if let eventSink = eventSink {
            eventSink(event)
            return
        }
        
        eventQueue.append(event)
    }
}

enum EventTypes: String {
    case pushReceived = "push.received"
    case pushOpened = "push.opened"
    case pushDeepLinkResolved = "deep-linking.linkResolved"
    case inAppInboxUpdated = "inbox.updated"
    case inAppDeepLinkPressed = "in-app.deepLinkPressed"
}
