param(
    # Path to a release .aab or .apk.
    [Parameter(Mandatory = $true)][string]$Path,
    # Debug keystore to compare against (public Android debug key, password "android").
    [string]$DebugKeystore = (Join-Path $env:USERPROFILE '.android\debug.keystore'),
    # Expected versionCode / versionName (optional extra checks).
    [int]$ExpectedVersionCode = 0,
    [string]$ExpectedVersionName = '',
    # Minimum acceptable targetSdkVersion (Play requires 36 from 2026-08-31).
    [int]$MinTargetSdk = 36
)
# Verifies that a release artifact is signed with a non-debug key and prints the
# signer SHA-256, version info, targetSdk, debuggable flag and the 16 KB ELF
# alignment of the 64-bit native libraries (APK and AAB). An .aab that cannot be
# inspected because bundletool is missing is reported as UNVERIFIED and fails.
# Exit code 1 on failure.
$ErrorActionPreference = 'Stop'
$jdk = if ($env:JAVA_HOME) { $env:JAVA_HOME } else { $null }
$sdk = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } elseif ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
$keytool = if ($jdk -and (Test-Path (Join-Path $jdk 'bin\keytool.exe'))) { Join-Path $jdk 'bin\keytool.exe' } else { (Get-Command keytool -ErrorAction Stop).Source }
$java = if ($jdk -and (Test-Path (Join-Path $jdk 'bin\java.exe'))) { Join-Path $jdk 'bin\java.exe' } else { (Get-Command java -ErrorAction Stop).Source }
$failed = $false
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Newest build-tools directory (by version, not by text) that contains $Name.
function Get-BuildTool([string]$Name) {
    $dirs = Get-ChildItem "$sdk\build-tools" -Directory -ErrorAction SilentlyContinue | Sort-Object {
        $v = $null
        if ([version]::TryParse(($_.Name -replace '[^0-9.].*$', ''), [ref]$v)) { $v } else { [version]'0.0' }
    } -Descending
    foreach ($d in $dirs) {
        $f = Get-ChildItem $d.FullName -Filter $Name -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($f) { Write-Host "Using $Name from build-tools $($d.Name)"; return $f }
    }
    return $null
}

