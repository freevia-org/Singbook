<#
Packages the exact validated portable CI payload for Microsoft Store.
The upload package remains unsigned; Partner Center signs it after certification.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PortableBundle,
    [Parameter(Mandatory)][string]$PortableManifest,
    [Parameter(Mandatory)][string]$OutputDirectory,
    [Parameter(Mandatory)][string]$IconPath,
    [Parameter(Mandatory)][string]$MakeAppxPath,
    [Parameter(Mandatory)][string]$ExpectedSourceTree
)
$ErrorActionPreference = 'Stop'

function Assert-UnderRoot([string]$Root, [string]$RelativePath) {
    $segments = $RelativePath -split '[\\/]'
    if ([IO.Path]::IsPathRooted($RelativePath) -or $RelativePath.Contains(':') -or
        @($segments | Where-Object { $_ -in @('', '.', '..') }).Count -gt 0) {
        throw "Unsafe manifest path: $RelativePath"
    }
    $fullRoot = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    $fullPath = [IO.Path]::GetFullPath((Join-Path $Root $RelativePath))
    if (-not $fullPath.StartsWith($fullRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Manifest path escapes the payload root: $RelativePath"
    }
    return $fullPath
}

$source = (Resolve-Path -LiteralPath $PortableBundle).Path
$sourceRoot = Get-Item -LiteralPath $source -Force
if (($sourceRoot.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
    throw 'PortableBundle root cannot be a reparse point.'
}
$ancestor = $sourceRoot
while ($null -ne $ancestor) {
    if (($ancestor.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Reparse point in trusted artifact extraction path: $($ancestor.FullName)"
    }
    if ($null -eq $ancestor.Parent) { break }
    $ancestor = Get-Item -LiteralPath $ancestor.Parent.FullName -Force
}
$manifestPath = (Resolve-Path -LiteralPath $PortableManifest).Path
$packageManifestPath = Join-Path $PSScriptRoot 'AppxManifest.xml'
$packageManifest = [xml](Get-Content -LiteralPath $packageManifestPath -Raw)
$release = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ($release.version -ne '0.2.14+28' -or $release.configuration -ne 'release' -or
    $release.distribution -ne 'portable-release') {
    throw 'Input manifest must describe the 0.2.14+28 portable release.'
}
if ($null -eq $release.requiredFiles -or $release.requiredFiles.Count -eq 0) {
    throw 'Input manifest is missing the requiredFiles list.'
}
if ($release.sourceTree -ne $ExpectedSourceTree) {
    throw 'Input portable artifact was built from an unexpected source tree.'
}
if ($release.version -notmatch '^\d+\.\d+\.\d+\+(\d+)$') {
    throw 'Application version must include the monotonic pubspec build number.'
}
$buildNumber = [int]$Matches[1]
if ($buildNumber -lt 1 -or $buildNumber -gt 65535) {
    throw 'Store package mapping requires a build number from 1 through 65535.'
}
$storePackageVersion = "1.0.$buildNumber.0"
$identity = $packageManifest.SelectSingleNode("/*[local-name()='Package']/*[local-name()='Identity']")
if ($null -eq $identity -or $identity.Name -ne 'Freevia.Singbook' -or
    $identity.Publisher -ne 'CN=BCFA4DEF-81A8-41BB-A9C8-5DDAB2101C9A' -or
    $identity.Version -ne $storePackageVersion -or $identity.ProcessorArchitecture -ne 'x64') {
    throw 'Package manifest does not match the reserved Store identity/version.'
}
if (-not $release.sourceCommit -or $release.files.Count -ne 54) {
    throw 'Input manifest lacks commit provenance or does not list the expected 54 files.'
}
if (-not (Test-Path -LiteralPath (Join-Path $source 'singbook.exe') -PathType Leaf)) {
    throw 'PortableBundle must be the extracted release payload containing singbook.exe.'
}
if (Test-Path -LiteralPath $OutputDirectory) {
    throw 'OutputDirectory exists; choose a fresh release artifact directory.'
}

$expected = @{}
foreach ($entry in $release.files) {
    $relative = ([string]$entry.path).Replace('/', '\')
    if ($expected.ContainsKey($relative) -or $entry.sha256 -notmatch '^[A-Fa-f0-9]{64}$') {
        throw "Duplicate or invalid manifest file entry: $relative"
    }
    $expected[$relative] = ([string]$entry.sha256).ToUpperInvariant()
    $file = Assert-UnderRoot $source $relative
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        throw "Release payload file is absent: $relative"
    }
    $item = Get-Item -LiteralPath $file -Force
    if ($item.Length -eq 0) { throw "Empty release payload file: $relative" }
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Reparse point in release payload: $relative"
    }
    if ((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ne $expected[$relative]) {
        throw "Release payload hash mismatch: $relative"
    }
}
$actualFiles = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
$pendingDirectories = [System.Collections.Generic.Stack[string]]::new()
$pendingDirectories.Push($source)
while ($pendingDirectories.Count -gt 0) {
    $currentDirectory = $pendingDirectories.Pop()
    foreach ($child in @(Get-ChildItem -LiteralPath $currentDirectory -Force)) {
        if (($child.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Reparse point in release payload: $($child.FullName)"
        }
        if ($child.PSIsContainer) { $pendingDirectories.Push($child.FullName) }
        else { $actualFiles.Add([IO.FileInfo]$child) }
    }
}
if ($actualFiles.Count -ne $expected.Count) { throw 'Release payload has an extra or missing file.' }
foreach ($required in $release.requiredFiles) {
    $requiredPath = ([string]$required).Replace('/', '\')
    if (-not $expected.ContainsKey($requiredPath)) {
        throw "Required release file is absent from manifest.files: $requiredPath"
    }
}
foreach ($item in $actualFiles) {
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Reparse point in release payload: $($item.FullName)"
    }
    $relative = [IO.Path]::GetRelativePath($source, $item.FullName).Replace('/', '\')
    if (-not $expected.ContainsKey($relative)) { throw "Unexpected release payload file: $relative" }
}
$null = New-Item -ItemType Directory -Path $OutputDirectory
$stage = Join-Path $OutputDirectory 'Package'
$appRoot = Join-Path $stage 'Singbook'
$assetRoot = Join-Path $stage 'Assets'
$null = New-Item -ItemType Directory -Path $appRoot -Force
$null = New-Item -ItemType Directory -Path $assetRoot
foreach ($relative in $expected.Keys) {
    $destination = Assert-UnderRoot $appRoot $relative
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force
    Copy-Item -LiteralPath (Assert-UnderRoot $source $relative) -Destination $destination
}
foreach ($relative in $expected.Keys) {
    $destination = Assert-UnderRoot $appRoot $relative
    if ((Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash -ne $expected[$relative]) {
        throw "Copied package payload differs from CI artifact: $relative"
    }
}

# Derive square Store tile PNGs from the existing product icon.
# Visual scale review remains part of release acceptance.
Add-Type -AssemblyName System.Drawing
$expectedIcon = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\assets\branding\singbook-icon.png'))
$resolvedIcon = (Resolve-Path -LiteralPath $IconPath).Path
if (-not [string]::Equals($expectedIcon, $resolvedIcon, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'IconPath must be the checked-out product asset assets/branding/singbook-icon.png.'
}
$icon = [System.Drawing.Image]::FromFile($resolvedIcon)
try {
    $targets = @(
        @{ Name = 'StoreLogo.png'; Width = 50; Height = 50; Padding = 0.04 },
        @{ Name = 'Square44x44Logo.png'; Width = 44; Height = 44; Padding = 0.04 },
        @{ Name = 'Square150x150Logo.png'; Width = 150; Height = 150; Padding = 0.04 }
    )
    foreach ($target in $targets) {
        $bitmap = [System.Drawing.Bitmap]::new($target.Width, $target.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            try {
                $graphics.Clear([System.Drawing.Color]::Transparent)
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                $padding = [Math]::Ceiling([Math]::Min($target.Width, $target.Height) * $target.Padding)
                $side = [Math]::Min($target.Width, $target.Height) - 2 * $padding
                $x = [Math]::Floor(($target.Width - $side) / 2)
                $y = [Math]::Floor(($target.Height - $side) / 2)
                $graphics.DrawImage($icon, [System.Drawing.Rectangle]::new($x, $y, $side, $side))
            } finally { $graphics.Dispose() }
            $bitmap.Save((Join-Path $assetRoot $target.Name), [System.Drawing.Imaging.ImageFormat]::Png)
        } finally { $bitmap.Dispose() }
    }
} finally { $icon.Dispose() }

Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'AppxManifest.xml') -Destination (Join-Path $stage 'AppxManifest.xml')
$msix = Join-Path $OutputDirectory ('Singbook_' + $storePackageVersion + '_x64.msix')
# MakeAppx pack performs full validation by default; do not pass /nv or call a
# nonexistent standalone validate command. /no prevents replacing outputs.
& $MakeAppxPath pack /d $stage /p $msix /h SHA256 /no
if ($LASTEXITCODE -ne 0) { throw 'MakeAppx pack failed.' }

# Unpack then compare each portable payload byte to the original CI manifest.
# This is payload round-trip proof, not WACK or app launch evidence.
$roundTrip = Join-Path $OutputDirectory 'RoundTrip'
& $MakeAppxPath unpack /p $msix /d $roundTrip /o
if ($LASTEXITCODE -ne 0) { throw 'MakeAppx unpack round-trip failed.' }
$roundTripBundle = Join-Path $roundTrip 'Singbook'
$roundTripFiles = @(Get-ChildItem -LiteralPath $roundTripBundle -File -Recurse -Force)
if ($roundTripFiles.Count -ne $expected.Count) {
    throw 'MSIX round-trip contains an extra or missing runtime file.'
}
foreach ($item in $roundTripFiles) {
    $relative = [IO.Path]::GetRelativePath($roundTripBundle, $item.FullName).Replace('/', '\')
    if (-not $expected.ContainsKey($relative)) { throw "Unexpected MSIX runtime file: $relative" }
}
foreach ($relative in $expected.Keys) {
    $unpacked = Assert-UnderRoot $roundTripBundle $relative
    if (-not (Test-Path -LiteralPath $unpacked -PathType Leaf) -or
        (Get-FileHash -LiteralPath $unpacked -Algorithm SHA256).Hash -ne $expected[$relative]) {
        throw "MSIX round-trip payload mismatch: $relative"
    }
}
$roundTripAssets = Join-Path $roundTrip 'Assets'
$assetHashes = @()
foreach ($name in @('StoreLogo.png','Square44x44Logo.png','Square150x150Logo.png')) {
    $assetPath = Join-Path $assetRoot $name
    $unpackedAsset = Join-Path $roundTripAssets $name
    if (-not (Test-Path -LiteralPath $unpackedAsset -PathType Leaf)) { throw "MSIX tile asset missing: $name" }
    $sourceHash = (Get-FileHash -LiteralPath $assetPath -Algorithm SHA256).Hash
    if ((Get-FileHash -LiteralPath $unpackedAsset -Algorithm SHA256).Hash -ne $sourceHash) {
        throw "MSIX tile asset round-trip mismatch: $name"
    }
    $assetHashes += @{ path = "Assets/$name"; sha256 = $sourceHash }
}
$manifestHash = (Get-FileHash -LiteralPath (Join-Path $stage 'AppxManifest.xml') -Algorithm SHA256).Hash
if ((Get-FileHash -LiteralPath (Join-Path $roundTrip 'AppxManifest.xml') -Algorithm SHA256).Hash -ne $manifestHash) {
    throw 'MSIX manifest round-trip mismatch.'
}

$evidence = [ordered]@{
    productVersion = $release.version
    packageVersion = $storePackageVersion
    packageVersionMapping = '1.0.<monotonic pubspec build>.0'
    architecture = 'x64'
    storeIdentity = 'Freevia.Singbook'
    sourceCommitFromArtifact = $release.sourceCommit
    sourceTree = $release.sourceTree
    sourcePortableManifestSha256 = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash
    sourceProductIconPath = 'assets/branding/singbook-icon.png'
    sourceProductIconSha256 = (Get-FileHash -LiteralPath $IconPath -Algorithm SHA256).Hash
    msixSha256 = (Get-FileHash -LiteralPath $msix -Algorithm SHA256).Hash
    sourcePortableFileCount = $expected.Count
    sourcePortableFiles = @($release.files | Sort-Object path)
    packageManifestSha256 = $manifestHash
    storeAssets = @($assetHashes)
    makeAppxFileVersion = [Diagnostics.FileVersionInfo]::GetVersionInfo($MakeAppxPath).FileVersion
    packageSigning = 'unsigned-for-Partner-Center-Store-signing'
    checks = @('manifest schema and requiredFiles', '54 source file hashes', 'no extra/missing/empty/reparse-point source files', 'payload copy hashes', 'MakeAppx full pack validation', 'exact 54-file unpacked runtime list and byte hashes', 'manifest and tile asset byte hashes')
}
$evidence | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'package-provenance.json')
Write-Output "Unsigned Store candidate: $msix"
