## 1.0.0
* Initial Release

## 1.1.0
* (Android) Added Instant App support.
* (iOS) Added App Clip support.
* (iOS) Increased minimum XCode version to 12.
* (iOS) Increased minimum Target to 10.3.
* (iOS) Support for App Tracking Transparency.
* (iOS) SKAdNetwork Support.

## 1.1.1
* (iOS) Corrected an issue when building for iOS.

## 1.1.2
* (iOS) Added support for embedded JSON passed in KVAEvent.infoString for adnetwork conversion metrics (SKAd).
* (iOS) Modified SKAdNetwork auto-registration to include a conversion value of zero when supported.

## 2.0.0
* A substantial overhaul of the Flutter SDK, improving usability, performance and stability.
* Added new feature Privacy, providing for restriction of data on a per-user basis.
* (iOS) Updated minimum Xcode version to 13.3.1.
* (iOS) Complete conversion of wrapped native SDK code base from Obj-C to Swift.

## 2.0.1
* Added support for Flutter 3.

## 2.0.2
* Corrected issue with missing files in pub.dev release.

## 2.1.0
* Miscellaneous improvements to performance and stability.

## 2.1.1
* (iOS) Improved the handling of unexpected values within network transaction responses.
* (Android) Fixed an issue with the proguard configuration.

## 2.2.0
* (iOS) Added support for SKAN 4.0 (SKAdNetwork v4). This includes support for coarse value and lock window.
* (iOS) Enhanced the deeplink timeout support such that the timeout timer will not start until the ATT authorization wait completes.
* (iOS) Removed support for Apple Search Ads method 2.  Apple has now officially discontinued the service.
* (iOS) Updated the minimum Xcode version to 14.1.
* (iOS) Updated the minimum iOS Target to 12.4.
* (Android) Corrected an issue when registering custom identifiers.

## 2.3.0
* (iOS) Added capability to disallow decreasing conversion values in SKAN 4.0, similar to SKAN 3.0 behavior.
* (Android) Added support for the Samsung Install Referrer.

## 2.4.0
* Added support for custom and default parameters to be included in certain payloads.
* Overhauled the Intelligent Consent Manager API.
* (iOS) Modified SKAdNetwork (SKAN) coarse conversion value support to begin at iOS 16.1, providing compatibility with Xcode 15.
* (Android) Added preliminary support for alternative install referrer collection.
* (Android) Updated to require Java 8 compatiblity, see the [following documentation](https://developer.android.com/studio/write/java8-support) more information on supporting Java 8 on Android.

## 2.5.0
* Includes support to automatically adorn data with the IAB TFC String, when present.
* (Android) Removed expiration from the url rotation alternate urls.
* (Android) Added support for collection and syndication of GAID and CGID.
* (Apple) Miscellaneous improvements to performance and stability.