# Parses the program headers of every lib/<abi>/*.so entry in a zip (.apk or
# .aab) and requires PT_LOAD p_align >= 16 KB for the 64-bit ABIs. Returns the
# number of failures, or -1 when the archive holds no native libraries.
function Test-ElfAlignment([string]$ZipPath) {
    $bad = 0; $checked = 0
    $zip = [IO.Compression.ZipFile]::OpenRead($ZipPath)
    try {
        foreach ($entry in $zip.Entries) {
            if ($entry.FullName -notmatch '(^|/)lib/([^/]+)/[^/]+\.so$') { continue }
            $abi = $Matches[2]
            $buf = New-Object byte[] 65536
            $stream = $entry.Open()
            try { $n = $stream.Read($buf, 0, $buf.Length) } finally { $stream.Dispose() }
            if ($n -lt 64 -or $buf[0] -ne 0x7F -or $buf[1] -ne 0x45 -or $buf[2] -ne 0x4C -or $buf[3] -ne 0x46) {
                Write-Host "FAIL: $($entry.FullName) is not a readable ELF file." -ForegroundColor Red; $bad++; continue
            }
            $is64 = $buf[4] -eq 2
            if ($is64) {
                $phoff = [int][BitConverter]::ToUInt64($buf, 0x20)
                $phentsize = [int][BitConverter]::ToUInt16($buf, 0x36)
                $phnum = [int][BitConverter]::ToUInt16($buf, 0x38)
            } else {
                $phoff = [int][BitConverter]::ToUInt32($buf, 0x1C)
                $phentsize = [int][BitConverter]::ToUInt16($buf, 0x2A)
                $phnum = [int][BitConverter]::ToUInt16($buf, 0x2C)
            }
            if ($phoff + $phentsize * $phnum -gt $n) {
                Write-Host "FAIL: $($entry.FullName) program headers lie beyond the first 64 KB." -ForegroundColor Red; $bad++; continue
            }
            $minAlign = [uint64]::MaxValue
            for ($i = 0; $i -lt $phnum; $i++) {
                $o = $phoff + $i * $phentsize
                if ([BitConverter]::ToUInt32($buf, $o) -ne 1) { continue }  # PT_LOAD only
                $align = if ($is64) { [BitConverter]::ToUInt64($buf, $o + 0x30) } else { [uint64][BitConverter]::ToUInt32($buf, $o + 0x1C) }
                if ($align -lt $minAlign) { $minAlign = $align }
            }
            $checked++
            if ($abi -in 'arm64-v8a', 'x86_64') {
                if ($minAlign -lt 16384) {
                    Write-Host "FAIL: $($entry.FullName) PT_LOAD alignment is $minAlign (needs >= 16384 for 16 KB devices)." -ForegroundColor Red; $bad++
                }
            }
        }
    } finally { $zip.Dispose() }
    if ($checked -eq 0) { return -1 }
    Write-Host "Checked ELF alignment of $checked native library entries; 32-bit ABIs are informational only."
    return $bad
}

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
    $apksigner = Get-BuildTool 'apksigner.bat'
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
    $aapt2 = Get-BuildTool 'aapt2.exe'
    if ($aapt2) {
        $badging = & $aapt2.FullName dump badging $Path 2>&1
        $pkgLine = $badging | Where-Object { $_ -like 'package:*' } | Select-Object -First 1
        if ($pkgLine -match "versionCode='(\d+)'") { $versionCode = [int]$Matches[1] }
        if ($pkgLine -match "versionName='([^']*)'") { $versionName = $Matches[1] }
        if ($pkgLine -match "name='([^']*)'") { Write-Host "Package: $($Matches[1])" }
        $sdkLines = $badging | Where-Object { $_ -match '^(minSdkVersion|targetSdkVersion|sdkVersion)' }
        $sdkLines | ForEach-Object { Write-Host $_ }
        $tsdk = $badging | Where-Object { $_ -match "^targetSdkVersion:'(\d+)'" } | ForEach-Object { [int]$Matches[1] } | Select-Object -First 1
        if ($null -eq $tsdk) { Write-Host 'FAIL: targetSdkVersion not found in the APK badging.' -ForegroundColor Red; $failed = $true }
        elseif ($tsdk -lt $MinTargetSdk) { Write-Host "FAIL: targetSdkVersion $tsdk < $MinTargetSdk." -ForegroundColor Red; $failed = $true }
        else { Write-Host "OK: targetSdkVersion $tsdk >= $MinTargetSdk." -ForegroundColor Green }
        $dbgFlag = $badging | Where-Object { $_ -match 'application-debuggable' }
        if ($dbgFlag) { Write-Host 'FAIL: application is debuggable.' -ForegroundColor Red; $failed = $true }
        $perms = $badging | Where-Object { $_ -like 'uses-permission:*' }
        Write-Host ("Permissions: " + (($perms | ForEach-Object { ($_ -replace "uses-permission: name='", '') -replace "'.*", '' }) -join ', '))
    } else { Write-Host 'FAIL: aapt2 not found; the APK targetSdk/debuggable flag are UNVERIFIED.' -ForegroundColor Red; $failed = $true }
    $zipalign = Get-BuildTool 'zipalign.exe'
    if ($zipalign) {
        $zaOut = & $zipalign.FullName -c -P 16 -v 4 $Path 2>&1
        $zaCode = $LASTEXITCODE
        if ($zaCode -eq 0) { Write-Host 'OK: zip entries are 16 KB aligned (zipalign -P 16).' -ForegroundColor Green }
        elseif (($zaOut -join "`n") -match 'Verification FAILED|\(BAD\)') {
            Write-Host 'FAIL: zipalign -c -P 16 reports misalignment (not 16 KB compatible).' -ForegroundColor Red; $failed = $true
        } else {
            Write-Host "FAIL: UNVERIFIED zip entry alignment. zipalign exited $zaCode without an alignment verdict (build-tools too old for -P?). The ELF check below covers native library segments only, not ZIP entry alignment." -ForegroundColor Red; $failed = $true
        }
    } else {
        Write-Host 'FAIL: UNVERIFIED zip entry alignment. zipalign.exe was not found in the Android SDK build-tools; the ELF check below covers native library segments only, not ZIP entry alignment.' -ForegroundColor Red; $failed = $true
    }
    $elfBad = Test-ElfAlignment $Path
    if ($elfBad -gt 0) { $failed = $true }
    elseif ($elfBad -lt 0) { Write-Host 'FAIL: no native libraries found; ELF alignment UNVERIFIED.' -ForegroundColor Red; $failed = $true }
    else { Write-Host 'OK: 64-bit native libraries have 16 KB ELF segment alignment.' -ForegroundColor Green }
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
        if ($text -match 'android:targetSdkVersion="(\d+)"') {
            $tsdk = [int]$Matches[1]
            if ($tsdk -lt $MinTargetSdk) { Write-Host "FAIL: targetSdkVersion $tsdk < $MinTargetSdk." -ForegroundColor Red; $failed = $true }
            else { Write-Host "OK: targetSdkVersion $tsdk >= $MinTargetSdk." -ForegroundColor Green }
        } else { Write-Host 'FAIL: targetSdkVersion not found in the bundle manifest.' -ForegroundColor Red; $failed = $true }
        $permNames = [regex]::Matches($text, '<uses-permission[^>]*android:name="([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
        Write-Host ("Permissions: " + ($permNames -join ', '))
    } else {
        Write-Host 'FAIL: UNVERIFIED. bundletool not found (put bundletool on PATH or bundletool*.jar in your home folder), so the bundle manifest (versionCode, debuggable, permissions, targetSdk) was NOT inspected.' -ForegroundColor Red
        $failed = $true
    }
    $elfBad = Test-ElfAlignment $Path
    if ($elfBad -gt 0) { $failed = $true }
    elseif ($elfBad -lt 0) { Write-Host 'FAIL: no native libraries found in the bundle; ELF alignment UNVERIFIED.' -ForegroundColor Red; $failed = $true }
    else { Write-Host 'OK: 64-bit native libraries have 16 KB ELF segment alignment.' -ForegroundColor Green }
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
