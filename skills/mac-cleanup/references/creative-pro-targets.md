# Creative-pro cleanup targets — video, photo, audio, 3D

Reclaimable space for non-developers. **Read the golden rules first — creative caches are the most
dangerous category in this whole skill**, because every app stores its regenerable cache *inside or
right next to* your irreplaceable originals, catalogs, and projects.

## Golden rules (apply to everything below)

1. **Prefer the app's own "purge / delete cache" command over deleting files.** It only ever touches
   regenerable data and there's no path to mistype. This is always the first choice.
2. **Never reach inside a library/package bundle** to reclaim cache: `.fcpbundle`, `.photoslibrary`,
   `.cocatalog`, `.logicx`, `<Catalog>.lrcat*`. The cache and the *only copy of your work* live in
   the same bundle. Use the app's purge instead.
3. **Move to Trash, don't `rm`.** For a non-developer these deletions should be *recoverable*. Prefer
   `trash <path>` (or Finder "Move to Trash") so a mistake can be undone. Reserve raw `rm` for pure
   dev caches with no user data nearby.
4. **Caches are user-relocatable.** Most of these apps let you point the cache at an external/second
   drive. Read the *configured* path from the app's preferences — don't assume the default — and make
   sure that volume is **mounted** before deleting (an unmounted relocated cache means you'll hit the
   wrong tree).
5. **Quit the app first.** Deleting a live cache/scratch file can corrupt the open document/project.

Tiers: **SAFE** = regenerates cheaply · **CAUTION** = regenerates but slow re-transcode/re-download or
loses recovery state · **NEVER** = irreplaceable work; refuse.

---

## 🎬 Video editing

| App | Item | Path | Tier | How |
|---|---|---|---|---|
| **Final Cut Pro** | Render files | inside `~/Movies/*.fcpbundle` | 🟢 Safe | **In app:** File ▸ Delete Generated Library Files ▸ *Render Files*. No safe CLI. |
| Final Cut Pro | Optimized (ProRes) media | inside `.fcpbundle` | 🟡 Caution | In app: …▸ *Optimized Media*. Often the biggest bucket — larger than the source; slow to re-transcode. |
| Final Cut Pro | Proxy media | inside `.fcpbundle` | 🟡 Caution | In app: …▸ *Proxy Media*. |
| Final Cut Pro | **Original Media / library DB** | `.fcpbundle/*/Original Media/` | 🔴 Never | Managed imports = your only copy, in the *same bundle* as the caches above. |
| **Adobe** (Pr/Ae/Me) | Media Cache Files + Database | `~/Library/Application Support/Adobe/Common/Media Cache Files` + `…/Media Cache` | 🟢 Safe | **In app:** Settings ▸ Media Cache ▸ *Delete Unused*. The classic Adobe disk hog (grows unbounded). |
| Adobe (shared) | Peak Files (`.pek` waveforms) | `~/Library/Application Support/Adobe/Common/Peak Files` | 🟢 Safe | Quit Adobe apps; Trash the folder contents. |
| After Effects | Disk Cache | `~/Library/Caches/Adobe/After Effects/<ver>` (relocatable) | 🟢 Safe | **In app:** Preferences ▸ Media & Disk Cache ▸ *Empty Disk Cache*. Can silently be 100+ GB. |
| Premiere / AE | **Auto-Save** project copies | `~/Documents/Adobe/*/…Auto-Save/` | 🟡 Caution | Crash-recovery copies of your `.prproj`/`.aep`. Keep the newest few; trim only old ones. |
| Adobe (shared) | **Motion Graphics Templates** (`.mogrt`) | `~/Library/Application Support/Adobe/Common/Motion Graphics Templates` | 🔴 Never | *Looks* like cache, sits right beside Media Cache — but it's installed/purchased templates. |
| **DaVinci Resolve** | Render cache (CacheClip) | `<Media Storage vol>/…/CacheClip` (relocatable; often `~/Movies`) | 🟢 Safe | **In app:** Playback ▸ Delete Render Cache ▸ All/Unused. Verify the path in Project Settings ▸ Working Folders. |
| DaVinci Resolve | Fusion disk cache | `~/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/DiskCache` | 🟢 Safe | Quit Resolve; Trash only the `DiskCache` folder. |
| DaVinci Resolve | Optimized/Proxy media | `…/OptimizedMedia`, `…/ProxyMedia` | 🟡 Caution | In app: Media Pool ▸ right-click ▸ Delete Optimized/Proxy Media. |
| DaVinci Resolve | **Gallery stills / PowerGrades** | `~/Movies/.gallery` (beside CacheClip!) | 🔴 Never | Your saved grades — same folder tree as the safe cache. |
| DaVinci Resolve | **Project Library (disk DB)** | `~/Library/Application Support/Blackmagic Design/DaVinci Resolve/Resolve Project Library` | 🔴 Never | Every project. Deleting it erases all projects not exported as `.drp`. |
| **Avid Media Composer** | Index/UI caches | `/Users/Shared/AvidMediaComposer/` (AvidImageCache, etc.) | 🟢 Safe | Quit Avid; delete those cache subfolders — they rebuild on launch. |
| Avid | **MXF source media** | `/Volumes/*/Avid MediaFiles/MXF/<n>/` | 🔴 Never | Source *and* deletable renders are commingled in one folder — use the in-app Media tool, never `rm`. |

