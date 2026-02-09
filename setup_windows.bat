@echo off
setlocal
title Youtube Downloader Setup

echo ===================================================
echo      Youtube Downloader - One-Time Setup
echo ===================================================
echo.

:: 1. Check for Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python is not installed or not in PATH.
    echo Please download and install Python 3.10+ from python.org
    echo IMPORTANT: Check "Add Python to PATH" during installation.
    pause
    exit /b
)
echo [OK] Python found.

:: 2. Check for Node.js
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js is not installed or not in PATH.
    echo Please download and install Node.js 18+ from nodejs.org
    pause
    exit /b
)
echo [OK] Node.js found.

:: 3. Check for FFmpeg (Optional but recommended to warn)
ffmpeg -version >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] FFmpeg is not found in your PATH.
    echo Backend will try to use a local 'ffmpeg' if configured, but it is highly recommended to install it.
    echo See the README for instructions.
) else (
    echo [OK] FFmpeg found.
)

echo.
echo ---------------------------------------------------
echo Setting up Backend (Python)...
echo ---------------------------------------------------
cd backend

if not exist venv (
    echo Creating virtual environment...
    python -m venv venv
)

echo Installing dependencies...
call venv\Scripts\activate.bat
pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install backend dependencies.
    pause
    exit /b
)

cd ..
echo.
echo ---------------------------------------------------
echo Setting up Frontend (Node.js)...
echo ---------------------------------------------------
cd frontend
echo Installing dependencies (this may take a moment)...
call npm install
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install frontend dependencies.
    pause
    exit /b
)

cd ..
echo.
echo ===================================================
echo           Setup Complete! ^_^+
echo ===================================================
echo You can now run the app using 'run_app.bat'
echo.
pause
