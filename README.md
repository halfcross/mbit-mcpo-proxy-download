# MindBehindAI — Install (macOS)

**Site:** [halfcross.github.io/mbit-mcpo-proxy-download](https://halfcross.github.io/mbit-mcpo-proxy-download/)

macOS · **MindBehindAI** ships a **local assistant bridge** (bundled runtime). **Docker is not required** for normal use. Enter your MindBehind license key inside the app.

**[User guide (English)](https://halfcross.github.io/mbit-mcpo-proxy-download/guide/)** — quick start, connections, Open WebUI, presets, troubleshooting.

Open the site for the install command, manual DMG steps, and notes. For convenience:

```bash
curl -fsSL https://halfcross.github.io/mbit-mcpo-proxy-download/install.sh | bash
```

If **`curl: (56) … 403`** when resolving the release: GitHub’s **anonymous API** allows only **60 requests/hour per IP**. The installer uses a proper **User-Agent** and falls back to the **HTML release page** if the API fails. You can also set **`DMG_URL`** to the direct `.dmg` link from [Releases](https://github.com/halfcross/mbit-mcpo-proxy-download/releases), or **`GITHUB_TOKEN`** (read-only PAT) for higher API limits.

The default **latest** asset may be **Apple Silicon (`arm64`) only**. On an **Intel Mac**, the script stops with a clear error if no `x64` / `amd64` / `intel` DMG is published—use **`DMG_URL`** to point at an Intel build when you ship one.
