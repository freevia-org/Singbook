param(
    # Path to a release .aab or .apk.
    [Parameter(Mandatory = $true)][string]$Path,
    # Debug keystore to compare against (public Android debug key, password "android").
    [string]$DebugKeystore = (Join-Path $env:USERPROFILE '.android\debug.keystore'),
    # Expected versionCode / versionName (optional extra checks).
    [int]$ExpectedVersionCode = 0,
    [string]$ExpectedVersionName = ''
)
# Verifies that a release artifact is signed with a non-debug key and prints the
# signer SHA-256, version info and (APK) 16 KB alignment. Exit code 1 on failure.
$ErrorActionPreference = 'Stop'
$jdk = if ($env:JAVA_HOME) { $env:JAVA_HOME } else { $null }
$sdk = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } elseif ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
$keytool = if ($jdk -and (Test-Path (Join-Path $jdk 'bin\keytool.exe'))) { Join-Path $jdk 'bin\keytool.exe' } else { (Get-Command keytool -ErrorAction Stop).Source }
$java = if ($jdk -and (Test-Path (Join-Path $jdk 'bin\java.exe'))) { Join-Path $jdk 'bin\java.exe' } else { (Get-Command java -ErrorAction Stop).Source }
$failed = $false

if (-not (Test-Path -LiteralPath $Path)) { throw "File not found: $Path" }
$Path = (Resolve-Path -LiteralPath $Path).Path
$ext = [IO.Path]::GetExtension($Path).ToLowerInvariant()
if ($ext -notin '.aab', '.apk') { throw 'Expected a .aab or .apk file.' }
Write-Host "Artifact: $Path"
Write-Host ("SHA-256 (file): " + (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant())

function Get-Sha256Fingerprints([string[]]$Lines) {
    $Lines | ForEach-Object {
        if ($_ -match 'SHA-?256:\s*([0-9A-Fa-f:]{95})') { $Matches[1].ToUpperInvariant() }
    } | Select-Object -Unique
}

# --- signer certificate(s) of the artifact ---
# AABs are JAR-signed (keytool). APKs normally carry only v2/v3 signatures,
# which keytool cannot read, so apksigner is preferred for them.
$certOut = @()
$signer = @()
if ($ext -eq '.apk') {
    $apksigner = Get-ChildItem "$sdk\build-tools" -Recurse -Filter apksigner.bat -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending | Select-Object -First 1
    if ($apksigner) {
        if ($jdk) { $env:JAVA_HOME = $jdk }
        $sigOut = & $apksigner.FullName verify --print-certs $Path 2>&1
        if ($LASTEXITCODE -eq 0) {
            $signer = @($sigOut | ForEach-Object {
                if ($_ -match 'certificate SHA-256 digest:\s*([0-9a-fA-F]{64})') {
                    (($Matches[1].ToUpperInvariant() -split '(?<=\G.{2})(?!$)') -join ':')
                }
            } | Select-Object -Unique)
            $certOut = @($sigOut | Where-Object { $_ -match 'certificate DN:' } | ForEach-Object { $_ -replace 'certificate DN:', 'Owner:' })
        } else {
            Write-Host ($sigOut -join "`n")
            Write-Host 'FAIL: apksigner verify failed (unsigned or invalid signature).' -ForegroundColor Red
            exit 1
        }
    }
}
if ($signer.Count -eq 0) {
    $certOut = & $keytool -printcert -jarfile $Path 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host ($certOut -join "`n")
        Write-Host 'FAIL: no signer certificate found (artifact is unsigned or keytool could not read it).' -ForegroundColor Red
        exit 1
    }
    $signer = @(Get-Sha256Fingerprints $certOut)
}
if ($signer.Count -eq 0) { Write-Host 'FAIL: could not parse a SHA-256 signer fingerprint.' -ForegroundColor Red; exit 1 }
foreach ($fp in $signer) { Write-Host "Signer SHA-256: $fp" }
$subject = $certOut | Where-Object { $_ -match '^\s*Owner:' } | Select-Object -First 1
if ($subject) { Write-Host ($subject.Trim()) }

# --- debug key fingerprint ---
$debugFp = @()
if (Test-Path -LiteralPath $DebugKeystore) {
    $dbg = & $keytool -list -v -keystore $DebugKeystore -storepass android -alias androiddebugkey 2>&1
    $debugFp = @(Get-Sha256Fingerprints $dbg)
    foreach ($fp in $debugFp) { Write-Host "Debug key SHA-256: $fp" }
} else {
    Write-Warning "Debug keystore not found at $DebugKeystore; falling back to the certificate subject check."
}
$isDebug = $false
if ($debugFp.Count -gt 0 -and ($signer | Where-Object { $debugFp -contains $_ })) { $isDebug = $true }
if ($subject -and $subject -match 'CN=Android Debug') { $isDebug = $true }
if ($isDebug) {
    Write-Host 'FAIL: artifact is signed with the Android DEBUG key. Do not distribute or upload it.' -ForegroundColor Red
    $failed = $true
} else {
    Write-Host 'OK: signed with a non-debug key.' -ForegroundColor Green
}

