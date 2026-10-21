param(
    [switch]$Debug,
    [switch]$AllowMissingDefines,
    [string]$DefinesFile = 'config/local.defines.json'
)
$ErrorActionPreference = 'Stop'
$workspace = Split-Path -Parent $PSScriptRoot
Push-Location $workspace
try {
    $revision = (& git rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Cannot determine source revision.' }
    $status = & git status --porcelain
    if ($status) {
        $status | Write-Output
        throw 'Commit the source before creating a traceable Windows bundle.'
    }
    $versionMatch = [regex]::Match((Get-Content pubspec.yaml -Raw), '(?m)^version:\s*(\S+)')
    if (-not $versionMatch.Success) { throw 'Cannot determine app version.' }
    $mode = if ($Debug) { 'debug' } else { 'release' }
    $configuration = if ($Debug) { 'Debug' } else { 'Release' }
    $buildArguments = @('build', 'windows', "--$mode")
    $desktopClientId = $null
    if (Test-Path -LiteralPath $DefinesFile) {
        $buildArguments += "--dart-define-from-file=$DefinesFile"
        $defines = Get-Content -LiteralPath $DefinesFile -Raw | ConvertFrom-Json
        $desktopIdProperty = $defines.PSObject.Properties['VERSE_GOOGLE_DESKTOP_CLIENT_ID']
        if ($null -ne $desktopIdProperty) { $desktopClientId = [string]$desktopIdProperty.Value }
    } elseif (-not $AllowMissingDefines) {
        throw 'Build configuration is missing. Provide -DefinesFile or use -AllowMissingDefines for an offline preview.'
    }
    # CI supplies the public Desktop OAuth client ID as an Actions variable.
    # Keep it out of the checkout and pass it directly to Flutter's compiler.
    if (-not [string]::IsNullOrWhiteSpace($env:VERSE_GOOGLE_DESKTOP_CLIENT_ID)) {
        $desktopClientId = $env:VERSE_GOOGLE_DESKTOP_CLIENT_ID
        $buildArguments += "--dart-define=VERSE_GOOGLE_DESKTOP_CLIENT_ID=$($env:VERSE_GOOGLE_DESKTOP_CLIENT_ID)"
    }
    $stamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
    $name = "singbook-$($versionMatch.Groups[1].Value)-windows-x64-$mode-$($revision.Substring(0,8))-$stamp"
    $evidence = Join-Path $workspace "artifacts/windows/$name"
    New-Item -ItemType Directory -Path $evidence | Out-Null
    & flutter @buildArguments *> (Join-Path $evidence 'build.log')
    if ($LASTEXITCODE -ne 0) { throw "Windows build failed; see $evidence/build.log" }
    $source = Join-Path $workspace "build/windows/x64/runner/$configuration"
    if (-not (Test-Path -LiteralPath (Join-Path $source 'singbook.exe'))) { throw 'Windows executable was not produced.' }
    $bundle = Join-Path $evidence 'Singbook'
    New-Item -ItemType Directory -Path $bundle | Out-Null
    Get-ChildItem -LiteralPath $source | Where-Object { $_.Extension -ne '.pdb' } | Copy-Item -Destination $bundle -Recurse

    # Check the copied bundle, including generated plugin dependencies and
    # native assets. Merely finding singbook.exe does not prove portability.
    $requiredFiles = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($relative in @(
        'singbook.exe', 'flutter_windows.dll', 'pdfium.dll',
        'data/icudtl.dat', 'data/flutter_assets/AssetManifest.bin',
        'data/flutter_assets/FontManifest.json', 'data/flutter_assets/NOTICES.Z',
        'data/flutter_assets/NativeAssetsManifest.json',
        'data/flutter_assets/assets/fonts/brand-candidates/Lora-OFL.txt',
        'data/flutter_assets/config/source-catalog.json',
        'data/flutter_assets/assets/branding/singbook-icon.png',
        'data/flutter_assets/assets/branding/singbook-mark-foreground.png'
    )) { [void]$requiredFiles.Add($relative) }
    # pubspec.yaml includes the entire top-level assets/fonts directory. These
    # files also supply PDF script fallbacks that FontManifest does not list.
    Get-ChildItem -LiteralPath (Join-Path $workspace 'assets/fonts') -File | ForEach-Object {
        [void]$requiredFiles.Add("data/flutter_assets/assets/fonts/$($_.Name)")
    }
    $pluginManifest = Join-Path $workspace "build/windows/x64/singbook-bundled-libraries-$configuration.txt"
    if (-not (Test-Path -LiteralPath $pluginManifest -PathType Leaf)) {
        throw 'The generated Windows plugin dependency manifest is missing; regenerate the Windows build.'
    }
    $pluginLibraries = @(Get-Content -LiteralPath $pluginManifest | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($pluginLibraries.Count -eq 0) { throw 'The Windows plugin dependency manifest is empty.' }
    foreach ($library in $pluginLibraries) {
        [void]$requiredFiles.Add((Split-Path -Leaf $library.Trim()))
    }
    $nativeManifest = Join-Path $bundle 'data/flutter_assets/NativeAssetsManifest.json'
    if (-not (Test-Path -LiteralPath $nativeManifest -PathType Leaf)) {
        throw 'The bundled native asset manifest is missing.'
    }
    $nativeAssets = (Get-Content -LiteralPath $nativeManifest -Raw | ConvertFrom-Json).'native-assets'.windows_x64
    if ($null -eq $nativeAssets -or $null -eq $nativeAssets.'package:sqlite3/src/ffi/libsqlite3.g.dart') {
        throw 'The Windows SQLite native asset is absent from the bundled manifest.'
    }
    foreach ($asset in $nativeAssets.PSObject.Properties) {
        $route = @($asset.Value)
        if ($route.Count -ne 2 -or $route[0] -ne 'absolute' -or [string]::IsNullOrWhiteSpace($route[1])) {
            throw "Unsupported Windows native asset route for $($asset.Name)."
        }
        $nativeLeaf = Split-Path -Leaf $route[1]
        if ($nativeLeaf -ne $route[1] -or [IO.Path]::IsPathRooted($route[1])) {
            throw "Windows native asset is not relocatable: $($asset.Name)."
        }
        [void]$requiredFiles.Add($nativeLeaf)
    }
    if ($Debug) {
        [void]$requiredFiles.Add('data/flutter_assets/kernel_blob.bin')
        Write-Warning 'Debug bundles are for local development only and require the developer runtime; do not distribute them.'
    } else {
        foreach ($relative in @('data/app.so', 'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll')) {
            [void]$requiredFiles.Add($relative)
        }
        $debugRuntime = @(Get-ChildItem -LiteralPath $bundle -Filter '*.dll' -File | Where-Object {
            $_.Name -match '^(msvcp\d+(?:_\d+)?d|vcruntime\d+(?:_\d+)?d|concrt\d+d|ucrtbased)\.dll$'
        })
        if ($debugRuntime.Count) { throw 'A release bundle contains non-redistributable debug CRT libraries.' }
    }
    foreach ($relative in $requiredFiles) {
        $required = Get-Item -LiteralPath (Join-Path $bundle $relative) -ErrorAction SilentlyContinue
        if ($null -eq $required -or $required.PSIsContainer -or $required.Length -eq 0) {
            throw "Windows bundle is incomplete: missing or empty $relative"
        }
    }
    $desktopClientIdSha256 = $null
    if (-not [string]::IsNullOrWhiteSpace($desktopClientId)) {
        $sha256 = [Security.Cryptography.SHA256]::Create()
        try {
            $desktopClientIdSha256 = [BitConverter]::ToString(
                $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes($desktopClientId))
            ).Replace('-', '')
        } finally {
            $sha256.Dispose()
        }
    }
    $manifest = @{
        version = $versionMatch.Groups[1].Value
        sourceCommit = $revision
        sourceTree = (& git rev-parse 'HEAD^{tree}').Trim()
        configuration = $mode
        distribution = if ($Debug) { 'local-development-only' } else { 'portable-release' }
        oauthConfiguration = @{
            googleDesktopClientIdConfigured = -not [string]::IsNullOrWhiteSpace($desktopClientId)
            googleDesktopClientIdSha256 = $desktopClientIdSha256
        }
        builtAtUtc = $stamp
        requiredFiles = @($requiredFiles | Sort-Object)
        files = @(Get-ChildItem -LiteralPath $bundle -File -Recurse | ForEach-Object {
            @{ path = [IO.Path]::GetRelativePath($bundle, $_.FullName); sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
        })
    }
    $manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $evidence 'manifest.json')
    $archive = Join-Path $evidence "$name.zip"
    Compress-Archive -LiteralPath $bundle -DestinationPath $archive
    Write-Output "Windows bundle: $archive"
    Write-Output "SHA256: $((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash)"
} finally {
    Pop-Location
}
