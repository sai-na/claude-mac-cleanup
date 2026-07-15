#!/usr/bin/env bash
# scan.sh — READ-ONLY. Measures disk usage and ranks reclaimable caches.
# Never deletes anything. Safe to run anytime.
set -uo pipefail
: "${HOME:?HOME must be set}"

hr() { printf '%s\n' "------------------------------------------------------------"; }
have() { command -v "$1" >/dev/null 2>&1; }
# du a path only if it exists; print "size<TAB>path". Quiet on missing.
size() { [ -e "$1" ] && du -sh "$1" 2>/dev/null; }

echo "# mac-cleanup scan  ($(date '+%Y-%m-%d %H:%M'))"
hr
echo "## Disk (Apple Silicon: the Data volume is the TRUE number; plain / is a sealed snapshot)"
df -h /System/Volumes/Data 2>/dev/null | sed -n '1p;2p'
hr

echo "## Largest app + tool caches under ~/Library/Caches and ~/.cache"
# NOTE: ~/.cache/huggingface, ms-playwright, puppeteer, torch are DELIBERATE downloads, not junk.
{ du -sh "$HOME"/Library/Caches/* 2>/dev/null; du -sh "$HOME"/.cache/* 2>/dev/null; } \
  | sort -rh | head -20
hr

echo "## Developer caches (only those present on this machine are listed)"
{
  size "$HOME/.gradle/caches"
  size "$HOME/.gradle/wrapper/dists"
  size "$HOME/.npm"
  size "$HOME/Library/pnpm/store"
  size "$HOME/.local/share/pnpm/store"
  size "$HOME/Library/Caches/Yarn"
  size "$HOME/.m2/repository"
  size "$HOME/.bun/install/cache"
  size "$HOME/.cargo/registry"
  size "$HOME/.rustup/toolchains"
  size "$HOME/go/pkg/mod"
  size "$HOME/Library/Caches/go-build"
  size "$HOME/Library/Caches/pip"
  size "$HOME/.pub-cache"
  size "$HOME/Library/Developer/Xcode/DerivedData"
  size "$HOME/Library/Developer/Xcode/iOS DeviceSupport"
  size "$HOME/Library/Developer/CoreSimulator/Caches"
  size "$HOME/Library/Caches/CocoaPods"
  size "$HOME/Library/Android/sdk/ndk"
  size "$HOME/Library/Android/sdk/system-images"
  size "$HOME/.android/avd"
  size "$HOME/Library/Caches/Homebrew"
  size "$HOME/Library/Caches/JetBrains"
  size "$HOME/Library/Caches/Google/AndroidStudio"*
  size "$HOME/.Trash"
} | sort -rh
hr

# Docker: distinguish Docker Desktop (Docker.raw, a SPARSE file — measure with du, never ls) from colima.
echo "## Container VMs"
DDIMG="$HOME/Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw"
if [ -e "/Applications/Docker.app" ] && [ -e "$DDIMG" ]; then
  echo "Docker Desktop disk image (real on-disk size via du, NOT the apparent size):"
  du -sh "$DDIMG" 2>/dev/null
  have docker && docker system df 2>/dev/null | sed -n '1,6p' || echo "  (start Docker Desktop and run: docker system df)"
else
  echo "Docker Desktop: not installed."
fi
if have colima; then
  # colima status exits non-zero when stopped; detect running vs not without a spurious fallback.
  if colima status >/dev/null 2>&1; then echo "colima: running"; else echo "colima: not running"; fi
  size "$HOME/.colima" | sed 's/^/  disk (reclaim only via colima delete — destroys the VM): /'
else
  echo "colima: not installed."
fi
hr

echo "## iCloud (NEVER deleted by this skill; excluded from sweeps — evicting placeholders deletes cloud data)"
size "$HOME/Library/Mobile Documents" | sed 's/^/  (dataless placeholders read as ~0): /' || true
hr

echo "Done. Nothing was deleted. See references/cleanup-targets.md for what each item means and its safety tier."
