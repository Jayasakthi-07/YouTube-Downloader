
<div align="center">

# 🌀 VORTEX DOWNLOADER
### *The Ultimate 4K/8K Video & Audio Experience*

[![Next.js](https://img.shields.io/badge/Next.js-15-black?style=for-the-badge&logo=next.js&logoColor=white)](https://nextjs.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![TailwindCSS](https://img.shields.io/badge/Tailwind_CSS-4.0+-38B2AC?style=for-the-badge&logo=tailwind-css&logoColor=white)](https://tailwindcss.com/)
[![License](https://img.shields.io/badge/License-MIT-purple?style=for-the-badge)](LICENSE)

<br />

**[ 🚀 LAUNCH APP (Windows) ](#-quick-start-windows)**
&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;
**[ 🎥 WATCH TUTORIAL ](https://youtu.be/hwNWx1GTSKo?si=-hAhvPGS9mHC1Ia-)**
&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;
**[ 🐛 REPORT BUG ](https://github.com/Jayasakthi-07/Youtube-Downloader/issues)**

<br />

> *Experience the future of media downloading. Blazing speeds, 8K support, and a stunning Glassmorphism UI.*

</div>

---

## ✨ Why Choose Vortex?

Vortex isn't just another downloader. It's a powerhouse built for quality and speed.

| 🚀 Extreme Performance | 🎨 Stunning Interface | 🎧 Audiophile Quality |
| :--- | :--- | :--- |
| Download **4K, 8K, & 60FPS** videos instantly with our optimized backend engine. | A modern, responsive **Cyberpunk/Glass UI** that looks amazing on any device. | Extract crystal clear **320kbps MP3s** with automatic metadata tagging. |

### 🔥 Key Features

- **Batch Downloads**: Paste a playlist link and download entire albums/series at once.
- **Real-Time Progress**: Watch the download bar fill up live via WebSockets.
- **Mobile Friendly**: Access the app from your phone on the same Wi-Fi network.
- **Smart Networking**: Auto-Retry handles temporary connection drops.
- **Multi-Format**: Choose between MP4, WebM, MP3, M4A, and more.
- **Metadata Embedded**: Cover art, artist, and title are automatically embedded in audio files.

---

## 🛠️ Tech Stack

Vortex is built with the latest technologies for maximum performance and maintainability.

### **Frontend**
- **Framework**: [Next.js 15](https://nextjs.org/) (App Router)
- **UI Library**: [Shadcn UI](https://ui.shadcn.com/) + [Radix UI](https://www.radix-ui.com/)
- **Styling**: [Tailwind CSS v4](https://tailwindcss.com/)
- **Icons**: [Lucide React](https://lucide.dev/)

### **Backend**
- **API Framework**: [FastAPI](https://fastapi.tiangolo.com/)
- **Core Engine**: [yt-dlp](https://github.com/yt-dlp/yt-dlp) (The best downloader engine)
- **Concurrency**: Asynchronous tasks with Python `asyncio`
- **Validation**: [Pydantic v2](https://docs.pydantic.dev/)

---

## 🚀 Quick Start (Windows)

> [!TIP]
> **New to Vortex?** Watch the **[Step-by-Step Video Tutorial](https://youtu.be/hwNWx1GTSKo?si=-hAhvPGS9mHC1Ia-)** for a complete walkthrough.
>
> [![Watch Tutorial](https://img.youtube.com/vi/hwNWx1GTSKo/0.jpg)](https://youtu.be/hwNWx1GTSKo?si=-hAhvPGS9mHC1Ia-)

We've automated everything for you. Get up and running in **seconds**.

### 1️⃣ Prerequisite Check
Ensure you have these installed:
- [**Python 3.10+**](https://www.python.org/downloads/) (⚠️ **Crucial:** Check **"Add Python to PATH"** during install)
- [**Node.js 18+**](https://nodejs.org/)
- **FFmpeg** (See the [Setup Guide](#-ffmpeg-setup-critical) below)

### 2️⃣ One-Click Setup
Double-click the **`setup_windows.bat`** file in the root directory.
> ☕ Grab a coffee while it installs backend and frontend dependencies automatically.

### 3️⃣ Launch
Double-click the **`run_app.bat`** file.
> 🌐 The app will automatically open in your browser at `http://localhost:3000`.

---

## 💻 Manual Installation (Dev)

Prefer the command line? Here is how to set it up manually.

### Backend Setup
```bash
cd backend
python -m venv venv
# Activate venv:
# Windows: venv\Scripts\activate
# Mac/Linux: source venv/bin/activate

pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend Setup
Open a new terminal:
```bash
cd frontend
npm install
npm run dev
# App runs at http://localhost:3000
```

---

## ⚠️ FFmpeg Setup (Critical)

**Vortex needs FFmpeg** to merge high-quality video and audio streams (e.g., 1080p+ usually separates audio/video). Without specific FFmpeg setup, downloads may fail or have no sound.

> [!IMPORTANT]
> **Windows Users:**
> 1. Download `ffmpeg-git-full.7z` from [gyan.dev](https://www.gyan.dev/ffmpeg/builds/).
> 2. Extract and rename the folder to `ffmpeg`.
> 3. Move it to `C:\ffmpeg`.
> 4. **Add to Path**: Search "Edit the system environment variables" -> Environment Variables -> System variables -> Path -> Edit -> New -> Add `C:\ffmpeg\bin`.
> 5. **Restart your PC** or Terminal to apply changes.

Verify installation by running:
```bash
ffmpeg -version
```

---

## 📱 Mobile Access (Local Wi-Fi)

Want to download directly to your phone?

1. Ensure your PC and Phone are on the **same Wi-Fi**.
2. Open Command Prompt (`Win+R` -> `cmd`) and type `ipconfig`.
3. Note your **IPv4 Address** (e.g., `192.168.1.5`).
4. On your phone browser, go to: `http://192.168.1.5:3000`

---

## 🔧 Troubleshooting

<details>
<summary><b>❌ "FFmpeg not found" Error</b></summary>

- Ensure you added FFmpeg to your System PATH.
- Restart your computer after installing FFmpeg.
- Verify by typing `ffmpeg -version` in a new terminal window.
</details>

<details>
<summary><b>❌ "Port already in use"</b></summary>
 
- You might have another instance running.
- Close all terminal windows and try running `run_app.bat` again.
- Or manually kill the process on port 3000/8000.
</details>

<details>
<summary><b>❌ Download Stuck at 0%</b></summary>

- Check the **Backend Terminal** (the black window) for error messages.
- Ensure you have a stable internet connection.
- Some YouTube videos (like Age Restricted ones) might require cookies (feature coming soon).
</details>

---

## 🗺️ Roadmap

- [ ] 🎵 **MP3 Metadata Editor**: Manually edit tags before downloading.
- [ ] 🍪 **Cookies Support**: Download age-restricted or member-only videos.
- [ ] ☁️ **Cloud Upload**: Upload directly to Google Drive/Dropbox.
- [ ] 🌑 **Dark/Light Mode**: Toggle between themes.

---

## 🤝 Contributing

Contributions are always welcome!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

<div align="center">

Made with ❤️ by **Jayasakthi-07**
<br />
<sub><i>(Educational Purpose Only. Please respect copyright laws.)</i></sub>

</div>