> **Traps:** FCP originals live *inside* the `.fcpbundle` next to Render Files. Premiere writes preview
> files into the *same folder as the `.prproj` and your exports* by default. Optimized/proxy media is
> often **bigger than the original footage**, so it shows up as the largest "media" — still Caution, not Safe.

## 📷 Photography

| App | Item | Path | Tier | How |
|---|---|---|---|---|
| **Lightroom Classic** | Camera Raw cache | `~/Library/Caches/Adobe Camera Raw*` (version-suffixed; relocatable, often 20–100 GB) | 🟢 Safe | **In app:** Settings ▸ Performance ▸ Camera Raw Cache ▸ *Purge Cache*. |
| Lightroom Classic | Previews (`Previews.lrdata`, esp. 1:1) | `~/Pictures/Lightroom/<Catalog> Previews.lrdata` (beside the `.lrcat`) | 🟡 Caution | **In app:** Library ▸ Previews ▸ *Discard 1:1 Previews*. If deleting, Trash **by exact name** — never a glob of the parent. |
| Lightroom Classic | Smart Previews | `…/<Catalog> Smart Previews.lrdata` | 🟡 Caution | Not thumbnails — they let you edit while originals are offline. In app: Discard Smart Previews. |
| Lightroom Classic | **Catalog** (`.lrcat`, `.lrcat-data`, Backups) | `~/Pictures/Lightroom/<Catalog>.lrcat*` | 🔴 Never | Every edit, keyword, rating, AI mask. Same folder as the deletable previews. |
| **Photoshop** | Scratch temp (`Photoshop Temp*`) | `$TMPDIR` / scratch volume root | 🟢 Safe (PS quit) | A clean quit auto-deletes them; only crash-orphans persist. Never delete while PS is running. |
| Photoshop | **AutoRecover** | `~/Library/Application Support/Adobe/Adobe Photoshop 2026/AutoRecover` | 🟡 Caution | Sole copy of unsaved work after a crash. Only clear with PS quit and nothing unsaved. |
| **Adobe Bridge** | Thumbnail/preview cache | `~/Library/Caches/Adobe/Bridge*/Cache` | 🟢 Safe | **In app:** Preferences ▸ Cache ▸ Purge Cache. |
| **Capture One** | Cache (Proxies/Previews/Thumbnails) | catalog: *inside* `<Catalog>.cocatalog/Cache`; session: `<Session>/CaptureOne/Cache` | 🟢 Safe | Quit; Trash **only the `Cache` subfolder**. Deleting the `.cocatalog` bundle destroys all edits. |
| Capture One | **Catalog / Session DB + originals** | `<Catalog>.cocatalog`, session `Capture/`, `Output/` | 🔴 Never | Edits, variants, masks, and shot originals. |
| **Apple Photos** | Derivatives/thumbnails | *inside* `~/Pictures/Photos Library.photoslibrary` | 🟡 Caution | **Only** via Photos: quit, relaunch holding ⌘⌥, click *Repair*. Never `rm` into the bundle. |
| Apple Photos | **Library (originals + DB)** | `~/Pictures/Photos Library.photoslibrary/originals` | 🔴 Never | Masters + edits. To free space use System Settings ▸ iCloud ▸ *Optimize Mac Storage* (macOS evicts safely). |

