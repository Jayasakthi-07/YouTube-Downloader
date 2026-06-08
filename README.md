<div align="center">

# 🎬 YouTube Downloader

**Two ways to download — a premium native Windows app, and a web app.**

</div>

This repository contains **two independent applications** that both download
YouTube videos and audio. Pick the one that fits how you work:

| | 🖥️ **TubeVault** — Windows App | 🌐 **Vortex** — Web App |
|---|---|---|
| **Type** | Native Windows desktop (`.exe`) | Browser app (runs locally) |
| **Stack** | Flutter + Dart | Next.js 15 + FastAPI (Python) |
| **Install** | One-click installer | Run backend + frontend locally |
| **Best for** | A polished, always-available desktop app with a queue, history, tray & background downloads | Quick access from any device on your Wi-Fi, including your phone |
| **Folder** | [`windows-app/`](windows-app/) | [`backend/`](backend/) · [`frontend/`](frontend/) |
| **Download** | [⬇️ Latest Release](https://github.com/Jayasakthi-07/YouTube-Downloader/releases/latest) | Build from source (below) |

---

# 🖥️ TubeVault — Premium Windows Application

<div align="center">

### *A flagship-grade, native YouTube downloader for Windows*

[![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11-0A84FF?style=for-the-badge&logo=windows&logoColor=white)](#)
[![Flutter](https://img.shields.io/badge/Flutter-Desktop-5B7CFF?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![yt-dlp](https://img.shields.io/badge/Engine-yt--dlp-FF5C72?style=for-the-badge)](https://github.com/yt-dlp/yt-dlp)
[![Download](https://img.shields.io/badge/⬇_Download-Setup_.exe-2BD4A0?style=for-the-badge)](https://github.com/Jayasakthi-07/YouTube-Downloader/releases/latest)

</div>

> **TubeVault** is a luxury-grade desktop experience — an *Aurora Glass* UI with a
> frameless custom window, frosted-glass surfaces, animated backgrounds, a live
> dashboard, and a download engine built on **yt-dlp + FFmpeg**.

### ✨ Highlights

- **Stunning Aurora Glass UI** — frameless window chrome, frosted glass, animated
  aurora background, sliding navigation, staggered entrance animations,
  hover-lift micro-interactions and a **user-selectable accent color**.
- **Live Dashboard** — animated stats (completed, total, storage used, active),
  one-tap presets, and recent downloads at a glance.
- **Every format & quality** — MP4 / WEBM / MKV up to **4K**, audio as
  MP3 / M4A / AAC / WAV with selectable bitrate up to **320 kbps**.
- **Power features** — **SponsorBlock** segment removal, **clip/section**
  downloads, embed **metadata + chapters + thumbnail + subtitles**, **speed
  limit**, and **parallel-fragment** acceleration.
- **Real download manager** — multi-download queue with concurrency, pause /
  resume / cancel / retry, drag-to-reorder, live speed & ETA, and **auto-resume**
  of interrupted downloads.
- **Playlists** — load a playlist, pick exactly which videos, batch download.
- **Library** — SQLite history with search / sort / filter; rename, move,
  delete, open or reveal files in Explorer.
- **Desktop-native** — Google Sign-In (OAuth loopback), **system tray** with
  background downloads, Windows toast notifications, clipboard link auto-detect.
- **Polished** — dark / light / system themes, offline **Inter** + **JetBrains
  Mono** fonts, and full **English / Spanish / Hindi / French** localization.

### 🚀 Install (end users)

1. Download **`TubeVault-Setup-x64.exe`** from the
   [latest release](https://github.com/Jayasakthi-07/YouTube-Downloader/releases/latest).
2. Run it and follow the installer.
3. Launch TubeVault, sign in with Google, paste a link, and download.

> The installer bundles `yt-dlp.exe` and `ffmpeg.exe` — no extra setup required.

### 🛠️ Build from source

Full setup, prerequisites (Visual Studio C++ workload, fonts, OAuth keys) and the
Inno Setup packaging steps live in **[`windows-app/README.md`](windows-app/README.md)**.

```powershell
cd windows-app
flutter pub get
powershell -ExecutionPolicy Bypass -File scripts\fetch_binaries.ps1   # yt-dlp + ffmpeg
copy config\secrets.example.json config\secrets.json                  # add Google OAuth keys
flutter run -d windows
```

---

# 🌐 Vortex — Web Application

<div align="center">

### *The Ultimate 4K/8K Video & Audio Experience — in your browser*

[![Next.js](https://img.shields.io/badge/Next.js-15-black?style=for-the-badge&logo=next.js&logoColor=white)](https://nextjs.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![Tailwind](https://img.shields.io/badge/Tailwind_CSS-4.0+-38B2AC?style=for-the-badge&logo=tailwind-css&logoColor=white)](https://tailwindcss.com/)

</div>

> **Vortex** is a browser-based downloader with a Cyberpunk/Glassmorphism UI,
> real-time WebSocket progress, and mobile access over your local Wi-Fi. Run it
> locally with a FastAPI backend and a Next.js frontend.

### 🔥 Features

- **4K / 8K / 60FPS** video and **320 kbps MP3** with embedded metadata.
- **Batch / playlist** downloads with live progress over WebSockets.
- **Mobile friendly** — open it from your phone on the same Wi-Fi.
- Multi-format (MP4, WebM, MP3, M4A) with automatic cover-art tagging.

### 🚀 Quick start (Windows)

1. Install [Python 3.10+](https://www.python.org/downloads/) (✅ "Add Python to PATH")
   and [Node.js 18+](https://nodejs.org/), plus **FFmpeg** on your PATH.
2. Double-click **`setup_windows.bat`** to install dependencies.
3. Double-click **`run_app.bat`** — opens at `http://localhost:3000`.

### 🧑‍💻 Manual (dev)

```bash
# Backend
cd backend
python -m venv venv && venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Frontend (new terminal)
cd frontend
npm install && npm run dev      # http://localhost:3000
```

📖 **Full web app guide** (FFmpeg setup, mobile access, troubleshooting):
**[`docs/WEB_APP.md`](docs/WEB_APP.md)**.

---

## ⚖️ Disclaimer & credits

Both apps are powered by [**yt-dlp**](https://github.com/yt-dlp/yt-dlp) and
[**FFmpeg**](https://ffmpeg.org/). Please download only content you own or have
permission to download, and respect the rights of content owners and YouTube's
Terms of Service. *Educational purposes only.*

<div align="center">
<sub>Made with ❤️ by <b><a href="https://www.jayasakthi.in">Jayasakthi</a></b> · www.jayasakthi.in</sub>
</div>
