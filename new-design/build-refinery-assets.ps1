Add-Type -AssemblyName System.Drawing
$sourcePath = Join-Path $PSScriptRoot 'source-assets\daxia-refinery-reference.png'
$output = Join-Path $PSScriptRoot '..\mods\reignition\bits'
$source = [System.Drawing.Bitmap]::new($sourcePath)
$cutout = [System.Drawing.Bitmap]::new($source.Width, $source.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$path = [System.Drawing.Drawing2D.GraphicsPath]::new()

# Preserve the dark machinery inside the silhouette instead of treating it as background.
# Exclude the rectangular backdrop, cropped caption and smoke above the chimneys.
$outline = '7,191 13,176 24,166 35,158 38,140 47,137 50,148 71,138 73,110 70,100 89,82 108,69 116,55 165,35 181,35 200,48 207,42 207,26 217,24 221,29 219,61 231,66 235,60 235,34 243,31 249,36 245,69 258,72 260,66 270,73 274,91 275,102 298,111 315,123 321,141 328,148 333,144 339,148 338,160 350,168 350,177 359,183 365,194 361,201 345,211 328,221 311,226 297,238 277,247 256,258 239,264 225,276 208,279 192,269 175,269 158,256 140,251 125,244 109,238 94,235 80,225 64,220 46,214 31,211 15,204'
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
        @{ Name = 'daxia-refinery.png'; Width = 192; Height = 160; ArtWidth = 168; ArtHeight = 144 },
        @{ Name = 'daxia-refinery-icon.png'; Width = 64; Height = 48; ArtWidth = 58; ArtHeight = 42 }
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
Write-Output 'Refinery world sprite and production icon rebuilt from the supplied reference.'
