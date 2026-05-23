#!/usr/bin/env bash
# MindBehindAI — macOS one-line installer (recommended)
# Fetches the latest .dmg from GitHub Releases, copies the app to /Applications, clears quarantine.
#
# Usage:
#   curl -fsSL https://halfcross.github.io/mbit-mcpo-proxy-download/install.sh | bash
#   DMG_RELEASE_REPO=org/mbit-mcpo-proxy-download curl -fsSL … | bash
#
# If the GitHub API returns 403, it is often anonymous rate limit (60/hour per IP), not only missing
# User-Agent — this script sends both. Mitigations: wait, GITHUB_TOKEN=…, DMG_URL=…, or the script’s
# HTML fallback on github.com/…/releases/latest.
#
# The DMG must live on a *public* repo’s Releases (CI copies it from the private app build).
# Bash + curl + grep/awk only (no Python). Download progress = curl’s own stderr meter.
#
set -euo pipefail

# Collect https://… .dmg from GitHub API JSON or HTML; include relative /…/releases/download/… links.
list_dmg_urls_from_text() {
  printf '%s' "$1" | grep -oE 'https://[^"]+\.dmg' || true
  printf '%s' "$1" | grep -oE 'href="/[^"]+/releases/download/[^"]+\.dmg"' | sed -e 's/^href="//' -e 's/"$//' | sed -e 's#^#https://github.com#' || true
}

dedupe_url_lines() {
  awk 'NF && !seen[$0]++'
}

# Plain `xattr -cr` follows symlinks; Node’s `bin/npx` etc. point into `lib/node_modules/…`. If that tree
# is missing for an arch, xattr errors with "No such file" and (with `set -e`) can abort the installer.
# Clear attrs on real files/dirs with `xattr -c`, and on symlink inodes with `xattr -c -s` (BSD flag
# `-s`: act on the link itself; do **not** use `-h` — on macOS that is **help**, not “no follow”).
clear_bundle_quarantine() {
  local app_root="$1"
  find "$app_root" \( -type f -o -type d \) -exec xattr -c {} + 2>/dev/null || true
  find "$app_root" -type l -exec xattr -c -s {} + 2>/dev/null || true
}

# Prefer arch-specific filename when multiple DMGs exist (e.g. *-arm64.dmg vs *-x64.dmg).
pick_dmg_for_this_mac() {
  local blob lines arch chosen line only_arm
  blob="$1"
  lines=$(list_dmg_urls_from_text "$blob" | dedupe_url_lines)
  [[ -z "$lines" ]] && return 0
  arch=$(uname -m)
  chosen=""
  if [[ "$arch" == "arm64" ]]; then
    while IFS= read -r line; do
      case "$line" in *arm64*|*aarch64*|*ARM64*|*AARCH64*) chosen=$line; break;; esac
    done <<< "$lines"
  elif [[ "$arch" == "x86_64" ]]; then
    while IFS= read -r line; do
      case "$line" in *x86_64*|*amd64*|*AMD64*|*x64*|*intel*|*Intel*|*x86-64*) chosen=$line; break;; esac
    done <<< "$lines"
    if [[ -z "$chosen" ]]; then
      only_arm=1
      while IFS= read -r line; do
        case "$line" in *arm64*|*aarch64*) ;; *) only_arm=0; break;; esac
      done <<< "$lines"
      if [[ "$only_arm" -eq 1 ]]; then
        echo " Error: The latest GitHub release only has an Apple Silicon (arm64) disk image." >&2
        echo "   There is no Intel (x86_64) DMG attached. Open the release in a browser and check assets," >&2
        echo "   or set DMG_URL= to a compatible .dmg URL." >&2
        exit 1
      fi
    fi
  fi
  if [[ -z "$chosen" ]]; then
    chosen=$(printf '%s\n' "$lines" | head -1)
  fi
  printf '%s' "$chosen"
}

APP_NAME="MindBehindAI.app"

# Public repo whose latest Release includes a .dmg (anonymous GitHub API). Not the private app repo.
DMG_RELEASE_REPO="${DMG_RELEASE_REPO:-halfcross/mbit-mcpo-proxy-download}"

# Optional: direct DMG URL (skips GitHub API). Example: exported asset URL from a release.
DMG_URL_OVERRIDE="${DMG_URL:-}"

# GitHub REST API rejects many requests without a descriptive User-Agent (often HTTP 403).
GH_API_UA="${GH_API_UA:-MindBehindAI-installer/1.0 (+https://halfcross.github.io/mbit-mcpo-proxy-download/)}"

if [[ "$(uname)" != "Darwin" ]]; then
  echo "Error: This installer supports macOS only." >&2
  exit 1
fi

echo "MindBehindAI · MindBehind IT — one-line install"
echo ""
echo " This will:"
echo "  1. Download the latest release DMG from GitHub (curl shows progress on the lines below)"
echo "  2. Copy ${APP_NAME} to /Applications"
echo "  3. Clear quarantine on the copied app (fixes “damaged” / Gatekeeper issues after download)"
echo ""

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

if [[ -n "$DMG_URL_OVERRIDE" ]]; then
  DMG_URL="$DMG_URL_OVERRIDE"
  echo " Using DMG_URL: $DMG_URL"
