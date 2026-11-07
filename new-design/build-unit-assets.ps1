Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$sourceRoot = Join-Path $PSScriptRoot 'source-assets\reignition-units'
$outputRoot = Join-Path $root 'mods\reignition\bits'

$assets = @(
    @{ Source = 'nu_dest'; World = 'reignition-dd' },
    @{ Source = 'nu_ftrk'; World = 'reignition-ftrk' },
    @{ Source = 'nu_harv'; World = 'reignition-harv' },
    @{ Source = 'nu_howz'; World = 'reignition-arty' },
    @{ Source = 'nu_htnk'; World = 'reignition-4tnk' },
    @{ Source = 'nu_ifv'; World = 'reignition-apc' },
    @{ Source = 'nu_kirov'; World = 'reignition-kirov' },
    @{ Source = 'nu_mig'; World = 'reignition-mig' },
    @{ Source = 'nu_sub'; World = 'reignition-ss' },
    @{ Source = 'nu_ttnk'; World = 'reignition-ttnk' },
    @{ Source = 'nu_v3'; World = 'reignition-v2rl' }
)

# MH60 now uses the layered nhaw artwork. Rebuild it separately with
# build-nhaw-animation.py so this static asset pass cannot erase its animation.

function New-Cutout([string]$path) {
    $source = [System.Drawing.Bitmap]::new($path)
    $bitmap = [System.Drawing.Bitmap]::new($source.Width, $source.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bitmap)
    try { $g.DrawImage($source, 0, 0, $source.Width, $source.Height) }
    finally { $g.Dispose(); $source.Dispose() }

    # The supplied concept renders include a small watermark in the lower-left corner.
    $watermarkY = [int]($bitmap.Height * 0.90)
    for ($y = 0; $y -lt $bitmap.Height; $y++) {
        for ($x = 0; $x -lt $bitmap.Width; $x++) {
            if ($x -lt [int]($bitmap.Width * 0.27) -and $y -ge $watermarkY) {
                $bitmap.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
            }
        }
    }

    $minX = $bitmap.Width; $minY = $bitmap.Height; $maxX = -1; $maxY = -1
    for ($y = 0; $y -lt $bitmap.Height; $y++) {
        for ($x = 0; $x -lt $bitmap.Width; $x++) {
            if ($bitmap.GetPixel($x, $y).A -gt 16) {
                $minX = [Math]::Min($minX, $x); $minY = [Math]::Min($minY, $y)
                $maxX = [Math]::Max($maxX, $x); $maxY = [Math]::Max($maxY, $y)
            }
        }
    }
    if ($maxX -lt 0) { $bitmap.Dispose(); throw "No visible artwork found in $path" }
    $bounds = [System.Drawing.Rectangle]::FromLTRB($minX, $minY, $maxX + 1, $maxY + 1)
    return @{ Bitmap = $bitmap; Bounds = $bounds }
}

function Save-Scaled([hashtable]$cutout, [string]$path, [int]$width, [int]$height, [int]$maxWidth, [int]$maxHeight) {
    $bitmap = [System.Drawing.Bitmap]::new($width, $height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $g.Clear([System.Drawing.Color]::Transparent)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $scale = [Math]::Min($maxWidth / [double]$cutout.Bounds.Width, $maxHeight / [double]$cutout.Bounds.Height)
        $drawWidth = [int][Math]::Round($cutout.Bounds.Width * $scale)
        $drawHeight = [int][Math]::Round($cutout.Bounds.Height * $scale)
        $destination = [System.Drawing.Rectangle]::new(
            [int](($width - $drawWidth) / 2), [int](($height - $drawHeight) / 2), $drawWidth, $drawHeight)
        $g.DrawImage($cutout.Bitmap, $destination, $cutout.Bounds.X, $cutout.Bounds.Y,
            $cutout.Bounds.Width, $cutout.Bounds.Height, [System.Drawing.GraphicsUnit]::Pixel)
        $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally { $g.Dispose(); $bitmap.Dispose() }
}

foreach ($asset in $assets) {
    $sourcePath = Join-Path $sourceRoot ("large\{0}.png" -f $asset.Source)
    $iconPath = Join-Path $sourceRoot ("icons\{0}.png" -f $asset.Source)
    $cutout = New-Cutout $sourcePath
    $icon = New-Cutout $iconPath
    try {
        Save-Scaled $cutout (Join-Path $outputRoot ("{0}.png" -f $asset.World)) 128 128 116 116
        Save-Scaled $icon (Join-Path $outputRoot ("{0}-icon.png" -f $asset.World)) 64 48 58 44
    }
    finally {
        $cutout.Bitmap.Dispose()
        $icon.Bitmap.Dispose()
    }
}

Write-Output ("Rebuilt {0} unit sprites and icons." -f $assets.Count)
