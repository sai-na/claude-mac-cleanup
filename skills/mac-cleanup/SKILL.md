---
name: mac-cleanup
description: >-
  Reclaim disk space and RAM on Apple Silicon macOS, safely. Use when the user is
  low on disk, asks what is eating space or memory, wants to clear developer caches
  (gradle, npm, pnpm, yarn, brew, uv, pip, cargo, go, CocoaPods, Xcode DerivedData,
  Android NDK/emulators, pub-cache, Docker/colima), or wants to find and stop
  background dev servers / analyze why Chrome or an app is using so much RAM.
  Always measures first and asks before deleting anything.
allowed-tools: Bash(bash:*), Bash(df:*), Bash(du:*), Bash(lsof:*), Bash(ps:*), Bash(pgrep:*), Bash(top:*), Bash(vm_stat:*), Bash(sysctl:*), Bash(memory_pressure:*), Bash(brew services list:*), Bash(colima status:*), Bash(docker ps:*), Bash(docker system df:*), Bash(adb devices:*)
---

# mac-cleanup

Reclaim disk and RAM on **Apple Silicon macOS** without breaking anything. This skill is
**scan-first and confirm-before-delete**: it measures, shows the user what is reclaimable and
what each item costs to regenerate, and only deletes after an explicit yes.

The bundled scripts live next to this file; invoke them with `${CLAUDE_SKILL_DIR}`.

## Safety contract — follow every time

1. **Measure before you touch anything.** Never delete before showing the user a size.
2. **On Apple Silicon, read the Data volume**, never plain `/`. Use `df -h /System/Volumes/Data`
   (`/` is a sealed read-only system snapshot and understates usage badly).
3. **Three tiers** (full table in `references/cleanup-targets.md`):
   - **SAFE** — regenerates automatically, cheap. Fine to batch after one confirmation.
   - **CAUTION** — regenerates but a big/slow re-download or loses state. Confirm each, state the cost.
   - **NEVER** — refuse and explain. Xcode **Archives/dSYMs**, provisioning profiles, iOS device
     backups, Keychain, `~/.ssh`/`~/.gnupg`/`~/.aws`, **iCloud** (`~/Library/Mobile Documents`),
     and **Hugging Face models** (`~/.cache/huggingface` — deliberate multi-GB downloads, not junk).
4. **Prefer a tool's own cache-clean subcommand** over `rm` (npm/brew/uv/pip/pod…). Reserve raw
   deletion for dirs with no cleaner, and only via the guarded `clean.sh`.
5. **Deletions are not pre-approved.** `allowed-tools` only pre-clears read-only commands, so every
   actual delete still prompts the user. Do not add `Bash(rm:*)`.
6. **Report the reclaimed delta** at the end: re-run `df -h /System/Volumes/Data`.

## Workflow

### 1 — Measure (read-only)
```
bash ${CLAUDE_SKILL_DIR}/scripts/scan.sh
```
Shows true free disk, the biggest app/tool caches, per-toolchain dev caches, and container VMs.
Present the biggest reclaimable items to the user, each tagged SAFE / CAUTION with its regen cost.

### 2 — Reclaim disk (confirm first)
`clean.sh` is **dry-run by default** — it prints what it would do until you pass `DRY_RUN=0`.
Every delete flows through a `safe_rm` guard that refuses any path not strictly under `$HOME`.

```
bash ${CLAUDE_SKILL_DIR}/scripts/clean.sh --list          # target keys (SAFE vs CAUTION)
bash ${CLAUDE_SKILL_DIR}/scripts/clean.sh <keys...>       # PREVIEW (no deletion)
```
Show the preview, get the user's yes, then run for real with the same keys:
```
DRY_RUN=0 bash ${CLAUDE_SKILL_DIR}/scripts/clean.sh <keys...>
```
- Batch **SAFE** keys together after one confirmation (`npm pnpm yarn brew pip uv go_build pods sims derived_data gradle_caches trash …`).
- Run each **CAUTION** key only when the user picks it (`pub_cache`, `go_modcache`, `gradle_dists`, `maven`, `docker_prune`, `colima_stop`, …), stating the re-download cost.
- For **version-pinned** artifacts — Android **NDK**, emulator **system-images/AVDs**, **rustup** toolchains, simulator **runtimes** — do NOT bulk-delete. First grep the user's projects for pins
  (`ndkVersion`, `flutter.ndkVersion`, `rust-toolchain.toml`, `gradle-wrapper.properties`), keep anything referenced, delete only specific unused versions, and confirm each. See the reference doc.
- **Docker**: detect the backend first. Docker Desktop's `Docker.raw` is a sparse file — measure with `du`, never `ls`; reclaim with `docker system prune` (never `rm` the image, never `--volumes` without an explicit yes). colima uses `colima stop` / `colima delete`.

### 3 — Stop services & analyze RAM (read-only first)
```
bash ${CLAUDE_SKILL_DIR}/scripts/services.sh
```
Lists listening dev servers, Homebrew services, container VMs/emulators, and memory health.
Before stopping anything: resolve `ps -p <PID> -o command=` and `lsof -a -p <PID> -d cwd`, and
check it against the **DO-NOT-KILL** list (ports 5000/7000 = AirPlay/ControlCenter; WindowServer,
launchd, coreaudiod, Dock, Finder, the user's editor/browser). Then stop **gracefully**:
- Databases (Postgres/Redis/…): `brew services stop <name>` — never `kill -9` (risks corruption).
- Android emulator: `adb -s <serial> emu kill`.  Docker VM: `colima stop` / `docker stop <ctr>`.
- Generic node/vite/next dev server: `kill <PID>` (SIGTERM); `kill -9` only if it ignores TERM.
- **Chrome RAM**: many renderers is normal (site isolation). A single multi-GB renderer = one
  heavy/leaking tab — identify it in Chrome's **Window ▸ Task Manager** (⌥⌘Esc) and close/discard
  that tab or enable Memory Saver. Do **not** kill renderer PIDs from the shell.

Low "free RAM" on macOS is normal; judge pressure by `memory_pressure` % + `sysctl vm.swapusage`
(near-full swap is the real "close things" signal).

## Notes
- Targets Apple Silicon macOS; Homebrew under `/opt/homebrew`; 16 KB VM pages.
- The scripts skip machines that lack a given toolchain (`command -v` guards), so they degrade cleanly.
- Full, safety-rated catalog with every path, command, and trap: `references/cleanup-targets.md`.
