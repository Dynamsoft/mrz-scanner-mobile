# Dynamsoft MRZ scanner samples for the Android and iOS editions

This repository contains MRZ scanner samples based on the [Dynamsoft Label Recognizer](https://www.dynamsoft.com/label-recognition/overview/) SDK.

## Requirements

### Android

- Supported OS: Android 5.0 (API Level 21) or higher.
- Supported ABI: **armeabi-v7a**, **arm64-v8a**, **x86** and **x86_64**.
- Development Environment: Android Studio 3.4+ (Android Studio 4.2+ recommended).

### iOS

- Supported OS: **iOS 11.0** or higher.
- Supported ABI: **arm64** and **x86_64**.
- Development Environment: Xcode 13 and above (Xcode 14.1+ recommended)., CocoaPods 1.11.0+

## Samples

| Sample Name | Description | Programming Language(s) |
| ----------- | ----------- | ----------------------- |
|MRZScanner       | This sample detects the machine readable zone of a id card/visa/passport, recognize the text, and parse the data into surname, given name, nationality, passport number, issuing country or organization, date of birth, sex/gender, and passport expiration date.                 | Java(Android)/Objective-C/Swift |

### How to build (For iOS Editions)

1. Enter the sample folder, install DLR SDK through `pod` command

    ```bash
    pod install
    ```

2. Open the generated file `[SampleName].xcworkspace`

## License

- If you want to use an offline license, please contact [Dynamsoft Support](https://www.dynamsoft.com/company/contact/)
- You can also request a 30-day trial license in the [customer portal](https://www.dynamsoft.com/customer/license/trialLicense?product=dlr&utm_source=github)

## Contact Us

https://www.dynamsoft.com/company/contact/
