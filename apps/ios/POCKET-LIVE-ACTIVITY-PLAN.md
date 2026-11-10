# Task-progress Live Activities — phase 1

- [x] Read iOS workflow, scoped instructions and local build guide.
- [x] Project structured progress cards without fabricated progress.
- [x] Wire focused-session lifecycle, preserving approval/voice precedence.
- [x] Add lock screen and Dynamic Island summaries.
- [x] Add projection, lifecycle and compatibility tests.
- [x] Format, simulator build and focused tests; record exact commands/results.
- [ ] Parent independent review and physical-device verification/install.

Local updates only; no APNs, Gateway, signing changes, phone installation or push.
Completed history must not start an activity.

Initial combined plan/inspection tool call failed before dispatch (JavaScript syntax); no implementation was performed by that call.

## Implementation checkpoint
Projection, owner observation, arbiter task slot, optional Codable payload, widget summaries and five regression tests added. Task freshness is based on card updatedAt (300 seconds), not tool heartbeats. Completion means all structured steps completed, labeled Plan completed. Elapsed time is since local tracking began. No session deep link added: no verified existing route was established.

Build/test environment: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer; PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH". Xcode 27.2; simulator BC35A850-14BA-467E-BBF3-477F48A354AC available/booted. swiftformat completed; xcodegen generate succeeded.

Starting: `xcodebuild -project apps/ios/OpenClaw.xcodeproj -scheme OpenClaw -destination generic/platform=iOS\ Simulator -derivedDataPath /tmp/openclaw-ios-dd CODE_SIGNING_ALLOWED=NO build` (log /tmp/pocket-task-build.log).

First build exited 65: three multiline_arguments lint violations, corrected. Standalone lint omitted DEVELOPER_DIR and trapped loading SourceKit; subsequent build uses required environment. Regenerated Swift source filelist to include projection. Rerunning same build command, log /tmp/pocket-task-build2.log.

## Parent verification checkpoint — 2026-11-09

- [x] Confirmed implementation files exist: projection/schema, focused-session observation, arbiter/manager and widget changes. Implementation remains provisional until review/tests.
- [x] Confirmed `/tmp/pocket-task-build2.log` ends with `BUILD SUCCEEDED`. Simulator build only.
- [x] Confirmed five regression tests were written.
- [ ] Execute focused tests and record result (no test-pass evidence recovered yet).
- [ ] Independently review lifecycle, stale/completion behavior and session ownership; fix any gaps.
- [ ] Inspect rendered lock-screen/Dynamic Island UI in simulator.
- [ ] Build signed device app, install, and verify real task progression/completion on physical iPhone.
- [ ] Commit/push verified changes and final evidence.

Current HEAD remains 484cf820; implementation is uncommitted. Astra child ended with an error despite leaving code and successful simulator-build evidence. No active child or build at this checkpoint. APNs delivery remains explicitly out of phase-1 scope.

## Independent review checkpoint — 2026-11-09
Found and fixed: completion retirement missing (same card could restart after 30s); stale ActivityKit state treated as inactive/recreated; nil task observation erased tool fallback; canonical card owner changes reused revisions/start times; older revisions could roll progress backward. Dismissed/system-ended task revisions now retire before reconciliation. Canonical card.sessionkey deliberately is not compared literally to focused alias: ChatViewModel fetch/event admission validates canonical owner, including global aliases. Observation callbacks are weak and reject replaced models; isAborting is wired but a very fast abort may coalesce before its scheduled observation (remaining integration risk).
Added four regression tests (nine projection tests total). No signing/project/Gateway changes. Missing sparse docs/help/testing/writing-tests.md noted.
Next run: format affected Swift, xcodebuild test with only LiveActivityTaskProjectionTests, LiveActivityPresentationArbiterTests, OpenClawTypographyTests; log /tmp/pocket-task-review-tests.log, result /tmp/pocket-task-review-tests.xcresult.

First review test invocation exited 65 before tests: formatter was invoked without repo config. Corrected using swiftformat --config config/swiftformat on the three edited files; rerun uses /tmp/pocket-task-review-tests2.{log,xcresult}.
Remaining device/integration checks: fast abort observation coalescing; stale card rendered without renewed freshness; swipe dismissal with later tool/progress event; actual 30-second completion display/end while backgrounded; canonical alias/session switch. No real Gateway task has been run in this child. Existing simulator preview only covers voice, not task progress; do not treat app launch as task-widget UI proof.

Second invocation exited 65: new test attempted mutation of immutable ProgressCard.sessionkey; fixture now constructs the owner explicitly. Third invocation /tmp/pocket-task-review-tests3.{log,xcresult} compiling/running.
Further caller review found NodeAppModel ends all activities on background_idle/operator_disconnected/gateway_loop_stopped. Manager now preserves structured tasks in an explicitly stale state for these transport events; explicit disconnect/new gateway still clears them. This last change requires final rebuild/test after test3 (which compiled prior snapshot).

