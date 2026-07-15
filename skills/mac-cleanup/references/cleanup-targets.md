# macOS cleanup targets — full safety-rated catalog

Everything the `mac-cleanup` skill knows about, with the path, the command (prefer the tool's own
cache-clean subcommand over `rm`), typical size, and a safety tier. Tiers:

- **SAFE** — regenerates automatically, cheap to rebuild.
- **CAUTION** — regenerates, but a big/slow re-download or loses local state. Confirm each; state the cost.
- **NEVER** — non-regenerable data. Refuse; only ever move to a backup, never delete.

> **Apple Silicon disk gotcha:** measure the Data volume, not `/`. `df -h /` shows the sealed,
> read-only system snapshot and dramatically understates usage. Always `df -h /System/Volumes/Data`.
> Time Machine local APFS snapshots + "purgeable" space can also make free space look larger than it is
> (`tmutil listlocalsnapshots /`; thin with `sudo tmutil thinlocalsnapshots / <bytes> 4`).

## Measure (read-only)

| What | Command |
|---|---|
| True free disk | `df -h /System/Volumes/Data` |
| Biggest caches | `du -sh ~/Library/Caches/* ~/.cache/* 2>/dev/null \| sort -rh \| head -30` |
| Home top-level hogs | `sudo du -xh -d1 ~ 2>/dev/null \| sort -rh \| head -30` (excludes iCloud — see below) |
| node_modules sweep | `find . -type d -name node_modules -prune -print0 \| xargs -0 du -sh \| sort -rh` (or `npx npkill`) |

## SAFE — regenerate automatically

| Target | Path | Command | Notes |
|---|---|---|---|
| npm cache | `~/.npm` | `npm cache clean --force` | `--force` is expected here. |
| pnpm store | `~/Library/pnpm/store`, `~/.local/share/pnpm/store` | `pnpm store prune` | Removes only packages no project references. |
| Yarn (classic) | `~/Library/Caches/Yarn` | `yarn cache clean` | Berry: `yarn cache clean --all`; never delete a project's committed `.yarn/cache` (Zero-Installs). |
| Homebrew | `~/Library/Caches/Homebrew` | `brew cleanup -s` | `brew cleanup --prune=all` scrubs everything; `-n` previews. |
| pip | `~/Library/Caches/pip` | `pip cache purge` | |
| uv | `~/.cache/uv` / `~/Library/Caches/uv` | `uv cache clean` | `uv cache prune` = only unused entries. |
| Go build cache | `~/Library/Caches/go-build` | `go clean -cache` | |
| CocoaPods download cache | `~/Library/Caches/CocoaPods` | `pod cache clean --all` | `--all` required with no pod name. `pod install` restores from `Podfile.lock`. |
| Unavailable simulators | — | `xcrun simctl delete unavailable` | Sims whose runtime is gone; they can't boot anyway. |
| Xcode DerivedData | `~/Library/Developer/Xcode/DerivedData` | delete + recreate dir | Often 20–50 GB. Rebuilds/reindexes on next build. No first-party cleaner. |
| CoreSimulator caches | `~/Library/Developer/CoreSimulator/Caches` | delete dir | dyld sim caches; safe. |
| Gradle dep caches | `~/.gradle/caches` | delete dir | **Stop daemons first** (see caveat). Re-downloads deps next build. |
| Gradle wrapper junk | `~/.gradle/wrapper/dists/gradle-REPLACEME-*` | delete those dirs | Corruption artifacts of a broken `distributionUrl`; always safe. |
| Trash | `~/.Trash/*` | delete contents | Permanent delete of already-trashed items. Delete the *contents*, not the dir. External drives: `/Volumes/<name>/.Trashes`. |

## CAUTION — regenerate, but costly or lose state

| Target | Path | Command | Why caution |
|---|---|---|---|
| Flutter/Dart pub cache | `~/.pub-cache` | `dart pub cache clean` | **Also wipes globally-activated Dart CLIs** (`dart pub global activate` — fvm, melos, very_good_cli). Re-activate each after. |
| Go module cache | `~/go/pkg/mod` | `go clean -modcache` | Files are read-only; use the subcommand, not `rm`. Re-downloads all modules. |
| Gradle distributions | `~/.gradle/wrapper/dists` | delete dir | Each project's wrapper re-downloads its pinned distro (~100–200 MB). Often **larger** than `caches/`. |
| Maven repo | `~/.m2/repository` | `rm -rf ~/.m2/repository` | Delete **only** `repository/` — never `~/.m2/settings.xml` (creds/mirror/proxy). Surgical: `mvn dependency:purge-local-repository`. |
| Bun cache | (from `bun pm cache`) | `bun pm cache rm` | Path is overridable (`BUN_INSTALL_CACHE_DIR`/bunfig) — resolve with `bun pm cache` first. |
| Cargo registry | `~/.cargo/registry`, `~/.cargo/git` | `cargo cache --autoclean` (crate `cargo-cache`) | Re-downloads crates. Rust ≥1.88 auto-GCs this. Per-project: `cargo clean`. |
| Xcode iOS DeviceSupport | `~/Library/Developer/Xcode/iOS DeviceSupport` | delete dir (note the space) | Re-copied (minutes) next time you connect a device on that iOS version. Also watchOS/tvOS variants. |
| Simulator runtimes | — | `xcrun simctl runtime list && … delete <id>` | Each iOS/watchOS runtime is multi-GB to re-download. |
| Homebrew unused deps | — | `brew autoremove` | **Uninstalls software** (not cache). Preview with `brew autoremove -n`. |

## Version-pinned — never bulk-delete; keep what projects pin

Grep the user's projects first and keep any referenced version. Delete only specific unused ones, confirm each.

