Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public static class RocketInfantryBuilder
{
    static bool IsBackground(Color c)
    {
        var max = Math.Max(c.R, Math.Max(c.G, c.B));
        var min = Math.Min(c.R, Math.Min(c.G, c.B));
        return max < 80 && max - min < 40;
    }

    static Bitmap CleanCrop(Bitmap source, Rectangle crop)
    {
        var output = new Bitmap(crop.Width, crop.Height, PixelFormat.Format32bppArgb);
        using (var graphics = Graphics.FromImage(output))
            graphics.DrawImage(source, new Rectangle(0, 0, crop.Width, crop.Height), crop, GraphicsUnit.Pixel);

        var visited = new bool[crop.Width, crop.Height];
        var queue = new Queue<Point>();
        Action<Point> enqueue = point =>
        {
            if (point.X < 0 || point.Y < 0 || point.X >= crop.Width || point.Y >= crop.Height || visited[point.X, point.Y])
                return;
            if (!IsBackground(output.GetPixel(point.X, point.Y)))
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
            output.SetPixel(point.X, point.Y, Color.Transparent);
            enqueue(new Point(point.X - 1, point.Y));
            enqueue(new Point(point.X + 1, point.Y));
            enqueue(new Point(point.X, point.Y - 1));
            enqueue(new Point(point.X, point.Y + 1));
        }
        return output;
    }

    static Bitmap Scale(Bitmap source, int maxWidth, int maxHeight)
    {
        var scale = Math.Min(maxWidth / (float)source.Width, maxHeight / (float)source.Height);
        var width = Math.Max(1, (int)Math.Round(source.Width * scale));
        var height = Math.Max(1, (int)Math.Round(source.Height * scale));
        var output = new Bitmap(width, height, PixelFormat.Format32bppArgb);
        using (var graphics = Graphics.FromImage(output))
        {
            graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
            graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;
            graphics.DrawImage(source, 0, 0, width, height);
        }
        return output;
    }

    public static void CreateSheet(string sourcePath, Rectangle rowCrop, int frameCount, string outputPath)
    {
        const int canvasWidth = 40;
        const int canvasHeight = 48;
        var source = new Bitmap(sourcePath);
        var sheet = new Bitmap(canvasWidth * frameCount, canvasHeight * 8, PixelFormat.Format32bppArgb);
        var frameWidth = rowCrop.Width / frameCount;
        using (var graphics = Graphics.FromImage(sheet))
        {
            for (var frame = 0; frame < frameCount; frame++)
            {
                var crop = new Rectangle(rowCrop.X + frame * frameWidth, rowCrop.Y, frameWidth, rowCrop.Height);
                var cleaned = CleanCrop(source, crop);
                var scaled = Scale(cleaned, 34, 44);
                for (var direction = 0; direction < 8; direction++)
                {
                    var x = frame * canvasWidth + (canvasWidth - scaled.Width) / 2;
                    var y = direction * canvasHeight + canvasHeight - scaled.Height;
                    if (direction < 4)
                        graphics.DrawImage(scaled, x, y);
                    else
                    {
                        var mirror = scaled.Clone(new Rectangle(0, 0, scaled.Width, scaled.Height), PixelFormat.Format32bppArgb);
                        mirror.RotateFlip(RotateFlipType.RotateNoneFlipX);
                        graphics.DrawImage(mirror, x, y);
                        mirror.Dispose();
                    }
                }
                scaled.Dispose();
                cleaned.Dispose();
            }
        }
        sheet.Save(outputPath, ImageFormat.Png);
        sheet.Dispose();
        source.Dispose();
    }
}
"@ -ReferencedAssemblies System.Drawing

$source = 'D:\code\OpenRA\new-design\原案图片\32.png'
$output = 'D:\code\OpenRA\mods\reignition\bits'
[RocketInfantryBuilder]::CreateSheet($source, [System.Drawing.Rectangle]::new(510, 350, 480, 140), 6, (Join-Path $output 'daxia-rocket-walk.png'))
[RocketInfantryBuilder]::CreateSheet($source, [System.Drawing.Rectangle]::new(510, 590, 440, 150), 4, (Join-Path $output 'daxia-rocket-attack.png'))
[RocketInfantryBuilder]::CreateSheet($source, [System.Drawing.Rectangle]::new(550, 800, 360, 160), 4, (Join-Path $output 'daxia-rocket-idle.png'))
Write-Output 'Rocket infantry sheets generated.'
