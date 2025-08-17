# I will get back soon on this project.
# iTimeMachine

An iOS 6–styled app to browse the stuffed18 IPA archive and install IPAs on-device (jailbroken only).

This repo follows plan.md and uses Build Option 2: an Xcode project targeting the iOS 6.1 SDK for local builds. CI only runs the catalog generator.

## Requirements (for building the app)
- macOS with Xcode 5.x installed
- iOS 6.1 SDK folder: `iPhoneOS6.1.sdk` (use the SDK linked below)
- A jailbroken device (for testing install flow) with `ipainstaller` available on PATH

SDK download:
- https://github.com/growtopiajaw/iPhoneOS-SDK/releases/download/v1.0/iPhoneOS6.1.sdk.zip

### Install the iOS 6.1 SDK into Xcode 5
1. Download and unzip `iPhoneOS6.1.sdk.zip`.
2. Copy the unzipped `iPhoneOS6.1.sdk` folder to:
   `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/`
3. (Optional) Also copy `iPhoneSimulator6.1.sdk` if you have it to the Simulator SDKs folder for sim testing.
4. Restart Xcode. In the project settings, set Base SDK to iOS 6.1 and Deployment Target to 6.1.

If Base SDK doesn’t appear, verify permissions and the path. Xcode 5.0–5.1 is recommended.

## Project Structure
- `app/` — Objective‑C iOS app (targets iOS 6.1)
- `catalog/` — Generated catalog artifacts
- `tools/fetch_catalog.py` — Script to build `catalog/catalog.json`
- `.github/workflows/catalog.yml` — CI to run catalog job

## Building the app (local)
1. Open `app/iTimeMachine.xcodeproj` in Xcode 5.x
2. Select target "iTimeMachine" and set:
   - Base SDK: iOS 6.1
   - iOS Deployment Target: 6.1
3. Build and run on a jailbroken device running iOS 6.1.x.

## App notes
- UI: classic iOS 6 UINavigationController and UITableView-based catalog.
- Install flow is jailbroken-only and will call `ipainstaller <path>` in a future milestone.

## Catalog generation (CI and local)
Local run:
```bash
python tools/fetch_catalog.py --owner stuffed18 --repo ipa-archive-updated --out catalog/catalog.json
```

GitHub Actions publishes the catalog as an artifact named `catalog.json`.

## Jailbreak disclaimer
This project assumes a jailbroken environment for on-device IPA installation. Do not expect App Store distribution or non-jailbroken device support.
