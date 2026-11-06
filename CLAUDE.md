# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Working with this user

- **Reply in Vietnamese.** They write in Vietnamese and read replies in Vietnamese.
- **Expand every abbreviation and piece of jargon in parentheses on first use** — "ACK (acknowledge
  — báo đã nhận)", "DTO (data transfer object — gói dữ liệu để truyền)". This applies to English
  abbreviations, Apple/iOS jargon, and names invented in this project. Keep the precise term and add
  the gloss; do not swap it for something vaguer. They asked for this directly after a reply used
  "Op" and "ACK" with no explanation and they could not follow it.
- **Hand over git commands; do not run them.** `add`, `commit`, `push`, `reset`, remote changes —
  write them in a copy-pasteable block and stop. Reading state (`git status`, `git log`, scanning for
  secrets before a public push) is fine and useful. They pushed back when these were run for them.
- This is their first iPhone + Apple Watch app. Prefer a concrete example or a short walkthrough over
  an abstract definition, and say plainly what has **not** been verified on a real device.

## The product being built: Voxo

**`PLAN.md` at the repo root is the source of truth for what we are building** — *Voxo: Voice Todo Reminder*, an
iPhone + Apple Watch todo app with self-managed repeating local notifications, Core Data per device, and
WatchConnectivity sync. Read it before writing feature code. When code and `PLAN.md` disagree, **ask the user**
rather than changing either.

Non-negotiables from `PLAN.md` §1 and §11 (do not change these without asking):

- Reminders are **self-scheduled local notifications**, not EventKit/Reminders. iPhone is the only scheduler in v1.
- **Reminders are aggregated, hybrid style** (`PLAN.md` §1.7, decided 2026-11-06): todos on the shared
  cycle share ONE repeating notification naming the oldest todo plus a count ("Call mum — and 4 others");
  todos with `intervalOverride > 0` still get their own. This replaced per-todo reminders because those
  burned `todos × 24h/cycle` of the 64-slot budget — 10 todos covered only ~6 hours. Cost: notification
  text is frozen at schedule time, so counts can go stale until something reschedules.
- Minimum reminder interval 60 min; allowed values 60/120/180/240/360/480/720/1440. Keep pending notifications
  under the 64 limit (`maxPending = 60`).
- Sync conflicts: last-writer-wins on `updatedAt`, deletes are tombstones (`deletedAt`), purged after 30 days.
- No iCloud sync, widget, Siri Shortcut, Live Activity, or `SFSpeechRecognizer` in v1. English UI only.
- **Apple frameworks only — no third-party libraries without asking first.**
- Business logic (`ReminderScheduler`, `MergeService`, outbox) lives in `Shared/` as pure, testable code; no UIKit,
  WatchKit, or Core Data imports in the scheduler. Views never touch `NSManagedObjectContext` — go through
  `TodoRepository`.
- Work the phases in `PLAN.md` §8 in order; each phase ends with build pass, tests pass, and a commit named for
  the phase (e.g. `Phase 2: scheduler and tests`). Do not start a phase before the previous one meets its criteria.
- Never tick the §10 on-device checklist yourself — only the user confirms those on real hardware. When writing
  notification, sync, or dictation code, state explicitly in your reply what is **not yet verified on a device**.
- Core Data schema changes require a new model version; don't rename or delete files in `Shared/Model`.

Phase 0 is a hard gate: if repeating notifications cannot be kept reliable, **stop and report** instead of
switching to EventKit.

## What is actually in the repo right now

**Decided (2026-11-05): Voxo is built on top of the BaseSource template** — option (b), not a fresh project.
`./rename.sh` has already been run, so the template is now `VoiceTodo` / `com.limgrow.voxo`. **Do not run
`rename.sh` again** — it only matches the literal string `BaseSource`, which no longer exists here.

| | |
|---|---|
| Repo folder | `Voxo` |
| Xcode project / target / scheme | `VoiceTodo`, `VoiceTodo-Dev` |
| Source folder | `VoiceTodo/Sources`, `VoiceTodo/Resources` |
| Bundle id + IAP product prefix | `com.limgrow.voxo` |
| Home-screen name | `INFOPLIST_KEY_CFBundleDisplayName` in `project.pbxproj` — currently `VoiceTodo` in both configs |
| In-app name | `APP_NAME` in `Enviroments/*.xcconfig` ("VoiceTodo Dev" / "VoiceTodo"), read via `AppConfiguration.appName` |

