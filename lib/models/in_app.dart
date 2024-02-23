class OptimoveInAppInboxItem {
  final int id;
  final String title;
  final String subtitle;
  final DateTime? availableFrom; // Date?
  final DateTime? availableTo;
  final DateTime? dismissedAt;
  final DateTime sentAt;
  final Map<String, dynamic>? data;
  final bool isRead;
  final String? imageUrl;

  OptimoveInAppInboxItem.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        title = map['title'],
        subtitle = map['subtitle'],
        sentAt = DateTime.parse(map['sentAt']),
        availableFrom = map['availableFrom'] != null ? DateTime.parse(map['availableFrom']) : null,
        availableTo = map['availableTo'] != null ? DateTime.parse(map['availableTo']) : null,
        data =  map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
        dismissedAt = map['dismissedAt'] != null ? DateTime.parse(map['dismissedAt']) : null,
        isRead = map['isRead'],
        imageUrl = map['imageUrl'];
}

enum OptimoveInAppPresentationResult { Presented, Expired, Failed }

class OptimoveInAppButtonPress {
  final Map<String, dynamic> deepLinkData;
  final int messageId;
  final Map<String, dynamic>? messageData;

  OptimoveInAppButtonPress(this.deepLinkData, this.messageId, this.messageData);

  OptimoveInAppButtonPress.fromMap(Map<String, dynamic> map)
      : deepLinkData = Map<String, dynamic>.from(map['deepLinkData']),
        messageId = map['messageId'],
        messageData = map['messageData'] != null ? Map<String, dynamic>.from(map['messageData']) : null;
}

class OptimoveInAppInboxSummary {
  final int totalCount;
  final int unreadCount;

  OptimoveInAppInboxSummary(this.totalCount, this.unreadCount);
}