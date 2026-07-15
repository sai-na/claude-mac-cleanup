#!/usr/bin/env bash
# clean.sh — reclaims disk by clearing regenerable caches.
#
# SAFETY MODEL (read before editing):
#   * DRY-RUN BY DEFAULT. It only PRINTS what it would do. Pass DRY_RUN=0 to actually delete.
#   * Every delete goes through safe_rm(), which refuses any path that is not a real,
#     absolute, canonical directory strictly under $HOME. An empty/unset variable can
#     therefore never expand into `rm -rf /`.
#   * Prefers each tool's own cache-clean subcommand (path-safe by construction) over rm.
#   * Only clears things that REGENERATE. It never touches user data, credentials,
#     Xcode Archives/dSYMs, iOS backups, iCloud, or HuggingFace models.
#
# USAGE:
#   bash clean.sh --list                 # show target keys
#   bash clean.sh <key> [key...]         # DRY-RUN (default): preview only
#   DRY_RUN=0 bash clean.sh <key> [key...]   # actually reclaim
#   bash clean.sh --self-test            # prove the safe_rm guardrail works
set -euo pipefail
IFS=$'\n\t'
: "${HOME:?HOME must be set}"
DRY_RUN="${DRY_RUN:-1}"   # 1 = report only (default); 0 = actually delete
trap 'echo "clean.sh: error at line $LINENO (exit $?)" >&2' ERR

have() { command -v "$1" >/dev/null 2>&1; }

# --- portable canonicalization: realpath -> python3 -> raw (older macOS lacks realpath) ---
canon() {
  local p="$1"
  if command -v realpath >/dev/null 2>&1; then realpath -- "$p" 2>/dev/null && return; fi
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$p" <<'PY' 2>/dev/null && return
import os,sys; print(os.path.realpath(os.path.expanduser(sys.argv[1])))
PY
  fi
  printf '%s\n' "$p"
}

# --- the single choke point for every delete ---
safe_rm() {
  local raw="${1:-}" t home
  [ -n "$raw" ]                 || { echo "REFUSE empty target" >&2; return 1; }
  raw="${raw/#\~/$HOME}"
  t="$(canon "$raw")"
  home="$(canon "$HOME")"
  [ -n "$t" ]                   || { echo "REFUSE empty canonical" >&2; return 1; }
  case "$t" in /*) : ;; *) echo "REFUSE not absolute: $t" >&2; return 1;; esac
  case "$t" in */../*|*/..) echo "REFUSE contains ..: $t" >&2; return 1;; esac
  [ "$t" != "/" ]              || { echo "REFUSE root" >&2; return 1; }
  [ "$t" != "$home" ]          || { echo "REFUSE is \$HOME: $t" >&2; return 1; }
  case "$t" in "$home"/?*) : ;; *) echo "REFUSE not under \$HOME: $t" >&2; return 1;; esac
  [ -e "$t" ]                  || { echo "skip (absent): $t"; return 0; }
  local before; before="$(du -sh "$t" 2>/dev/null | cut -f1)"
  if [ "$DRY_RUN" != "0" ]; then echo "DRY-RUN would rm -rf: $t  (${before:-?})"; return 0; fi
  echo "rm -rf: $t  (freeing ${before:-?})"
  rm -rf -- "${t:?}"           # :? tripwire = defense-in-depth second interlock
}
# clear a cache dir but keep the dir itself (avoids the /* dotfile+empty-glob traps)
wipe_dir() { safe_rm "$1" && { [ "$DRY_RUN" = "0" ] && mkdir -p -- "$1" || true; }; }

# RECOVERABLE delete — moves to Trash (undoable) instead of rm. Same $HOME guard as safe_rm.
# Used for creative-app caches, which sit near irreplaceable work, so a mistake must be recoverable.
trash_path() {
  local raw="${1:-}" t home
  [ -n "$raw" ]                || { echo "REFUSE empty target" >&2; return 1; }
  raw="${raw/#\~/$HOME}"
  t="$(canon "$raw")"; home="$(canon "$HOME")"
  [ -n "$t" ]                  || { echo "REFUSE empty canonical" >&2; return 1; }
  case "$t" in /*) : ;; *) echo "REFUSE not absolute: $t" >&2; return 1;; esac
  case "$t" in */../*|*/..) echo "REFUSE contains ..: $t" >&2; return 1;; esac
  [ "$t" != "$home" ]         || { echo "REFUSE is \$HOME: $t" >&2; return 1; }
  case "$t" in "$home"/?*) : ;; *) echo "REFUSE not under \$HOME: $t" >&2; return 1;; esac
  [ -e "$t" ]                  || { echo "skip (absent): $t"; return 0; }
  local before; before="$(du -sh "$t" 2>/dev/null | cut -f1)"
  if [ "$DRY_RUN" != "0" ]; then echo "DRY-RUN would move to Trash: $t  (${before:-?})"; return 0; fi
  echo "→ Trash (recoverable): $t  (${before:-?})"
  if command -v trash >/dev/null 2>&1; then trash "$t"
  else osascript -e "tell application \"Finder\" to delete (POSIX file \"${t}\" as alias)" >/dev/null 2>&1; fi
}

