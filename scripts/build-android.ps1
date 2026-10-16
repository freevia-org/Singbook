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
    [switch]$Bundle,
    # Allow replacing an existing artifacts/ file of the same version. Without
    # it the script refuses, so a verified .aab is never silently overwritten.
    [switch]$Force,
    # Internal worker mode, launched under the native kill-on-close job below.
    [switch]$BuildWorker
)
$ErrorActionPreference = 'Stop'
$workspace = Split-Path -Parent $PSScriptRoot
$environmentKeysToRestore = @(
    'ORG_GRADLE_PROJECT_requireReleaseSigning',
    'ORG_GRADLE_PROJECT_allowDebugSigning'
)
$originalEnvironment = @{}
foreach ($key in $environmentKeysToRestore) {
    $originalEnvironment[$key] = @{
        Exists = Test-Path -LiteralPath "Env:$key"
        Value = [Environment]::GetEnvironmentVariable($key, 'Process')
    }
}
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Flutter is not on PATH. Install Flutter and add its bin directory to PATH before building.'
}
if (-not $env:JAVA_HOME -and -not (Get-Command java -ErrorAction SilentlyContinue)) {
    throw 'Java is not available. Set JAVA_HOME to a JDK 21 installation or add Java to PATH.'
}
if (-not $BuildWorker) {
    $workerArguments = @(
        '-NoLogo',
        '-NoProfile',
        '-NonInteractive',
        '-File',
        $PSCommandPath,
        '-BuildWorker'
    )
    $switchesToForward = @{
        Debug = $Debug
        AllowMissingDefines = $AllowMissingDefines
        Production = $Production
        Bundle = $Bundle
        Force = $Force
    }
    foreach ($switchName in $switchesToForward.Keys) {
        if ($switchesToForward[$switchName]) { $workerArguments += "-$switchName" }
    }
    $powerShellExecutable = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    $jobRunner = Join-Path $PSScriptRoot 'invoke-build-in-job.ps1'
    $workerExitCode = & $jobRunner -FilePath $powerShellExecutable -ArgumentList $workerArguments -WorkingDirectory $workspace
    if ($workerExitCode -ne 0) { throw "Android build worker failed ($workerExitCode)" }
    return
}
Push-Location $workspace
try {
    if ($Production -and $Debug) { throw '-Production cannot be combined with -Debug.' }
    if ($Bundle -and $Debug) { throw '-Bundle builds a release bundle and cannot be combined with -Debug.' }
    if ($Production -and $AllowMissingDefines) { throw '-Production cannot be combined with -AllowMissingDefines (the build would ship without the Genius token / Google sign-in IDs).' }
    if ($Bundle -and -not $Production) { Write-Warning 'Bundle built without -Production: it is only suitable for upload to Play if android/key.properties exists (the build fails otherwise).' }
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
        if ($Bundle) { throw 'A release bundle requires android/key.properties; the debug-key preview fallback is only for APKs.' }
        Write-Warning 'android/key.properties is missing: the release APK is signed with the DEBUG key (local preview only, never distribute or upload to Play).'
        # Gradle refuses to use the debug key unless explicitly allowed
        # (android/app/build.gradle.kts, -PallowDebugSigning=true).
        $env:ORG_GRADLE_PROJECT_allowDebugSigning = 'true'
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
        $symName = "singbook-$suffix-native-debug-symbols.zip"
        foreach ($existing in @($aabTarget, (Join-Path $artifacts $symName))) {
            if ((Test-Path -LiteralPath $existing) -and -not $Force) {
                throw "$existing already exists. Raise the versionCode in pubspec.yaml, or pass -Force to replace it (a verified artifact must not be overwritten silently)."
            }
        }
        $aabBuilt = Get-Item -LiteralPath $aabSource
        Copy-Item -LiteralPath $aabSource -Destination $aabTarget -Force
        Write-Host "Bundle:  $aabTarget"

        # Exact AGP output path; it must also be at least as new as the bundle
        # so a zip left by an earlier versionCode is never copied under this name.
        $symbols = Get-Item -LiteralPath (Join-Path $workspace 'build/app/outputs/native-debug-symbols/release/native-debug-symbols.zip') -ErrorAction SilentlyContinue
        if ($symbols -and $symbols.LastWriteTime -lt $aabBuilt.LastWriteTime.AddMinutes(-5)) {
            Write-Warning "Ignoring stale native-debug-symbols.zip ($($symbols.LastWriteTime)); it predates this bundle."
            $symbols = $null
        }
        if ($symbols) {
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
    foreach ($key in $environmentKeysToRestore) {
        $original = $originalEnvironment[$key]
        if ($original.Exists) {
            [Environment]::SetEnvironmentVariable($key, $original.Value, 'Process')
        } else {
            Remove-Item -LiteralPath "Env:$key" -ErrorAction SilentlyContinue
        }
    }
    Pop-Location
}