The marketing name in `PLAN.md` §0 is **"Voxo: Voice Todo Reminder"**, which no user-facing string carries yet:
the display name, `APP_NAME`, and the `INFOPLIST_KEY_NS*UsageDescription` strings (they interpolate
`$(PRODUCT_NAME)`) all still say "VoiceTodo". Ask the user before changing these — the target name is
deliberately `VoiceTodo` while the bundle id is `com.limgrow.voxo`.

Everything else is still the untouched template: SwiftUI + MVVM-C, iOS 16+, CocoaPods **and** SPM,
Firebase/AdMob/IAP/tracking pre-wired. Nothing from `PLAN.md` has been built yet — no watchOS target, no App
Group, no `Shared/` module, no `Todo` entity, no test targets.

### Still unresolved — ask before acting on these

Building on the template contradicts parts of `PLAN.md`; these were not settled when the rename was done:

| `PLAN.md` wants | Template has | Status |
|---|---|---|
| iOS 13+ / watchOS 6+ | iOS 16+ (`Podfile` platform, pods, `Layout`/SwiftUI APIs) | unresolved — iOS 16+ almost certainly wins, but confirm |
| Apple frameworks only | Alamofire, AdMob + mediation, Adjust/FBSDK/TikTok, Firebase, Lottie, Kingfisher, Mantis, … | unresolved — ask what to strip |
| No ads / no IAP in v1 | ads + paywall wired into launch and splash flow | unresolved — ask before removing or keeping |
| English-only `Localizable.strings` | 16 languages in `Localizable.xcstrings` + in-app `LanguageManager` | unresolved — extra languages are harmless, can stay |
| `Shared/` + 2 app targets + 4 test targets | one `VoiceTodo` app target, no test target | to build in Phase 1 |

Phase 1 is therefore: add the watchOS target + App Group + `Shared/` module + the four test targets to **this**
project, and decide what template machinery to keep.

## Phase 0 harness (throwaway)

Two probes exist purely to clear `PLAN.md` §0. **Delete all of it once Phase 0 is signed off** — it is not
app code and must not be built on:

- `VoiceTodoWatch/` — standalone watchOS 10 app, target `VoiceTodoWatch`, bundle `com.limgrow.voxo.watchkitapp`.
  Reads 10 Vietnamese todo sentences aloud into a `TextField` (system dictation, not `SFSpeechRecognizer`) and
  scores each with a word-level Levenshtein distance that **keeps diacritics** (`WordDiff.swift`), so Phase 0's
  "sửa tối đa 1 từ mỗi câu" bar is measured, not eyeballed.
- `VoiceTodo/Sources/Modules/Phase0/` — notification probe. Reachable two ways: the shared scheme
  **`VoiceTodo-Phase0`**, which passes `-phase0Probe` so `RootView` opens the probe directly and skips
  splash/onboarding/paywall, or a `#if DEBUG` row in Settings.
  Schedules `series × firesPerSeries` notifications, reads back `getPendingNotificationRequests` to catch the
  64-notification ceiling, then measures delivery with `UNUserNotificationCenter.deliveredNotifications()` —
  the `date` on each delivered notification, so the app does not need to be running when they fire.

Two deliberate deviations from `PLAN.md`, both still open:

- **The Watch target IS embedded in the iOS app** (target dependency + `Embed Watch Content` copying to
  `$(CONTENTS_FOLDER_PATH)/Watch`, with `INFOPLIST_KEY_WKCompanionAppBundleIdentifier = com.limgrow.voxo`).
  That is what makes the Watch app install onto the paired Watch. Consequence: **every iOS build now needs
  the watchOS platform runtime** — it is installed, but keep that in mind if the build suddenly complains
  about `watchsimulator`.
  **The embed phase must sit directly after `Resources`**, before `SwiftLint` / `Upload dSyms` / the Pods
  phases. Appending it last produces `error: Cycle inside VoiceTodo` — `Upload dSyms` derives the `.dSYM`
  from the finished bundle, so anything writing into that bundle has to run first.
