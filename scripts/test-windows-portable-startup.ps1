param(
    [string]$BundleDirectory,
    [string]$EvidenceDirectory = (Join-Path $PSScriptRoot '../artifacts/windows-parity/portable-startup')
)
$ErrorActionPreference = 'Stop'
$workspace = Split-Path -Parent $PSScriptRoot
$bundleRoot = if ($BundleDirectory) {
    (Resolve-Path -LiteralPath $BundleDirectory).Path
} else {
    $bundles = @(Get-ChildItem -LiteralPath (Join-Path $workspace 'artifacts/windows') -Directory)
    if ($bundles.Count -ne 1) {
        throw "Expected one Windows bundle, found $($bundles.Count)."
    }
    Join-Path $bundles[0].FullName 'Singbook'
}
$executable = Join-Path $bundleRoot 'singbook.exe'
if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) {
    throw "Portable Windows executable is missing: $executable"
}

$runId = if ($env:GITHUB_RUN_ID) { "$($env:GITHUB_RUN_ID)-$($env:GITHUB_RUN_ATTEMPT)" } else { [guid]::NewGuid().ToString('N') }
$runtimeRoot = Join-Path $env:RUNNER_TEMP "singbook-portable-startup-$runId"
if (Test-Path -LiteralPath $runtimeRoot) {
    throw "Disposable startup-test directory already exists: $runtimeRoot"
}
$libraryDirectory = Join-Path $runtimeRoot 'library'
$profileDirectory = Join-Path $runtimeRoot 'profile'
$localAppData = Join-Path $profileDirectory 'Local'
$roamingAppData = Join-Path $profileDirectory 'Roaming'
$tempDirectory = Join-Path $runtimeRoot 'temp'
$libraryPath = Join-Path $libraryDirectory 'singbook.db'
New-Item -ItemType Directory -Path $libraryDirectory, $localAppData, $roamingAppData, $tempDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $EvidenceDirectory -Force | Out-Null
$windowScreenshotPath = Join-Path $EvidenceDirectory 'portable-startup-window.bmp'

Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Runtime.InteropServices;

