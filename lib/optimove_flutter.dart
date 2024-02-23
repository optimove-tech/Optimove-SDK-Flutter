import 'dart:async';
import 'package:flutter/services.dart';

import 'models/location.dart';

export 'models/location.dart';

class Optimove {
  static const MethodChannel _methodChannel = MethodChannel('optimove_flutter_sdk');
  static const EventChannel _eventChannelImmediate = EventChannel('optimove_flutter_sdk_events');
  static StreamSubscription? _eventStreamImmediate;

  static const EventChannel _eventChannelDelayed = EventChannel('optimove_flutter_sdk_events_delayed');
  static StreamSubscription? _eventStreamDelayed;

  static void Function(OptimovePushNotification)? _pushOpenedHandler;
  static void Function(OptimovePushNotification)? _pushReceivedHandler;
  static void Function(OptimoveDeepLinkOutcome)? _deepLinkHandler;
  static Function? _inboxUpdatedHandler;
  static void Function(OptimoveInAppButtonPress)? _inAppDeepLinkHandler;

  static Future<void> registerUser({required String userId, required String email}) async {
    return _methodChannel.invokeMethod('registerUser', {'userId': userId, 'email': email});
  }

  static Future<void> setUserId({required String userId}) async {
    return _methodChannel.invokeMethod('setUserId', {'userId': userId});
  }

  static Future<void> setUserEmail({required String email}) async {
    return _methodChannel.invokeMethod('setUserEmail', {'email': email});
  }

  static Future<void> signOutUser() async {
    return _methodChannel.invokeMethod('signOutUser');
  }

  static Future<String> getVisitorId() async {
    String visitorId = await _methodChannel.invokeMethod('getVisitorId');
    return visitorId;
  }

  static Future<void> reportEvent({required String event, Map<String, dynamic>? parameters}) async {
    return _methodChannel.invokeMethod('reportEvent', {'event': event, 'parameters': parameters});
  }

  static Future<void> reportScreenVisit({required String screenName, String? screenCategory}) async {
    return _methodChannel.invokeMethod('reportScreenVisit', {'screenName': screenName, 'screenCategory': screenCategory});
  }

  static void pushRequestDeviceToken() {
    _methodChannel.invokeMethod('pushRequestDeviceToken');
  }

  static Future<void> pushUnregister() async {
    return _methodChannel.invokeMethod('pushUnregister');
  }

  static Future<bool> inAppMarkAllInboxItemsAsRead() async {
    var result = await _methodChannel.invokeMethod<bool>('inAppMarkAllInboxItemsAsRead');

    return result ?? false;
  }

  static Future<OptimoveInAppInboxSummary?> inAppGetInboxSummary() async {
    Map<String, dynamic> result = Map<String, dynamic>.from(await _methodChannel.invokeMethod('inAppGetInboxSummary'));

    return OptimoveInAppInboxSummary(result['totalCount'], result['unreadCount']);
  }

  static Future<void> inAppUpdateConsent(bool consentGiven) async {
    return _methodChannel.invokeMethod('inAppUpdateConsent', <String, bool>{
      'consentGiven': consentGiven
    });
  }

  static Future<List<OptimoveInAppInboxItem>> inAppGetInboxItems() async {
    var data = await _methodChannel.invokeMethod('inAppGetInboxItems');

    if (data == null) {
      return [];
    }

    var items = List.from(data).map((e) => OptimoveInAppInboxItem.fromMap(Map<String, dynamic>.from(e))).toList();
    return items;
  }

  static Future<OptimoveInAppPresentationResult> inAppPresentInboxMessage(OptimoveInAppInboxItem item) async {
    var result = await _methodChannel.invokeMethod<int>('inAppPresentInboxMessage', <String, int>{
      'id': item.id
    });

    return result != null ? OptimoveInAppPresentationResult.values[result] : OptimoveInAppPresentationResult.Failed;
  }

  static Future<bool> inAppDeleteMessageFromInbox(OptimoveInAppInboxItem item) async {
    var result = await _methodChannel.invokeMethod<bool>('inAppDeleteMessageFromInbox', <String, int>{
      'id': item.id
    });

    return result ?? false;
  }

  static Future<bool> inAppMarkAsRead(OptimoveInAppInboxItem item) async {
    var result = await _methodChannel.invokeMethod<bool>('inAppMarkAsRead', <String, int>{
      'id': item.id
    });

    return result ?? false;
  }

  static Future<void> sendLocationUpdate(Location location) async {
    return _methodChannel.invokeMethod('sendLocationUpdate', location.toMap());
  }

