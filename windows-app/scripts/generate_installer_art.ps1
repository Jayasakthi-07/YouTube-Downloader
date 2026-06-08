<#
.SYNOPSIS
  Generates the Inno Setup wizard images (branded TubeVault):
    installer\wizard-large.bmp  (left banner on Welcome/Finished pages)
    installer\wizard-small.bmp  (small logo on interior page headers)
  Inno Setup requires BMP for these images.
#>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$out  = Join-Path $root 'installer'
New-Item -ItemType Directory -Force -Path $out | Out-Null

$blue = [System.Drawing.Color]::FromArgb(255, 10, 132, 255)
$cyan = [System.Drawing.Color]::FromArgb(255, 100, 210, 255)

function New-RoundedPath($x, $y, $w, $h, $r) {
  $d = $r * 2
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath
  $p.AddArc($x, $y, $d, $d, 180, 90)
  $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
  $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $p.CloseAllFigures()
  return $p
}

# ---- Large banner (2x of 164x314) -----------------------------------------
$lw = 328; $lh = 628
$big = New-Object System.Drawing.Bitmap($lw, $lh)
$g = [System.Drawing.Graphics]::FromImage($big)
$g.SmoothingMode = 'AntiAlias'
$g.TextRenderingHint = 'ClearTypeGridFit'
$rect = New-Object System.Drawing.Rectangle(0, 0, $lw, $lh)
$grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $blue, $cyan, 90)
$g.FillRectangle($grad, $rect)

# Soft white disc behind the glyph
$discR = 78; $cx = $lw / 2; $cy = 250
$disc = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(46, 255, 255, 255))
$g.FillEllipse($disc, $cx - $discR, $cy - $discR, $discR * 2, $discR * 2)

# White play triangle
$tri = @(
  (New-Object System.Drawing.PointF([single]($cx - 26), [single]($cy - 40))),
  (New-Object System.Drawing.PointF([single]($cx - 26), [single]($cy + 40))),
  (New-Object System.Drawing.PointF([single]($cx + 44), [single]$cy))
)
$g.FillPolygon((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)), $tri)

# Wordmark + tagline
$white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$soft  = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 255, 255, 255))
$fmt = New-Object System.Drawing.StringFormat
$fmt.Alignment = 'Center'
$titleFont = New-Object System.Drawing.Font('Segoe UI', 30, [System.Drawing.FontStyle]::Bold)
$tagFont   = New-Object System.Drawing.Font('Segoe UI', 13, [System.Drawing.FontStyle]::Regular)
$g.DrawString('TubeVault', $titleFont, $white, (New-Object System.Drawing.RectangleF(0, 360, $lw, 50)), $fmt)
$g.DrawString('YouTube Downloader', $tagFont, $soft, (New-Object System.Drawing.RectangleF(0, 408, $lw, 30)), $fmt)
$g.Dispose()
$big.Save((Join-Path $out 'wizard-large.bmp'), [System.Drawing.Imaging.ImageFormat]::Bmp)
$big.Dispose()

# ---- Small header logo (2x of 55x58) --------------------------------------
$sw = 110; $sh = 116
$sm = New-Object System.Drawing.Bitmap($sw, $sh)
$g2 = [System.Drawing.Graphics]::FromImage($sm)
$g2.SmoothingMode = 'AntiAlias'
$g2.Clear([System.Drawing.Color]::White)   # interior page header is white
$icon = 92; $ix = ($sw - $icon) / 2; $iy = ($sh - $icon) / 2
$path = New-RoundedPath $ix $iy $icon $icon 22
$irect = New-Object System.Drawing.Rectangle($ix, $iy, $icon, $icon)
$ig = New-Object System.Drawing.Drawing2D.LinearGradientBrush($irect, $blue, $cyan, 45)
$g2.FillPath($ig, $path)
$icx = $sw / 2; $icy = $sh / 2
$tri2 = @(
  (New-Object System.Drawing.PointF([single]($icx - 14), [single]($icy - 20))),
  (New-Object System.Drawing.PointF([single]($icx - 14), [single]($icy + 20))),
  (New-Object System.Drawing.PointF([single]($icx + 20), [single]$icy))
)
$g2.FillPolygon((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)), $tri2)
$g2.Dispose()
$sm.Save((Join-Path $out 'wizard-small.bmp'), [System.Drawing.Imaging.ImageFormat]::Bmp)
$sm.Dispose()

Write-Host 'Wrote installer\wizard-large.bmp and installer\wizard-small.bmp' -ForegroundColor Green
