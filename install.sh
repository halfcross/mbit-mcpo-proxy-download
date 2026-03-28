#!/usr/bin/env bash
# MCPBehindIT – macOS one-line installer
# Fetches the latest .dmg from GitHub Releases, copies the app to /Applications, clears quarantine.
#
# Usage:
#   curl -fsSL https://halfcross.github.io/mbit-mcpo-proxy-download/install.sh | bash
#   DMG_RELEASE_REPO=org/mbit-mcpo-proxy-download curl -fsSL … | bash
#
# The DMG must live on a *public* repo’s Releases (CI copies it from the private app build).
#
set -euo pipefail

APP_NAME="MCPBehindIT.app"

# Public repo whose latest Release includes a .dmg (anonymous GitHub API). Not the private app repo.
DMG_RELEASE_REPO="${DMG_RELEASE_REPO:-halfcross/mbit-mcpo-proxy-download}"

# Optional: direct DMG URL (skips GitHub API). Example: exported asset URL from a release.
DMG_URL_OVERRIDE="${DMG_URL:-}"

if [[ "$(uname)" != "Darwin" ]]; then
  echo "Error: This installer supports macOS only." >&2
  exit 1
fi

echo ""
echo " MCPBehindIT – installer for macOS"
echo " ─────────────────────────────────"
echo ""
echo " This will:"
echo "  1. Download the latest release DMG from GitHub"
echo "  2. Copy ${APP_NAME} to /Applications"
echo "  3. Run xattr -cr to clear quarantine (fixes “damaged” / Gatekeeper issues after download)"
echo ""

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

if [[ -n "$DMG_URL_OVERRIDE" ]]; then
  DMG_URL="$DMG_URL_OVERRIDE"
  echo " Using DMG_URL: $DMG_URL"
else
  API_URL="https://api.github.com/repos/${DMG_RELEASE_REPO}/releases/latest"
  echo " Resolving latest DMG from (public repo): $API_URL"
  JSON=$(curl -fsSL -H "Accept: application/vnd.github+json" "$API_URL") || {
    echo " Error: Could not fetch release info. Check DMG_RELEASE_REPO and network." >&2
    exit 1
  }
  DMG_URL=$(echo "$JSON" | /usr/bin/python3 -c "
import sys, json
j = json.load(sys.stdin)
for a in j.get('assets', []):
    u = a.get('browser_download_url') or ''
    if u.lower().endswith('.dmg'):
        print(u)
        break
else:
    sys.exit(1)
") || {
    echo " Error: No .dmg asset found in latest release." >&2
    exit 1
  }
  echo " Download URL: $DMG_URL"
fi

DMG_PATH="$TMPDIR/mcpbehindit.dmg"
echo " Downloading…"
curl -fsSL -o "$DMG_PATH" "$DMG_URL"

echo " Mounting DMG…"
ATTACH_OUT=$(hdiutil attach -nobrowse -readonly -noverify "$DMG_PATH" 2>&1) || {
  echo " Error: hdiutil attach failed." >&2
  echo "$ATTACH_OUT" >&2
  exit 1
}
MOUNT_POINT=$(echo "$ATTACH_OUT" | /usr/bin/python3 -c "
import re, sys
text = sys.stdin.read()
paths = re.findall(r'(/Volumes/.+)', text)
if not paths:
    raise SystemExit(1)
# Longest match last line (handles spaces in volume names)
last = paths[-1].strip()
# Trim trailing tabs/spaces from line noise
last = last.split('\t')[0].strip()
print(last)
") || true
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

echo " Clearing quarantine (xattr -cr)…"
xattr -cr "$APP_DST"

echo ""
echo " Done. You can open MCPBehindIT from Applications or Spotlight."
echo " Activation uses your MindBehind license key inside the app (no installer password)."
echo ""
