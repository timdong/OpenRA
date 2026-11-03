Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public static class ReignitionAssetBuilderV2
{
    static bool IsBackground(Color c)
    {
        var max = Math.Max(c.R, Math.Max(c.G, c.B));
        var min = Math.Min(c.R, Math.Min(c.G, c.B));
        return max < 80 && max - min < 40;
    }

    static Bitmap CleanCrop(string sourcePath, Rectangle crop)
    {
        var source = new Bitmap(sourcePath);
        var cropped = new Bitmap(crop.Width, crop.Height, PixelFormat.Format32bppArgb);
        using (var graphics = Graphics.FromImage(cropped))
            graphics.DrawImage(source, new Rectangle(0, 0, crop.Width, crop.Height), crop, GraphicsUnit.Pixel);
        source.Dispose();

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

        var labelWidth = Math.Min(125, crop.Width);
        var labelHeight = Math.Min(42, crop.Height);
        for (var y = crop.Height - labelHeight; y < crop.Height; y++)
            for (var x = 0; x < labelWidth; x++)
                cropped.SetPixel(x, y, Color.Transparent);

        return cropped;
    }

    static Bitmap Rotate(Bitmap source, float angle)
    {
        var output = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb);
        using (var graphics = Graphics.FromImage(output))
        {
            graphics.TranslateTransform(source.Width / 2f, source.Height / 2f);
            graphics.RotateTransform(angle);
            graphics.TranslateTransform(-source.Width / 2f, -source.Height / 2f);
            graphics.DrawImage(source, 0, 0);
        }
        return output;
    }

    static Bitmap ScaleAndSharpen(Bitmap source, int maxWidth, int maxHeight)
    {
        var scale = Math.Min(maxWidth / (float)source.Width, maxHeight / (float)source.Height);
        var width = Math.Max(1, (int)Math.Round(source.Width * scale));
        var height = Math.Max(1, (int)Math.Round(source.Height * scale));
        var scaled = new Bitmap(width, height, PixelFormat.Format32bppArgb);
        using (var graphics = Graphics.FromImage(scaled))
        {
            graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
            graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;
            graphics.DrawImage(source, 0, 0, width, height);
        }

        var output = new Bitmap(width, height, PixelFormat.Format32bppArgb);
        for (var y = 0; y < height; y++)
        {
            for (var x = 0; x < width; x++)
            {
                var center = scaled.GetPixel(x, y);
                if (center.A == 0 || x == 0 || y == 0 || x == width - 1 || y == height - 1)
                {
                    output.SetPixel(x, y, center);
                    continue;
                }

                var left = scaled.GetPixel(x - 1, y);
                var right = scaled.GetPixel(x + 1, y);
                var top = scaled.GetPixel(x, y - 1);
                var bottom = scaled.GetPixel(x, y + 1);
                Func<int, int, int, int, int, int, byte> channel = (a, b, c, d, e, f) =>
                {
                    var value = (int)Math.Round(a * 1.35 - (b + c + d + e) * 0.0875);
                    return (byte)Math.Max(0, Math.Min(255, value));
                };
                output.SetPixel(x, y, Color.FromArgb(center.A,
                    channel(center.R, left.R, right.R, top.R, bottom.R, 0),
                    channel(center.G, left.G, right.G, top.G, bottom.G, 0),
                    channel(center.B, left.B, right.B, top.B, bottom.B, 0)));
            }
        }
        scaled.Dispose();
        return output;
    }

    public static void CreateBuilding(string sourcePath, Rectangle crop, string outputPath)
    {
        var cleaned = CleanCrop(sourcePath, crop);
        var scaled = ScaleAndSharpen(cleaned, 82, 82);
        var output = new Bitmap(96, 96, PixelFormat.Format32bppArgb);
        using (var graphics = Graphics.FromImage(output))
            graphics.DrawImage(scaled, (96 - scaled.Width) / 2, 96 - scaled.Height);
        output.Save(outputPath, ImageFormat.Png);
        output.Dispose();
        scaled.Dispose();
        cleaned.Dispose();
    }

    public static void CreateVehicleSheet(string sourcePath, Rectangle crop, string outputPath)
    {
        const int frameWidth = 64;
        const int frameHeight = 56;
        var cleaned = CleanCrop(sourcePath, crop);
        var sheet = new Bitmap(frameWidth * 2, frameHeight * 8, PixelFormat.Format32bppArgb);
        using (var graphics = Graphics.FromImage(sheet))
        {
            for (var direction = 0; direction < 8; direction++)
            {
                var rotated = Rotate(cleaned, direction * 45f);
                var scaled = ScaleAndSharpen(rotated, 54, 46);
                for (var frame = 0; frame < 2; frame++)
                {
                    var x = frame * frameWidth + (frameWidth - scaled.Width) / 2;
                    var y = direction * frameHeight + frameHeight - scaled.Height + (frame == 0 ? -1 : 1);
                    graphics.DrawImage(scaled, x, y);
                }
                scaled.Dispose();
                rotated.Dispose();
            }
        }
        sheet.Save(outputPath, ImageFormat.Png);
        sheet.Dispose();
        cleaned.Dispose();
    }
}
"@ -ReferencedAssemblies System.Drawing

$root = 'D:\code\OpenRA'
$source = Join-Path $root 'new-design\原案图片'
$output = Join-Path $root 'mods\reignition\bits'

function New-Building([string]$page, [int]$x, [int]$y, [int]$width, [int]$height, [string]$name) {
    [ReignitionAssetBuilderV2]::CreateBuilding((Join-Path $source $page), ([System.Drawing.Rectangle]::new($x, $y, $width, $height)), (Join-Path $output $name))
}

function New-Vehicle([string]$page, [int]$x, [int]$y, [int]$width, [int]$height, [string]$name) {
    [ReignitionAssetBuilderV2]::CreateVehicleSheet((Join-Path $source $page), ([System.Drawing.Rectangle]::new($x, $y, $width, $height)), (Join-Path $output $name))
}

New-Vehicle '13.png' 180 280 400 300 'crimson-xingtian.png'
New-Vehicle '13.png' 750 280 400 300 'allied-prism.png'
New-Vehicle '13.png' 1330 280 400 300 'daxia-houyi.png'
New-Vehicle '13.png' 180 620 420 280 'crimson-thunderbolt.png'
New-Vehicle '13.png' 750 620 420 280 'daxia-chidian.png'
New-Vehicle '13.png' 1330 620 400 280 'allied-hound.png'
New-Vehicle '21.png' 75 160 650 650 'reignition-mcv.png'

New-Building '19.png' 310 270 410 310 'daxia-weap.png'
New-Building '19.png' 1250 270 410 310 'daxia-barr.png'
New-Building '19.png' 300 600 420 310 'daxia-lab.png'
New-Building '19.png' 1240 600 420 310 'daxia-silo.png'
New-Building '21.png' 1080 170 560 650 'daxia-fact.png'
New-Building '23.png' 650 300 600 520 'daxia-powr.png'
New-Building '23.png' 100 300 520 520 'daxia-dome.png'
New-Building '22.png' 100 280 400 330 'daxia-gun.png'
New-Building '22.png' 1300 280 400 330 'crimson-tsla.png'
New-Building '30.png' 80 300 400 350 'allied-pdox.png'

Write-Output 'V2 assets generated.'
