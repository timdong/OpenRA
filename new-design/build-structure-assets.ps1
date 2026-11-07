Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$sourceRoot = Join-Path $PSScriptRoot 'source-assets\reignition-structures'
$outputRoot = Join-Path $root 'mods\reignition\bits'

$assets = @(
    @{ Source = 'daxia-fact'; World = 'daxia-fact' },
    @{ Source = 'daxia-powr'; World = 'daxia-powr' },
    @{ Source = 'daxia-oref'; World = 'daxia-refinery' },
    @{ Source = 'daxia-barr'; World = 'daxia-barr' },
    @{ Source = 'daxia-depot'; World = 'daxia-depot' },
    @{ Source = 'daxia-dome'; World = 'daxia-dome' },
    @{ Source = 'daxia-weap'; World = 'daxia-weap' },
    @{ Source = 'daxia-lab'; World = 'daxia-lab' },
    @{ Source = 'daxia-flak'; World = 'daxia-flak' },
    @{ Source = 'daxia-gun'; World = 'daxia-gun' },
    @{ Source = 'daxia-syrd'; World = 'daxia-syrd' },
    @{ Source = 'daxia-silo'; World = 'daxia-silo' },
    @{ Source = 'daxia-mslo'; World = 'daxia-mslo' },
    @{ Source = 'daxia-nuke'; World = 'reignition-nuclear' },
    @{ Source = 'crimson-tsla'; World = 'crimson-tsla' },
    @{ Source = 'crimson-iron'; World = 'crimson-iron' },
    @{ Source = 'allied-pdox'; World = 'allied-pdox' },
    @{ Source = 'allied-gapt'; World = 'allied-gapt' }
)

function New-Cutout([string]$path, [bool]$whiteBackground) {
    $source = [System.Drawing.Bitmap]::new($path)
    $bitmap = [System.Drawing.Bitmap]::new($source.Width, $source.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bitmap)
    try { $g.DrawImage($source, 0, 0, $source.Width, $source.Height) }
    finally { $g.Dispose(); $source.Dispose() }

    # The supplied concept renders include a small watermark in the lower-left corner.
    $watermarkY = [int]($bitmap.Height * 0.90)
    for ($y = 0; $y -lt $bitmap.Height; $y++) {
        for ($x = 0; $x -lt $bitmap.Width; $x++) {
            $pixel = $bitmap.GetPixel($x, $y)
            $remove = $false
            if ($x -lt [int]($bitmap.Width * 0.27) -and $y -ge $watermarkY) { $remove = $true }
            if ($whiteBackground -and $pixel.R -gt 235 -and $pixel.G -gt 235 -and $pixel.B -gt 235) { $remove = $true }
            if ($remove) { $bitmap.SetPixel($x, $y, [System.Drawing.Color]::Transparent) }
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
    $cutout = New-Cutout $sourcePath $false
    $icon = New-Cutout $iconPath $false
    try {
        Save-Scaled $cutout (Join-Path $outputRoot ("{0}.png" -f $asset.World)) 192 192 176 176
        Save-Scaled $icon (Join-Path $outputRoot ("{0}-icon.png" -f $asset.World)) 64 48 58 44
    }
    finally { $cutout.Bitmap.Dispose(); $icon.Bitmap.Dispose() }
}

# Convert the six-frame white-background deployment GIF into a transparent PNG sheet.
$gifPath = Join-Path $sourceRoot 'large\reignition-mcv-deploy.gif'
$gif = [System.Drawing.Bitmap]::new($gifPath)
$dimension = [System.Drawing.Imaging.FrameDimension]::new($gif.FrameDimensionsList[0])
$frameCount = $gif.GetFrameCount($dimension)
$sheet = [System.Drawing.Bitmap]::new(192 * $frameCount, 192, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$sheetGraphics = [System.Drawing.Graphics]::FromImage($sheet)
try {
    $sheetGraphics.Clear([System.Drawing.Color]::Transparent)
    for ($i = 0; $i -lt $frameCount; $i++) {
        $gif.SelectActiveFrame($dimension, $i)
        $framePath = Join-Path $env:TEMP ("reignition-mcv-frame-{0}.png" -f $i)
        $gif.Save($framePath, [System.Drawing.Imaging.ImageFormat]::Png)
        $cutout = New-Cutout $framePath $true
        try {
            $scale = [Math]::Min(176 / [double]$cutout.Bounds.Width, 176 / [double]$cutout.Bounds.Height)
            $drawWidth = [int][Math]::Round($cutout.Bounds.Width * $scale)
            $drawHeight = [int][Math]::Round($cutout.Bounds.Height * $scale)
            $destination = [System.Drawing.Rectangle]::new(
                $i * 192 + [int]((192 - $drawWidth) / 2), [int]((192 - $drawHeight) / 2), $drawWidth, $drawHeight)
            $sheetGraphics.DrawImage($cutout.Bitmap, $destination, $cutout.Bounds.X, $cutout.Bounds.Y,
                $cutout.Bounds.Width, $cutout.Bounds.Height, [System.Drawing.GraphicsUnit]::Pixel)
        }
        finally { $cutout.Bitmap.Dispose(); Remove-Item $framePath -Force | Out-Null }
    }
    $sheet.Save((Join-Path $outputRoot 'reignition-mcv-deploy.png'), [System.Drawing.Imaging.ImageFormat]::Png)
}
finally { $sheetGraphics.Dispose(); $sheet.Dispose(); $gif.Dispose() }

Write-Output ("Rebuilt {0} structure sprites/icons and a {1}-frame MCV deployment sheet." -f $assets.Count, $frameCount)
