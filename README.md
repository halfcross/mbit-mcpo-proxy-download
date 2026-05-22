# MindBehindAI — Download

**Site:** [halfcross.github.io/mbit-mcpo-proxy-download](https://halfcross.github.io/mbit-mcpo-proxy-download/)

**MindBehindAI** ships a **local assistant bridge** (bundled runtime). **Docker is not required** for normal use. Enter your MindBehind license key inside the app.

**[User guide (English)](https://halfcross.github.io/mbit-mcpo-proxy-download/guide/)** — quick start, connections, Open WebUI, presets, troubleshooting.

## macOS (Apple Silicon)

Open the site for macOS and Windows install steps. **macOS** one-line install:

```bash
curl -fsSL https://halfcross.github.io/mbit-mcpo-proxy-download/install.sh | bash
```

If **`curl: (56) … 403`** when resolving the release: GitHub’s **anonymous API** allows only **60 requests/hour per IP**. The installer uses a proper **User-Agent** and falls back to the **HTML release page** if the API fails. You can also set **`DMG_URL`** to the direct `.dmg` link from [Releases](https://github.com/halfcross/mbit-mcpo-proxy-download/releases), or **`GITHUB_TOKEN`** (read-only PAT) for higher API limits.

Intel Macs are not supported in current macOS releases (Apple Silicon `.dmg` only).

## Windows (x64 portable)

Download a **portable `.exe`** directly from [Releases](https://github.com/halfcross/mbit-mcpo-proxy-download/releases) — **no installer** and no download script.

| PC type | Asset name pattern |
|--------|---------------------|
| 64-bit (Intel/AMD and Windows on ARM) | `MindBehindAI-<version>-portable-x64.exe` |

Direct link (replace `<version>` with the release tag, e.g. `5.1.15`):

- `https://github.com/halfcross/mbit-mcpo-proxy-download/releases/latest/download/MindBehindAI-<version>-portable-x64.exe`

The GitHub Pages site substitutes the current version into that URL on each release sync.