  static Future<void> trackIBeaconProximity(IBeaconProximity iBeaconProximity) async {
    return _methodChannel.invokeMethod('trackIBeaconProximity', iBeaconProximity.toMap());
  }

  static Future<void> trackEddystoneBeaconProximity(EddystoneBeaconProximity  eddystoneBeaconProximity) async {
    return _methodChannel.invokeMethod('trackEddystoneBeaconProximity', eddystoneBeaconProximity.toMap());
  }

  static void setPushReceivedHandler(void Function(OptimovePushNotification)? pushReceivedHandler) {
    _pushReceivedHandler = pushReceivedHandler;
    initImmediateStreamIfNeeded();
  }

  static void setPushOpenedAndDeeplinkHandlers(void Function(OptimovePushNotification)? pushOpenedHandler, void Function(OptimoveDeepLinkOutcome)? deepLinkHandler) {
    _pushOpenedHandler = pushOpenedHandler;
    _deepLinkHandler = deepLinkHandler;
    initDelayedStreamIfNeeded();
  }

  static void setInAppDeeplinkHandler(void Function(OptimoveInAppButtonPress)? inAppDeepLinkHandler) {
    _inAppDeepLinkHandler = inAppDeepLinkHandler;
    initImmediateStreamIfNeeded();
  }

  static void setOnInboxUpdatedHandler(Function? handler) {
    _inboxUpdatedHandler = handler;
    initImmediateStreamIfNeeded();
  }

  static void initImmediateStreamIfNeeded() {
    if (!immediateListenersExist()) {
      _eventStreamImmediate?.cancel();
      _eventStreamImmediate = null;
      return;
    }

    if (_eventStreamImmediate != null) {
      return;
    }

    initImmediateStream();
  }

  static void initDelayedStreamIfNeeded() {
    if (!delayedListenersExist()) {
      _eventStreamDelayed?.cancel();
      _eventStreamDelayed = null;
      return;
    }

    if (_eventStreamDelayed != null) {
      return;
    }

    initDelayedStream();
  }

  static bool immediateListenersExist() {
    return _pushReceivedHandler != null || _inboxUpdatedHandler != null || _inAppDeepLinkHandler != null;
  }

  static bool delayedListenersExist() {
    return _pushOpenedHandler != null || _deepLinkHandler != null;
  }

  static void initImmediateStream() {
    _eventStreamImmediate = _eventChannelImmediate.receiveBroadcastStream().listen((event) {
      String type = event['type'];

      switch (type) {
        case 'push.received':
          _pushReceivedHandler?.call(OptimovePushNotification.fromMap(Map<String, dynamic>.from(event['data'])));
          return;
        case 'inbox.updated':
          _inboxUpdatedHandler?.call();
          return;
        case 'in-app.deepLinkPressed':
          _inAppDeepLinkHandler?.call(OptimoveInAppButtonPress.fromMap(Map<String, dynamic>.from(event['data'])));
          return;
      }
    });
  }

  static void initDelayedStream() {
    _eventStreamDelayed = _eventChannelDelayed.receiveBroadcastStream().listen((event) {
      String type = event['type'];
      Map<String, dynamic> data = Map<String, dynamic>.from(event['data']);

      switch (type) {
        case 'push.opened':
          _pushOpenedHandler?.call(OptimovePushNotification.fromMap(data));
          return;
        case 'deep-linking.linkResolved':
          _deepLinkHandler?.call(OptimoveDeepLinkOutcome.fromMap(data));
          return;
      }
    });
  }
}

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

enum OptimoveDeepLinkResolution { LookupFailed, LinkNotFound, LinkExpired, LimitExceeded, LinkMatched }

class OptimoveDeepLinkContent {
  final String? title;
  final String? description;

  OptimoveDeepLinkContent(this.title, this.description);
}

class OptimoveDeepLinkOutcome {
  final OptimoveDeepLinkResolution resolution;
  final String url;
  final OptimoveDeepLinkContent? content;
  final Map<String, dynamic>? linkData;

  OptimoveDeepLinkOutcome(this.resolution, this.url, this.content, this.linkData);

  OptimoveDeepLinkOutcome.fromMap(Map<String, dynamic> map)
      : resolution = OptimoveDeepLinkResolution.values[map['resolution']],
        url = map['url'],
        content = map['link']?['content'] != null ? OptimoveDeepLinkContent(map['link']['content']['title'], map['link']['content']['description']) : null,
        linkData = map['link']?['data'] != null ? Map<String, dynamic>.from(map['link']['data']) : null;
}

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
