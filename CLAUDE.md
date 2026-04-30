# June — Project Context & Rules

Context file for Claude (and future humans) working on this repo. Read this before making changes.

## What this app is

iOS SwiftUI app that replicates the Apple Maps look-and-feel as the home screen of a personal places companion called **June**. The home view is a full-screen MapKit map (dark mode, transit overlay, 3D / locate / Look Around buttons) with a draggable bottom sheet that holds the search field, configurable Places shortcuts, and Recents.

- **Platform:** iOS 26+, SwiftUI, Swift 5.9 (bumped from 17.0 on 2026-04-29 — June has zero shipped users so we target the latest iOS for the freshest APIs, including `mapItemDetailSheet` from 18+)
- **Backend:** CloudKit (private database) — favorites, recents, profile picture sync via the user's iCloud account
- **Auth:** Sign in with Apple
- **Weather pill:** WeatherKit (Apple)
- **Repo:** https://github.com/divinedavis/June (SSH: `git@github.com:divinedavis/June.git`)
- **Local path:** `/Users/divinedavis/June` (NOT Desktop)
- **Bundle ID:** `com.divinedavis.june`
- **Team ID:** `CG89RY4W6R`
- **Apple Developer:** paid Apple Developer Program account (divinejdavis@gmail.com)

## Repo layout

```
June/
├── CLAUDE.md                         # this file
├── README.md
├── project.yml                       # xcodegen spec — source of truth for Xcode project
├── June.xcodeproj/                   # generated, gitignored — never hand-edit
├── June/                             # SwiftUI sources
│   ├── JuneApp.swift                 # @main entry
│   ├── ContentView.swift             # auth gate
│   ├── AuthManager.swift             # Sign in with Apple, keychain
│   ├── SignInView.swift              # auth UI
│   ├── MapHomeView.swift             # main map screen
│   ├── HomeSheet.swift               # bottom sheet (search, places, recents)
│   ├── WeatherPill.swift             # top-left temp / AQI pill
│   ├── MapControls.swift             # right-side button stack + Look Around
│   ├── PlaceModels.swift             # Favorite, RecentPlace, UserProfile
│   ├── CloudKitStore.swift           # CloudKit private DB wrapper
│   ├── LocationManager.swift         # Core Location (When In Use)
│   ├── WeatherService.swift          # WeatherKit wrapper
│   ├── Theme.swift                   # colors
│   ├── June.entitlements
│   └── Assets.xcassets/
└── scripts/
    ├── ship-to-testflight.sh         # one command to ship a build
    ├── asc_set_whats_new.py          # used by ship-to-testflight; sets release notes
    ├── bootstrap-asc-app.py          # one-time: writes ASC_APP_ID to asc-config.env
    ├── asc-config.env.example        # template (committed)
    └── asc-config.env                # gitignored — real ASC creds
```

## Working rules

### 1. Push to GitHub after every change

After any edit:
1. Build: `xcodebuild -project June.xcodeproj -scheme June -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO`
2. Only commit if the build succeeds.
3. **Sensitive-file review (mandatory)** — see rule 5 below. Scan every file about to be pushed for credentials, keys, PII, or build junk.
4. `git add` specific files (never `git add -A` blindly — could catch `scripts/asc-config.env`).
5. Verify `git status` shows no `asc-config.env`, `*.p8`, or other secrets before committing.
6. `git push origin main`.

Remote is SSH: `git@github.com:divinedavis/June.git`.

### 2. Ship a TestFlight build after every change

Run `scripts/ship-to-testflight.sh --auto-notes` after every commit that touches app code. Per-change shipping mirrors what's done for Clock-In, Hidden Gems, and Baseball Stat Tracker.

- Each ship bumps `CURRENT_PROJECT_VERSION` by 1 automatically. `MARKETING_VERSION` only changes when you pass `--marketing X.Y`.
- `--auto-notes` reads `scripts/.last-shipped-commit` (gitignored) and formats notes from `git log --pretty=format:"- %s" <last>..HEAD`.
- Ships take 10–25 min end-to-end; run with `run_in_background: true` and wait for the task notification before starting another.

