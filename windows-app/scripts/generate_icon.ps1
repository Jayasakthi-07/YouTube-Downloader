<#
.SYNOPSIS
  Generates the TubeVault app icon (a blue rounded-square with a play glyph)
  as a MULTI-SIZE .ico (16,24,32,48,64,128,256) so Windows Explorer renders it
  crisply at every size. Writes to the Windows runner + tray locations.
  No external tools required (uses .NET System.Drawing).
#>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$sizes = 16, 24, 32, 48, 64, 128, 256

function Get-IconPng([int]$size) {
  $bmp = New-Object System.Drawing.Bitmap($size, $size)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.Clear([System.Drawing.Color]::Transparent)

  $r = [single]($size * 0.22)
  $d = $r * 2
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $path.AddArc(0, 0, $d, $d, 180, 90)
  $path.AddArc($size - $d, 0, $d, $d, 270, 90)
  $path.AddArc($size - $d, $size - $d, $d, $d, 0, 90)
  $path.AddArc(0, $size - $d, $d, $d, 90, 90)
  $path.CloseAllFigures()

  $rect = New-Object System.Drawing.Rectangle(0, 0, $size, $size)
  $c1 = [System.Drawing.Color]::FromArgb(255, 10, 132, 255)
  $c2 = [System.Drawing.Color]::FromArgb(255, 100, 210, 255)
  $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $c1, $c2, 45)
  $g.FillPath($brush, $path)

  # Play triangle (normalized to the 256px design, scaled to this size)
  $s = [single]$size
  $tri = @(
    (New-Object System.Drawing.PointF([single](0.398 * $s), [single](0.305 * $s))),
    (New-Object System.Drawing.PointF([single](0.398 * $s), [single](0.695 * $s))),
    (New-Object System.Drawing.PointF([single](0.734 * $s), [single](0.500 * $s)))
  )
  $g.FillPolygon((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)), $tri)
  $g.Dispose()

  $ms = New-Object System.IO.MemoryStream
  $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  return , $ms.ToArray()
}

function Write-Ico([string]$outPath, [int[]]$sizeList) {
  $pngs = @{}
  foreach ($sz in $sizeList) { $pngs[$sz] = Get-IconPng $sz }

  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $outPath) | Out-Null
  $fs = [System.IO.File]::Create($outPath)
  $bw = New-Object System.IO.BinaryWriter($fs)

  # ICONDIR
  $bw.Write([UInt16]0)
  $bw.Write([UInt16]1)
  $bw.Write([UInt16]$sizeList.Count)

  $offset = 6 + (16 * $sizeList.Count)
  foreach ($sz in $sizeList) {
    $len = $pngs[$sz].Length
    $dim = if ($sz -ge 256) { 0 } else { $sz }
    $bw.Write([Byte]$dim)        # width
    $bw.Write([Byte]$dim)        # height
    $bw.Write([Byte]0)           # palette
    $bw.Write([Byte]0)           # reserved
    $bw.Write([UInt16]1)         # planes
    $bw.Write([UInt16]32)        # bpp
    $bw.Write([UInt32]$len)      # bytes in resource
    $bw.Write([UInt32]$offset)   # offset
    $offset += $len
  }
  foreach ($sz in $sizeList) { $bw.Write($pngs[$sz]) }
  $bw.Flush(); $bw.Close(); $fs.Close()
}

$targets = @(
  (Join-Path $root 'windows\runner\resources\app_icon.ico'),
  (Join-Path $root 'assets\icons\tray.ico')
)
foreach ($t in $targets) {
  Write-Ico $t $sizes
  $kb = [math]::Round((Get-Item $t).Length / 1KB, 1)
  Write-Host "Wrote $t ($kb KB, $($sizes.Count) sizes)" -ForegroundColor Green
}
