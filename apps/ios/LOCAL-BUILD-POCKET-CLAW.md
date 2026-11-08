# Local build guide — Pocket Claw fork (verified 2026-11-07)

This fork: `github.com/bysa/openclaw`, branch `pocket-local`, forked from
`github.com/openclaw/openclaw` (MIT). Upstream is tracked as `origin`; the fork is `fork`.

Everything below was verified on macOS with Xcode 27.2 against an iPhone 14 Pro (iOS 27.0.1).

## One-time prerequisites (all installed and verified)

| Tool | Version | Why |
|---|---|---|
| Node | 26.13.0 | repo rejects Node 25.x (`preinstall` range is >=24.16 <25 \|\| >=26.1) |
| pnpm | 12.18.0 | `pnpm ios:build` |
| xcodegen | 2.46.0 | generates `apps/ios/OpenClaw.xcodeproj` from `project.yml` |
| swiftformat | **0.63.1** exactly | `scripts/check-swift-tools.sh` hard-fails on mismatch. Homebrew ships 0.64.6, so use `~/.local/bin/swiftformat` from the GitHub artifactbundle. |
| swiftlint | 0.65.1 | matches the pinned version |
| Xcode | 27.2 | iOS 26.2 deployment target |

Rust/WebRTC is **not** needed only because the Watch companion target is disabled (below).

## Required source scope (sparse checkout)

A narrow checkout fails in confusing ways. This set is required:

```sh
git sparse-checkout set apps/ios apps/shared apps/swabble apps/macos \
  packages scripts patches src config ui extensions tools
```

- `patches/` → pnpm patch failures
- `src/` + `config/` → `prepare-git-hooks` / tsconfig failures
- `apps/macos` → `OpenClawTests` target references `apps/macos/Tests/OpenClawIPCTests`

If pnpm's `prepare` script fails on `@openclaw/normalization-core/*`, run
`pnpm install` after widening the checkout; the workspace packages must be present.

## Local change: Watch companion disabled

In `apps/ios/project.yml`, the `OpenClaw` target dependency `- target: OpenClawWatchApp`
is commented out. Without this, the build runs a `Build Watch WebRTC` script that needs
`rustup` + the pinned nightly toolchain. An iPhone-only build is otherwise complete.

## Build

```sh
cd ~/.openclaw/workspace/vendor/openclaw-official
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
pnpm ios:build            # configure signing, version xcconfig, swift filelist, xcodegen, xcodebuild
```

Or, after one `pnpm ios:gen`:

```sh
cd apps/ios
xcodebuild -project OpenClaw.xcodeproj -scheme OpenClaw \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/openclaw-ios-dd -configuration Debug build
```

## Run in simulator (verified)

```sh
SIM=BC35A850-14BA-467E-BBF3-477F48A354AC          # iPhone 17e, keeps the paired identity free
APP=/tmp/openclaw-ios-dd/Build/Products/Debug-iphonesimulator/OpenClaw.app
xcrun simctl boot $SIM; xcrun simctl bootstatus $SIM -b
xcrun simctl install $SIM "$APP"
xcrun simctl launch $SIM ai.openclawfoundation.app.test.shafigh-fw9ylpj4v2.debug
```

The generated bundle id is `ai.openclawfoundation.app.test.shafigh-fw9ylpj4v2.debug`
(local signing config appends the machine suffix). Read it from the built `Info.plist`
rather than assuming.

## Notes

- Simulator-only noise that is not a failure: `WCSession is not paired`, `libCoreFSCache` fopen.
- For a physical device you must run `scripts/ios-configure-signing.sh` (already part of
  `pnpm ios:build`) and set a personal team; expect a unique bundle id per machine.
- Keep `apps/ios/project.yml` changes minimal and documented so upstream updates stay mergeable.
