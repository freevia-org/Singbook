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
$windowScreenshotPath = Join-Path $EvidenceDirectory 'portable-startup-window.png'

Add-Type -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
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

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool GetWindowRect(IntPtr handle, out RECT rect);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool PrintWindow(IntPtr handle, IntPtr deviceContext, uint flags);

    public static void Capture(IntPtr handle, string path)
    {
        RECT rect;
        if (!GetWindowRect(handle, out rect))
            throw new InvalidOperationException("GetWindowRect failed: " + Marshal.GetLastWin32Error());

        int width = rect.Right - rect.Left;
        int height = rect.Bottom - rect.Top;
        if (width <= 0 || height <= 0)
            throw new InvalidOperationException("The app window has invalid screenshot dimensions.");

        using (var bitmap = new Bitmap(width, height, PixelFormat.Format32bppArgb))
        using (var graphics = Graphics.FromImage(bitmap))
        {
            IntPtr deviceContext = graphics.GetHdc();
            bool captured;
            try
            {
                captured = PrintWindow(handle, deviceContext, 2); // PW_RENDERFULLCONTENT
                if (!captured)
                    captured = PrintWindow(handle, deviceContext, 0);
            }
            finally
            {
                graphics.ReleaseHdc(deviceContext);
            }

            if (!captured)
                throw new InvalidOperationException("PrintWindow failed: " + Marshal.GetLastWin32Error());

            bitmap.Save(path, ImageFormat.Png);
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
