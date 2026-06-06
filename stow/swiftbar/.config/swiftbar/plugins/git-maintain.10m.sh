#!/bin/bash
# SwiftBar plugin: git-maintenance health.
# Refresh every 10 minutes (rarely changes).
#
# <swiftbar.title>Git Maintenance</swiftbar.title>
# <swiftbar.desc>Registered repos, stale paths, last fetch ages</swiftbar.desc>

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

REAL_GIT="/usr/bin/git"
[ -x "$REAL_GIT" ] || REAL_GIT=$(command -v git)

# Threshold (seconds) above which a repo is considered "stale fetch"
STALE_FETCH_SEC=$((3 * 3600))   # > 3h since last prefetch

# Portable replacement for bash 4's `mapfile` (macOS ships bash 3.2).
REPOS=()
while IFS= read -r _line; do
    [ -n "$_line" ] && REPOS+=("$_line")
done < <("$REAL_GIT" config --global --get-all maintenance.repo 2>/dev/null)
LAUNCHD_LOADED=$(launchctl list 2>/dev/null | awk '/org\.git-scm\.git\./' | wc -l | tr -d ' ')

LIVE=0; STALE_PATH=0; STALE_FETCH=0
now=$(date +%s)
declare -a ROWS

for r in "${REPOS[@]}"; do
    if [ ! -e "$r" ]; then
        STALE_PATH=$((STALE_PATH + 1))
        ROWS+=("✗|—|$r")
        continue
    fi
    LIVE=$((LIVE + 1))
    git_dir=$("$REAL_GIT" -C "$r" rev-parse --git-dir 2>/dev/null)
    [ -n "$git_dir" ] && [ "${git_dir:0:1}" != "/" ] && git_dir="$r/$git_dir"
    fh="$git_dir/FETCH_HEAD"
    if [ -n "$git_dir" ] && [ -f "$fh" ]; then
        mtime=$(stat -f %m "$fh" 2>/dev/null)
        age=$((now - mtime))
        if [ "$age" -gt "$STALE_FETCH_SEC" ]; then
            STALE_FETCH=$((STALE_FETCH + 1))
            mark="⚠"
        else
            mark="✓"
        fi
        if   [ "$age" -lt 60    ]; then label="${age}s"
        elif [ "$age" -lt 3600  ]; then label="$((age/60))m"
        elif [ "$age" -lt 86400 ]; then label="$((age/3600))h"
        else                            label="$((age/86400))d"
        fi
        ROWS+=("$mark|$label|$r")
    else
        STALE_FETCH=$((STALE_FETCH + 1))
        ROWS+=("⚠|never|$r")
    fi
done

# ── Menu bar title ────────────────────────────────────────────────────────────
TOTAL=${#REPOS[@]}
ICON="🔧"
SUFFIX=""
if [ "$LAUNCHD_LOADED" -eq 0 ] && [ "$TOTAL" -gt 0 ]; then
    ICON="⛔"
    SUFFIX=" launchd off"
elif [ "$STALE_PATH" -gt 0 ]; then
    SUFFIX=" ${STALE_PATH}✗"
fi
echo "${ICON} ${LIVE}/${TOTAL}${SUFFIX}"

# ── Menu ──────────────────────────────────────────────────────────────────────
echo "---"
echo "git maintenance | size=12 color=#888888"
echo "Live: ${LIVE} · Stale path: ${STALE_PATH} · Old fetch: ${STALE_FETCH} | size=12"
if [ "$LAUNCHD_LOADED" -gt 0 ]; then
    echo "launchd: ${LAUNCHD_LOADED} job(s) loaded ✓ | size=12 color=#5fa850"
else
    echo "launchd: NO jobs loaded — background fetch off | size=12 color=#cc4444"
fi
echo "---"

# Rows, sorted: stale-path first, then stale-fetch, then by age
if [ "${#ROWS[@]}" -gt 0 ]; then
    printf '%s\n' "${ROWS[@]}" | sort | while IFS='|' read -r mark label path; do
        short=$(echo "$path" | sed -E "s|^$HOME|~|; s|/\.git/?$||")
        echo "${mark} ${label}  ${short} | size=11 font=Menlo"
    done
fi

# ── Actions ───────────────────────────────────────────────────────────────────
echo "---"
echo "Run status report | shell=$HOME/.bin/git-maintain-status terminal=true refresh=true"
if [ "$STALE_PATH" -gt 0 ]; then
    echo "Prune ${STALE_PATH} stale path(s) | shell=$HOME/.bin/git-maintain-prune param1=--yes terminal=true refresh=true"
fi
echo "Refresh | refresh=true"
