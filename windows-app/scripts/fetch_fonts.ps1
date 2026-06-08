<#
.SYNOPSIS
  Downloads the Inter typeface (static TTFs) into assets\fonts\.
  JetBrains Mono is copied from the local font\ folder separately.
#>
$ErrorActionPreference = 'Stop'
$root    = Split-Path -Parent $PSScriptRoot
$fontDir = Join-Path $root 'assets\fonts'
New-Item -ItemType Directory -Force -Path $fontDir | Out-Null

Write-Host 'Downloading Inter 4.0 ...' -ForegroundColor Cyan
$url    = 'https://github.com/rsms/inter/releases/download/v4.0/Inter-4.0.zip'
$tmpZip = Join-Path $env:TEMP 'inter-tubevault.zip'
$tmpDir = Join-Path $env:TEMP 'inter-tubevault'
Invoke-WebRequest -Uri $url -OutFile $tmpZip
if (Test-Path $tmpDir) { Remove-Item -Recurse -Force $tmpDir }
Expand-Archive -Path $tmpZip -DestinationPath $tmpDir

$want = 'Inter-Regular.ttf','Inter-Medium.ttf','Inter-SemiBold.ttf','Inter-Bold.ttf'
foreach ($name in $want) {
  $f = Get-ChildItem -Path $tmpDir -Recurse -Filter $name | Select-Object -First 1
  if ($null -eq $f) { throw "Not found in archive: $name" }
  Copy-Item $f.FullName (Join-Path $fontDir $name) -Force
}
Remove-Item -Force $tmpZip
Remove-Item -Recurse -Force $tmpDir

Write-Host 'Done. Fonts in assets\fonts:' -ForegroundColor Green
Get-ChildItem $fontDir -Filter '*.ttf' | ForEach-Object { $_.Name } | Write-Host