- **No App Group was added.** `PLAN.md` §2 wants one for shared settings, but an App Group does not span
  devices — iPhone and Watch are separate devices with separate containers, so it buys nothing for
  phone↔watch settings sync, which §6 already routes through `updateApplicationContext`. Adding
  `com.apple.security.application-groups` to the iOS entitlements would also break device builds until the
  Manual provisioning profile is regenerated. Raise with the user before adding it.

Target edits were made with the `xcodeproj` Ruby gem (ships with CocoaPods) rather than by hand-editing
`project.pbxproj`. The Watch target uses **Automatic** signing (team `D4692K9B9S`) while the iOS target is
**Manual** — mixing is intentional, but installing on a real Watch may still need profile work.

## Shared module (`Shared/`)

A **local Swift package `VoxoShared`**, depended on by both app targets. This is the `Shared/` module
`PLAN.md` §2 and §3 ask for: no UIKit, no WatchKit, compiler-enforced because it is a separate module.

```bash
cd Shared && swift test     # 24 tests, ~0.02s, runs on macOS — no simulator needed
```

- `Model/` — `TodoDTO`, `SyncOpDTO`, `DeviceRole`, the `NSManagedObject` subclasses, and `VoxoModel.swift`
- `Repository/` — `TodoRepository` / `SyncOutbox` / `ProcessedOpLog` protocols, `CoreDataTodoRepository`, `PersistenceStack`
- `Sync/` — `MergeService`, `SyncMessage`, `SyncSettings`
- `Scheduling/` — empty until Phase 2

Three things to know before touching it:

- **The Core Data model is built in Swift, not an `.xcdatamodeld`** (`Model/VoxoModel.swift`). SwiftPM's
  command-line build never runs `momc` — it copies the model bundle verbatim — so a visual model cannot be
  loaded by `swift test`. The cost is that there is no graphical model editor. `PLAN.md` §11 still holds:
  a schema change adds a new `version2` builder, it never edits `version1` in place.
- **`ProcessedOpEntity` is not in `PLAN.md` §4.** §6.3 requires the phone to skip `opId`s it already
  applied, and that ledger has to be durable or a relaunch re-applies every unacknowledged op. Flagged for
  the user; §4 should gain this entity.
- **Writes go through `CoreDataTodoRepository.write(op:todo:now:)`**, which puts the todo change and its
  `SyncOp` in one `save()` — that is the §6.1 "cùng một transaction" guarantee. `apply(remote:)`
  deliberately skips the outbox so an incoming change never echoes back.

## Voxo UI and design system

`PLAN.md` §7 fixes the screens; the visual layer was designed from scratch (no Figma). It lives in the
`VoxoDesign` target of `Shared/`, so iPhone and Watch share one source of truth.

| | |
|---|---|
| Accent | indigo `#4F46E5` light / `#8B84FF` dark — distinct from the green/orange used for status |
| Type | Mulish on iPhone, SF rounded on watchOS (Mulish is not in the Watch bundle, and SF reads better at watch sizes) |
| Dynamic Type | every size is declared `relativeTo:` a system text style — `PLAN.md` §7 requires it, fixed sizes would break it |
| Status | always shape + text as well as colour, never colour alone (§7) |

Screens: `VoiceTodo/Sources/Modules/Todo/` (list with Doing/Done, edit sheet, settings) and
`VoiceTodoWatch/Watch*.swift` (list, add-by-dictation, detail).

**`VoxoRootView` is the app's root.** Building any normal scheme launches straight into Voxo — the
template's splash/language/paywall flow is no longer on the launch path.

Schemes and launch arguments (`#if DEBUG`):

| Scheme | What it runs |
|---|---|
| `VoiceTodo`, `VoiceTodo-Dev` | the real app |
| `VoiceTodo-SampleData` | `-voxoSeed`: in-memory store with sample tasks, for design review |
| `VoiceTodo-Phase0` | `-phase0Probe`: the notification probe |
| — | `-templateUI`: escape hatch back to the BaseSource demo flow |