> **Traps:** `.xmp` sidecar files next to raws are **your edits**, not cache. The iCloud `originals/`
> folder may hold the only full-res copy of a still-uploading photo — let macOS evict via *Optimize
> Mac Storage*, never hand-delete.

## 🎹 Music / audio

| App | Item | Path | Tier | How |
|---|---|---|---|---|
| **Logic / GarageBand** | Downloaded Sound Library (loops, samplers, Alchemy) | `/Library/Application Support/Logic` · `/Library/Audio/Apple Loops` | 🟡 Caution | Free re-download but ~72 GB full set. **Better: Logic ▸ Sound Library ▸ Relocate** to an external drive, don't delete. |
| Logic | App cache / bounce scratch | `~/Library/Caches/com.apple.logic10` | 🟢 Safe | Trash it; empty Trash after bounces. |
| Logic | **Track freeze / Undo** | inside `~/Music/Logic/<Project>.logicx` | 🟡 Caution | Un-freeze the track in Logic. Never hand-delete inside the `.logicx`. |
| All AU hosts | Audio Unit scan cache | `~/Library/Caches/AudioUnitCache` | 🟢 Safe | Rebuilt on next AU scan. |
| **Ableton Live** | Decoding cache | `~/Library/Caches/Ableton/Cache` | 🟢 Safe | **In app:** Settings ▸ Library ▸ Decoding Cache ▸ Cleanup. |
| Ableton Live | Factory/Core Packs | `~/Music/Ableton/Factory Packs` | 🟡 Caution | Owned, re-downloadable from your account. |
| Ableton Live | **User Library** | `~/Music/Ableton/User Library` | 🔴 Never | Your presets/racks/grooves — right beside Factory Packs. |
| **Pro Tools** | Volume waveform/index DB | `/Library/Application Support/Digidesign/Databases/Unicode/Volumes` | 🟢 Safe | Quit PT; delete **only the `Volumes` child** — it rebuilds. |
| Pro Tools | **DigiBase Catalogs** | `…/Digidesign/Databases/Unicode/Catalogs` | 🔴 Never | User-created media libraries — nested *inside* the otherwise-safe Databases folder. Never delete the parent. |
| Pro Tools | Per-session WaveCache / Fade Files | `<Session>/WaveCache.wfm`, `Fade Files/` | 🟡 Caution | Regenerate, but sit beside your recordings + `Session File Backups` (Never). |
| **Kontakt/NI, Spitfire, EastWest** | Installed sample libraries | `/Users/Shared/…`, app-configured content path | 🟡 Caution | Owned, free re-download but 20 GB–1 TB. **Relocate to external** rather than delete. |
| **All DAWs** | **Projects / recordings / user presets** | `*.logicx/.als/.ptx`, `Audio Files/`, `~/Music/Audio Music Apps` | 🔴 Never | The actual work + custom recordings that exist on no server. |

> **Traps:** `~/Music/Audio Music Apps` looks like disposable app-support but holds your custom
> patches/Sampler instruments. Freeze files land in the project's `Samples` folder next to recorded
> audio — use the DAW's *Manage Files ▸ Unused Samples*, not Finder.

## 🧊 3D / VFX / motion

