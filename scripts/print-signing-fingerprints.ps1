param(
    # Path to android/key.properties (git-ignored). Default: next to this repo's android folder.
    [string]$KeyProperties = (Join-Path $PSScriptRoot '..\android\key.properties'),
    # Debug keystore (public Android debug key, password "android").
    [string]$DebugKeystore = (Join-Path $env:USERPROFILE '.android\debug.keystore')
)
# Prints ONLY owner, SHA-1 and SHA-256 of the upload and debug certificates, for
# registering Android OAuth clients (see docs/google-oauth-setup.md).
# Passwords are read from key.properties, handed to keytool through environment
# variables (-storepass:env), and are never printed. The Play app-signing SHA-1
# is not available locally: copy it from Play Console > App integrity.
$ErrorActionPreference = 'Stop'
$jdk = 'C:\Program Files\Microsoft\jdk-21.0.12.101-hotspot'
$keytool = if (Test-Path "$jdk\bin\keytool.exe") { "$jdk\bin\keytool.exe" } else { (Get-Command keytool -ErrorAction Stop).Source }

function Show-Fingerprints([string]$Label, [string]$Store, [string]$Alias, [string]$EnvVar) {
    Write-Host "== $Label =="
    $out = & $keytool -list -v -keystore $Store -alias $Alias "-storepass:env" $EnvVar 2>&1
    if ($LASTEXITCODE -ne 0) {
        # Do not echo keytool output beyond a generic message (it may name paths only, never passwords).
        Write-Warning "keytool failed for $Label (wrong password, alias or keystore?)."
        return
    }
    foreach ($line in $out) {
        $text = "$line"
        if ($text -match '^\s*Owner:\s*(.+)$') { Write-Host ("Owner : " + $Matches[1]) }
        elseif ($text -match '^\s*SHA1:\s*([0-9A-Fa-f:]+)\s*$') { Write-Host ("SHA-1 : " + $Matches[1].ToUpperInvariant()) }
        elseif ($text -match '^\s*SHA256:\s*([0-9A-Fa-f:]+)\s*$') { Write-Host ("SHA-256: " + $Matches[1].ToUpperInvariant()) }
    }
}

# Debug key (public default password).
if (Test-Path -LiteralPath $DebugKeystore) {
    $env:SINGBOOK_FP_PASS = 'android'
    try { Show-Fingerprints 'Debug keystore' $DebugKeystore 'androiddebugkey' 'SINGBOOK_FP_PASS' }
    finally { Remove-Item Env:\SINGBOOK_FP_PASS -ErrorAction SilentlyContinue }
} else {
    Write-Warning "Debug keystore not found: $DebugKeystore"
}

# Upload key from key.properties.
if (Test-Path -LiteralPath $KeyProperties) {
    $props = @{}
    Get-Content -LiteralPath $KeyProperties | ForEach-Object {
        if ($_ -match '^\s*([^#=\s][^=]*?)\s*=\s*(.*)$') { $props[$Matches[1]] = $Matches[2].Trim() }
    }
    $missing = 'storeFile', 'storePassword', 'keyAlias' | Where-Object { -not $props[$_] }
    if ($missing) {
        Write-Warning ("key.properties is missing: " + ($missing -join ', '))
    } else {
        $store = $props['storeFile']
        if (-not [IO.Path]::IsPathRooted($store)) {
            # Gradle resolves relative to the android/app module; try that, then android/.
            $base = Split-Path -Parent $KeyProperties
            $candidate = Join-Path (Join-Path $base 'app') $store
            $store = if (Test-Path -LiteralPath $candidate) { $candidate } else { Join-Path $base $store }
        }
        if (-not (Test-Path -LiteralPath $store)) {
            Write-Warning 'Upload keystore file from key.properties was not found.'
        } else {
            $env:SINGBOOK_FP_PASS = $props['storePassword']
            try { Show-Fingerprints 'Upload keystore' $store $props['keyAlias'] 'SINGBOOK_FP_PASS' }
            finally { Remove-Item Env:\SINGBOOK_FP_PASS -ErrorAction SilentlyContinue }
        }
    }
} else {
    Write-Warning 'android/key.properties not found; upload key fingerprints skipped.'
}

Write-Host ''
Write-Host 'Play app-signing SHA-1: Play Console > your app > App integrity > App signing.'