# run a tool's own cache cleaner (dry-run just prints it)
run() {
  local IFS=' '   # join $* with spaces for display (script-wide IFS is \n\t)
  if [ "$DRY_RUN" != "0" ]; then echo "DRY-RUN would run: $*"; return 0; fi
  echo "run: $*"; "$@"
}

# ---------------------------------------------------------------------------
#  SAFE targets — regenerate automatically, cheap.
# ---------------------------------------------------------------------------
t_npm()          { have npm  && run npm cache clean --force; }
t_pnpm()         { have pnpm && run pnpm store prune; }
t_yarn()         { have yarn && run yarn cache clean; }
t_brew()         { have brew && run brew cleanup -s; }
t_pip()          { have pip  && run pip cache purge; }
t_uv()           { have uv   && run uv cache clean; }
t_go_build()     { have go   && run go clean -cache; }
t_pods()         { have pod  && run pod cache clean --all; }
t_sims()         { have xcrun && run xcrun simctl delete unavailable; }
t_derived_data() { wipe_dir "$HOME/Library/Developer/Xcode/DerivedData"; }
t_sim_caches()   { wipe_dir "$HOME/Library/Developer/CoreSimulator/Caches"; }
t_trash()        { wipe_dir "$HOME/.Trash"; }
t_gradle_junk()  { safe_rm "$HOME/.gradle/wrapper/dists/gradle-REPLACEME-all"
                   safe_rm "$HOME/.gradle/wrapper/dists/gradle-REPLACEME-bin"; }

# Gradle caches: MUST stop daemons first or the delete can corrupt a live cache.
t_gradle_caches() {
  if pgrep -fl GradleDaemon >/dev/null 2>&1; then
    echo "!! A Gradle daemon is running. Quit Android Studio/IntelliJ and run:"
    echo "     ./gradlew --stop   (project version)   or   pkill -f '[G]radleDaemon'   (all)"
    echo "   then re-run. Skipping ~/.gradle/caches to avoid corruption."
    return 0
  fi
  safe_rm "$HOME/.gradle/caches"
}

# ---------------------------------------------------------------------------
#  CAUTION targets — regenerate but a big/slow re-download or state loss.
#  Only run these when the user has explicitly chosen them.
# ---------------------------------------------------------------------------
t_ios_devsupport(){ wipe_dir "$HOME/Library/Developer/Xcode/iOS DeviceSupport"; }   # re-caches on next device connect
t_go_modcache()  { have go && run go clean -modcache; }                              # re-downloads all modules
t_gradle_dists() { wipe_dir "$HOME/.gradle/wrapper/dists"; }                         # each wrapper re-downloads its distro
t_maven()        { safe_rm "$HOME/.m2/repository"; }                                 # NEVER ~/.m2 (settings.xml has creds)
t_bun()          { have bun && run bun pm cache rm; }
t_pub_cache()    {
  echo "!! ~/.pub-cache also holds globally-activated Dart CLIs (fvm, melos, ...)."
  echo "   Cleaning DE-ACTIVATES them; re-run 'dart pub global activate <pkg>' after."
  have dart && run dart pub cache clean || { have flutter && run flutter pub cache clean; }
}
t_docker_prune() {   # safe default: no -a, no --volumes (those can erase image data / DB volumes)
  have docker && run docker system prune
}
t_colima_stop()  { have colima && run colima stop; }   # frees RAM + releases disk; reversible with colima start

# NOTE: NDK versions, emulator system-images/AVDs, rustup toolchains, and simulator RUNTIMES
# require picking a specific version and cross-checking project pins — do those interactively
# from SKILL.md, not as blind bulk targets. See references/cleanup-targets.md.

