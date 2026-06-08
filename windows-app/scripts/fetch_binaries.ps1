<#
.SYNOPSIS
  Downloads yt-dlp.exe and ffmpeg.exe into assets\bin\ for bundling.

.DESCRIPTION
  Run this once before `flutter run` / `flutter build windows` so the app can
  resolve the engine binaries. These files are intentionally git-ignored.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\fetch_binaries.ps1
#>

$ErrorActionPreference = 'Stop'

$root   = Split-Path -Parent $PSScriptRoot
$binDir = Join-Path $root 'assets\bin'
New-Item -ItemType Directory -Force -Path $binDir | Out-Null

Write-Host 'Downloading yt-dlp.exe ...' -ForegroundColor Cyan
$ytdlp = 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe'
Invoke-WebRequest -Uri $ytdlp -OutFile (Join-Path $binDir 'yt-dlp.exe')

Write-Host 'Downloading FFmpeg (essentials build) ...' -ForegroundColor Cyan
$ffUrl = 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip'
$tmpZip = Join-Path $env:TEMP 'ffmpeg-tubevault.zip'
$tmpDir = Join-Path $env:TEMP 'ffmpeg-tubevault'
Invoke-WebRequest -Uri $ffUrl -OutFile $tmpZip

if (Test-Path $tmpDir) { Remove-Item -Recurse -Force $tmpDir }
Expand-Archive -Path $tmpZip -DestinationPath $tmpDir

$ffExe = Get-ChildItem -Path $tmpDir -Recurse -Filter 'ffmpeg.exe' |
         Select-Object -First 1
if ($null -eq $ffExe) { throw 'ffmpeg.exe not found in the downloaded archive.' }
Copy-Item $ffExe.FullName (Join-Path $binDir 'ffmpeg.exe') -Force

Remove-Item -Force $tmpZip
Remove-Item -Recurse -Force $tmpDir

Write-Host ''
Write-Host 'Done. Binaries placed in assets\bin:' -ForegroundColor Green
Get-ChildItem $binDir -Filter '*.exe' | ForEach-Object {
  '{0,-14} {1,8:N1} MB' -f $_.Name, ($_.Length / 1MB) | Write-Host
}
