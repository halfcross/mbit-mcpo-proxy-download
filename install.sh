#!/usr/bin/env bash
# MCPBehindIT – macOS one-line installer
# Fetches the latest .dmg from GitHub Releases, copies the app to /Applications, clears quarantine.
#
# Usage:
#   curl -fsSL https://halfcross.github.io/mbit-mcpo-proxy-download/install.sh | bash
#   DMG_RELEASE_REPO=org/mbit-mcpo-proxy-download curl -fsSL … | bash
#
# The DMG must live on a *public* repo’s Releases (CI copies it from the private app build).
# Bash + curl + grep/awk only (no Python). Download progress = curl’s own stderr meter.
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

print_banner() {
  cat <<'EOF'
    ╭────────────────────────────────────────────╮
    │                                            │
    │    *  MCPBehindIT  ·  MindBehind IT  *     │
    │       macOS — gateway & MCP orchestrator   │
    │                                            │
    │    ───────────  one-line installer  ───────────
    │                                            │
    ╰────────────────────────────────────────────╯
EOF
}

print_banner
echo ""
echo " This will:"
echo "  1. Download the latest release DMG from GitHub (curl shows progress on the lines below)"
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
  echo " Resolving latest DMG from (public repo):"
  echo "   $API_URL"
  JSON=$(curl -fsSL -H "Accept: application/vnd.github+json" "$API_URL") || {
    echo " Error: Could not fetch release info. Check DMG_RELEASE_REPO and network." >&2
    exit 1
  }
  # First https://… .dmg URL in the JSON (release assets).
  DMG_URL=$(printf '%s' "$JSON" | grep -oE 'https://[^"]+\.dmg' | head -1 || true)
  if [[ -z "$DMG_URL" ]]; then
    echo " Error: No .dmg asset found in latest release." >&2
    exit 1
  fi
  echo " Download URL:"
  echo "   $DMG_URL"
fi

DMG_PATH="$TMPDIR/mcpbehindit.dmg"

echo ""
echo " ━━━ Downloading DMG ━━━"
echo ""

# No -s: curl writes its standard progress meter to stderr (%, transferred, total, speed, time left when known).
if [[ -t 2 ]]; then
  curl -fL -o "$DMG_PATH" "$DMG_URL"
else
  curl -fSL -o "$DMG_PATH" "$DMG_URL"
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

echo " Clearing quarantine (xattr -cr)…"
xattr -cr "$APP_DST"

echo ""
echo " ════════════════════════════════════════"
echo " Done. You can open MCPBehindIT from Applications or Spotlight."
echo " Activation uses your MindBehind license key inside the app (no installer password)."
echo " ════════════════════════════════════════"
echo ""