# ---------------------------------------------------------------------------
#  CREATIVE-PRO app caches — genuinely safe, $HOME-scoped, and NOT sitting next
#  to originals. Moved to TRASH (recoverable), because creative work is nearby.
#  QUIT the app first. For caches that live inside a library bundle (.fcpbundle,
#  .photoslibrary, .cocatalog, .logicx) or next to a catalog, use the app's OWN
#  purge — those are documented in references/creative-pro-targets.md, NOT here.
# ---------------------------------------------------------------------------
t_adobe_mediacache() {   # shared Premiere/AE/Media Encoder cache — NOT Motion Graphics Templates
  trash_path "$HOME/Library/Application Support/Adobe/Common/Media Cache Files"
  trash_path "$HOME/Library/Application Support/Adobe/Common/Media Cache"
  trash_path "$HOME/Library/Application Support/Adobe/Common/Peak Files"
}
t_ae_diskcache()  { trash_path "$HOME/Library/Caches/Adobe/After Effects"; }
t_camera_raw()    { for d in "$HOME"/Library/Caches/Adobe\ Camera\ Raw*; do [ -e "$d" ] && trash_path "$d"; done; }
t_bridge_cache()  { for d in "$HOME"/Library/Caches/Adobe/Bridge*; do [ -e "$d" ] && trash_path "$d"; done; }
t_ableton_cache() { trash_path "$HOME/Library/Caches/Ableton/Cache"; }
t_au_cache()      { trash_path "$HOME/Library/Caches/AudioUnitCache"; trash_path "$HOME/Library/Caches/com.apple.audiounits.cache"; }
t_logic_cache()   { trash_path "$HOME/Library/Caches/com.apple.logic10"; }
t_browser_cache() {   # relocated HTTP/code cache only — never the App Support profile (bookmarks/passwords)
  echo "!! Quit the browser first, or the cache is locked and only partially clears."
  trash_path "$HOME/Library/Caches/Google/Chrome"
  trash_path "$HOME/Library/Caches/com.brave.Browser"
  trash_path "$HOME/Library/Caches/company.thebrowser.Browser"
  trash_path "$HOME/Library/Caches/Firefox"
  trash_path "$HOME/Library/Containers/com.apple.Safari/Data/Library/Caches"
}
t_diagnostics()   { trash_path "$HOME/Library/Logs/DiagnosticReports"; }
t_quicklook()     { run qlmanage -r cache; }

declare -a SAFE=(npm pnpm yarn brew pip uv go_build pods sims derived_data sim_caches trash gradle_junk gradle_caches)
declare -a CAUTION=(ios_devsupport go_modcache gradle_dists maven bun pub_cache docker_prune colima_stop)
# CREATIVE targets move to Trash (recoverable). Quit the app first.
declare -a CREATIVE=(adobe_mediacache ae_diskcache camera_raw bridge_cache ableton_cache au_cache logic_cache browser_cache diagnostics quicklook)

list_targets() {
  echo "SAFE — dev caches, regenerate automatically, deleted with rm:"; printf '  %s\n' "${SAFE[@]}"
  echo "CAUTION — regenerate but big/slow re-download or state loss:"; printf '  %s\n' "${CAUTION[@]}"
  echo "CREATIVE — app caches, moved to TRASH (recoverable); QUIT the app first:"; printf '  %s\n' "${CREATIVE[@]}"
  echo
  echo "  (Caches inside a library bundle — Final Cut, Photos, Lightroom, Logic, Resolve —"
  echo "   are NOT here: use the app's own purge. See references/creative-pro-targets.md.)"
  echo
  echo "Run a target:      bash clean.sh <key>                 (dry-run preview)"
  echo "Actually reclaim:  DRY_RUN=0 bash clean.sh <key>..."
}

self_test() {
  echo "self-test: safe_rm must REFUSE dangerous inputs and ACCEPT a real dir under \$HOME"
  local td; td="$HOME/.mac-cleanup-selftest.$$"; mkdir -p "$td"
  local ok=0 fail=0
  _refuse() { if DRY_RUN=0 safe_rm "$1" >/dev/null 2>&1; then echo "  FAIL accepted: '${2:-$1}'"; fail=$((fail+1)); else echo "  ok refused: ${2:-$1}"; ok=$((ok+1)); fi; }
  _refuse "" "(empty)"
  _refuse "/" "/"
  _refuse "$HOME" "\$HOME"
  _refuse "/tmp/outside-home" "/tmp/outside-home"
  _refuse "$HOME/../etc" "\$HOME/../etc"
  # accept: dry-run on a real dir under HOME should succeed (return 0)
  if DRY_RUN=1 safe_rm "$td" >/dev/null 2>&1; then echo "  ok accepted real dir under \$HOME"; ok=$((ok+1)); else echo "  FAIL rejected real dir"; fail=$((fail+1)); fi
  rmdir "$td" 2>/dev/null || true
  echo "self-test: $ok passed, $fail failed"; [ "$fail" -eq 0 ]
}

main() {
  [ $# -ge 1 ] || { list_targets; exit 0; }
  case "${1:-}" in
    --list|-l) list_targets; exit 0;;
    --self-test) self_test; exit $?;;
  esac
  [ "$DRY_RUN" = "0" ] && echo "== LIVE (DRY_RUN=0): will delete ==" || echo "== DRY-RUN (preview only). Pass DRY_RUN=0 to reclaim. =="
  for key in "$@"; do
    fn="t_${key//-/_}"
    if declare -F "$fn" >/dev/null; then echo "--- $key ---"; "$fn"; else echo "unknown target: $key (try --list)" >&2; fi
  done
}
main "$@"
