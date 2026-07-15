#!/usr/bin/env bash
# services.sh — READ-ONLY. Shows listening dev servers, background services, and RAM health.
# Never kills or stops anything. Stopping is a separate, confirmed step (see SKILL.md).
set -uo pipefail
: "${HOME:?HOME must be set}"

hr() { printf '%s\n' "------------------------------------------------------------"; }
have() { command -v "$1" >/dev/null 2>&1; }

echo "# mac-cleanup services + RAM  ($(date '+%Y-%m-%d %H:%M'))"
hr

echo "## Listening TCP ports (port -> process -> project). Full command names (+c 0)."
# COMMAND is truncated by default; +c 0 shows full names. Resolve cwd per PID below.
lsof +c 0 -nP -iTCP -sTCP:LISTEN 2>/dev/null | awk 'NR==1 || /LISTEN/'
echo
echo "### Resolve a PID before acting on it:"
echo "  ps -p <PID> -o pid,command=          # exactly what it is"
echo "  lsof -a -p <PID> -d cwd              # which project/repo it belongs to"
echo
echo "### DO NOT KILL (system-owned): ports 5000/7000 = AirPlay Receiver (ControlCenter),"
echo "    plus WindowServer, launchd(1), coreaudiod, mds/mds_stores, Dock, Finder,"
echo "    and your own active editor/browser. Stop DBs with 'brew services stop', never kill -9."
hr

echo "## Homebrew-managed services (source of truth for Postgres/Redis/etc.)"
if have brew; then brew services list 2>/dev/null; else echo "brew: not installed."; fi
hr

echo "## Container VMs / emulators (stop gracefully, don't kill)"
have colima && { echo -n "colima: "; colima status 2>&1 | grep -o 'colima is [a-z]*' | head -1 || echo "unknown"; }
have docker && docker ps --format '  container {{.Names}} ({{.Image}})' 2>/dev/null
have adb && { echo "adb devices:"; adb devices 2>/dev/null | sed '1d;/^$/d;s/^/  /'; }
hr

echo "## Memory health (low 'free RAM' is NORMAL on macOS — judge by pressure + swap)"
echo "### Top processes by real memory footprint:"
top -l 1 -o mem -n 12 -stats pid,command,mem,cpu 2>/dev/null \
  | awk '/PhysMem|PID +COMMAND/{p=1} p'
echo
echo "### Pressure + swap (the real signals):"
memory_pressure 2>/dev/null | grep -i "free percentage" || true
sysctl -n vm.swapusage 2>/dev/null | sed 's/^/swap: /'
echo
echo "### Chrome: many 'Renderer' processes is normal (one per site = site isolation)."
echo "    A single multi-GB renderer = one heavy/leaking tab. To find WHICH tab:"
echo "    Chrome menu bar > Window > Task Manager (Option+Cmd+Esc) maps each PID to a tab name."
echo "    Fix by closing/discarding that tab (chrome://discards) or enabling Memory Saver —"
echo "    do NOT kill renderer PIDs from the shell (that just crashes the tab with 'Aw, Snap')."
hr
echo "Done. Nothing was stopped."
