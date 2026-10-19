# JailbreakLab v1

A SwiftUI diagnostic research app for an iPhone 16 Pro Max on iOS 26.2. This is NOT a jailbreak, exploit, entitlement escalation tool, or sandbox escape.

## Build on your Mac

1. Install Xcode and select it as your developer directory.
2. Install XcodeGen: `brew install xcodegen`.
3. From this folder run `xcodegen generate`.
4. Open `JailbreakLab.xcodeproj` in Xcode.
5. In Signing & Capabilities choose your own development Team. Change bundle identifier if needed.
6. Connect your iPhone, enable Developer Mode if prompted, select it as the run destination, and press Run.
7. In the app tap Run All Tests; export the JSON report via the share sheet.

## Export an IPA (after configuring signing)

In Xcode use Product > Archive and, where supported by your signing account and distribution method, Organizer > Distribute App. You can also install directly from Xcode without creating an IPA. Do not distribute development-signed builds to others.

## Notes

- The simulator runs a macOS-hosted simulated iOS environment. Kernel, hardware, and security observations must be collected on a physical device.
- Results can include paths, identifiers, and signing team information; review JSON before sharing publicly.
- Sandbox and memory tests only exercise APIs inside the app's own process.
- PASS means a diagnostic completed, not that an exploit exists.
