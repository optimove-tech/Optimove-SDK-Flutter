### Description of Changes

(briefly outline the reason for changes, and describe what's been done)

### Breaking Changes

-   None

### Release Checklist

Bump versions in:

- [ ] `CHANGELOG.md`
- [ ] `pubspec.yaml` 
- [ ] `example/pubspec.yaml`
- [ ] `ios/optimove_flutter.podspec` 
- [ ] `ios/Classes/SwiftOptimoveFlutterPlugin.swift` 
- [ ] `android/src/main/java/com/optimove/flutter/OptimoveInitProvider.java`

Release:

- [ ] Squash and merge to main
- [ ] Delete branch once merged
- [ ] Create tag from main matching chosen version
- [ ] Fill out release notes
- [ ] Run `dart pub publish --dry-run` to make sure there are no issues
- [ ] Run `dart pub publish`