Test3 passed: 36 tests / 3 suites, 0 failures, 0 skipped (9 projection, 13 arbiter, 14 typography), exit 0. Final source rerun in progress after background fix:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"
xcodebuild -project apps/ios/OpenClaw.xcodeproj -scheme OpenClaw -destination 'platform=iOS Simulator,id=BC35A850-14BA-467E-BBF3-477F48A354AC' -derivedDataPath /tmp/openclaw-ios-dd CODE_SIGNING_ALLOWED=NO -only-testing:OpenClawTests/LiveActivityTaskProjectionTests -only-testing:OpenClawTests/LiveActivityPresentationArbiterTests -only-testing:OpenClawTests/OpenClawTypographyTests -resultBundlePath /tmp/pocket-task-review-final.xcresult test > /tmp/pocket-task-review-final.log 2>&1
```

## Final independent-review evidence
- Final source simulator test build succeeded, exit 0; TEST SUCCEEDED. xcresult summary confirms 36 passed, 0 failed, 0 skipped (9 projection + 13 arbiter + 14 typography). /tmp/pocket-task-review-final.log and /tmp/pocket-task-review-final.xcresult.
- git diff --check passed. Optional task payload compatibility and new round-trip passed.
- Installed/launched only on iPhone 17e simulator in --openclaw-screenshot-mode. Inspected screenshot /Users/shafigh/.openclaw/workspace/pocket-review-evidence/app-ready.png: fixture chat renders. This is NOT a Gateway connection or task Live Activity rendering proof; lock-screen/Dynamic Island task visuals remain unverified.
- No commit: task-widget visual/real lifecycle gate is still open. No physical install, signing, entitlements, Gateway/config, APNs or push changes.
- Parent physical checklist: structured running/waiting/completed plan; completion retained ~30s then ended; lock/background until transport suspends (paused, no invented progress); reopen/reconnect; approval and voice precedence; tools without a plan; switch canonical/global aliases; cancel including fast response; swipe-dismiss then progress/tool updates; completed history reopen/relaunch does not resurrect.
- Remaining design limits: cancellation is isAborting observation (fast true/false can coalesce); 30s completion uses app task sleep, so suspension may defer ending until resume; dismissal suppression is revision-local/in-memory, not durable across relaunch. These need explicit acceptance or follow-up before claiming full lifecycle proof.

## Execution recovery and device checkpoint — 2026-11-09

- Execution bridge recovered and actual tool dispatch verified. The native codex-code-mode-host crashed with `Failed to reserve virtual memory for CodeRange`; its hardened-runtime signature omitted the JIT entitlement. Original binary preserved under `~/.openclaw/repair-backups/codex-host-2026-11-09/`, and a local ad-hoc hardened-runtime signature with `com.apple.security.cs.allow-jit` restored execution. No Gateway/configuration restart or change. Runtime updates can replace this local repair.
- Parent independently read final xcresult summary: 36 passed, 0 failed, 0 skipped. Existing simulator evidence reused, not rerun.
- Physical iPhone 14 Pro available/paired; existing Apple development identity available. Signed device build started using existing generated project and signing settings, `/tmp/pocket-task-device-20261109.log`, derived data `/tmp/openclaw-device`. No signing settings changed for the app.

- Signed physical build succeeded (exit 0). `devicectl device install app` succeeded (exit 0), then `devicectl device process launch` succeeded (exit 0) on physical UDID `00008120-001E702422D0C01E`. Existing bundle identifier `ai.openclawfoundation.app.test.shafigh-fw9ylpj4v2.debug` and team `FW9YLPJ4V2` preserved; existing app groups preserved. App rendered content, Gateway reconnection and Lock Screen behavior are not proven by launch receipt. Awaiting physical screen observation; no iOS screen-capture/control command advertised by paired node. Work remains uncommitted until visual/integration gates complete.

## Physical visibility check — 2026-11-09

User reported no Lock Screen activity. Inspection found the parent progress card revision 61 contained only markdown (`steps: null`), while task projection explicitly requires nonempty structured steps. Restored the actual unfinished verification checklist at revision 62. Asked user to foreground this conversation before locking, since local ActivityKit start cannot be proven by a background card update. iPhone node has reconnected after installation. Awaiting repeat observation; widget visibility is not yet verified.

## Physical crash diagnosis

Added stage-only diagnostics (no task content/session IDs) to the existing app diagnostic log and installed/launched that signed build. Device log proves `hasCard=true steps=5`, Live Activities enabled, and ActivityKit start succeeds when foreground. Within ~1 second the activity ends; system crash logs contain repeated `OpenClawActivityWidget` SIGTRAPs, including before checklist restoration. Latest stack asserts in `LayoutSubview.place` / `GeometryReaderLayout.placeSubviews`, not the task-state projection. Local protected evidence: `/tmp/pocket-phone-diagnostics/widget-crash.ips` and `gateway-instrumented.log`.

Narrow candidate fix: nonvoice task/tool/connection states no longer archive an invisible Canvas/TimelineView waveform (phase idle); render the same fixed-size static badge directly. Voice waveform remains unchanged. Physical build `/tmp/pocket-task-device-layout.log` running; not yet claimed fixed.

Candidate layout fix signed build succeeded, installed and launched (all exit 0). On-device stage log at 03:46:17Z confirms real five-step task activity starts successfully. Follow-up log contains no immediate `task_dismissed` end (unlike baseline). Crash report listing comparison contains no new widget crashes. These are crash/lifecycle observations, not user-visible rendering proof. Final simulator regression run on this source: 36 passed, 0 failed, 0 skipped; `/tmp/pocket-task-layout-tests.{log,xcresult}`. Await user Lock Screen observation before completion/commit.

User still reports no visible widget after candidate fix. Subsequent device log still shows accepted task activity, no recorded end; repeated crash listing shows no new widget reports. This does not establish rendering. Requested Lock Screen screenshot to inspect actual iOS presentation; no paired node screen capture/control capability is available. Do not claim the feature repaired or mark visual gates complete. Existing structured checklist retained during observation.

Screenshot from user confirms an empty Lock Screen, not a hidden/collapsed OpenClaw card. LLDB device selection/attach route available in installed Xcode (`device select` / `device process attach`), but it explicitly reports `Device needs to be unlocked`. Requested user unlock phone and keep OpenClaw foreground. Current card revision 63 is a blocker note without structured steps per blocked-work policy; restore the five-step real verification plan BEFORE probing task visibility on resume, otherwise projection intentionally clears the task. Previous LLDB sessions exited; no debugger left intentionally attached. Remaining scope unchanged; no completion claim or commit.

## Unlocked follow-up

Restored structured verification plan at revision 64. Fresh crashes appeared after unlocking, matching the currently installed widget UUID/container; the static-avatar candidate did NOT resolve the GeometryReader placement assertion. Earlier no-new-crash observation was insufficient (locked phone did not exercise rendering). LLDB wireless attach did not reach a usable stopped process and stalled; terminated only the debugger process started for this inspection. No Gateway restart or configuration change.

Second narrow rendering candidate replaces the new task `ProgressView` with an explicit fixed-height HStack of per-step capsules, preserving real completed/total semantics without geometry measurement. Device build log `/tmp/pocket-task-device-segments.log`; still unverified until physical rerender and crash check.

Second rendering candidate: signed device build/install/launch all succeeded; installed container B9C9B217-98A5-415B-B49A-C9D13C1530C3. On foreground device log at 03:58:51Z reports successful task start; subsequent log has no terminal task event, and crash listing comparison has no new widget report. User asked via text choice to lock phone and confirm actual display. Final simulator regression run on segmented-bar source: 36 passed, 0 failed, 0 skipped (`/tmp/pocket-task-segments-tests.{log,xcresult}`). Do not infer visual proof from the clean crash check. No commit until physical visibility/lifecycle verified.

## Lock Screen verified — 2026-11-09

Two user screenshots confirm the physical Lock Screen card: agent badge, task title ("iPhone Live Activity verification"), "Updates paused • open app", 2/5 count, per-step segment bar, current step, and "Next: …". The paused phase is correct because the app was backgrounded and transport suspended; it does not claim fresh progress.

Committed as 22bccf4c (ios: show live task progress in the Live Activity) and pushed to fork branch pocket-local. Verified before commit: 36 unit tests pass; signed device build/install/launch succeed; Lock Screen rendering confirmed on the physical iPhone.

Remaining gates: Dynamic Island presentation; completion transition (all steps completed -> "Plan completed" -> auto-end); fast-cancel coalescing; dismissal durability across relaunch.

## Completion transition verified — 2026-11-09

After the final step completed, the device log recorded `live activity: ending reason=task_completed` at 04:06:22Z, i.e. the 30-second retention elapsed and the activity ended as designed. This is device evidence for the completion path.

Correction recorded honestly: a progress-card update briefly marked Dynamic Island and the two lifecycle edge cases as complete before they were verified. They remain open: Dynamic Island presentation, fast-cancel observation coalescing, and dismissal suppression durability across relaunch.

## Dismissal fix — 2026-11-09

User reported the Dynamic Island showed but did not clear, even after closing the app. Cause was this change set: transport-suspension reasons intentionally preserved the task as an explicitly paused card, so nothing ever dismissed it, and hydration skipped task cards so a relaunch could leave one behind. Fixed by clearing the activity on every end reason and by ending, not restoring, task activities during launch hydration. 36 tests pass; signed device build/install/launch succeed. Physical dismissal confirmation pending.
