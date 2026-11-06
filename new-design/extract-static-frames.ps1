Add-Type -AssemblyName System.Drawing
$folder = 'D:\code\OpenRA\mods\reignition\bits'
$vehicles = @('crimson-xingtian', 'allied-prism', 'daxia-houyi', 'crimson-thunderbolt', 'daxia-chidian', 'allied-hound', 'reignition-mcv')
foreach ($name in $vehicles) {
    $path = Join-Path $folder ($name + '.png')
    $source = [System.Drawing.Bitmap]::new($path)
    $output = [System.Drawing.Bitmap]::new(64, 56)
    $graphics = [System.Drawing.Graphics]::FromImage($output)
    $graphics.DrawImage($source, [System.Drawing.Rectangle]::new(0, 0, 64, 56), [System.Drawing.Rectangle]::new(0, 0, 64, 56), [System.Drawing.GraphicsUnit]::Pixel)
    $temp = $path + '.tmp.png'
    $output.Save($temp, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $output.Dispose()
    $source.Dispose()
    Copy-Item $temp $path -Force
    Remove-Item $temp
}
foreach ($name in @('daxia-rocket-walk', 'daxia-rocket-attack', 'daxia-rocket-idle')) {
    $path = Join-Path $folder ($name + '.png')
    $source = [System.Drawing.Bitmap]::new($path)
    $output = [System.Drawing.Bitmap]::new(40, 48)
    $graphics = [System.Drawing.Graphics]::FromImage($output)
    $graphics.DrawImage($source, [System.Drawing.Rectangle]::new(0, 0, 40, 48), [System.Drawing.Rectangle]::new(0, 0, 40, 48), [System.Drawing.GraphicsUnit]::Pixel)
    $temp = $path + '.tmp.png'
    $output.Save($temp, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $output.Dispose()
    $source.Dispose()
    Copy-Item $temp $path -Force
    Remove-Item $temp
}
Write-Output 'Static single-frame PNGs generated.'