Consequence worth knowing: UMP consent was gathered in `SplashView`, which no longer runs, so
**ad consent and ATT never happen now**. That matches `PLAN.md` (no ads in v1), but if ads ever come
back, consent has to be re-wired somewhere on the new launch path. `AppDelegate` still initialises
Firebase and `TrackingKit` on every launch, unchanged.

**Light and dark both work now.** The template forced `.colorScheme(.dark)` app-wide in `App.swift`;
that was moved onto `RootView.mainContent` so only the template's own hardcoded white-on-black screens
stay pinned to dark, and Voxo's screens follow the system. The template's 46 single-appearance
colorsets in `Color.xcassets` are effectively dead for Voxo screens — use `VoxoColor`, not `Asset.Color`.

Still wired loosely: Phase 6 should make `VoxoRootView` the real root and drop the `-voxoUI` flag.

## Signing

Automatic, **no development team set**, no entitlements file. The user signs with a **free Apple ID
(Personal Team)**, so:

- `DEVELOPMENT_TEAM` is deliberately empty. The template shipped `D4692K9B9S`, which belongs to
  BaseSource's author — Xcode showed it as a red "Unknown Name". Do not put a team id back in;
  the developer picks their Personal Team in Xcode.
- `VoiceTodo.entitlements` was deleted. It only held an empty `keychain-access-groups` array, and a
  Personal Team profile would have had to match it for nothing — `KeychainStorageService` uses
  `Keychain(service:)` and needs no access group.
- A Personal Team **cannot sign In-App Purchase, Push Notifications, or App Groups.** Do not add
  those capabilities; if Voxo ever needs one, the user must join the paid program first.
- `StoreKit.framework` was removed from the Frameworks build phase for this reason: an explicit
  link is what makes Xcode show the In-App Purchase capability and demand it on the App ID, which
  a Personal Team cannot provision. `import StoreKit` still autolinks, so `SubscriptionManager`
  compiles unchanged — **do not re-add the explicit link.** The real cleanup is removing the
  subscription machinery altogether, which `PLAN.md` §1/§9 call for anyway.
- Personal Team profiles expire after 7 days, so device builds need reinstalling that often.

The Watch app needs a second App ID (`com.limgrow.voxo.watchkitapp`); Xcode registers it on first Run.

Never delete a simulator runtime image without `--keep-asset` when a duplicate exists: both entries can
share one downloaded asset, and deleting either takes the asset — and the good runtime — with it.

Simulator builds need none of this and work as-is.

## Commands

```bash
pod install                 # after any Podfile change; always open the .xcworkspace, never the .xcodeproj
swiftgen                    # regenerate Sources/Generated/* after touching Resources/Assets, Fonts, or Json
open VoiceTodo.xcworkspace

# Build / run from CLI (schemes: "VoiceTodo-Dev" -> Dev config, "VoiceTodo" -> Release config)
xcodebuild -workspace VoiceTodo.xcworkspace -scheme VoiceTodo-Dev \
  -configuration Dev -destination 'platform=iOS Simulator,name=iPhone 16' build

# Tracking acceptance gate (see Docs/Tracking.md)
python3 ~/.claude/skills/ios-tracking-integration/sdk_gate/sdk_gate_t1.py <app_config>.json
```

- **There is no test target.** The only native target is the app; the testing section in README.md is aspirational.
  Don't claim tests were run. `PLAN.md` §3 requires four (`SchedulerTests`, `MergeTests`, `OutboxTests`,
  `RepositoryTests`), so Phase 1/2 has to create them before any phase can "pass tests".
- `swiftlint` is not installed locally and `.swiftlint.yml` still points `included:` at the stale path
  `ProjectStructure/Sources` (real path is `VoiceTodo/Sources`), so linting is effectively a no-op today. The
  Xcode "SwiftLint" build phase ends with `touch`, so a missing binary does not fail the build. Fix the
  `included:` path before relying on lint output.
- Firebase DebugView: add `-FIRDebugEnabled` to the scheme's launch arguments.