# --- version info ---
$versionCode = $null; $versionName = $null
if ($ext -eq '.apk') {
    $aapt2 = Get-ChildItem "$sdk\build-tools" -Recurse -Filter aapt2.exe -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending | Select-Object -First 1
    if ($aapt2) {
        $badging = & $aapt2.FullName dump badging $Path 2>&1
        $pkgLine = $badging | Where-Object { $_ -like 'package:*' } | Select-Object -First 1
        if ($pkgLine -match "versionCode='(\d+)'") { $versionCode = [int]$Matches[1] }
        if ($pkgLine -match "versionName='([^']*)'") { $versionName = $Matches[1] }
        if ($pkgLine -match "name='([^']*)'") { Write-Host "Package: $($Matches[1])" }
        $sdkLines = $badging | Where-Object { $_ -match '^(minSdkVersion|targetSdkVersion|sdkVersion)' }
        $sdkLines | ForEach-Object { Write-Host $_ }
        $dbgFlag = $badging | Where-Object { $_ -match 'application-debuggable' }
        if ($dbgFlag) { Write-Host 'FAIL: application is debuggable.' -ForegroundColor Red; $failed = $true }
        $perms = $badging | Where-Object { $_ -like 'uses-permission:*' }
        Write-Host ("Permissions: " + (($perms | ForEach-Object { ($_ -replace "uses-permission: name='", '') -replace "'.*", '' }) -join ', '))
    } else { Write-Warning 'aapt2 not found; skipping APK version/permission dump.' }
    $zipalign = Get-ChildItem "$sdk\build-tools" -Recurse -Filter zipalign.exe -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending | Select-Object -First 1
    if ($zipalign) {
        & $zipalign.FullName -c -P 16 -v 4 $Path 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { Write-Host 'OK: native libraries are 16 KB aligned (zipalign -P 16).' -ForegroundColor Green }
        else { Write-Host 'FAIL: zipalign -c -P 16 reports misalignment (not 16 KB compatible).' -ForegroundColor Red; $failed = $true }
    }
} else {
    $bundletool = Get-Command bundletool -ErrorAction SilentlyContinue
    $bundletoolJar = Get-ChildItem $env:USERPROFILE -Filter 'bundletool*.jar' -ErrorAction SilentlyContinue | Select-Object -First 1
    $manifest = $null
    if ($bundletool) { $manifest = & $bundletool.Source dump manifest --bundle $Path 2>&1 }
    elseif ($bundletoolJar) { $manifest = & $java -jar $bundletoolJar.FullName dump manifest --bundle $Path 2>&1 }
    if ($manifest) {
        $text = $manifest -join "`n"
        if ($text -match 'android:versionCode="(\d+)"') { $versionCode = [int]$Matches[1] }
        if ($text -match 'android:versionName="([^"]*)"') { $versionName = $Matches[1] }
        if ($text -match 'android:debuggable="true"') { Write-Host 'FAIL: bundle is debuggable.' -ForegroundColor Red; $failed = $true }
        $permNames = [regex]::Matches($text, '<uses-permission[^>]*android:name="([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
        Write-Host ("Permissions: " + ($permNames -join ', '))
    } else {
        Write-Warning 'bundletool not found (put bundletool on PATH or bundletool*.jar in your home folder); version info taken from pubspec.yaml instead.'
        $pub = Join-Path (Split-Path -Parent $PSScriptRoot) 'pubspec.yaml'
        if ((Test-Path $pub) -and ((Get-Content $pub -Raw) -match '(?m)^version:\s*([^\s+]+)\+(\d+)')) {
            Write-Host "pubspec.yaml version (not read from the bundle): $($Matches[1]) ($($Matches[2]))"
        }
    }
}
if ($null -ne $versionName -or $null -ne $versionCode) { Write-Host "versionName=$versionName versionCode=$versionCode" }
if ($ExpectedVersionCode -gt 0 -and $null -ne $versionCode -and $versionCode -ne $ExpectedVersionCode) {
    Write-Host "FAIL: versionCode $versionCode != expected $ExpectedVersionCode." -ForegroundColor Red; $failed = $true
}
if ($ExpectedVersionName -and $null -ne $versionName -and $versionName -ne $ExpectedVersionName) {
    Write-Host "FAIL: versionName $versionName != expected $ExpectedVersionName." -ForegroundColor Red; $failed = $true
}
if ($failed) { exit 1 }
Write-Host 'Release verification passed.' -ForegroundColor Green
