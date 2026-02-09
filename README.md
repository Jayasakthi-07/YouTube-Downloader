<div align="center">

# 🌀 VORTEX DOWNLOADER
### *The Ultimate 4K Video & Audio Experience*

[![Next.js](https://img.shields.io/badge/Next.js-15-black?style=for-the-badge&logo=next.js&logoColor=white)](https://nextjs.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-MIT-purple?style=for-the-badge)](LICENSE)

<br />

**[ 🚀 LAUNCH APP ](#-quick-start-windows)**
&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;
**[ 📖 READ DOCS ](#-usage-guide)**
&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;
**[ 🐛 REPORT BUG ](https://github.com/Jayasakthi-07/Youtube-Downloader/issues)**

<br />

> *Experience the future of media downloading. Blazing speeds, 8K support, and a stunning Glassmorphism UI.*

</div>

---

## ✨ Why Choose Vortex?

| 🚀 Extreme Performance | 🎨 Stunning Interface | 🎧 Audiophile Quality |
| :--- | :--- | :--- |
| Download **4K, 8K, & 60FPS** videos instantly with our optimized backend engine. | A modern, responsive **Cyberpunk/Glass UI** that looks amazing on any device. | Extract crystal clear **320kbps MP3s** with automatic metadata tagging. |

<details>
<summary><b>🔥 Click to see more features</b></summary>

- **Batch Downloads**: Paste a playlist link and download entire albums/series at once.
- **Real-Time Progress**: Watch the download bar fill up live via WebSockets.
- **Mobile Friendly**: Access the app from your phone on the same Wi-Fi network.
- **Auto-Retry**: Smart networking handles temporary connection drops.
- **Format Selection**: Choose between MP4, WebM, MP3, M4A, and more.

</details>

---

## 🚀 Quick Start (Windows)

We've automated everything for you. Get up and running in **seconds**.

### 1️⃣ Prerequisite Check
Ensure you have these installed:
- [**Python 3.10+**](https://www.python.org/downloads/) (⚠️ Check **"Add into PATH"** during install)
- [**Node.js 18+**](https://nodejs.org/)
- **FFmpeg** (See the [Setup Guide](#-ffmpeg-setup-critical) below)

### 2️⃣ One-Click Setup
Double-click the **`setup_windows.bat`** file.
> ☕ Grab a coffee while it installs dependencies for you.

### 3️⃣ Launch
Double-click the **`run_app.bat`** file.
> 🌐 The app will automatically open in your browser!

---

## �️ FFmpeg Setup (Critical)

**Vortex needs FFmpeg** to merge high-quality video and audio streams. Without it, downloads may fail or have no sound.

> [!IMPORTANT]
> **Windows Users:**
> 1. Download `ffmpeg-git-full.7z` from [gyan.dev](https://www.gyan.dev/ffmpeg/builds/).
> 2. Extract and rename the folder to `ffmpeg`.
> 3. Move it to `C:\ffmpeg`.
> 4. Add `C:\ffmpeg\bin` to your **System Environment Path**.
> 5. **Restart your PC** or Terminal to apply changes.

---

## � Mobile Access (Wi-Fi)

Want to download directly to your phone?

1. Ensure your PC and Phone are on the **same Wi-Fi**.
2. Open Command Prompt (`Win+R` -> `cmd`) and type `ipconfig`.
3. Note your **IPv4 Address** (e.g., `192.168.1.5`).
4. On your phone, go to: `http://192.168.1.5:3000`

---

## 🔧 Troubleshooting

<details>
<summary><b>❌ "FFmpeg not found" Error</b></summary>

- Ensure you installed FFmpeg correctly as per the guide above.
- Verify by typing `ffmpeg -version` in a new terminal.
- Restart the release `run_app.bat` script.

</details>

<details>
<summary><b>❌ "Port already in use"</b></summary>
 
- You might have another instance running properly. 
- Close all terminal windows and try again.

</details>

<details>
<summary><b>❌ Download Stuck at 0% / Network Error</b></summary>

- Check if the **Backend Terminal** (the black window) is running and shows no errors.
- Ensure your internet connection is stable.

</details>

---

<div align="center">

Made with ❤️ by **Jayasakthi-07**
<br />
<sub><i>(Educational Purpose Only. Please respect copyright laws.)</i></sub>

</div>