public static class SingbookWindowCapture
{
    [StructLayout(LayoutKind.Sequential)]
    private struct RECT
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct BITMAPINFOHEADER
    {
        public uint Size;
        public int Width;
        public int Height;
        public ushort Planes;
        public ushort BitCount;
        public uint Compression;
        public uint SizeImage;
        public int XPelsPerMeter;
        public int YPelsPerMeter;
        public uint ColorsUsed;
        public uint ColorsImportant;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct BITMAPINFO
    {
        public BITMAPINFOHEADER Header;
        public uint Color;
    }

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool GetWindowRect(IntPtr handle, out RECT rect);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool PrintWindow(IntPtr handle, IntPtr deviceContext, uint flags);

    [DllImport("gdi32.dll", SetLastError = true)]
    private static extern IntPtr CreateCompatibleDC(IntPtr deviceContext);

    [DllImport("gdi32.dll", SetLastError = true)]
    private static extern IntPtr CreateDIBSection(IntPtr deviceContext, ref BITMAPINFO info,
        uint usage, out IntPtr bits, IntPtr section, uint offset);

    [DllImport("gdi32.dll", SetLastError = true)]
    private static extern IntPtr SelectObject(IntPtr deviceContext, IntPtr value);

    [DllImport("gdi32.dll", SetLastError = true)]
    private static extern bool DeleteObject(IntPtr value);

    [DllImport("gdi32.dll", SetLastError = true)]
    private static extern bool DeleteDC(IntPtr deviceContext);

    public static void Capture(IntPtr handle, string path)
    {
        RECT rect;
        if (!GetWindowRect(handle, out rect))
            throw new InvalidOperationException("GetWindowRect failed: " + Marshal.GetLastWin32Error());

        int width = rect.Right - rect.Left;
        int height = rect.Bottom - rect.Top;
        if (width <= 0 || height <= 0)
            throw new InvalidOperationException("The app window has invalid screenshot dimensions.");

        long byteCount = (long)width * height * 4;
        if (width > 8192 || height > 8192 || byteCount > Int32.MaxValue)
            throw new InvalidOperationException("The app window exceeds the screenshot size limit.");

        IntPtr deviceContext = CreateCompatibleDC(IntPtr.Zero);
        if (deviceContext == IntPtr.Zero)
            throw new InvalidOperationException("CreateCompatibleDC failed: " + Marshal.GetLastWin32Error());

        IntPtr bitmap = IntPtr.Zero;
        IntPtr previous = IntPtr.Zero;
        try
        {
            var info = new BITMAPINFO();
            info.Header.Size = (uint)Marshal.SizeOf(typeof(BITMAPINFOHEADER));
            info.Header.Width = width;
            info.Header.Height = -height; // top-down rows
            info.Header.Planes = 1;
            info.Header.BitCount = 32;
            info.Header.Compression = 0; // BI_RGB
            info.Header.SizeImage = (uint)byteCount;

            IntPtr bits;
            bitmap = CreateDIBSection(deviceContext, ref info, 0, out bits, IntPtr.Zero, 0);
            if (bitmap == IntPtr.Zero || bits == IntPtr.Zero)
                throw new InvalidOperationException("CreateDIBSection failed: " + Marshal.GetLastWin32Error());

            previous = SelectObject(deviceContext, bitmap);
            if (previous == IntPtr.Zero)
                throw new InvalidOperationException("SelectObject failed: " + Marshal.GetLastWin32Error());

            bool captured = PrintWindow(handle, deviceContext, 2); // PW_RENDERFULLCONTENT
            if (!captured)
                captured = PrintWindow(handle, deviceContext, 0);
            if (!captured)
                throw new InvalidOperationException("PrintWindow failed: " + Marshal.GetLastWin32Error());

            var pixels = new byte[(int)byteCount];
            Marshal.Copy(bits, pixels, 0, pixels.Length);
            using (var stream = File.Create(path))
            using (var writer = new BinaryWriter(stream))
            {
                writer.Write((ushort)0x4d42); // BMP signature
                writer.Write((uint)(54 + pixels.Length));
                writer.Write((ushort)0);
                writer.Write((ushort)0);
                writer.Write((uint)54);
                writer.Write((uint)40);
                writer.Write(width);
                writer.Write(-height); // top-down rows
                writer.Write((ushort)1);
                writer.Write((ushort)32);
                writer.Write((uint)0); // BI_RGB
                writer.Write((uint)pixels.Length);
                writer.Write(0);
                writer.Write(0);
                writer.Write((uint)0);
                writer.Write((uint)0);
                writer.Write(pixels);
            }
        }
        finally
        {
            if (previous != IntPtr.Zero)
                SelectObject(deviceContext, previous);
            if (bitmap != IntPtr.Zero)
                DeleteObject(bitmap);
            DeleteDC(deviceContext);
        }
    }
}
'@

$process = $null
$startupPassed = $false
$mainWindowObserved = $false
$mainWindowTitle = $null
$windowScreenshotCaptured = $false
$windowScreenshotFailure = $null
$databaseHeaderValid = $false
$gracefulClose = $false
$forcedStop = $false
$failure = $null
$stopwatch = [Diagnostics.Stopwatch]::StartNew()
try {
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = $executable
    $start.WorkingDirectory = $bundleRoot
    $start.Arguments = '--library-path "' + $libraryPath + '"'
    $start.UseShellExecute = $false
    $start.WindowStyle = [Diagnostics.ProcessWindowStyle]::Normal
    $start.EnvironmentVariables['PATH'] = "$bundleRoot;$env:SystemRoot\System32;$env:SystemRoot"
    $start.EnvironmentVariables['APPDATA'] = $roamingAppData
    $start.EnvironmentVariables['LOCALAPPDATA'] = $localAppData
    $start.EnvironmentVariables['TEMP'] = $tempDirectory
    $start.EnvironmentVariables['TMP'] = $tempDirectory
    $process = [Diagnostics.Process]::Start($start)
    if ($null -eq $process) { throw 'Windows did not start the packaged app.' }

    $deadline = [DateTime]::UtcNow.AddSeconds(45)
    while ([DateTime]::UtcNow -lt $deadline) {
        $process.Refresh()
        if ($process.HasExited) {
            throw "Packaged app exited during startup with code $($process.ExitCode)."
        }
        $database = Get-Item -LiteralPath $libraryPath -ErrorAction SilentlyContinue
        if ($database -and $database.Length -ge 16) {
            $process.Refresh()
            $mainWindowObserved = $process.MainWindowHandle -ne [IntPtr]::Zero
            $mainWindowTitle = $process.MainWindowTitle
            $startupPassed = $mainWindowObserved -and
                -not [string]::IsNullOrWhiteSpace($mainWindowTitle)
            if ($startupPassed) {
                try {
                    [SingbookWindowCapture]::Capture($process.MainWindowHandle, $windowScreenshotPath)
                    $windowScreenshotCaptured = $true
                } catch {
                    $windowScreenshotFailure = $_.Exception.Message
                }
                break
            }
        }
        Start-Sleep -Milliseconds 500
    }
    if (-not $startupPassed) {
        throw 'Packaged app did not create a main window and isolated SQLite library within 45 seconds.'
    }
} catch {
    $failure = $_.Exception.Message
} finally {
    $stopwatch.Stop()
    if ($process) {
        try {
            $process.Refresh()
            if (-not $process.HasExited) {
                if ($process.CloseMainWindow()) {
                    $gracefulClose = $process.WaitForExit(8000)
                }
                if (-not $process.HasExited) {
                    $process.Kill()
                    [void]$process.WaitForExit(5000)
                    $forcedStop = $true
                }
            }
        } catch {
            if (-not $failure) { $failure = "App cleanup failed: $($_.Exception.Message)" }
        }
    }
    try {
        $stream = [IO.File]::OpenRead($libraryPath)
        try {
            $header = [byte[]]::new(16)
            [void]$stream.Read($header, 0, $header.Length)
        } finally {
            $stream.Dispose()
        }
        $databaseHeaderValid = [Text.Encoding]::ASCII.GetString($header) -eq "SQLite format 3`0"
        if (-not $databaseHeaderValid -and -not $failure) {
            $failure = 'Packaged app did not create a valid SQLite library.'
        }
    } catch {
        if (-not $failure) { $failure = "Could not validate the closed SQLite library: $($_.Exception.Message)" }
    }
    $receipt = [ordered]@{
        result = if ($failure) { 'failed' } else { 'passed' }
        checkoutCommit = (& git -C $workspace rev-parse HEAD).Trim()
        sourceTree = (& git -C $workspace rev-parse 'HEAD^{tree}').Trim()
        executable = $executable
        runtimeDirectory = $runtimeRoot
        explicitLibraryPath = $libraryPath
        isolatedAppData = $profileDirectory
        developerToolPathExcluded = $true
        databaseHeaderValid = $databaseHeaderValid
        mainWindowObserved = $mainWindowObserved
        mainWindowTitle = $mainWindowTitle
        windowScreenshotCaptured = $windowScreenshotCaptured
        windowScreenshotPath = $windowScreenshotPath
        windowScreenshotFailure = $windowScreenshotFailure
        gracefulClose = $gracefulClose
        forcedStop = $forcedStop
        elapsedMilliseconds = $stopwatch.ElapsedMilliseconds
        failure = $failure
    }
    $receipt | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $EvidenceDirectory 'summary.json') -Encoding utf8
    if ($process) { $process.Dispose() }
}
if ($failure) { throw $failure }
Write-Output "Portable Windows startup smoke passed. Evidence: $(Join-Path $EvidenceDirectory 'summary.json')"
