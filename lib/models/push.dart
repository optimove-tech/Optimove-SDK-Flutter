class OptimovePushNotification {
  final String? title;
  final String? message;
  final Map<String, dynamic>? data;
  final String? url;
  final String? actionId;

  OptimovePushNotification(this.title, this.message, this.data, this.url, this.actionId);

  OptimovePushNotification.fromMap(Map<String, dynamic> map)
      : title = map['title'],
        message = map['message'],
        data = map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
        url = map['url'],
        actionId = map['actionId'];
}