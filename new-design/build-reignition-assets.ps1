Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public static class ReignitionAssetBuilder
{
    static bool IsBackground(Color c)
    {
        var max = Math.Max(c.R, Math.Max(c.G, c.B));
        var min = Math.Min(c.R, Math.Min(c.G, c.B));
        return max < 65 && max - min < 35;
    }

    public static void Create(string sourcePath, Rectangle crop, Size canvasSize, string outputPath)
    {
        var source = new Bitmap(sourcePath);
        var cropped = new Bitmap(crop.Width, crop.Height, PixelFormat.Format32bppArgb);
        using (var graphics = Graphics.FromImage(cropped))
            graphics.DrawImage(source, new Rectangle(0, 0, crop.Width, crop.Height), crop, GraphicsUnit.Pixel);

        var visited = new bool[crop.Width, crop.Height];
        var queue = new Queue<Point>();
        Action<Point> enqueue = point =>
        {
            if (point.X < 0 || point.Y < 0 || point.X >= crop.Width || point.Y >= crop.Height || visited[point.X, point.Y])
                return;
            if (!IsBackground(cropped.GetPixel(point.X, point.Y)))
                return;
            visited[point.X, point.Y] = true;
            queue.Enqueue(point);
        };

        for (var x = 0; x < crop.Width; x++)
        {
            enqueue(new Point(x, 0));
            enqueue(new Point(x, crop.Height - 1));
        }
        for (var y = 0; y < crop.Height; y++)
        {
            enqueue(new Point(0, y));
            enqueue(new Point(crop.Width - 1, y));
        }

        while (queue.Count > 0)
        {
            var point = queue.Dequeue();
            cropped.SetPixel(point.X, point.Y, Color.Transparent);
            enqueue(new Point(point.X - 1, point.Y));
            enqueue(new Point(point.X + 1, point.Y));
            enqueue(new Point(point.X, point.Y - 1));
            enqueue(new Point(point.X, point.Y + 1));
        }

        var scale = Math.Min(canvasSize.Width * 0.92 / crop.Width, canvasSize.Height * 0.92 / crop.Height);
        var width = Math.Max(1, (int)(crop.Width * scale));
        var height = Math.Max(1, (int)(crop.Height * scale));
        var output = new Bitmap(canvasSize.Width, canvasSize.Height, PixelFormat.Format32bppArgb);
        using (var graphics = Graphics.FromImage(output))
        {
            graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
            graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;
            graphics.DrawImage(cropped, (canvasSize.Width - width) / 2, canvasSize.Height - height, width, height);
        }
        output.Save(outputPath, ImageFormat.Png);
        output.Dispose();
        cropped.Dispose();
        source.Dispose();
    }
}
"@ -ReferencedAssemblies System.Drawing

$root = 'D:\code\OpenRA'
$source = Join-Path $root 'new-design\原案图片'
$output = Join-Path $root 'mods\reignition\bits'

function New-Sprite([string]$page, [int]$x, [int]$y, [int]$width, [int]$height, [int]$canvasWidth, [int]$canvasHeight, [string]$name) {
    try {
        [ReignitionAssetBuilder]::Create(
            (Join-Path $source $page),
            ([System.Drawing.Rectangle]::new($x, $y, $width, $height)),
            ([System.Drawing.Size]::new($canvasWidth, $canvasHeight)),
            (Join-Path $output $name))
    }
    catch {
        Write-Output "Failed $name : $($_.Exception.ToString())"
        throw
    }
}

New-Sprite '13.png' 180 280 400 300 112 96 'crimson-xingtian.png'
New-Sprite '13.png' 750 280 400 300 112 96 'allied-prism.png'
New-Sprite '13.png' 1330 280 400 300 112 96 'daxia-houyi.png'
New-Sprite '13.png' 180 620 420 280 112 96 'crimson-thunderbolt.png'
New-Sprite '13.png' 750 620 420 280 112 96 'daxia-chidian.png'
New-Sprite '13.png' 1330 620 400 280 112 96 'allied-hound.png'
New-Sprite '19.png' 310 270 410 310 144 128 'daxia-weap.png'
New-Sprite '19.png' 1250 270 410 310 144 128 'daxia-barr.png'
New-Sprite '19.png' 300 600 420 310 144 128 'daxia-lab.png'
New-Sprite '19.png' 1240 600 420 310 144 128 'daxia-silo.png'
New-Sprite '21.png' 75 160 650 650 144 128 'reignition-mcv.png'
New-Sprite '21.png' 1080 170 560 650 144 128 'daxia-fact.png'
New-Sprite '23.png' 650 300 600 520 144 128 'daxia-powr.png'
New-Sprite '23.png' 100 300 520 520 144 128 'daxia-dome.png'
New-Sprite '22.png' 100 280 400 330 112 112 'daxia-gun.png'
New-Sprite '22.png' 1300 280 400 330 112 112 'crimson-tsla.png'
New-Sprite '30.png' 80 300 400 350 144 128 'allied-pdox.png'

Write-Output 'Reignition placeholder assets generated.'
