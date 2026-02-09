@echo off
setlocal
title Youtube Downloader Launcher

echo ===================================================
echo      Starting Youtube Downloader...
echo ===================================================

if not exist backend\venv (
    echo [ERROR] Virtual environment not found.
    echo Please run 'setup_windows.bat' first!
    pause
    exit /b
)

:: Start Backend
echo Starting Backend Server...
start "Vortex Backend" cmd /k "cd backend && venv\Scripts\activate && python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"

:: Start Frontend
echo Starting Frontend Server...
start "Vortex Frontend" cmd /k "cd frontend && npm run dev"

echo.
echo [INFO] Servers are starting...
echo [INFO] Backend: http://localhost:8000
echo [INFO] Frontend: http://localhost:3000
echo.
echo Opening App in Browser...
timeout /t 5 >nul
start http://localhost:3000

echo App is running! Close this window to stop nothing (you must close the other two windows).
pause
