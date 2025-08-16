# iTimeMachine — Project Plan

Goal: iOS 6-styled app that browses the stuffed18 IPA archive and installs IPAs on-device.

Status: Initial scaffolding and automation.

---

## Scope
- Source of truth: stuffed18/ipa-archive-updated (Archive.org IPA index)
- App: iOS 6 UI theme, search/list apps (name, bundle id, min iOS, icon), and an Install button.
- Install flow: Download IPA and call `ipainstaller` on-device.

## Hard Constraints & Assumptions
- iOS 6.1.3 target. Realistically requires a jailbroken device for on-device install and process execution.
- `ipainstaller` implies jailbreak with a binary in PATH (or a known location) accessible by the app (or via helper/daemon).
- Building an iOS 6 app on GitHub Actions with the iOS 6.1 SDK is not supported by modern Xcode toolchains.
  - Action item: pick a viable build approach. Options below.

## Build Options
1) Theos (recommended for iOS 6 + jailbreak)
   - Build on GitHub Actions (macos runner) with Theos toolchain.
   - Ship .deb or .ipa for jailbroken devices.
2) Xcode project targeting iOS 6 SDK
   - Needs old Xcode 5.x + iOS 6.1 SDK which is not available on GH runners.
   - Could store project for local use; CI would skip build or run lint only.

Decision needed: Use Theos for builds, while still providing an Xcode project for browsing/UI editing.

## Data Pipeline (Archive Catalog)
- Use GitHub API to crawl `stuffed18/ipa-archive-updated` `data/` directories.
- Extract from each `*.plist` minimal metadata: title/name, bundle id, min iOS, download URL, icon path.
- Normalize into `catalog/catalog.json` and `catalog/icons/` map (optional) and publish via Actions artifacts.

## App Features (MVP)
- iOS 6 look: UINavigationController, UITableView with grouped style, classic gradient/nav bar.
- Search/filter: by name, bundle id, and min iOS.
- Detail view: large icon, description (if available), Install button.
- Install action (jailbreak only):
  - Download IPA to `/var/mobile/Media/iTimeMachine/Downloads`.
  - Execute `ipainstaller <path>` (requires proper entitlements/privileges or helper; see risks).

## Risks
- Non-jailbroken devices cannot run `ipainstaller` or execute binaries from an App Store app.
- iOS 6 SDK build on CI: infeasible on GH Actions; must use Theos or build locally.
- Entitlements and sandbox escape needed for process exec; will plan for jailbreak environments only.

## Milestones
- [ ] Confirm jailbreak requirement and build system choice (Theos + optional Xcode proj)
- [x] Create project scaffold (plan, readme, CI, catalog script)
- [ ] Implement catalog generator end-to-end
- [ ] Commit iOS UI project skeleton (Obj‑C) with iOS 6 theme assets
- [ ] Implement downloader and `ipainstaller` invocation (jailbroken code path)
- [ ] Wire UI to catalog and install flow
- [ ] End-to-end test on device

## Deliverables
- plan.md (this file)
- README.md (usage, constraints, jailbreak note)
- tools/fetch_catalog.py (catalog generator)
- .github/workflows/catalog.yml (CI to build catalog & publish)
- app/ (later): Objective‑C project sources and resources (iOS 6 style)

## Open Questions
- Do you want to proceed with Theos builds on CI? I can include both Theos and an Xcode project.
- Confirm your device is jailbroken and has `ipainstaller` installed.
- Any preference on subset of archive (to reduce catalog size)?
