# Changelog

## 3.2.0

- Added small icon customization in Android

## 3.1.0

- Added sendLocationUpdate API
- Added trackEddystoneBeaconProximity API

## 3.0.0

- [Breaking] For push opens don't set launch intent flags. Instead rely on the default launch mode.

## 2.2.0

- Updated the iOS SDK to version 5.2.2

## 2.1.0

- Added support for T&T only and Optimobile only initializations

## 2.0.0

- [Breaking] Updated API method names:
  1. `updateConsentForUser` to `inAppUpdateConsent`
  2. `markAllInboxItemsAsRead` to `inAppMarkAllInboxItemsAsRead`
  3. `getInboxSummary` to `inAppGetInboxSummary`
  4. `getInboxItems` to `inAppGetInboxItems`
  5. `presentInboxMessage` to `inAppPresentInboxMessage`
  6. `deleteMessageFromInbox` to `inAppDeleteMessageFromInbox`
  7. `markAsRead` to `inAppMarkAsRead`
- [Breaking] Updated the `setInAppDeeplinkHandler` API to receive `inAppPress` objects
- Updated the Android SDK version to 7.0.0
- Updated the iOS SDK to version 5.1.1
- Added `signOutUser` API
- Added `pushUnregister` API
- Added install info report
- Fixed an iOS bug where push notification is not shown when a foreground notification received listener is set
- Fixed an iOS bug where in some scenarios, in app inbox items dates are not formatted properly

## 1.0.0

Flutter SDK release, use [the documentation](https://github.com/optimove-tech/Optimove-SDK-Flutter/blob/main/README.md) to implement
