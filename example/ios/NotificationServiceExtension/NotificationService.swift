import UserNotifications
import OptimoveNotificationServiceExtension

class NotificationService: UNNotificationServiceExtension {
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        OptimoveNotificationService.didReceive(request, withContentHandler: contentHandler)
    }
}
