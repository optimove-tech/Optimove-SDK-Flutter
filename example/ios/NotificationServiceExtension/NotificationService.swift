import UserNotifications
import KumulosSDKExtension

class NotificationService: UNNotificationServiceExtension {
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        KumulosNotificationService.didReceive(request, withContentHandler: contentHandler)
    }
}