else
  API_URL="https://api.github.com/repos/${DMG_RELEASE_REPO}/releases/latest"
  echo " Resolving latest DMG from (public repo):"
  echo "   $API_URL"
  CURL_API=(curl -fsSL \
    -H "Accept: application/vnd.github+json" \
    -H "User-Agent: ${GH_API_UA}" \
    -H "X-GitHub-Api-Version: 2022-11-28")
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    CURL_API+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
  fi
  DMG_URL=""
  JSON=""
  if JSON=$("${CURL_API[@]}" "$API_URL" 2>/dev/null); then
    DMG_URL=$(pick_dmg_for_this_mac "$JSON")
  fi
  if [[ -z "$DMG_URL" ]]; then
    echo " GitHub API did not yield a DMG (rate limit, offline, or no .dmg on latest release)."
    echo " Trying HTML releases page (separate limit)…"
    HTML_URL="https://github.com/${DMG_RELEASE_REPO}/releases/latest"
    echo "   $HTML_URL"
    PAGE=$(curl -fsSL -L -H "User-Agent: ${GH_API_UA}" "$HTML_URL" 2>/dev/null || true)
    DMG_URL=$(pick_dmg_for_this_mac "$PAGE")
    if [[ -z "$DMG_URL" ]]; then
      REL=$(printf '%s' "$PAGE" | grep -oE 'href="/[^"]+/releases/download/[^"]+\.dmg"' | head -1 | sed -e 's/^href="//' -e 's/"$//' || true)
      if [[ -n "$REL" ]]; then
        DMG_URL=$(pick_dmg_for_this_mac "https://github.com${REL}")
      fi
    fi
  fi
  if [[ -z "$DMG_URL" ]]; then
    echo " Error: Could not resolve a .dmg download URL." >&2
    echo "   Anonymous GitHub API is limited to 60 requests/hour per IP (HTTP 403 when exhausted)." >&2
    echo "   Options: wait a few minutes and retry; export GITHUB_TOKEN=… (PAT with repo read); or set DMG_URL to the direct .dmg URL." >&2
    echo "   Repo: ${DMG_RELEASE_REPO}" >&2
    exit 1
  fi
  echo " Download URL:"
  echo "   $DMG_URL"
fi

DMG_PATH="$TMPDIR/mindbehindai.dmg"

echo ""
echo " ━━━ Downloading DMG ━━━"
echo ""

# No -s: curl writes its standard progress meter to stderr (%, transferred, total, speed, time left when known).
CURL_DL=(curl -fL -H "User-Agent: ${GH_API_UA}")
if [[ -n "${GITHUB_TOKEN:-}" && "$DMG_URL" == *"github.com"* ]]; then
  CURL_DL+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi
if [[ -t 2 ]]; then
  "${CURL_DL[@]}" -o "$DMG_PATH" "$DMG_URL"
else
  "${CURL_DL[@]}" -sS -o "$DMG_PATH" "$DMG_URL"
  echo " Download finished (stderr is not a terminal — curl could not show a live progress meter)."
fi

echo ""
echo " Mounting DMG…"
ATTACH_OUT=$(hdiutil attach -nobrowse -readonly -noverify "$DMG_PATH" 2>&1) || {
  echo " Error: hdiutil attach failed." >&2
  echo "$ATTACH_OUT" >&2
  exit 1
}
# Last path starting with /Volumes/ on a line (handles tab-separated hdiutil output).
MOUNT_POINT=$(printf '%s\n' "$ATTACH_OUT" | awk -F '\t' '{
  for (i = 1; i <= NF; i++) {
    gsub(/^ +| +$/, "", $i)
    if ($i ~ /^\/Volumes\//) { mp = $i }
  }
}
END { if (mp != "") print mp }')
if [[ -z "$MOUNT_POINT" || ! -d "$MOUNT_POINT" ]]; then
  echo " Error: Could not determine DMG mount point." >&2
  echo "$ATTACH_OUT" >&2
  exit 1
fi

cleanup_mount() {
  hdiutil detach -quiet "$MOUNT_POINT" 2>/dev/null || true
}
trap 'cleanup_mount; rm -rf "$TMPDIR"' EXIT

APP_SRC=""
if [[ -d "$MOUNT_POINT/$APP_NAME" ]]; then
  APP_SRC="$MOUNT_POINT/$APP_NAME"
else
  APP_SRC=$(find "$MOUNT_POINT" -maxdepth 3 -name "$APP_NAME" -print -quit || true)
fi
if [[ -z "$APP_SRC" || ! -d "$APP_SRC" ]]; then
  echo " Error: ${APP_NAME} not found inside the DMG." >&2
  exit 1
fi

APP_DST="/Applications/$APP_NAME"
echo " Installing to ${APP_DST}…"
rm -rf "$APP_DST"
cp -R "$APP_SRC" "$APP_DST"

echo " Unmounting…"
cleanup_mount
trap 'rm -rf "$TMPDIR"' EXIT

echo " Clearing quarantine…"
clear_bundle_quarantine "$APP_DST"

echo ""
echo " ════════════════════════════════════════"
echo " Done. Open MindBehindAI from Applications or Spotlight."
echo " Activation uses your MindBehind license key inside the app (no installer password)."
echo " ════════════════════════════════════════"
echo ""