| App | Item | Path | Tier | How |
|---|---|---|---|---|
| **Blender** | Temp/scratch | `$TMPDIR/blender_*`, `/tmp/blender_*` | 🟢 Safe (Blender quit) | Preserve any `quit.blend`/autosave you might need. Config lives elsewhere (`~/Library/Application Support/Blender` — **not** cache). |
| Blender | Physics/sim bake | `blendcache_*/` next to the `.blend` | 🟡 Caution | In app: Physics ▸ Cache ▸ *Free All Bakes*. |
| **Houdini** | `HOUDINI_TEMP` scratch | `/tmp/houdini_temp` (or `HOUDINI_TEMP_DIR` in `houdini.env`) | 🟢 Safe | Resolve the configured path first; quit Houdini; delete contents. |
| **Cinema 4D / Redshift** | Converted texture cache (`.rstexbin`) | `~/redshift/` or `REDSHIFT_CACHEPATH` | 🟢 Safe | **In app:** Redshift ▸ Clear Baked Textures. Resolve the configured path. |
| **Arnold** | `.tx` texture cache | *next to each source texture* | 🟡 Caution | Only remove `*.tx` where a same-name source (`.exr/.png`) exists beside it; regenerates via auto-tx. |
| **Nuke** | Disk / localization cache | `/var/tmp/nuke-u<uid>` (or `NUKE_TEMP_DIR`) | 🟢 Safe | **In app:** Cache ▸ Clear Disk Cache. |
| Nuke | **`~/.nuke`** | `~/.nuke` | 🔴 Never | Your init.py/gizmos/prefs — config, not cache. |
| **Unreal** | Local DDC (Zen, UE 5.4+) | `~/Library/Application Support/Epic/Zen/Data` | 🟢 Safe | Quit editor; delete — Zen recreates it (auto-evicts after ~8 days). |
| Unreal | Per-project `Saved/{Cooked,StagedBuilds,Logs,Crashes}` | `<Project>/Saved/…` | 🟢 Safe | Delete only those four subfolders (keep `Saved/Autosaves`). |
| **Unity** | GI (lighting) cache | `~/Library/Caches/com.unity3d.UnityEditor/GiCache` | 🟢 Safe | **In app:** Preferences ▸ GI Cache ▸ Clean Cache. |
| Unity | Per-project `Library/`, `Temp/` | `<Project>/Library`, `<Project>/Temp` | 🟡 Caution | Close Unity; delete — full reimport on next open. |
| **Substance 3D Painter** | Baking/compute cache | `~/Library/Caches/Adobe/Substance Painter` | 🟢 Safe | **In app:** Preferences ▸ Cache ▸ Clear Cache. |

## 💬 General apps (every profession)

| App | Item | Path | Tier | Notes |
|---|---|---|---|---|
| **Chromium browsers** | Cache/Code Cache/GPUCache/Service Worker/Dawn* | `~/Library/Caches/Google/Chrome/*/{Cache,Code Cache}` + `~/Library/Application Support/Google/Chrome/*/{GPUCache,Service Worker,Dawn*Cache}` | 🟢 Safe | **Prefer** ⌘⇧⌫ ▸ *Cached images and files only*. Never `rm` the profile folder (bookmarks/passwords/cookies live there). Service Worker is usually the biggest. |
| Safari/Firefox | HTTP cache | `~/Library/Containers/com.apple.Safari/Data/Library/Caches` · `~/Library/Caches/Firefox` | 🟢 Safe | Quit the browser first. |
| **Spotify** | Streaming cache | `~/Library/Application Support/Spotify/PersistentCache` | 🟡 Caution | Mixed with Premium **offline downloads** — clearing forces re-download. |
| **Slack/Teams/Discord/Zoom** | App caches | `~/Library/Application Support/<app>/…Cache`, `~/Library/Caches/<app>` | 🟢 Safe | Zoom **recordings** default to `~/Documents/Zoom` = Never. |
| WhatsApp / Telegram | Media | app data | 🟡 Caution | Telegram re-downloads from cloud (safe); **WhatsApp media may exist only locally** — user review. |
| **Apple Messages / Mail** | `Attachments`, message store | `~/Library/Messages`, `~/Library/Mail/V*` | 🔴 Never | Original received media + your whole history. (Mail's separate *"Mail Downloads"* opened-attachment copies **are** safe.) |
| **QuickLook** | Finder thumbnail cache | private temp | 🟢 Safe | `qlmanage -r cache`. |
| **Time Machine** | Local APFS snapshots ("purgeable") | boot volume | 🟡 Caution | `tmutil listlocalsnapshots /`; thin with `sudo tmutil thinlocalsnapshots / <bytes> 4`. |
| **iOS device backups** | Local iPhone/iPad backups | `~/Library/Application Support/MobileSync/Backup` | 🟡/🔴 | May be the only backup of a lost/wiped device. Prune old ones via Finder ▸ Manage Backups, not `rm`. |
| **Adobe CC Files** / iCloud Drive / Dropbox | Synced placeholders | various | 🔴 Never (unsynced) | May be the only copy of a not-yet-synced file. Verify sync status first. |

> Dev caches for these same users (Xcode DerivedData, Homebrew/npm/pip/CocoaPods/Gradle, Docker) are in
> the developer catalog: [`cleanup-targets.md`](cleanup-targets.md).
