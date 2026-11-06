Add-Type -AssemblyName System.Drawing
Add-Type @"
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public static class RocketLayoutBuilder
{
    public static void Rebuild(string sourcePath, string outputPath, int frameCount, int columns, int rows)
    {
        const int canvasWidth = 40;
        const int canvasHeight = 48;
        var source = new Bitmap(sourcePath);
        if (columns <= 0 || rows <= 0 || frameCount <= 0 || frameCount > columns * rows
            || source.Width % columns != 0 || source.Height % rows != 0)
        {
            source.Dispose();
            throw new System.ArgumentException("The source image must contain a complete grid of individual sprites.");
        }
        var frameWidth = source.Width / columns;
        // Source grid dimensions are independent of how many animation frames we use.
        var frameHeight = source.Height / rows;
        var output = new Bitmap(canvasWidth * frameCount, canvasHeight * 8, PixelFormat.Format32bppArgb);

        using (var graphics = Graphics.FromImage(output))
        {
            graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
            graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;
            for (var frame = 0; frame < frameCount; frame++)
            {
                var frameX = frame % columns * frameWidth;
                var frameY = frame / columns * frameHeight;
                using (var sprite = source.Clone(new Rectangle(frameX, frameY, frameWidth, frameHeight), PixelFormat.Format32bppArgb))
                {
                    var scale = System.Math.Min(34f / sprite.Width, 44f / sprite.Height);
                    var width = System.Math.Max(1, (int)System.Math.Round(sprite.Width * scale));
                    var height = System.Math.Max(1, (int)System.Math.Round(sprite.Height * scale));
                    for (var direction = 0; direction < 8; direction++)
                    {
                        using (var oriented = sprite.Clone(new Rectangle(0, 0, sprite.Width, sprite.Height), PixelFormat.Format32bppArgb))
                        {
                            if (direction >= 4)
                                oriented.RotateFlip(RotateFlipType.RotateNoneFlipX);
                            var x = frame * canvasWidth + (canvasWidth - width) / 2;
                            var y = direction * canvasHeight + canvasHeight - height;
                            graphics.DrawImage(oriented, x, y, width, height);
                        }
                    }
                }
            }
        }

        output.Save(outputPath, ImageFormat.Png);
        output.Dispose();
        source.Dispose();
    }
}
"@ -ReferencedAssemblies System.Drawing

$source = Join-Path $PSScriptRoot 'bits-rebuilt'
$output = Join-Path $PSScriptRoot '..\mods\reignition\bits'
[RocketLayoutBuilder]::Rebuild((Join-Path $source 'daxia-rocket-walk.png'), (Join-Path $output 'daxia-rocket-walk.png'), 6, 3, 4)
[RocketLayoutBuilder]::Rebuild((Join-Path $source 'daxia-rocket-attack.png'), (Join-Path $output 'daxia-rocket-attack.png'), 4, 2, 4)
[RocketLayoutBuilder]::Rebuild((Join-Path $source 'daxia-rocket-idle.png'), (Join-Path $output 'daxia-rocket-idle.png'), 4, 2, 4)

# Production icons use one person, not the full animation sheet.
$sheet = [System.Drawing.Bitmap]::new((Join-Path $output 'daxia-rocket-idle.png'))
$icon = [System.Drawing.Bitmap]::new(64, 48, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($icon)
try {
    $graphics.DrawImage($sheet, [System.Drawing.Rectangle]::new(12, 0, 40, 48),
        [System.Drawing.Rectangle]::new(0, 0, 40, 48), [System.Drawing.GraphicsUnit]::Pixel)
    $icon.Save((Join-Path $output 'daxia-rocket-icon.png'), [System.Drawing.Imaging.ImageFormat]::Png)
}
finally {
    $graphics.Dispose()
    $icon.Dispose()
    $sheet.Dispose()
}
Write-Output 'Rocket sheets rebuilt from raw frames.'
