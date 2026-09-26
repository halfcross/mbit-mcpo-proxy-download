# GL DIGITAL — Download

**Site:** [halfcross.github.io/mbit-mcpo-proxy-download](https://halfcross.github.io/mbit-mcpo-proxy-download/)

GL DIGITAL runs on **macOS (Apple Silicon)**. It replaces MindBehindAI and takes over its settings.

## Install or update

The same command installs the app and updates it. A running app is quit, updated and reopened:

```bash
curl -fsSL https://halfcross.github.io/mbit-mcpo-proxy-download/install.sh | bash
```

If the command fails with **`403`**, GitHub's anonymous API limit (60 requests per hour) was hit. Wait a moment, or set **`GITHUB_TOKEN`** (read-only) or **`DMG_URL`** (direct `.dmg` link from [Releases](https://github.com/halfcross/mbit-mcpo-proxy-download/releases)).

**By hand:** download the `.dmg` from [Releases](https://github.com/halfcross/mbit-mcpo-proxy-download/releases/latest), drag **GL DIGITAL** to **Applications**. If macOS says the app is damaged, clear the quarantine flag:

```bash
APP="/Applications/GL DIGITAL.app"
find "$APP" \( -type f -o -type d \) -exec xattr -c {} + 2>/dev/null
find "$APP" -type l -exec xattr -c -s {} + 2>/dev/null
```
