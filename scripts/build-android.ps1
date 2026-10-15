param(
    [switch]$Debug,
    # Release builds need config/local.defines.json (API tokens, OAuth IDs).
    # Without it the app silently ships without them, so fail unless asked.
    [switch]$AllowMissingDefines,
    # Production build: refuse to sign a release with the debug key
    # (requires android/key.properties; see README "Release signing").
    [switch]$Production,
    # Build a Play App Bundle (.aab) instead of an APK:
    #   flutter build appbundle --release
    # Copies the .aab and native-debug-symbols zip to artifacts/ and prints the
    # SHA-256 of the bundle. Use with -Production for anything uploaded to Play.
    [switch]$Bundle
)
$ErrorActionPreference = 'Stop'
$workspace = Split-Path -Parent $PSScriptRoot
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Flutter is not on PATH. Install Flutter and add its bin directory to PATH before building.'
}
if (-not $env:JAVA_HOME -and -not (Get-Command java -ErrorAction SilentlyContinue)) {
    throw 'Java is not available. Set JAVA_HOME to a JDK 21 installation or add Java to PATH.'
}
Push-Location $workspace
try {
    if ($Production -and $Debug) { throw '-Production cannot be combined with -Debug.' }
    if ($Bundle -and $Debug) { throw '-Bundle builds a release bundle and cannot be combined with -Debug.' }
    $mode = if ($Debug) { '--debug' } else { '--release' }
    $target = if ($Bundle) { 'appbundle' } else { 'apk' }
    $arguments = @('build', $target, $mode, '--dart-define=cronetHttpNoPlay=true')
    $definesPath = Join-Path $workspace 'config/local.defines.json'
    if (Test-Path -LiteralPath $definesPath) {
        $arguments += @('--dart-define-from-file', $definesPath)
    } elseif (-not $Debug) {
        $message = "config/local.defines.json is missing: this release build will have no Genius token and no Google sign-in IDs. Copy config/defines.example.json to config/local.defines.json and fill it in."
        if (-not $AllowMissingDefines) {
            throw "$message Pass -AllowMissingDefines to build anyway."
        }
        Write-Warning $message
    }
    $keyProps = Join-Path $workspace 'android/key.properties'
    if ($Production) {
        if (-not (Test-Path -LiteralPath $keyProps)) {
            throw 'Production build requires android/key.properties (release keystore).'
        }
        # Read by android/app/build.gradle.kts as -PrequireReleaseSigning=true.
        $env:ORG_GRADLE_PROJECT_requireReleaseSigning = 'true'
    } elseif (-not $Debug -and -not (Test-Path -LiteralPath $keyProps)) {
        Write-Warning 'android/key.properties is missing: the release build is signed with the DEBUG key (local preview only, never distribute or upload to Play).'
    }
    & flutter @arguments
    if ($LASTEXITCODE -ne 0) { throw "Flutter build failed ($LASTEXITCODE)" }

    if ($Bundle) {
        $pubspec = Get-Content -LiteralPath (Join-Path $workspace 'pubspec.yaml') -Raw
        if ($pubspec -notmatch '(?m)^version:\s*([^\s+]+)\+(\d+)') { throw 'Cannot read version from pubspec.yaml.' }
        $versionName = $Matches[1]
        $versionCode = $Matches[2]
        $suffix = "$versionName+$versionCode"
        $artifacts = Join-Path $workspace 'artifacts'
        New-Item -ItemType Directory -Force -Path $artifacts | Out-Null

        $aabSource = Join-Path $workspace 'build/app/outputs/bundle/release/app-release.aab'
        if (-not (Test-Path -LiteralPath $aabSource)) { throw "Expected bundle not found: $aabSource" }
        $aabName = "singbook-$suffix-release.aab"
        $aabTarget = Join-Path $artifacts $aabName
        Copy-Item -LiteralPath $aabSource -Destination $aabTarget -Force
        Write-Host "Bundle:  $aabTarget"

        $symbols = Get-ChildItem -Path (Join-Path $workspace 'build') -Recurse -Filter '*.zip' -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match 'native-debug-symbols' -and $_.FullName -match 'release' } |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($symbols) {
            $symName = "singbook-$suffix-native-debug-symbols.zip"
            Copy-Item -LiteralPath $symbols.FullName -Destination (Join-Path $artifacts $symName) -Force
            Write-Host "Symbols: $(Join-Path $artifacts $symName)"
        } else {
            Write-Warning 'No native-debug-symbols zip found under build/; Play Console may warn about missing symbols.'
        }

        $hash = (Get-FileHash -LiteralPath $aabTarget -Algorithm SHA256).Hash.ToLowerInvariant()
        Write-Host "SHA-256: $hash  $aabName"
        Write-Host "Version: $versionName (versionCode $versionCode)"
        Write-Host "Next:    .\scripts\verify-release.ps1 -Path '$aabTarget'"
    }
} finally {
    Remove-Item Env:ORG_GRADLE_PROJECT_requireReleaseSigning -ErrorAction SilentlyContinue
    Pop-Location
}
