Add-Type -AssemblyName System.Drawing
$sourcePath = Join-Path $PSScriptRoot 'source-assets\reignition-nuclear-reference.png'
$output = Join-Path $PSScriptRoot '..\mods\reignition\bits'
$source = [System.Drawing.Bitmap]::new($sourcePath)
$cutout = [System.Drawing.Bitmap]::new($source.Width, $source.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$path = [System.Drawing.Drawing2D.GraphicsPath]::new()

# Preserve the dark machinery inside the silhouette instead of treating it as background.
# Exclude the reference backdrop, watermark and title beneath the building.
$outline = '30,334 64,316 27,296 27,264 53,250 30,240 31,217 41,190 68,179 80,97 80,80 88,71 109,64 133,65 153,72 156,49 154,39 162,32 178,27 202,25 223,31 232,39 231,57 233,99 240,127 258,104 279,88 300,75 330,61 351,52 378,47 405,49 431,61 449,73 470,89 492,114 511,143 524,155 546,165 579,178 581,141 587,132 601,129 614,136 617,150 629,144 641,143 653,149 657,171 668,158 681,155 693,162 697,179 695,213 706,229 706,244 723,253 723,266 734,277 740,294 720,312 698,328 688,353 657,375 628,392 603,405 576,419 547,435 523,450 505,465 435,466 427,476 319,478 291,467 276,470 239,456 193,435 194,424 150,408 111,387 75,371 31,350'
$points = [System.Drawing.Point[]]@($outline.Split(' ') | ForEach-Object {
    $xy = $_.Split(',')
    [System.Drawing.Point]::new([int]$xy[0], [int]$xy[1])
})
$path.AddPolygon($points)
$texture = [System.Drawing.TextureBrush]::new($source)
$graphics = [System.Drawing.Graphics]::FromImage($cutout)
try {
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.FillPath($texture, $path)
    $bounds = [System.Drawing.Rectangle]::Ceiling($path.GetBounds())
    foreach ($entry in @(
        @{ Name = 'reignition-nuclear.png'; Width = 192; Height = 160; ArtWidth = 168; ArtHeight = 144 },
        @{ Name = 'reignition-nuclear-icon.png'; Width = 64; Height = 48; ArtWidth = 58; ArtHeight = 42 }
    )) {
        $bitmap = [System.Drawing.Bitmap]::new($entry.Width, $entry.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $g = [System.Drawing.Graphics]::FromImage($bitmap)
        $attributes = [System.Drawing.Imaging.ImageAttributes]::new()
        try {
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $attributes.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
            $scale = [Math]::Min($entry.ArtWidth / [double]$bounds.Width, $entry.ArtHeight / [double]$bounds.Height)
            $width = [int][Math]::Round($bounds.Width * $scale)
            $height = [int][Math]::Round($bounds.Height * $scale)
            $destination = [System.Drawing.Rectangle]::new(
                [int](($entry.Width - $width) / 2), [int](($entry.Height - $height) / 2), $width, $height)
            $g.DrawImage($cutout, $destination, $bounds.X, $bounds.Y, $bounds.Width, $bounds.Height,
                [System.Drawing.GraphicsUnit]::Pixel, $attributes)
            $bitmap.Save((Join-Path $output $entry.Name), [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $attributes.Dispose()
            $g.Dispose()
            $bitmap.Dispose()
        }
    }
}
finally {
    $graphics.Dispose()
    $texture.Dispose()
    $path.Dispose()
    $cutout.Dispose()
    $source.Dispose()
}
Write-Output 'Nuclear reactor world sprite and production icon rebuilt from the supplied reference.'
