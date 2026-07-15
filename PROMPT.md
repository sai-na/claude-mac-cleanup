# Standalone prompt — Mac disk & RAM cleanup

Paste everything in the block below into Claude Code (or any capable coding agent with shell
access) when you want to reclaim disk space and RAM on an **Apple Silicon Mac**. It encodes the
same measure-first, confirm-before-delete workflow as the skill.

---

```
You are helping me safely reclaim disk space and RAM on my Apple Silicon Mac. Follow this
workflow exactly. Be conservative: measure first, and NEVER delete anything without showing me
the size and getting my explicit confirmation.

RULES
- On Apple Silicon, read the TRUE free space from the Data volume: `df -h /System/Volumes/Data`.
  Never use plain `df -h /` — it is a sealed read-only snapshot and understates usage.
- Classify every target as:
  SAFE    = regenerates automatically, cheap (fine to batch after one confirmation)
  CAUTION = regenerates but a big/slow re-download or loses state (confirm each, state the cost)
  NEVER   = refuse. This includes: Xcode Archives/dSYMs (~/Library/Developer/Xcode/Archives),
            provisioning profiles, iOS backups (~/Library/Application Support/MobileSync/Backup),
            credentials (~/.ssh, ~/.gnupg, ~/.aws, Keychain), iCloud (~/Library/Mobile Documents),
            and Hugging Face / ML model caches (~/.cache/huggingface, ms-playwright, puppeteer,
            torch) — these are deliberate multi-GB downloads, not junk.
- Prefer each tool's own cache-clean subcommand over `rm`. Only fall back to `rm -rf` for dirs
  with no cleaner, and only on an absolute path strictly under $HOME (never with sudo).
- Exclude iCloud from `du` sweeps (it can force re-downloads): `du ... -I "Mobile Documents"`.

STEP 1 — MEASURE (read-only, no deletion)
  df -h /System/Volumes/Data
  du -sh ~/Library/Caches/* ~/.cache/* 2>/dev/null | sort -rh | head -20
  du -sh ~/.gradle/caches ~/.gradle/wrapper/dists ~/.npm ~/.m2/repository ~/.cargo/registry \
        ~/.rustup/toolchains ~/go/pkg/mod ~/.pub-cache \
        ~/Library/Developer/Xcode/DerivedData "~/Library/Developer/Xcode/iOS DeviceSupport" \
        ~/Library/Android/sdk/ndk ~/Library/Android/sdk/system-images ~/.android/avd 2>/dev/null \
        | sort -rh
Report the biggest reclaimable items with a SAFE/CAUTION tag and the regen cost.

STEP 2 — RECLAIM (only after I confirm)
  SAFE (regenerate automatically):
    npm cache clean --force
    pnpm store prune ; yarn cache clean
    brew cleanup -s
    pip cache purge ; uv cache clean
    go clean -cache
    pod cache clean --all
    xcrun simctl delete unavailable
    rm -rf ~/Library/Developer/Xcode/DerivedData && mkdir -p ~/Library/Developer/Xcode/DerivedData
    # Gradle: stop daemons first, or the delete can corrupt the cache:
    pgrep -fl GradleDaemon    # if any, quit Android Studio/IntelliJ then: pkill -f '[G]radleDaemon'
    rm -rf ~/.gradle/caches
  CAUTION (confirm each — big re-download or state loss):
    dart pub cache clean          # also DE-ACTIVATES global Dart CLIs (fvm, melos) — re-activate after
    go clean -modcache            # re-downloads all modules
    rm -rf ~/.gradle/wrapper/dists
    rm -rf ~/.m2/repository       # ONLY the repository subdir, NEVER ~/.m2/settings.xml
  VERSION-PINNED (never bulk-delete — keep what projects reference):
    Android NDK / system-images / AVDs: grep projects for `ndkVersion` / `flutter.ndkVersion`,
      keep those, delete only specific unused versions (kill a running emulator: `adb -s <serial> emu kill`).
    rustup: keep the `(active, default)` toolchain and any `rust-toolchain.toml` pin;
      remove others with `rustup toolchain uninstall <name>`.
  DOCKER (detect backend first):
    Docker Desktop: measure Docker.raw with `du -sh` (NOT ls); reclaim with `docker system prune`.
      Never `rm` Docker.raw; never add `--volumes` without an explicit yes (it erases DB volumes).
    colima: `colima stop` (reversible) or `colima delete` (destroys the VM).

STEP 3 — CREATIVE-PRO / APP CACHES (most dangerous — caches sit next to originals)
  GOLDEN RULES: (a) prefer the app's OWN purge command; (b) NEVER reach inside a library bundle
  (.fcpbundle, .photoslibrary, .cocatalog, .logicx, <Catalog>.lrcat*); (c) move to Trash
  (recoverable) instead of rm for creative caches; (d) caches are relocatable — read the app's
  configured path and confirm the drive is mounted; (e) QUIT the app first.
  App-native purge (no safe filesystem command — tell the user the in-app steps):
    Final Cut Pro:   File > Delete Generated Library Files (Render/Optimized/Proxy)
    Premiere/AE:     Settings > Media Cache > Delete Unused; AE > Media & Disk Cache > Empty Disk Cache
    DaVinci Resolve: Playback > Delete Render Cache > All/Unused
    Lightroom:       Settings > Performance > Camera Raw Cache > Purge; Library > Previews > Discard 1:1
    Apple Photos:    quit, relaunch holding Cmd+Option, click Repair (never rm inside .photoslibrary)
    Logic:           Sound Library > Relocate (don't delete); un-freeze tracks in-app
    Pro Tools:       delete ONLY .../Digidesign/Databases/Unicode/Volumes — NEVER .../Unicode/Catalogs
  Standalone caches safe to move to Trash (app quit): ~/Library/Application Support/Adobe/Common/{Media Cache Files,Media Cache,Peak Files}
    (NOT 'Motion Graphics Templates'), ~/Library/Caches/Adobe/After Effects, ~/Library/Caches/Adobe Camera Raw*,
    ~/Library/Caches/Ableton/Cache, ~/Library/Caches/AudioUnitCache, ~/Library/Caches/<browser> (never the profile),
    ~/Library/Logs/DiagnosticReports, and `qlmanage -r cache`.
  NEVER: camera originals, catalogs (.lrcat/.cocatalog/.fcpbundle), DAW projects & recordings,
    ~/Music/Audio Music Apps, ~/Music/Ableton/User Library, Nuke ~/.nuke, Messages/Mail stores.

STEP 4 — SERVICES + RAM (read-only first, stop gracefully)
  lsof -nP -iTCP -sTCP:LISTEN            # port -> process; resolve with `ps -p <PID> -o command=`
  DO NOT KILL: ports 5000/7000 = AirPlay (ControlCenter); WindowServer, launchd, coreaudiod,
    Dock, Finder, my editor/browser. Stop DBs with `brew services stop <name>`, never kill -9.
  Android emulator: `adb -s <serial> emu kill`. Docker VM: `colima stop`. Node/vite/next: kill <PID>.
  RAM: `top -l 1 -o mem -n 12`, `memory_pressure` (no args!), `sysctl vm.swapusage`.
    Low free RAM is normal; near-full swap is the real "close things" signal.
  Chrome: many renderers is normal (site isolation). One multi-GB renderer = a heavy/leaking tab —
    find it in Chrome's Window > Task Manager (Option+Cmd+Esc) and close/discard it; don't kill PIDs.

STEP 5 — Report the reclaimed delta: re-run `df -h /System/Volumes/Data`.
```

---

> Full, safety-rated catalog with every path and trap:
> [`skills/mac-cleanup/references/cleanup-targets.md`](skills/mac-cleanup/references/cleanup-targets.md).
