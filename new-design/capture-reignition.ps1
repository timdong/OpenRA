Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class ReignitionCaptureNative {
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, uint flags);
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
}
"@ -ReferencedAssemblies System.Drawing
$process = Get-Process | Where-Object { $_.MainWindowTitle -like '*Reignition*' } | Select-Object -First 1
if ($null -eq $process) { throw 'Reignition window not found.' }
$rect = New-Object ReignitionCaptureNative+RECT
[ReignitionCaptureNative]::GetWindowRect($process.MainWindowHandle, [ref]$rect) | Out-Null
$width = $rect.Right - $rect.Left
$height = $rect.Bottom - $rect.Top
$bitmap = New-Object System.Drawing.Bitmap $width, $height
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$hdc = $graphics.GetHdc()
[ReignitionCaptureNative]::PrintWindow($process.MainWindowHandle, $hdc, 2) | Out-Null
$graphics.ReleaseHdc($hdc)
$bitmap.Save('D:\code\OpenRA\new-design\reignition-rocket-fixed.png', [System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose()
$bitmap.Dispose()
Write-Output "Captured ${width}x${height}"
