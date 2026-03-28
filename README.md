# mbit-mcpo-proxy-download

Public **download & install** site for **MCPBehindIT** (macOS), hosted at  
**https://halfcross.github.io/mbit-mcpo-proxy-download/** (after GitHub Pages is enabled).

- **App source & DMG releases:** [halfcross/mbit-mcpo-proxy](https://github.com/halfcross/mbit-mcpo-proxy) (no `-download` suffix).
- This repo only hosts `index.html`, `install.sh`, and `.nojekyll`. The installer pulls the **latest `.dmg`** from the app repo’s GitHub Releases.

Inspired by [mcp-telekom-proxy-download](https://github.com/Tim-Ganther/mcp-telekom-proxy-download), without ZIP/password; licensing is in the app.

## One-liner (for users)

```bash
curl -fsSL https://halfcross.github.io/mbit-mcpo-proxy-download/install.sh | bash
```

## Automated sync from mbit-mcpo-proxy (recommended)

On each **semver tag** in the main app repo, CI can push this folder to **main** here, create tag **`vX.Y.Z`**, and attach a **ZIP** of the site to a **Release** on this repository. Configure secret **`DOWNLOAD_SITE_PUSH_TOKEN`** on [halfcross/mbit-mcpo-proxy](https://github.com/halfcross/mbit-mcpo-proxy) (see main repo README).

## What you still need to do (first-time maintainer checklist)

### 1. Push this folder to the empty download repo

From your machine (paths may vary):

```bash
cd /path/to/mbit-mcpo-proxy/mbit-mcpo-proxy-download
git init
git branch -M main
git remote add origin https://github.com/halfcross/mbit-mcpo-proxy-download.git
git add .
git commit -m "Add GitHub Pages download site and installer"
git push -u origin main
```

If the repo already has a README from GitHub, use `git pull origin main --allow-unrelated-histories` once, then push.

### 2. Turn on GitHub Pages

Repo **Settings → Pages → Build and deployment:**

- Source: **Deploy from a branch**
- Branch: **`main`**, folder **`/ (root)`**
- Save. After ~1 minute, open  
  **https://halfcross.github.io/mbit-mcpo-proxy-download/**  
  and confirm `index.html` loads.

### 3. Confirm the main app repo has a public Release with a `.dmg`

The installer calls  
`https://api.github.com/repos/halfcross/mbit-mcpo-proxy/releases/latest`  
and expects an asset whose name ends in **`.dmg`**.

If there is no release yet, tag and push on **mbit-mcpo-proxy** (CI builds the DMG), or upload a DMG manually to Releases.

### 4. Optional: executable bit for `install.sh`

```bash
chmod +x install.sh
git add install.sh
git commit -m "chmod +x install.sh"
git push
git update-index --chmod=+x install.sh   # if you use git to track mode
```

### Optional: pin a specific DMG

```bash
curl -fsSL https://halfcross.github.io/mbit-mcpo-proxy-download/install.sh | \
  DMG_URL='https://github.com/halfcross/mbit-mcpo-proxy/releases/download/v2.0.0/MCPBehindIT-2.0.0.dmg' bash
```

Use the exact **browser_download_url** from the release asset.

## Files

| File | Purpose |
|------|---------|
| `index.html` | English landing page |
| `install.sh` | One-line installer (default `MBIT_GITHUB_REPO=halfcross/mbit-mcpo-proxy`) |
| `.nojekyll` | Static Pages serving |
