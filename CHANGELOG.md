# Changelog

## 2.0.0

- [Breaking] Updated the ```updateConsentForUser``` API method name to ```inAppUpdateConsentForUser```
- [Breaking] Updated the ```setInAppDeeplinkHandler``` API to receive ``inAppPress`` objects 
- Updated the Android SDK version to 7.0.0
- Updated the iOS SDK to version 5.1.1
- Added ```signOutUser``` API
- Added ```pushUnregister``` API
- Added install info report
- Fixed an iOS bug where push notification is not shown when a foreground notification received listener is set
- Fixed an iOS bug where in some scenarios, in app inbox items dates are not formatted properly

## 1.0.0

Flutter SDK release, use [the documentation](https://github.com/optimove-tech/Optimove-SDK-Flutter/blob/main/README.md) to implement