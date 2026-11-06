Add-Type -AssemblyName System.Drawing
& (Join-Path $PSScriptRoot 'rebuild-mcv-assets.ps1')
$sourcePath = Join-Path $PSScriptRoot '..\mods\reignition\bits\daxia-fact.png'
$source = [System.Drawing.Bitmap]::new($sourcePath)
$preview = [System.Drawing.Bitmap]::new(360, 200)
$graphics = [System.Drawing.Graphics]::FromImage($preview)
$graphics.Clear([System.Drawing.Color]::Black)
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$scale = [Math]::Min(360.0 / $source.Width, 200.0 / $source.Height)
$width = [int]($source.Width * $scale)
$height = [int]($source.Height * $scale)
$graphics.DrawImage($source, [int]((360 - $width) / 2), [int]((200 - $height) / 2), $width, $height)
$preview.Save('D:\code\OpenRA\mods\reignition\maps\rift-outpost\map.png', [System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose()
$preview.Dispose()
$source.Dispose()
Write-Output 'Deployed MCV restored for command core and mission preview.'