### 3. Regenerate the Xcode project after adding files

```bash
xcodegen generate
```

Do not hand-edit `project.pbxproj`. SourceKit may show stale "Cannot find type X in scope" errors right after adding files — they clear after the first successful build.

### 4. Never commit secrets

Gitignored:
- `scripts/asc-config.env` — App Store Connect API credentials (key id, issuer, team id, app id)
- `scripts/.last-shipped-commit` — last shipped git sha marker
- `*.p8` — App Store Connect API private keys (these live at `~/.appstoreconnect/private_keys/`, never inside the repo)

The ASC API key is shared across all of the user's iOS apps under team `CG89RY4W6R` — same `AuthKey_DCW4DGNGQ4.p8` works for Clock-In, Baseball Tracker, Hidden Gems, and June.

### 5. Sensitive-file review before every push

Before every `git push`, review every file about to leave the machine. Scan for:

- **Credential strings:** `API_KEY=`, `SECRET=`, `PASSWORD=`, `TOKEN=`, `Bearer `, `aws_secret_access_key`, `-----BEGIN .* PRIVATE KEY-----`, token prefixes like `xox[bp]-`, `sk_live_`, `ghp_`, `github_pat_`, Supabase service-role JWTs.
- **Sensitive filenames:** anything ending in `.env` (other than `.env.example`), `*.p8`, `*.pem`, `*.key`, `id_rsa`, `id_ed25519`, `credentials.json`, `service-account.json`, `Secrets.swift`, `asc-config.env`, `.npmrc` with auth tokens.
- **Hardcoded secrets in source:** real production URLs to internal hosts, real user PII, hardcoded JWT secrets, hardcoded DB passwords, real test-account passwords.
- **Unintended bulk:** `node_modules/`, `DerivedData/`, `*.xcarchive`, build outputs, large binaries, `.DS_Store`, editor state with tokens.

If anything sensitive is found: **don't push**. Remove it, gitignore the path, unstage it, or rewrite history if it landed in a commit but hasn't been pushed yet. If a secret has already been pushed to the remote, tell the user immediately so it can be rotated.

Prefer adding patterns to `.gitignore` over remembering — once a class of sensitive file is gitignored, future commits can't slip it in.

## One-time setup before first ship

App Store Connect doesn't permit creating apps via the API (only via the web UI). Do this once:

1. Go to https://appstoreconnect.apple.com/apps and click + → New App.
2. Fill in:
   - Platform: **iOS**
   - Name: **June**
   - Primary Language: **English (U.S.)**
   - Bundle ID: **com.divinedavis.june** (already registered as "XC com divinedavis june" — just select it)
   - SKU: **june**
   - User Access: **Full Access**
3. Click Create.
4. Run `python3 scripts/bootstrap-asc-app.py` — it will look up the new app's id and write `ASC_APP_ID` into `scripts/asc-config.env`.
5. Run `scripts/ship-to-testflight.sh --auto-notes` — first build goes up.

After step 4, every subsequent change just needs `scripts/ship-to-testflight.sh --auto-notes`.

## Build & run locally

```bash
xcodegen generate
open June.xcodeproj
# Cmd+R in Xcode for the simulator.
```

For Sign in with Apple + CloudKit + WeatherKit to actually function on a device you need the entitlements provisioned through the developer portal — Xcode handles this on first archive (`-allowProvisioningUpdates`).

## Known quirks

- SourceKit in standalone file inspection often reports false-positive "Cannot find type X" errors. The real `xcodebuild` build is the source of truth.
- WeatherKit requires the developer to have agreed to Apple's WeatherKit terms once — done at first archive that includes the entitlement.
- CloudKit container `iCloud.com.divinedavis.june` is created automatically by Xcode on first archive with `-allowProvisioningUpdates`.
