[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$MsixPath,
    [Parameter(Mandatory)][string]$ProvenancePath,
    [Parameter(Mandatory)][string]$ExpectedSha256,
    [Parameter(Mandatory)][string]$ExpectedSourceTree,
    [Parameter(Mandatory)][string]$ExpectedSourceManifestSha256,
    [Parameter(Mandatory)][string]$EvidenceDirectory
)
$ErrorActionPreference = 'Stop'

$expectedIdentity = 'Freevia.Singbook'
$expectedPublisher = 'CN=BCFA4DEF-81A8-41BB-A9C8-5DDAB2101C9A'
$expectedVersion = [version]'1.0.28.0'
$expectedArchitecture = 'x64'
$expectedExecutable = 'Singbook\singbook.exe'
$expectedPortableExecutable = 'singbook.exe'
$runnerTemp = [IO.Path]::GetFullPath($env:RUNNER_TEMP).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
$runId = if ($env:GITHUB_RUN_ID) { "$($env:GITHUB_RUN_ID)-$($env:GITHUB_RUN_ATTEMPT)" } else { [guid]::NewGuid().ToString('N') }
$runtimeRoot = [IO.Path]::GetFullPath((Join-Path $runnerTemp "singbook-msix-install-$runId"))
$evidenceRoot = [IO.Path]::GetFullPath($EvidenceDirectory)
$evidencePrefix = [IO.Path]::GetFullPath((Join-Path (Get-Location).Path 'artifacts\windows-store-msix-smoke')).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
if (-not $evidenceRoot.StartsWith($evidencePrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'EvidenceDirectory must stay under artifacts/windows-store-msix-smoke.'
}
if (-not $runtimeRoot.StartsWith($runnerTemp, [StringComparison]::OrdinalIgnoreCase) -or $runtimeRoot -eq $runnerTemp.TrimEnd('\')) {
    throw 'Runtime path is not a child of RUNNER_TEMP.'
}
if (Test-Path -LiteralPath $runtimeRoot) { throw "Disposable test path already exists: $runtimeRoot" }
if (Get-AppxPackage -Name $expectedIdentity -ErrorAction SilentlyContinue) {
    throw 'The test package is already installed on this runner; refusing to replace it.'
}

$summaryPath = Join-Path $evidenceRoot 'install-summary.json'
$installAttempted = $false
$packageRemoved = $false
$runtimeCleanupConfirmed = $false
$certificateImported = $false
$certificateRemoved = $false
$testCertificateThumbprint = $null
$packageFullName = $null
$packageFamilyName = $null
$signToolPath = $null
$sourceSha256 = $null
$sourcePortableManifestSha256 = $null
$sourcePayloadFileCount = 0
$installedExecutableSha256 = $null
$signedCopySha256 = $null
$activationId = $null
$databasePath = $null
$databaseHeaderValid = $false
$mainWindowTitle = $null
$windowScreenshotPath = Join-Path $evidenceRoot 'msix-install-window.bmp'
$windowScreenshotCaptured = $false
$gracefulClose = $false
$processId = $null
$processPath = $null
$activatedPackageFamilyName = $null
$activatedPackageFullName = $null
$secondProcessPath = $null
$secondProcessId = $null
$secondActivatedPackageFamilyName = $null
$secondActivatedPackageFullName = $null
$secondGracefulClose = $false
$persistenceMarker = [guid]::NewGuid().ToString('N')
$persistenceMarkerConfirmed = $false
$executablePath = $null
$process = $null
$failure = $null
$forcedStop = $false
$startedAtUtc = [DateTime]::UtcNow.ToString('o')

try {
    New-Item -ItemType Directory -Path $runtimeRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $evidenceRoot -Force | Out-Null
    $source = (Resolve-Path -LiteralPath $MsixPath).Path
    $sourceSha256 = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
    if ($sourceSha256 -ne $ExpectedSha256.ToUpperInvariant()) {
        throw 'Unsigned source MSIX SHA-256 does not match the pinned package.'
    }
    $provenance = Get-Content -LiteralPath (Resolve-Path -LiteralPath $ProvenancePath).Path -Raw | ConvertFrom-Json
    if ($provenance.productVersion -ne '0.2.14+28' -or $provenance.packageVersion -ne '1.0.28.0' -or
        $provenance.architecture -ne $expectedArchitecture -or $provenance.storeIdentity -ne $expectedIdentity -or
        $provenance.sourceTree -ne $ExpectedSourceTree -or
        $provenance.sourcePortableManifestSha256 -ne $ExpectedSourceManifestSha256.ToUpperInvariant() -or
        $provenance.msixSha256 -ne $ExpectedSha256.ToUpperInvariant() -or
        $provenance.sourcePortableFileCount -ne 54 -or $provenance.sourcePortableFiles.Count -ne 54) {
        throw 'Package provenance does not match the pinned version, source tree, manifest, or file count.'
    }
    $expectedPayloadHashes = @{}
    foreach ($entry in $provenance.sourcePortableFiles) {
        $relative = ([string]$entry.path).Replace('/', '\')
        $segments = $relative -split '\\'
        if ([IO.Path]::IsPathRooted($relative) -or $relative.Contains(':') -or
            @($segments | Where-Object { $_ -in @('', '.', '..') }).Count -gt 0 -or
            $entry.sha256 -notmatch '^[A-Fa-f0-9]{64}$' -or $expectedPayloadHashes.ContainsKey($relative)) {
            throw "Package provenance contains an unsafe, duplicate, or invalid payload entry: $relative"
        }
        $expectedPayloadHashes[$relative] = ([string]$entry.sha256).ToUpperInvariant()
    }
    $sourcePortableManifestSha256 = [string]$provenance.sourcePortableManifestSha256
    $sourcePayloadFileCount = $expectedPayloadHashes.Count
    if (-not $expectedPayloadHashes.ContainsKey($expectedPortableExecutable)) {
        throw 'Package provenance does not list the packaged application executable.'
    }

    Add-Type -AssemblyName System.IO.Compression
    $archive = [System.IO.Compression.ZipFile]::OpenRead($source)
    try {
        $manifestEntry = $archive.GetEntry('AppxManifest.xml')
        if ($null -eq $manifestEntry) { throw 'MSIX AppxManifest.xml is missing.' }
        if ($null -ne $archive.GetEntry('AppxSignature.p7x')) { throw 'Pinned source MSIX must remain unsigned.' }
        $runtimeEntries = @($archive.Entries | Where-Object {
            $_.FullName.StartsWith('Singbook/', [StringComparison]::OrdinalIgnoreCase) -and -not $_.FullName.EndsWith('/')
        })
        if ($runtimeEntries.Count -ne $expectedPayloadHashes.Count) {
            throw 'Unsigned MSIX has an extra or missing runtime file compared with its provenance manifest.'
        }
        $observedPayloadPaths = @{}
        foreach ($entry in $runtimeEntries) {
            $relative = $entry.FullName.Substring('Singbook/'.Length).Replace('/', '\')
            if (-not $expectedPayloadHashes.ContainsKey($relative) -or $observedPayloadPaths.ContainsKey($relative)) {
                throw "Unsigned MSIX contains an unexpected or duplicate runtime file: $relative"
            }
            $stream = $entry.Open()
            $hasher = [Security.Cryptography.SHA256]::Create()
            try { $payloadHash = [Convert]::ToHexString($hasher.ComputeHash($stream)) }
            finally { $hasher.Dispose(); $stream.Dispose() }
            if ($payloadHash -ne $expectedPayloadHashes[$relative]) {
                throw "Unsigned MSIX payload hash differs from its provenance manifest: $relative"
            }
            $observedPayloadPaths[$relative] = $true
        }
        $reader = [IO.StreamReader]::new($manifestEntry.Open())
        try { [xml]$manifest = $reader.ReadToEnd() } finally { $reader.Dispose() }
        $identity = $manifest.SelectSingleNode("//*[local-name()='Identity']")
        $application = $manifest.SelectSingleNode("//*[local-name()='Application']")
        if ($null -eq $identity -or $identity.GetAttribute('Name') -ne $expectedIdentity -or
            $identity.GetAttribute('Publisher') -ne $expectedPublisher -or
            [version]$identity.GetAttribute('Version') -ne $expectedVersion -or
            $identity.GetAttribute('ProcessorArchitecture') -ne $expectedArchitecture) {
            throw 'MSIX identity, publisher, version, or architecture does not match the approved Store package.'
        }
        if ($null -eq $application -or $application.GetAttribute('Executable') -ne $expectedExecutable) {
            throw 'MSIX application executable does not match the approved package manifest.'
        }
    } finally { $archive.Dispose() }

    $signedCopy = Join-Path $runtimeRoot 'Singbook-test-signed.msix'
    Copy-Item -LiteralPath $source -Destination $signedCopy
    if ((Get-FileHash -LiteralPath $signedCopy -Algorithm SHA256).Hash -ne $sourceSha256) {
        throw 'Temporary test copy differs from the unsigned source MSIX.'
    }

    $cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject $expectedPublisher `
        -CertStoreLocation 'Cert:\CurrentUser\My' -HashAlgorithm SHA256 `
        -NotAfter ([DateTime]::Now.AddHours(2)) -FriendlyName "Singbook MSIX CI test $runId"
    $testCertificateThumbprint = $cert.Thumbprint
    $publicCertPath = Join-Path $runtimeRoot 'temporary-test-certificate.cer'
    Export-Certificate -Cert $cert -FilePath $publicCertPath -Force | Out-Null
    Import-Certificate -FilePath $publicCertPath -CertStoreLocation 'Cert:\LocalMachine\TrustedPeople' | Out-Null
    $certificateImported = $true

    $kitRoot = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin'
    $signTools = @(Get-ChildItem -LiteralPath $kitRoot -Filter signtool.exe -File -Recurse |
        Where-Object { $_.FullName -match '[\\/]x64[\\/]signtool\.exe$' } |
        Sort-Object FullName -Descending)
    if ($signTools.Count -eq 0) { throw 'Windows SDK x64 SignTool was not found.' }
    $signToolPath = $signTools[0].FullName
    & $signToolPath sign /fd SHA256 /s My /sha1 $testCertificateThumbprint $signedCopy
    if ($LASTEXITCODE -ne 0) { throw 'SignTool could not sign the disposable MSIX copy.' }
    & $signToolPath verify /pa /v $signedCopy
    if ($LASTEXITCODE -ne 0) { throw 'SignTool could not verify the disposable test signature.' }
    $signedCopySha256 = (Get-FileHash -LiteralPath $signedCopy -Algorithm SHA256).Hash
    if ($signedCopySha256 -eq $sourceSha256) { throw 'The test copy did not acquire a signature.' }

    $installAttempted = $true
    Add-AppxPackage -Path $signedCopy -ErrorAction Stop
    $package = Get-AppxPackage -Name $expectedIdentity -ErrorAction Stop
    $packageFullName = $package.PackageFullName
    $packageFamilyName = $package.PackageFamilyName
    if ($package.Version -ne $expectedVersion -or $package.Publisher -ne $expectedPublisher -or
        "$($package.Architecture)" -notmatch '^(X64|x64)$') {
        throw 'Installed package metadata differs from the approved identity.'
    }

    $installLocation = [IO.Path]::GetFullPath($package.InstallLocation)
    $appRoot = [IO.Path]::GetFullPath((Join-Path $installLocation 'Singbook'))
    $executablePath = [IO.Path]::GetFullPath((Join-Path $installLocation $expectedExecutable))
    $installPrefix = $installLocation.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if (-not $executablePath.StartsWith($installPrefix, [StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath $executablePath -PathType Leaf)) {
        throw 'Installed package executable is missing or outside the installed package location.'
    }
    $installedPayloadFiles = @(Get-ChildItem -LiteralPath $appRoot -File -Recurse -Force)
    if ($installedPayloadFiles.Count -ne $expectedPayloadHashes.Count) {
        throw 'Installed package has an extra or missing runtime file compared with the pinned 54-file manifest.'
    }
    foreach ($item in $installedPayloadFiles) {
        $relative = [IO.Path]::GetRelativePath($appRoot, $item.FullName).Replace('/', '\')
        if (-not $expectedPayloadHashes.ContainsKey($relative) -or
            (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash -ne $expectedPayloadHashes[$relative]) {
            throw "Installed package file differs from the pinned portable payload: $relative"
        }
    }
    $installedExecutableSha256 = (Get-FileHash -LiteralPath $executablePath -Algorithm SHA256).Hash
    if ($installedExecutableSha256 -ne $expectedPayloadHashes[$expectedPortableExecutable]) {
        throw 'Installed executable hash differs from the pinned portable payload.'
    }

    Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Runtime.InteropServices;

[ComImport, Guid("2e941141-7f97-4756-ba1d-9decde894a3d"),
 InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface ISingbookApplicationActivationManager
{
    [PreserveSig]
    int ActivateApplication(
        [In, MarshalAs(UnmanagedType.LPWStr)] string appUserModelId,
        [In, MarshalAs(UnmanagedType.LPWStr)] string arguments,
        [In] int options,
        out uint processId);
}

public static class SingbookMsixActivation
{
    public static uint Activate(string appUserModelId, string arguments)
    {
        var classId = new Guid("45BA127D-10A8-46EA-8AB7-56EA9078943C");
        var type = Type.GetTypeFromCLSID(classId, true);
        var instance = Activator.CreateInstance(type);
        try
        {
            var manager = (ISingbookApplicationActivationManager)instance;
            uint processId;
            var result = manager.ActivateApplication(appUserModelId, arguments, 0, out processId);
            Marshal.ThrowExceptionForHR(result);
            return processId;
        }
        finally
        {
            if (Marshal.IsComObject(instance)) Marshal.FinalReleaseComObject(instance);
        }
    }

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern int GetPackageFamilyName(IntPtr process, ref uint length, [Out] System.Text.StringBuilder familyName);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern int GetPackageFullName(IntPtr process, ref uint length, [Out] System.Text.StringBuilder fullName);

    private static string ReadPackageValue(IntPtr process, bool fullName)
    {
        uint length = 0;
        int result = fullName
            ? GetPackageFullName(process, ref length, null)
            : GetPackageFamilyName(process, ref length, null);
        if (result != 122 || length == 0)
            throw new InvalidOperationException("Could not query activated process package identity: " + result);
        var value = new System.Text.StringBuilder((int)length);
        result = fullName
            ? GetPackageFullName(process, ref length, value)
            : GetPackageFamilyName(process, ref length, value);
        if (result != 0)
            throw new InvalidOperationException("Could not read activated process package identity: " + result);
        return value.ToString();
    }

    public static string GetProcessPackageFamilyName(IntPtr process) { return ReadPackageValue(process, false); }
    public static string GetProcessPackageFullName(IntPtr process) { return ReadPackageValue(process, true); }
}

public static class SingbookMsixWindowCapture
{
    [StructLayout(LayoutKind.Sequential)]
    private struct RECT { public int Left; public int Top; public int Right; public int Bottom; }

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
    private struct BITMAPINFO { public BITMAPINFOHEADER Header; public uint Color; }

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool GetWindowRect(IntPtr handle, out RECT rect);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool PrintWindow(IntPtr handle, IntPtr deviceContext, uint flags);

    [DllImport("user32.dll")]
    private static extern bool ShowWindow(IntPtr handle, int command);

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

    public static void Maximize(IntPtr handle) { ShowWindow(handle, 3); }

    public static void Capture(IntPtr handle, string path)
    {
        RECT rect;
        if (!GetWindowRect(handle, out rect))
            throw new InvalidOperationException("GetWindowRect failed: " + Marshal.GetLastWin32Error());
        int width = rect.Right - rect.Left;
        int height = rect.Bottom - rect.Top;
        long byteCount = (long)width * height * 4;
        if (width <= 0 || height <= 0 || width > 8192 || height > 8192 || byteCount > Int32.MaxValue)
            throw new InvalidOperationException("Invalid packaged window dimensions.");

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
            info.Header.Height = -height;
            info.Header.Planes = 1;
            info.Header.BitCount = 32;
            info.Header.Compression = 0;
            info.Header.SizeImage = (uint)byteCount;
            IntPtr bits;
            bitmap = CreateDIBSection(deviceContext, ref info, 0, out bits, IntPtr.Zero, 0);
            if (bitmap == IntPtr.Zero || bits == IntPtr.Zero)
                throw new InvalidOperationException("CreateDIBSection failed: " + Marshal.GetLastWin32Error());
            previous = SelectObject(deviceContext, bitmap);
            if (previous == IntPtr.Zero)
                throw new InvalidOperationException("SelectObject failed: " + Marshal.GetLastWin32Error());
            bool captured = PrintWindow(handle, deviceContext, 2);
            if (!captured) captured = PrintWindow(handle, deviceContext, 0);
            if (!captured) throw new InvalidOperationException("PrintWindow failed: " + Marshal.GetLastWin32Error());
            var pixels = new byte[(int)byteCount];
            Marshal.Copy(bits, pixels, 0, pixels.Length);
            using (var stream = File.Create(path))
            using (var writer = new BinaryWriter(stream))
            {
                writer.Write((ushort)0x4d42);
                writer.Write((uint)(54 + pixels.Length));
                writer.Write((ushort)0);
                writer.Write((ushort)0);
                writer.Write((uint)54);
                writer.Write((uint)40);
                writer.Write(width);
                writer.Write(-height);
                writer.Write((ushort)1);
                writer.Write((ushort)32);
                writer.Write((uint)0);
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
            if (previous != IntPtr.Zero) SelectObject(deviceContext, previous);
            if (bitmap != IntPtr.Zero) DeleteObject(bitmap);
            DeleteDC(deviceContext);
        }
    }
}
'@

    function Get-InstalledPackageProcessIds([string]$ExpectedExecutablePath) {
        $ids = [System.Collections.Generic.List[int]]::new()
        foreach ($candidate in @(Get-Process -Name 'singbook' -ErrorAction SilentlyContinue)) {
            try {
                $candidate.Refresh()
                if ($candidate.HasExited) { continue }
                $candidatePath = [IO.Path]::GetFullPath($candidate.MainModule.FileName)
                if ([string]::Equals($candidatePath, $ExpectedExecutablePath, [StringComparison]::OrdinalIgnoreCase)) {
                    $ids.Add($candidate.Id)
                }
            } catch {
                throw "Could not verify the image path for Singbook process $($candidate.Id): $($_.Exception.Message)"
            }
        }
        return $ids.ToArray()
    }

    function Test-SqliteDatabaseHeader([string]$Path) {
        $stream = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
        try {
            if ($stream.Length -lt 16) { return $false }
            $header = [byte[]]::new(16)
            $read = 0
            while ($read -lt $header.Length) {
                $count = $stream.Read($header, $read, $header.Length - $read)
                if ($count -eq 0) { return $false }
                $read += $count
            }
            return [Text.Encoding]::ASCII.GetString($header) -eq "SQLite format 3`0"
        } finally { $stream.Dispose() }
    }

    $databaseDirectory = Join-Path $runtimeRoot 'library'
    $databasePath = Join-Path $databaseDirectory 'singbook.db'
    New-Item -ItemType Directory -Path $databaseDirectory -Force | Out-Null
    $persistenceProbePath = Join-Path $runtimeRoot 'persistence_probe.py'
    @'
import sqlite3
import sys

mode, database_path, marker = sys.argv[1:]
if len(marker) != 32 or any(char not in "0123456789abcdef" for char in marker):
    raise SystemExit("invalid persistence marker")

with sqlite3.connect(database_path) as connection:
    if mode == "write":
        connection.execute("CREATE TABLE IF NOT EXISTS __singbook_ci_persistence (marker TEXT NOT NULL)")
        connection.execute("DELETE FROM __singbook_ci_persistence")
        connection.execute("INSERT INTO __singbook_ci_persistence(marker) VALUES (?)", (marker,))
    elif mode == "verify":
        row = connection.execute(
            "SELECT COUNT(*) FROM __singbook_ci_persistence WHERE marker = ?", (marker,)
        ).fetchone()
        if row != (1,):
            raise SystemExit("persistence marker was not retained")
    else:
        raise SystemExit("invalid persistence probe mode")
'@ | Set-Content -LiteralPath $persistenceProbePath -Encoding utf8
    $applicationNode = $manifest.SelectSingleNode("//*[local-name()='Application']")
    $activationId = "$packageFamilyName!$($applicationNode.GetAttribute('Id'))"
    $arguments = '--library-path "' + $databasePath + '"'
    $processId = [SingbookMsixActivation]::Activate($activationId, $arguments)
    $process = [Diagnostics.Process]::GetProcessById([int]$processId)
    $deadline = [DateTime]::UtcNow.AddSeconds(45)
    while ([DateTime]::UtcNow -lt $deadline) {
        $process.Refresh()
        if ($process.HasExited) { throw "MSIX-activated app exited with code $($process.ExitCode)." }
        $database = Get-Item -LiteralPath $databasePath -ErrorAction SilentlyContinue
        if ($database -and $database.Length -ge 16 -and $process.MainWindowHandle -ne [IntPtr]::Zero) {
            $processPath = [IO.Path]::GetFullPath($process.MainModule.FileName)
            $mainWindowTitle = $process.MainWindowTitle
            if (-not [string]::Equals($processPath, $executablePath, [StringComparison]::OrdinalIgnoreCase)) {
                throw 'Activated process image does not match the exact installed package executable.'
            }
            $activatedPackageFamilyName = [SingbookMsixActivation]::GetProcessPackageFamilyName($process.Handle)
            $activatedPackageFullName = [SingbookMsixActivation]::GetProcessPackageFullName($process.Handle)
            if ($activatedPackageFamilyName -ne $packageFamilyName -or $activatedPackageFullName -ne $packageFullName) {
                throw 'Activated process package identity differs from the exact installed package.'
            }
            if ($mainWindowTitle -ne 'Singbook') { throw 'Activated package did not expose the Singbook main window.' }
            $processIds = @(Get-InstalledPackageProcessIds $executablePath)
            if ($processIds.Count -ne 1 -or $processIds[0] -ne $processId) {
                throw 'MSIX activation did not produce exactly one process for the installed package executable.'
            }
            [SingbookMsixWindowCapture]::Maximize($process.MainWindowHandle)
            Start-Sleep -Milliseconds 750
            [SingbookMsixWindowCapture]::Capture($process.MainWindowHandle, $windowScreenshotPath)
            $windowScreenshotCaptured = Test-Path -LiteralPath $windowScreenshotPath -PathType Leaf
            if (-not $windowScreenshotCaptured) { throw 'Packaged window screenshot was not saved.' }
            break
        }
        Start-Sleep -Milliseconds 500
    }
    if (-not $windowScreenshotCaptured) { throw 'MSIX activation did not produce a window and isolated database within 45 seconds.' }

    if ($process.CloseMainWindow()) { $gracefulClose = $process.WaitForExit(10000) }
    if (-not $gracefulClose) { throw 'First MSIX-activated app instance did not close gracefully.' }
    $process = $null
    $closeDeadline = [DateTime]::UtcNow.AddSeconds(10)
    do {
        $remainingProcessIds = @(Get-InstalledPackageProcessIds $executablePath)
        if ($remainingProcessIds.Count -eq 0) { break }
        Start-Sleep -Milliseconds 250
    } while ([DateTime]::UtcNow -lt $closeDeadline)
    if ($remainingProcessIds.Count -ne 0) { throw 'First MSIX app process remained after graceful close.' }
    $databaseHeaderValid = Test-SqliteDatabaseHeader $databasePath
    if (-not $databaseHeaderValid) { throw 'MSIX activation did not create a valid isolated SQLite library.' }

    & python $persistenceProbePath write $databasePath $persistenceMarker
    if ($LASTEXITCODE -ne 0) { throw 'Could not write a disposable SQLite marker before the package restart.' }
    $secondProcessId = [SingbookMsixActivation]::Activate($activationId, $arguments)
    $process = [Diagnostics.Process]::GetProcessById([int]$secondProcessId)
    $secondDeadline = [DateTime]::UtcNow.AddSeconds(45)
    while ([DateTime]::UtcNow -lt $secondDeadline) {
        $process.Refresh()
        if ($process.HasExited) { throw "Second MSIX-activated app exited with code $($process.ExitCode)." }
        $database = Get-Item -LiteralPath $databasePath -ErrorAction SilentlyContinue
        if ($database -and $database.Length -ge 16 -and $process.MainWindowHandle -ne [IntPtr]::Zero) {
            $secondProcessPath = [IO.Path]::GetFullPath($process.MainModule.FileName)
            if (-not [string]::Equals($secondProcessPath, $executablePath, [StringComparison]::OrdinalIgnoreCase)) {
                throw 'Second activated process image does not match the exact installed package executable.'
            }
            $secondActivatedPackageFamilyName = [SingbookMsixActivation]::GetProcessPackageFamilyName($process.Handle)
            $secondActivatedPackageFullName = [SingbookMsixActivation]::GetProcessPackageFullName($process.Handle)
            if ($secondActivatedPackageFamilyName -ne $packageFamilyName -or $secondActivatedPackageFullName -ne $packageFullName) {
                throw 'Second activated process package identity differs from the exact installed package.'
            }
            if ($process.MainWindowTitle -ne 'Singbook') { throw 'Second activation did not expose the Singbook main window.' }
            $secondProcessIds = @(Get-InstalledPackageProcessIds $executablePath)
            if ($secondProcessIds.Count -ne 1 -or $secondProcessIds[0] -ne $secondProcessId) {
                throw 'Second activation did not produce exactly one process for the installed package executable.'
            }
            break
        }
        Start-Sleep -Milliseconds 500
    }
    if ($process.MainWindowHandle -eq [IntPtr]::Zero) { throw 'Second MSIX activation did not produce a window and isolated database within 45 seconds.' }
    if ($process.CloseMainWindow()) { $secondGracefulClose = $process.WaitForExit(10000) }
    if (-not $secondGracefulClose) { throw 'Second MSIX-activated app instance did not close gracefully.' }
    $process = $null
    $closeDeadline = [DateTime]::UtcNow.AddSeconds(10)
    do {
        $remainingProcessIds = @(Get-InstalledPackageProcessIds $executablePath)
        if ($remainingProcessIds.Count -eq 0) { break }
        Start-Sleep -Milliseconds 250
    } while ([DateTime]::UtcNow -lt $closeDeadline)
    if ($remainingProcessIds.Count -ne 0) { throw 'Second MSIX app process remained after graceful close.' }
    $databaseHeaderValid = Test-SqliteDatabaseHeader $databasePath
    if (-not $databaseHeaderValid) { throw 'Second activation did not reopen the same valid isolated SQLite library.' }
    & python $persistenceProbePath verify $databasePath $persistenceMarker
    $persistenceMarkerConfirmed = $LASTEXITCODE -eq 0
    if (-not $persistenceMarkerConfirmed) { throw 'Disposable library marker did not persist across the packaged app restart.' }
} catch {
    $failure = $_.Exception.Message
} finally {
    if ($executablePath -and (Get-Command Get-InstalledPackageProcessIds -ErrorAction SilentlyContinue)) {
        $cleanupProcessIds = [System.Collections.Generic.HashSet[int]]::new()
        foreach ($candidateId in @($processId, $secondProcessId)) {
            if ($candidateId) { [void]$cleanupProcessIds.Add([int]$candidateId) }
        }
        try {
            foreach ($candidateId in @(Get-InstalledPackageProcessIds $executablePath)) {
                [void]$cleanupProcessIds.Add([int]$candidateId)
            }
        } catch {
            if (-not $failure) { $failure = "Could not enumerate package processes for cleanup: $($_.Exception.Message)" }
        }
        foreach ($candidateId in @($cleanupProcessIds)) {
            $candidateProcess = $null
            try {
                try { $candidateProcess = [Diagnostics.Process]::GetProcessById($candidateId) }
                catch [ArgumentException] { continue }
                $candidateProcess.Refresh()
                if ($candidateProcess.HasExited) { continue }
                $candidatePath = [IO.Path]::GetFullPath($candidateProcess.MainModule.FileName)
                if (-not [string]::Equals($candidatePath, $executablePath, [StringComparison]::OrdinalIgnoreCase)) {
                    continue
                }
                if ($candidateProcess.CloseMainWindow()) { $candidateProcess.WaitForExit(5000) | Out-Null }
                $candidateProcess.Refresh()
                if (-not $candidateProcess.HasExited) {
                    $verifiedPath = [IO.Path]::GetFullPath($candidateProcess.MainModule.FileName)
                    if ([string]::Equals($verifiedPath, $executablePath, [StringComparison]::OrdinalIgnoreCase)) {
                        $candidateProcess.Kill()
                        $forcedStop = $true
                        $candidateProcess.WaitForExit()
                    }
                }
            } catch {
                $stillRunning = $false
                if ($candidateProcess) {
                    try {
                        $candidateProcess.Refresh()
                        $stillRunning = -not $candidateProcess.HasExited
                    } catch { }
                }
                if ($stillRunning -and -not $failure) {
                    $failure = "Process cleanup failed for PID ${candidateId}: $($_.Exception.Message)"
                }
            } finally {
                if ($candidateProcess) { $candidateProcess.Dispose() }
            }
        }
    }
    if ($installAttempted) {
        try {
            $currentPackage = Get-AppxPackage -Name $expectedIdentity -ErrorAction SilentlyContinue
            if ($currentPackage) {
                if (-not $packageFullName) {
                    if ($currentPackage.Publisher -ne $expectedPublisher -or $currentPackage.Version -ne $expectedVersion) {
                        throw 'A different package appeared during the isolated install attempt; refusing to remove it.'
                    }
                    $packageFullName = $currentPackage.PackageFullName
                }
                if ($currentPackage.PackageFullName -ne $packageFullName) {
                    throw 'Installed package identity changed during the isolated test.'
                }
                Remove-AppxPackage -Package $packageFullName -ErrorAction Stop
            }
            $packageRemoved = $null -eq (Get-AppxPackage -Name $expectedIdentity -ErrorAction SilentlyContinue)
            if (-not $packageRemoved) { throw 'Test Appx package remained installed after cleanup.' }
        } catch {
            if (-not $failure) { $failure = "Package cleanup failed: $($_.Exception.Message)" }
        }
    }
    if ($testCertificateThumbprint) {
        $trustedPath = "Cert:\LocalMachine\TrustedPeople\$testCertificateThumbprint"
        if (Test-Path -LiteralPath $trustedPath) {
            Remove-Item -LiteralPath $trustedPath -Force -ErrorAction SilentlyContinue
        }
        $personalPath = "Cert:\CurrentUser\My\$testCertificateThumbprint"
        if (Test-Path -LiteralPath $personalPath) {
            Remove-Item -LiteralPath $personalPath -Force -ErrorAction SilentlyContinue
        }
        $certificateRemoved = -not (Test-Path -LiteralPath $trustedPath) -and -not (Test-Path -LiteralPath $personalPath)
        if (-not $certificateRemoved -and -not $failure) { $failure = 'Temporary test certificate cleanup could not be confirmed.' }
    }
    if (Test-Path -LiteralPath $runtimeRoot) {
        $item = Get-Item -LiteralPath $runtimeRoot -Force
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
            -not $runtimeRoot.StartsWith($runnerTemp, [StringComparison]::OrdinalIgnoreCase)) {
            if (-not $failure) { $failure = 'Refusing unsafe runtime cleanup path.' }
        } else {
            Remove-Item -LiteralPath $runtimeRoot -Recurse -Force -ErrorAction SilentlyContinue
            $runtimeCleanupConfirmed = -not (Test-Path -LiteralPath $runtimeRoot)
            if (-not $runtimeCleanupConfirmed -and -not $failure) { $failure = 'Disposable test files remained after cleanup.' }
        }
    }
    if (-not (Test-Path -LiteralPath $evidenceRoot)) { New-Item -ItemType Directory -Path $evidenceRoot -Force | Out-Null }
    $result = if ($failure) { 'failed' } else { 'passed' }
    try {
        [pscustomobject]@{
            result = $result
            startedAtUtc = $startedAtUtc
            packageIdentity = $expectedIdentity
            packagePublisher = $expectedPublisher
            packageVersion = "$expectedVersion"
            architecture = $expectedArchitecture
            unsignedSourceMsixSha256 = $sourceSha256
            sourcePortableManifestSha256 = $sourcePortableManifestSha256
            sourcePayloadFileCount = $sourcePayloadFileCount
            installedExecutableSha256 = $installedExecutableSha256
            temporarySignedCopySha256 = $signedCopySha256
            packageFullName = $packageFullName
            packageFamilyName = $packageFamilyName
            testCertificateThumbprint = $testCertificateThumbprint
            testCertificateWasImportedToLocalMachineTrustedPeople = $certificateImported
            testCertificateCleanupConfirmed = $certificateRemoved
            packageRemovalConfirmed = $packageRemoved
            runtimeCleanupConfirmed = $runtimeCleanupConfirmed
            installLocationExecutable = $executablePath
            activatedApplicationUserModelId = $activationId
            processId = $processId
            processPath = $processPath
            activatedPackageFamilyName = $activatedPackageFamilyName
            activatedPackageFullName = $activatedPackageFullName
            secondProcessId = $secondProcessId
            secondProcessPath = $secondProcessPath
            secondActivatedPackageFamilyName = $secondActivatedPackageFamilyName
            secondActivatedPackageFullName = $secondActivatedPackageFullName
            databasePath = $databasePath
            databaseHeaderValid = $databaseHeaderValid
            persistenceMarkerConfirmed = $persistenceMarkerConfirmed
            mainWindowTitle = $mainWindowTitle
            windowScreenshotPath = $windowScreenshotPath
            windowScreenshotCaptured = $windowScreenshotCaptured
            gracefulClose = $gracefulClose
            secondGracefulClose = $secondGracefulClose
            forcedStop = $forcedStop
            failure = $failure
        } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $summaryPath -Encoding utf8
    } catch {
        if (-not $failure) { $failure = "Could not write install evidence: $($_.Exception.Message)" }
    }
}
if ($failure) { throw $failure }
