# TubeVault — Premium YouTube Downloader for Windows

A polished Flutter **Windows desktop** application for downloading YouTube
videos, audio, thumbnails and subtitles, with a queue, history, playlists,
system-tray background downloads and Google Sign-In.

> **Use responsibly.** Download only content you own or are permitted to
> download, and respect the rights of content owners and YouTube's Terms of
> Service. TubeVault is a tool; how you use it is your responsibility.

---

## How it works (important technical notes)

- **Downloading is done by [`yt-dlp`](https://github.com/yt-dlp/yt-dlp)**, not
  the YouTube Data API. The Data API cannot download streams and is heavily
  quota-limited. `yt-dlp.exe` is bundled and invoked as a subprocess; metadata
  comes from `yt-dlp --dump-single-json`.
- **[FFmpeg](https://ffmpeg.org/)** (`ffmpeg.exe`, bundled) merges the separate
  DASH video/audio streams, extracts audio (MP3/M4A/AAC/WAV) and embeds
  thumbnails/subtitles.
- **yt-dlp breaks when YouTube changes things.** Settings → *Update downloader
  engine* fetches the latest `yt-dlp.exe` at runtime.
- **Google Sign-In uses the OAuth 2.0 loopback flow** (implemented directly for
  desktop): the system browser opens, a temporary `localhost` server captures
  the redirect, and tokens are stored in `flutter_secure_storage`. The mobile
  `google_sign_in` package does **not** support Windows.

---

## Prerequisites

| Requirement | Why | Notes |
|---|---|---|
| **Flutter (stable)** | Build the app | Tested with Flutter 3.44 / Dart 3.12 |
| **Visual Studio 2022 + "Desktop development with C++"** | Flutter Windows apps compile native C++ | **Required** — `flutter build windows` fails without it |
| **Windows Developer Mode** | Flutter desktop plugins use symlinks | `start ms-settings:developers` → enable |
| **Inno Setup 6** | Build the `.exe` installer | https://jrsoftware.org/isdl.php (puts `iscc` on PATH) |

Verify your toolchain with `flutter doctor -v` — the **Visual Studio** line must
show `[√]`.

---

## Setup

```powershell
# 1. Install dependencies
flutter pub get

# 2. Download the bundled engine binaries (yt-dlp.exe + ffmpeg.exe)
powershell -ExecutionPolicy Bypass -File scripts\fetch_binaries.ps1

# 3. Configure Google OAuth credentials
copy config\secrets.example.json config\secrets.json
#   then edit config\secrets.json and paste your Client ID & Secret
```

### Google OAuth credentials

1. Go to the [Google Cloud Console](https://console.cloud.google.com/) →
   *APIs & Services* → *Credentials*.
2. Create an **OAuth client ID** of type **Desktop app**.
3. Copy the **Client ID** and **Client Secret** into `config/secrets.json`:

```json
{
  "googleClientId": "xxxxxxxx.apps.googleusercontent.com",
  "googleClientSecret": "xxxxxxxx",
  "youtubeDataApiKey": ""
}
```

`youtubeDataApiKey` is **optional** (reserved for richer search later) and not
required for any download feature. `secrets.json` is git-ignored — never commit
it.

---

## Run (development)

```powershell
flutter run -d windows
```

The bundled `yt-dlp.exe`/`ffmpeg.exe` are copied into the app's writable data
directory on first launch (`%APPDATA%\com.tubevault\tubevault\bin`), which is
where the engine self-updater writes.

---

## Build & package the installer

```powershell
# 1. Release build → build\windows\x64\runner\Release\
flutter build windows --release

# 2. Ensure assets\bin\yt-dlp.exe and ffmpeg.exe exist
#    (scripts\fetch_binaries.ps1 if you haven't already)

# 3. Build the single-file installer with Inno Setup
iscc installer\tubevault.iss
```

Output: **`installer\Output\TubeVault-Setup-x64.exe`** — installs to
`Program Files`, adds Start Menu (and optional desktop) shortcuts, registers an
uninstaller, and places `yt-dlp.exe`/`ffmpeg.exe` in `{app}\bin` where the app
resolves them at runtime.

---

## Project structure

```
lib/
  main.dart                 # async bootstrap + Riverpod overrides
  app/
    app.dart                # MaterialApp + auth gate
    app_shell.dart          # sidebar navigation shell
    theme/                  # design tokens + Material 3 themes (Inter)
  core/
    config/                 # secrets loader (no hardcoded keys)
    db/                     # sqflite_common_ffi database + history repo
    engine/                 # binary resolver, yt-dlp service, self-updater
    models/                 # VideoInfo, MediaFormat, DownloadTask, enums
    settings/               # AppSettings + persistence + controller
  features/
    auth/                   # OAuth loopback flow, profile, sign-in
    download/               # url input, preview, options, queue orchestration
    queue/                  # live progress + controls UI
    playlist/               # flat-playlist selection + batch enqueue
    files/                  # history screen + file management actions
    settings/               # settings screen (storage, engine, about)
    profile/
  shared/
    notifications.dart      # Windows toast notifications
    window/                 # window_manager + tray_manager (minimize to tray)
    utils/                  # formatters, URL validation, storage info
    widgets/                # design-system widgets (cards, empty states…)
assets/
  bin/                      # yt-dlp.exe + ffmpeg.exe (provided, not committed)
config/                     # secrets.json (provided, not committed)
installer/tubevault.iss     # Inno Setup script
scripts/fetch_binaries.ps1  # downloads the engine binaries
```

---

## What's new — "Aurora Glass" redesign

- **Completely redesigned UI:** frameless custom window chrome, frosted-glass
  surfaces, animated aurora background, sliding sidebar indicator, staggered
  entrance animations, hover-lift micro-interactions, gradient CTAs and a
  user-selectable **accent color**.
- **Dashboard** home with live stats (completed, total, storage, active) and
  one-tap **quick presets**.
- **SponsorBlock** segment removal, **clip/section** downloads (start–end),
  **embed metadata + chapters**, **download speed limit**, and
  **parallel-fragment acceleration**.
- **Presets:** Max Quality, 1080p MP4, Music · 320, Podcast · M4A, Data Saver.

## Feature overview

- **Download modes:** video (merged), audio-only (MP3/M4A/AAC/WAV), thumbnail,
  subtitles (manual + auto, embed or `.srt`, language selection).
- **Quality:** 144p → 4K, only offering resolutions the video actually provides.
- **File info:** resolution, FPS, bitrate, codecs and estimated size before
  downloading.
- **Queue:** start / pause / resume / cancel / retry, configurable concurrency
  (1–5), drag-to-reorder, live speed/ETA/size, auto-resume of interrupted jobs.
- **Playlists:** load, select specific videos, batch download.
- **History:** persisted in SQLite; search, sort, filter; rename / move /
  delete / open / reveal in Explorer / copy path / copy source URL.
- **Storage:** custom download folder (any drive), usage + free-space display,
  clear-cache.
- **UI:** dark (default) + light + system themes, sidebar nav, animations,
  skeleton loaders, empty states, toasts, confirmation dialogs.
- **Desktop:** minimize-to-tray with background downloads, Windows toast
  notifications, clipboard link auto-detect, command-line URL handling.

---

## Verification status

This repo was developed and statically verified with `flutter analyze`
(**0 issues**) and `flutter test` (**unit tests pass**). A full `flutter run` /
`flutter build windows` requires the Visual Studio C++ toolchain and Windows
Developer Mode (see Prerequisites).

---

## Credits & licenses

- **yt-dlp** — download engine. The Unlicense. https://github.com/yt-dlp/yt-dlp
- **FFmpeg** — media processing. LGPL/GPL. https://ffmpeg.org/
- Built with Flutter, Riverpod, and the Inter typeface.

TubeVault is an independent project and is **not** affiliated with, endorsed by,
or sponsored by YouTube or Google.
