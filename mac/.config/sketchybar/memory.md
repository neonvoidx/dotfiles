## [2026-09-17] SketchyBar crashes and workspace update fan-out
Context: SketchyBar 2.24.0 with AeroSpace 0.21.3-Beta on macOS 26.6.2.
Signal: SketchyBar exits and the bar sometimes flickers.
Root cause: September 16 and 17 DiagnosticReports both show SIGABRT with POINTER_BEING_FREED_WAS_NOT_ALLOCATED; other threads include __window_apply_frame_block_invoke. The exact native bug and trigger remain unconfirmed. AeroSpace starts SketchyBar directly, and no SketchyBar launchctl service was loaded at inspection.
Fix: Consolidated workspace icons, visibility, and highlights into one batch from a single bulk window query. Workspace items now handle clicks only; removed hover refreshes and workspace animations. Query failures preserve the previous render. Native crash mitigation remains unconfirmed.
Verification: Shell syntax and diff checks passed. A dry run against live AeroSpace state produced the expected ten-item batch; a failed query exited without rendering. Started SketchyBar and confirmed live icons/highlighting and survival through five refresh events. The remove/recreate logic in plugins/aerospace.sh is not wired to an active item by items/front_app.sh.
Reuse hint: Distinguish a native SketchyBar crash from AeroSpace triggering frequent updates. Check actual subscriptions before treating unused integration scripts as causes.