## Architecture

### Two parallel DI systems — know which one a type uses

1. **Global service registry** (`Sources/Injected/Injected.swift`): services are registered once in
   `AppDelegate.dependencies` (a `Dependencies { Dependency { ... } }` result builder) and resolved by type via
   `@Injected var adsManager: AdsManager`. Resolution is `fatalError` on a missing registration, so a new service
   must be added to **both** `AppDelegate.dependencies` and `PreviewModifier` in `Common/FlowStacks/Preview.swift`
   (otherwise previews crash).
2. **`DIContainer`** (`Sources/Injected/DependencyInjector.swift`): a SwiftUI `EnvironmentKey` carrying only
   `Store<AppState>` (`Store<T>` = `CurrentValueSubject`). Injected with `.inject(container)`, read via
   `@Environment(\.injected)`. Use it for app-wide state (`AppState.path`, `system`), not for services.

Services conforming to `Service` (`shouldAutostart` / `start()` / `stop()`) are auto-started by `AppDelegate`
after `dependencies.build()`.

### Navigation: vendored FlowStacks + a global navigator

`Common/FlowStacks/` is a vendored, modified copy of FlowStacks. `RootView` owns the single `FlowStack`/`FlowPath`;
`NavigatorModifier` stashes the live navigator in `FlowNavigatorHolder.shared`, which the `@Navigation` property
wrapper reads. That makes navigation callable from ViewModels (`navigation.push(...)`, `.pop()`,
`.presentCover(...)`) without passing the environment down — but it `fatalError`s if used before `RootView`
appears, and it is a single global navigator (one `FlowStack`). Route payloads are the coordinator enums, so
destinations are registered on `RootView` via `.flowDestination(for: Coordinator.Navigation.self)`.

### Module shape (MVVM-C)

Each screen in `Sources/Modules/<Feature>/` is three files, with ViewModel and Coordinator **nested in an
extension of the View** so types read as `SettingView.ViewModel` / `SettingView.Coordinator`:

```swift
struct SettingView: View { @ObservedObject var viewModel: ViewModel; var body: some View { BaseView { ... } } }
extension SettingView { class ViewModel: BaseViewModel { @Navigation var navigation; @Published var coordinator = Coordinator() } }
extension SettingView { struct Coordinator: BaseCoordinator { enum Navigation: BaseNavigation { case language } } }
```

`BaseCoordinator` has three associated types with defaults (`Alert`, `FullScreen`, `Navigation`) — declare only the
enums a screen actually uses. `BaseView` (`Common/Protocols/BaseView.swift`) forces dark color scheme, hides the
back button, and applies the screen background; the whole app is `.colorScheme(.dark)`.

### Launch sequence (order is load-bearing)

`AppDelegate.didFinishLaunching`: Firebase → Meta `ApplicationDelegate` → `TrackingKit.shared.start()` (never
gated) → `startMobileAdsIfAllowed()` → `dependencies.build()` → start autostart services → `LanguageManager.initialize`.
Then `SplashView` runs UMP consent (`GoogleMobileAdsConsentManager.gatherConsent`, which also surfaces ATT — the
app never calls ATT itself) → `TrackingKit.releaseFirstSessionDelay()` → ads SDK start. `SplashView.handlePushNext()`
only routes once consent, Remote Config (`.remoteConfigReady` notification) and `SubscriptionManager` loading have
all settled.

### Data layer

`Sources/Data/Services/`: `Network` (Alamofire + `AuthInterceptor`, base URL overridable by Remote Config key
`base_url`), `Persistence` (Core Data + repositories), `Store/Subscription` (StoreKit 2), `Ads`
(interstitial/rewarded/app-open/banner/native + UMP consent + `AdsPreloadService`), `Analytics`
(`TrackingKit` + `FirebaseAnalyticsService`), `LocalStorage` (UserDefaults + Keychain wrappers), `FileManager`,
`Loading`. `Configuration/FirebaseRemoteConfig.swift` holds the `FirebaseRemoteConfigKey` enum that drives ad
placements, paywall/language-after-splash gating, and limits — add new keys there.

## Conventions

