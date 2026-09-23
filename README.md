# Dynamsoft MRZ Scanner for Android & iOS Editions

This repository hosts the **Dynamsoft MRZ Scanner** — a ready-to-use scanning component for native mobile apps. With minimal setup, you can drop the built-in scanner UI (`MRZScannerActivity` on Android, `MRZScannerViewController` on iOS) into your app to read the Machine Readable Zone (MRZ) on passports and ID cards and extract the holder's information.

This repo contains runnable samples for each platform that demonstrate launching the scanner, handling results, and displaying the extracted data — from a minimal single-screen app up to a complete **`ScanMRZ`** app.

## Supported Document Types

The SDK recognizes three ICAO Machine Readable Travel Document (MRTD) formats: **TD1** (3-line MRZ ID cards), **TD2** (2-line MRZ ID cards), and **TD3** (2-line MRZ passports). For other MRTD types, contact the [Dynamsoft Support Team](https://www.dynamsoft.com/company/contact/).

## Documentation

| | Android | iOS |
| --- | --- | --- |
| User Guide | [Android Guide](https://www.dynamsoft.com/mrz-scanner/docs/mobile/programming/android/user-guide/index.html) | [iOS Guide](https://www.dynamsoft.com/mrz-scanner/docs/mobile/programming/ios/user-guide/index.html) |
| API Reference | [Android API](https://www.dynamsoft.com/mrz-scanner/docs/mobile/programming/android/api-reference/) | [iOS API](https://www.dynamsoft.com/mrz-scanner/docs/mobile/programming/ios/api-reference/) |

## System Requirements

### Android

- Supported OS: **Android 5.0** (API Level 21) or higher.
- Supported ABI: **armeabi-v7a**, **arm64-v8a**, **x86** and **x86_64**.
- Development Environment:
   - IDE: **Android Studio 2024.3.2** suggested.
   - JDK: **Java 17** or higher.
   - Gradle: **8.0** or higher.
- Languages: **Java** and **Kotlin**.

### iOS

- Supported OS: **iOS 16** or higher — required by the Core ML models the scanner ships.
- Supported ABI: **arm64** and **x86_64**.
- Development Environment: **Xcode 14.1** or higher; **CocoaPods 1.11.0+** if you use the CocoaPods integration path.
- Languages: **Swift** and **Objective-C**.

### Building the samples in this repository

The requirements above are what the **SDK** needs when you add it to your own app. The samples here pin a newer toolchain of their own, which applies only to building them:

- **Android** — Android Gradle Plugin **8.13.0** and `compileSdk 36`, so use an Android Studio recent enough to support AGP 8.13 (these samples are developed against **2025.2**). You do not need Gradle installed: the Gradle wrapper downloads **8.14.5** on first build. JDK **17** or higher, as above.
- **iOS** — the samples are Swift-only and use Swift Package Manager; Xcode resolves the package on open. Every sample deploys to **iOS 16**, matching the SDK's own minimum.

## Add the SDK

The recommended way to add `DynamsoftMRZScannerBundle` to your app is via the platform's standard package manager, which ships the bundle as a precompiled binary. Building it yourself is only necessary if you intend to customize the scanner's internals (see [Further Customization](#further-customization)).

### Android — Maven (recommended)

1. Add the Dynamsoft Maven repository to the `dependencyResolutionManagement` block of your project-level **settings.gradle** / **settings.gradle.kts**:

   ```groovy
   dependencyResolutionManagement {
       repositories {
           google()
           mavenCentral()
           maven { url "https://download2.dynamsoft.com/maven/aar" }
       }
   }
   ```

2. Add the dependency to your app-level **build.gradle** / **build.gradle.kts**:

   ```groovy
   dependencies {
       implementation 'com.dynamsoft:mrzscannerbundle:3.6.2000'
   }
   ```

3. Click **Sync Now**.

For full details, see the [Android Add the SDK guide](https://www.dynamsoft.com/mrz-scanner/docs/mobile/programming/android/user-guide/index.html#add-the-sdk).

### iOS — Swift Package Manager or CocoaPods (recommended)

**Option 1 — Swift Package Manager**

In Xcode, go to **File > Add Packages**, search for `https://github.com/Dynamsoft/mrz-scanner-spm`, pick **Exact Version 3.6.2000**, and add the package. Then add its `DynamsoftMRZScanner` library product to your target — it brings in both the MRZ scanner and the Capture Vision framework it depends on. This is exactly how the iOS samples in this repository are configured.

**Option 2 — CocoaPods**

Add the pod to your **Podfile** (replacing `TargetName` with your real target), then run `pod install`:

```ruby
target 'TargetName' do
   use_frameworks!

   pod 'DynamsoftMRZScannerBundle', '3.6.2000'
end
```

For full details, see the [iOS Add the SDK guide](https://www.dynamsoft.com/mrz-scanner/docs/mobile/programming/ios/user-guide/index.html#add-the-sdk).

## Samples

### ScanMRZBasic

The smallest app that scans an MRZ and shows the data — one screen that launches the scanner, handles all three result statuses, and renders the parsed fields and the portrait. It is the runnable counterpart to the user guide ([Android](https://www.dynamsoft.com/mrz-scanner/docs/mobile/programming/android/user-guide/index.html) / [iOS](https://www.dynamsoft.com/mrz-scanner/docs/mobile/programming/ios/user-guide/index.html)): start here if you are integrating the SDK for the first time.

- [Android sample](android/samples/ScanMRZBasic) — Java
- [Android sample](android/samples/ScanMRZBasicKt) — Kotlin
- [iOS sample](ios/samples/ScanMRZBasic) — Swift (UIKit)
- [iOS sample](ios/samples/ScanMRZBasicSwiftUI) — Swift (SwiftUI)

On Android it is a single activity of about 100 lines. On iOS there is no storyboard and no navigation controller: `ScanMRZBasic` presents `MRZScannerViewController` modally and dismisses it when the result arrives, and `ScanMRZBasicSwiftUI` does the same through a `.fullScreenCover`, wrapping the scanner in the `MRZScannerView` bridge described below.

### ScanMRZ

A complete end-to-end app that scans the MRZ on a passport or ID card and displays the extracted holder information, document images, and raw MRZ text. It adds a separate result screen, document image browsing, per-field validation explanations, and camera-permission recovery on top of what `ScanMRZBasic` covers.

- [Android sample](android/samples/ScanMRZ) — Java
- [Android sample](android/samples/ScanMRZKt) — Kotlin
- [iOS sample](ios/samples/ScanMRZ) — Swift (UIKit)
- [iOS sample](ios/samples/ScanMRZSwiftUI) — Swift (SwiftUI)

Within each pair the second sample is a direct port of the first — the Kotlin Android modules share the Java modules' layouts, resources, and screen flow, and the SwiftUI iOS samples reproduce the UIKit ones' screens, result layout, and scanner flow — so pick whichever language or UI framework matches your project.

The four Android samples are modules of a single Gradle project: open **`android/samples`** in Android Studio (not an individual sample folder) and choose the run configuration you want. Both SwiftUI samples wrap the SDK's `MRZScannerViewController` in a `UIViewControllerRepresentable`, which is the pattern to copy when integrating the scanner into a SwiftUI app of your own. All four iOS samples deploy to **iOS 16**, the SDK's own minimum.

Every sample declares its own application ID / bundle identifier, so you can install them side by side on one device and compare them.

A physical device is required to run any of the samples — the host machine's simulator/emulator does not expose a camera.

## License

A valid license key is required to use the SDK. You can request a free 30-day trial via the [Request a Trial License](https://www.dynamsoft.com/customer/license/trialLicense?product=mrz&utm_source=samples&package=mobile) link. For production license setup, see the License Activation guide ([Android](https://www.dynamsoft.com/mrz-scanner/docs/mobile/programming/android/user-guide/license-activation.html) / [iOS](https://www.dynamsoft.com/mrz-scanner/docs/mobile/programming/ios/user-guide/license-activation.html)).

## Further Customization

The package-manager integrations above ship the bundle as a precompiled binary, which is the right choice for the vast majority of apps. If you need behavior that `MRZScannerConfig` cannot express — for example changing the built-in UI flow — you can build `DynamsoftMRZScannerBundle` from source instead:

- **Android** — [Building from Source](https://www.dynamsoft.com/mrz-scanner/docs/mobile/programming/android/user-guide/build-from-source.html)
- **iOS** — [Building from Source](https://www.dynamsoft.com/mrz-scanner/docs/mobile/programming/ios/user-guide/build-from-source.html)

Building from source replaces the package-manager dependency, and your changes have to be re-applied on each SDK release, so treat it as a last resort. If you are unsure whether it is the right path for your app, reach out to the [Dynamsoft Support Team](https://www.dynamsoft.com/company/contact/).

## Contact Us

For any questions or feedback, you can either [contact us](https://www.dynamsoft.com/company/contact/) or [submit an issue](https://github.com/Dynamsoft/mrz-scanner-mobile/issues/new).
