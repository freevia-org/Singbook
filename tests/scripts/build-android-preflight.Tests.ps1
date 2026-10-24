# No SDK or device required: run the worker against a disposable repository and
# fake Flutter, proving collisions are refused before Flutter changes build/.
$ErrorActionPreference = 'Stop'
$root = Join-Path ([IO.Path]::GetTempPath()) ('singbook-android-preflight-' + [Guid]::NewGuid().ToString('N'))
$originalJavaHome = [Environment]::GetEnvironmentVariable('JAVA_HOME', 'Process')
try {
    New-Item -ItemType Directory -Path "$root/scripts", "$root/config", "$root/android", "$root/artifacts" | Out-Null
    Copy-Item (Join-Path $PSScriptRoot '../../scripts/build-android.ps1') "$root/scripts/build-android.ps1"
    Set-Content "$root/pubspec.yaml" 'version: 0.2.20+34'
    Set-Content "$root/config/local.defines.json" '{}'
    Set-Content "$root/android/key.properties" 'fixture only'
    $env:JAVA_HOME = 'fixture-jdk'
    $global:PreflightFlutterCalls = 0
    function global:flutter {
        $global:PreflightFlutterCalls++
        New-Item -ItemType Directory -Force -Path 'build/app/outputs/bundle/release', 'build/app/outputs/native-debug-symbols/release' | Out-Null
        Set-Content 'build/app/outputs/bundle/release/app-release.aab' 'new bundle'
        Set-Content 'build/app/outputs/native-debug-symbols/release/native-debug-symbols.zip' 'new symbols'
        $global:LASTEXITCODE = 0
    }
    $script = "$root/scripts/build-android.ps1"
    foreach ($leaf in @('singbook-0.2.20+34-release.aab', 'singbook-0.2.20+34-native-debug-symbols.zip')) {
        $target = Join-Path "$root/artifacts" $leaf
        Set-Content $target 'verified bytes'
        $before = (Get-FileHash $target).Hash
        $refused = $false
        try { & $script -Bundle -Production -BuildWorker } catch {
            if ($_.Exception.Message -notmatch 'already exists') { throw }
            $refused = $true
        }
        if (-not $refused -or $PreflightFlutterCalls -ne 0 -or (Test-Path "$root/build")) { throw 'Collision invoked Flutter or changed build outputs.' }
        if ((Get-FileHash $target).Hash -ne $before) { throw 'Collision changed verified bytes.' }
        Remove-Item $target
    }
    Set-Content "$root/artifacts/singbook-0.2.20+34-release.aab" 'old bundle'
    Set-Content "$root/artifacts/singbook-0.2.20+34-native-debug-symbols.zip" 'old symbols'
    & $script -Bundle -Production -BuildWorker -Force
    if ($PreflightFlutterCalls -ne 1) { throw 'Force did not invoke Flutter exactly once.' }
    if ((Get-Content "$root/artifacts/singbook-0.2.20+34-release.aab" -Raw).Trim() -ne 'new bundle') { throw 'Force did not copy the new bundle.' }
    if ((Get-Content "$root/artifacts/singbook-0.2.20+34-native-debug-symbols.zip" -Raw).Trim() -ne 'new symbols') { throw 'Force did not copy the new symbols.' }
    if ((Get-Content "$root/pubspec.yaml" -Raw).Trim() -ne 'version: 0.2.20+34') { throw 'Retry changed the release number.' }
    Write-Output 'Android output preflight tests passed.'
} finally {
    Remove-Item Function:flutter -ErrorAction SilentlyContinue
    [Environment]::SetEnvironmentVariable('JAVA_HOME', $originalJavaHome, 'Process')
    if (Test-Path $root) { Remove-Item $root -Recurse -Force }
}
