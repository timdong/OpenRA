Add-Type -AssemblyName System.Drawing
$folder = 'D:\code\OpenRA\mods\reignition\bits'
$names = @('daxia-fact', 'daxia-weap', 'daxia-barr', 'daxia-lab', 'daxia-refinery', 'daxia-silo', 'daxia-powr', 'daxia-dome', 'daxia-gun', 'crimson-tsla', 'allied-pdox')
foreach ($name in $names) {
    $source = New-Object System.Drawing.Bitmap (Join-Path $folder ($name + '.png'))
    $icon = [System.Drawing.Bitmap]::new(64, 48, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($icon)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $scale = [Math]::Min(58.0 / $source.Width, 42.0 / $source.Height)
    $width = [Math]::Max(1, [int][Math]::Round($source.Width * $scale))
    $height = [Math]::Max(1, [int][Math]::Round($source.Height * $scale))
    $graphics.DrawImage($source, [int]((64 - $width) / 2), [int]((48 - $height) / 2), $width, $height)
    $icon.Save((Join-Path $folder ($name + '-icon.png')), [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $icon.Dispose()
    $source.Dispose()
}
Write-Output 'Building icons generated at 64x48.'
