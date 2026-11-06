Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public static class McvAssetBuilder
{
    static Point[] Points(string coordinates)
    {
        var pairs = coordinates.Split(' ');
        var points = new Point[pairs.Length];
        for (var i = 0; i < pairs.Length; i++)
        {
            var values = pairs[i].Split(',');
            points[i] = new Point(int.Parse(values[0]), int.Parse(values[1]));
        }
        return points;
    }

    public static void Build(string sourcePath, Rectangle crop, string outline,
        string outputPath, Size canvas, Size artwork)
    {
        using (var source = new Bitmap(sourcePath))
        {
            if (!new Rectangle(Point.Empty, source.Size).Contains(crop))
                throw new ArgumentException("MCV reference image does not match the recorded crop.");
            using (var cropped = source.Clone(crop, PixelFormat.Format32bppArgb))
            using (var cutout = new Bitmap(crop.Width, crop.Height, PixelFormat.Format32bppArgb))
            using (var path = new GraphicsPath())
            {
                // Mask only outside the silhouette. Dark armor inside it must stay opaque.
                path.AddPolygon(Points(outline));
                using (var graphics = Graphics.FromImage(cutout))
                using (var texture = new TextureBrush(cropped))
                {
                    graphics.SmoothingMode = SmoothingMode.AntiAlias;
                    graphics.FillPath(texture, path);
                }

                var bounds = Rectangle.Ceiling(path.GetBounds());
                var scale = Math.Min((float)artwork.Width / bounds.Width, (float)artwork.Height / bounds.Height);
                var width = Math.Max(1, (int)Math.Round(bounds.Width * scale));
                var height = Math.Max(1, (int)Math.Round(bounds.Height * scale));
                using (var output = new Bitmap(canvas.Width, canvas.Height, PixelFormat.Format32bppArgb))
                using (var graphics = Graphics.FromImage(output))
                using (var attributes = new ImageAttributes())
                {
                    graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
                    graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;
                    attributes.SetWrapMode(WrapMode.TileFlipXY);
                    graphics.DrawImage(cutout,
                        new Rectangle((canvas.Width - width) / 2, (canvas.Height - height) / 2, width, height),
                        bounds.X, bounds.Y, bounds.Width, bounds.Height, GraphicsUnit.Pixel, attributes);
                    output.Save(outputPath, ImageFormat.Png);
                }
            }
        }
    }
}
"@ -ReferencedAssemblies System.Drawing

$reference = Join-Path $PSScriptRoot 'source-assets\reignition-mcv-reference.png'
$output = Join-Path $PSScriptRoot '..\mods\reignition\bits'
$mobileCrop = [System.Drawing.Rectangle]::new(124, 183, 854, 640)
$deployedCrop = [System.Drawing.Rectangle]::new(1362, 183, 854, 640)

# Traced against the supplied reference, excluding captions, slide backgrounds and dividers.
$mobileOutline = '37,460 67,419 91,391 96,371 125,351 127,313 144,311 154,335 179,303 200,303 196,275 212,251 238,246 243,231 261,228 266,242 309,222 315,205 235,177 238,194 222,218 207,219 199,196 198,172 190,155 195,131 217,110 264,94 395,43 421,34 470,14 495,21 506,35 505,55 498,63 499,82 514,88 537,93 541,79 558,80 571,95 572,116 582,126 594,153 594,174 612,165 635,145 744,98 767,84 789,91 801,108 799,134 792,147 789,176 778,194 768,191 762,177 766,155 726,176 710,200 733,206 741,215 815,238 815,230 823,231 824,243 831,249 828,273 809,290 805,318 791,331 779,353 779,375 766,397 752,412 732,419 710,414 697,427 687,442 669,458 648,463 628,460 612,466 595,484 576,494 557,494 535,484 512,474 475,473 443,477 415,479 383,478 360,492 352,518 341,543 319,562 297,570 275,563 255,566 235,576 218,573 206,584 192,584 171,565 145,567 122,554 105,554 85,543 78,522 62,510 53,487 42,484'
$deployedOutline = '367,625 352,587 322,578 300,567 265,583 239,579 207,562 199,541 183,532 151,518 131,489 104,472 82,455 63,426 39,407 33,372 49,348 85,327 104,311 131,299 146,281 163,276 177,253 204,239 220,216 239,207 166,186 144,178 143,202 145,222 154,239 144,253 137,245 134,263 128,252 116,245 118,231 127,220 129,183 121,169 125,156 140,149 163,159 288,196 295,187 297,178 285,171 284,156 293,149 297,118 284,106 282,88 290,41 298,28 312,20 331,24 343,41 365,78 380,122 386,98 392,97 396,79 403,81 408,103 409,135 428,137 431,110 433,79 439,77 443,103 451,99 458,77 468,84 471,104 480,107 501,57 514,27 526,14 539,12 552,22 558,41 557,70 565,91 565,107 555,119 555,151 562,159 565,174 558,183 547,179 543,166 553,153 552,119 537,112 535,89 534,64 514,99 507,125 494,152 491,169 510,193 524,211 564,197 708,163 725,159 737,169 738,187 733,199 733,230 744,243 747,258 737,270 730,265 724,277 718,262 708,257 705,244 724,229 724,197 705,195 591,234 601,248 623,252 639,267 667,272 671,291 698,300 709,316 739,329 769,339 790,355 791,383 778,405 789,433 775,457 745,475 723,494 696,501 682,520 653,537 620,552 587,569 557,565 529,552 499,571 479,580 473,615 445,626 400,632'

# Keep extra raster detail; sequence Scale controls the final world size.
[McvAssetBuilder]::Build($reference, $mobileCrop, $mobileOutline,
    (Join-Path $output 'reignition-mcv.png'), [System.Drawing.Size]::new(128, 112), [System.Drawing.Size]::new(108, 96))
[McvAssetBuilder]::Build($reference, $deployedCrop, $deployedOutline,
    (Join-Path $output 'daxia-fact.png'), [System.Drawing.Size]::new(192, 192), [System.Drawing.Size]::new(170, 170))
[McvAssetBuilder]::Build($reference, $mobileCrop, $mobileOutline,
    (Join-Path $output 'reignition-mcv-icon.png'), [System.Drawing.Size]::new(64, 48), [System.Drawing.Size]::new(58, 42))
[McvAssetBuilder]::Build($reference, $deployedCrop, $deployedOutline,
    (Join-Path $output 'daxia-fact-icon.png'), [System.Drawing.Size]::new(64, 48), [System.Drawing.Size]::new(58, 42))

Write-Output 'Mobile and deployed MCV artwork rebuilt from the supplied reference with opaque armor.'