| Target | Path | Keep if pinned by | Remove |
|---|---|---|---|
| Android NDK | `~/Library/Android/sdk/ndk/<version>` | `android { ndkVersion }`, `flutter.ndkVersion` | `sdkmanager --uninstall "ndk;<version>"` or delete the specific version subdir (never the `ndk` parent). |
| Android system-images | `~/Library/Android/sdk/system-images/...` | any AVD built on it | `sdkmanager --uninstall "system-images;android-XX;..."` — only images with no AVD. |
| Android AVDs | `~/.android/avd` | — | `avdmanager delete avd -n <name>`. Often the biggest Android hog (per-AVD snapshots). Kill a running one first: `adb -s emulator-5554 emu kill`. |
| rustup toolchains | `~/.rustup/toolchains/<name>` | `rust-toolchain.toml`, and the `(active, default)` one | `rustup toolchain uninstall <name>` (`remove` is an alias). Removing the default silently leaves no default — fix with `rustup default stable`. Distinct from `~/.cargo`. |

## Containers — detect the backend first

> **This skill only ever does the *safe* Docker reclaim** — never anything that can lose data. It
> distinguishes **images/build cache/stopped containers** (re-creatable — re-pulled or rebuilt on
> demand) from **named volumes and the VM itself** (where databases keep their real data). The
> data-losing commands below are listed **only so the skill refuses them**; it does not offer or run
> them as "cleanup."

### colima
| Command | Effect | The skill's stance |
|---|---|---|
| `colima stop` | Stops the VM; frees RAM + releases in-use disk | ✅ Safe — reversible with `colima start`. This is the only colima action the skill runs. |
| `colima delete` | Destroys the VM: **all** containers, images, **and volumes** | ❌ **Data loss — the skill never runs this and does not present it as cleanup.** |

Disk lives under `~/.colima`. The VM disk is sparse and **does not shrink** from `colima stop` or
`docker prune`, so that space is **not safely reclaimable** — leave it. `colima status` exits
non-zero with "colima is not running" when stopped — treat as already-stopped, not an error.

### Docker Desktop
Detect: `/Applications/Docker.app` **and** `~/Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw` exist. `Docker.raw` is **one sparse disk image** holding every image/container/volume/build-cache; it only grows and often reaches 30–60 GB+.

**Safe reclaim (no data loss) — what the skill does:**
| Command | Effect |
|---|---|
| `du -sh …/Docker.raw` | REAL size (never `ls`/Finder — they show the apparent max) |
| `docker system df [-v]` | What's reclaimable inside the VM (daemon must be running) |
| `docker system prune` | Stopped containers, dangling images, unused networks, build cache — **no volume loss** |
| `docker builder prune` | Build cache only |
| `docker image prune -a` | All unused images — re-pullable, so no data loss (just a re-download later) |
| `docker run --privileged --pid=host docker/desktop-reclaim-space` | Shrinks `Docker.raw` after a prune (fstrim); deletes nothing |

**❌ Data loss — the skill never does these, and won't suggest them as cleanup:**
- `docker system prune -a --volumes` — `--volumes` erases named volumes = your DB data.
- `rm …/Docker.raw`, the Settings disk-size slider, Troubleshoot ▸ Clean/Purge — wipe **everything**.
- To reclaim a volume's space you must first back it up, then remove it deliberately — that's a manual
  decision, not a cleanup step:
  `docker run --rm -v <vol>:/data -v "$PWD":/backup alpine tar czf /backup/<vol>.tgz /data`

## NEVER — refuse and explain

| Path | Why |
|---|---|
| `~/Library/Developer/Xcode/Archives` | `.xcarchive` + **dSYMs** to symbolicate crash reports of shipped app versions. Irreplaceable. |
| `~/Library/MobileDevice/Provisioning Profiles` | Signing profiles. |
| `~/Library/Application Support/MobileSync/Backup` | iOS device backups — huge but irreplaceable user data. |
| `~/Library/Mobile Documents` and iCloud Drive/Desktop/Documents | **iCloud dataless placeholders.** `du` reads them as ~0 (they don't hold content), but deleting a placeholder deletes the real cloud copy on every device. Also **exclude from `du` sweeps** — traversal can materialize (re-download) dataless folders. Use `du … -I "Mobile Documents"`. |
| `~/.cache/huggingface` (and `ms-playwright`, `puppeteer`, `torch`) | Deliberate multi-GB model/browser/weight downloads that merely live under `~/.cache`. Inspect with `hf cache ls` before touching; never lump into a generic cache wipe. |
| `~/.ssh`, `~/.gnupg`, `~/.aws`, `~/.config/*` creds, Keychains | Credentials. |
| `~/Downloads` | User data — report large/old files for manual review only. |

## Caveats that bite

- **Gradle daemons:** deleting `~/.gradle/caches` while a daemon holds locks corrupts the cache.
  `./gradlew --stop` only stops the matching version; with multiple Gradle versions installed use
  `pkill -f '[G]radleDaemon'` after quitting Android Studio/IntelliJ. Check with `pgrep -fl GradleDaemon`.
- **App caches are locked while the app runs** (Chrome's `~/Library/Caches/Google` clears only
  partially with Chrome open). Quit the app for a full clean.
- **Never `sudo rm`** in a cleanup path — it turns an empty-variable slip from user-scoped into
  system-scoped disaster. The only legitimate `sudo` here is `tmutil` snapshot thinning.
- **`docker system prune --volumes` / `colima delete` / deleting `Docker.raw`** = permanent data loss
  (named volumes hold DB data; `colima delete` takes the whole VM). The skill treats these as
  off-limits — it does the safe prune only, and never pitches the VM's disk as reclaimable.