- **Never hardcode design values.** Use SwiftGen output and the design tokens: `Asset.Color.*.color`,
  `Asset.Icon.*.image`, `FontFamily.Mulish.<weight>.font(size:)`, and `Layout.Spacing/Margin/CornerRadius/Text.*`
  (`Helpers/Style/Layout.swift` — every token auto-adapts iPhone vs iPad via `AdaptiveSize`).
  `Sources/Generated/` is committed; regenerate with `swiftgen`, never hand-edit.
- **Localization**: strings live in `Resources/Languages/Localizable.xcstrings` (16 languages). Language switching
  is in-app, not system: `LanguageManager.shared` publishes `currentLocale` + `layoutDirection` and `RootView`
  applies them to the environment. Use `Text("key")` for literals, `String.localizedKey` for dynamic strings, and
  `String.localizedString` when a plain `String` is needed (bindings). `LanguageManager.supportedCodes` must stay
  in sync with `Language.supportedLanguages` in `Modules/Settings/Language/LanguageViewModel.swift`.
- **Analytics**: screen/impression tracking via the view modifiers `.trackScreen("name")` / `.trackImpression("event")`;
  custom events via `FirebaseAnalyticsService.logEvent`.
- **Revenue tracking has exactly two entry points** — `TrackingKit.logVerifiedPurchase` and
  `TrackingKit.handleAdPaidEvent`. Calling `AppEvents.logPurchase`, revenue-bearing `Adjust.trackEvent`,
  `TikTokBusiness.track*`, or `SKAdNetwork.*` anywhere else is forbidden. Adjust is the only MMP (no AppsFlyer);
  Meta/TikTok SDKs are signal-only. See `Docs/Tracking.md` and the `ios-tracking-integration` skill.
- Combine subscriptions are retained with `CancelBag` (`.store(in: cancelBag)`).
- Existing code mixes English and Vietnamese comments; both are fine — match the file you are editing.

## Per-app configuration placeholders

`Enviroments/Dev.xcconfig` and `Release.xcconfig` ship `REPLACE_WITH_*` values for `APP_ID`, `PRIVACY_URL`,
`TERM_OF_USE_URL`, `EMAIL_FEEDBACL` (sic), `ADJUST_TOKEN`, `ADJUST_PURCHASE_TOKEN`, `FACEBOOK_APP_ID`,
`FACEBOOK_CLIENT_TOKEN`, `TIKTOK_APP_ID`, `TIKTOK_ACCESS_TOKEN`. Code checks for the `REPLACE_WITH` prefix and
silently skips the corresponding SDK/event — notably `FirebaseApp.configure()` is skipped when
`GoogleService-Info.plist` is still the placeholder, which means Remote Config falls back to defaults and posts
`.remoteConfigReady` immediately. `GADApplicationIdentifier` is still AdMob's test id. The IAP product prefix in
`Data/Services/Store/Subscription/Subscription.swift` now reads `com.limgrow.voxo.` (rewritten by the rename) —
it matches the bundle id, so it only needs changing if the real App Store product ids differ.

## Gotchas

- Build configurations are **`Dev` / `Release`** (no `Debug`). CocoaPods treats an unknown name as release-type, so
  `Podfile`'s `post_install` force-sets `-Onone` for `Dev` to keep SwiftUI Previews working — preserve that hook.
- Dependencies are split across `Podfile` (Alamofire, AdMob + mediation, Adjust/FBSDK/TikTok pinned exactly,
  Lottie, Mantis, LBTATools, TPInAppReceipt) and SPM in the project file (Firebase 12+, Kingfisher, BottomSheet,
  CoreDataKit, FlagAndCountryCode, Mijick Timer, SwiftUI-Introspect). Firebase pods in the `Podfile` are
  intentionally commented out — do not re-enable them alongside the SPM Firebase.
- `Common/FlowStacks/FlowNavigator 2.swift` is a fully commented-out duplicate; ignore it, and edit
  `FlowNavigator.swift`.
- `Common/Camera/` is a vendored camera library (MijickCamera-style, `Public/` + `Internal/`) — treat it as a
  third-party dependency rather than app code.
