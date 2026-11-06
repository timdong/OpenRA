Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public static class VehicleLayoutBuilder
{
    static void RemoveBorderBackground(Bitmap image)
    {
        var visited = new bool[image.Width, image.Height];
        var queue = new Queue<Point>();
        Action<int, int> enqueue = (x, y) =>
        {
            if (x < 0 || y < 0 || x >= image.Width || y >= image.Height || visited[x, y])
                return;
            visited[x, y] = true;
            var color = image.GetPixel(x, y);
            var max = Math.Max(color.R, Math.Max(color.G, color.B));
            var min = Math.Min(color.R, Math.Min(color.G, color.B));
            if (color.A == 0 || (max < 80 && max - min < 40))
                queue.Enqueue(new Point(x, y));
        };

        for (var x = 0; x < image.Width; x++)
        {
            enqueue(x, 0);
            enqueue(x, image.Height - 1);
        }
        for (var y = 0; y < image.Height; y++)
        {
            enqueue(0, y);
            enqueue(image.Width - 1, y);
        }
        while (queue.Count > 0)
        {
            var point = queue.Dequeue();
            image.SetPixel(point.X, point.Y, Color.Transparent);
            enqueue(point.X - 1, point.Y);
            enqueue(point.X + 1, point.Y);
            enqueue(point.X, point.Y - 1);
            enqueue(point.X, point.Y + 1);
        }
    }

    static Rectangle VisibleBounds(Bitmap image)
    {
        var left = image.Width;
        var top = image.Height;
        var right = -1;
        var bottom = -1;
        for (var y = 0; y < image.Height; y++)
            for (var x = 0; x < image.Width; x++)
                if (image.GetPixel(x, y).A > 0)
                {
                    left = Math.Min(left, x);
                    top = Math.Min(top, y);
                    right = Math.Max(right, x);
                    bottom = Math.Max(bottom, y);
                }
        if (right < left)
            throw new InvalidOperationException("The selected vehicle frame is empty.");
        return Rectangle.FromLTRB(left, top, right + 1, bottom + 1);
    }

    static void SaveSprite(Bitmap sprite, Rectangle bounds, string path, int height, bool bottomAligned)
    {
        const int width = 64;
        var scale = Math.Min(54f / bounds.Width, (height - 8f) / bounds.Height);
        var drawWidth = Math.Max(1, (int)Math.Round(bounds.Width * scale));
        var drawHeight = Math.Max(1, (int)Math.Round(bounds.Height * scale));
        using (var output = new Bitmap(width, height, PixelFormat.Format32bppArgb))
        using (var graphics = Graphics.FromImage(output))
        {
            graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
            graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;
            var y = bottomAligned ? height - drawHeight - 2 : (height - drawHeight) / 2;
            graphics.DrawImage(sprite, new Rectangle((width - drawWidth) / 2, y, drawWidth, drawHeight),
                bounds, GraphicsUnit.Pixel);
            output.Save(path, ImageFormat.Png);
        }
    }

    public static void Build(string sourcePath, Rectangle crop, string outputPath, string iconPath, bool cleanBackground)
    {
        using (var source = new Bitmap(sourcePath))
        {
            if (!new Rectangle(0, 0, source.Width, source.Height).Contains(crop))
                throw new ArgumentException("Vehicle crop is outside the source image.");
            using (var sprite = source.Clone(crop, PixelFormat.Format32bppArgb))
            {
                if (cleanBackground)
                    RemoveBorderBackground(sprite);
                var bounds = VisibleBounds(sprite);
                SaveSprite(sprite, bounds, outputPath, 56, true);
                SaveSprite(sprite, bounds, iconPath, 48, false);
            }
        }
    }

    public static void BuildFromGrid(string sourcePath, string outputPath, string iconPath)
    {
        // These raw sheets have two columns and SIXTEEN rows, not eight.
        // Preserve the current single-facing artwork by taking one complete cell.
        using (var source = new Bitmap(sourcePath))
        {
            if (source.Width != 128 || source.Height != 448)
                throw new ArgumentException("Expected a 128x448 vehicle source sheet (2 columns, 16 rows).");
        }
        Build(sourcePath, new Rectangle(0, 0, 64, 28), outputPath, iconPath, false);
    }
}
"@ -ReferencedAssemblies System.Drawing

$source = Join-Path $PSScriptRoot 'bits-rebuilt'
$output = Join-Path $PSScriptRoot '..\mods\reignition\bits'
$vehicles = @('crimson-xingtian', 'allied-prism', 'daxia-houyi', 'crimson-thunderbolt', 'daxia-chidian', 'allied-hound')
foreach ($name in $vehicles) {
    [VehicleLayoutBuilder]::BuildFromGrid(
        (Join-Path $source ($name + '.png')),
        (Join-Path $output ($name + '.png')),
        (Join-Path $output ($name + '-icon.png')))
}

# Use the traced reference silhouettes so dark MCV armor is never removed as background.
& (Join-Path $PSScriptRoot 'rebuild-mcv-assets.ps1')

Write-Output 'Single-vehicle sprites and production icons rebuilt.'
