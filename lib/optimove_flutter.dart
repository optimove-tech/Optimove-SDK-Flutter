import 'dart:async';
import 'package:flutter/services.dart';

import 'models/deeplink.dart';
import 'models/in_app.dart';
import 'models/location.dart';
import 'models/push.dart';

export 'models/deeplink.dart';
export 'models/in_app.dart';
export 'models/location.dart';
export 'models/push.dart';

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

  static Future<void> inAppSetDisplayMode(OptimoveInAppDisplayMode displayMode) async {
    return _methodChannel.invokeMethod('inAppSetDisplayMode', <String, String>{
      'displayMode': displayMode.toStringValue()
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