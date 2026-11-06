Add-Type -AssemblyName System.Drawing
$source = [System.Drawing.Bitmap]::new('D:\code\OpenRA\mods\reignition\maps\rift-outpost\map.png')
$folder = 'D:\code\OpenRA\mods\reignition\bits'
foreach ($entry in @(@{ Width = 96; Height = 96; Name = 'daxia-fact.png' }, @{ Width = 64; Height = 48; Name = 'daxia-fact-icon.png' })) {
    $bitmap = [System.Drawing.Bitmap]::new($entry.Width, $entry.Height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $scale = [Math]::Min($entry.Width / $source.Width, $entry.Height / $source.Height)
    $drawWidth = [int]($source.Width * $scale)
    $drawHeight = [int]($source.Height * $scale)
    $graphics.DrawImage($source, [int](($entry.Width - $drawWidth) / 2), [int](($entry.Height - $drawHeight) / 2), $drawWidth, $drawHeight)
    $bitmap.Save((Join-Path $folder $entry.Name), [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bitmap.Dispose()
}
$source.Dispose()
Write-Output 'Command core and icon replaced with Daxia emblem.'
