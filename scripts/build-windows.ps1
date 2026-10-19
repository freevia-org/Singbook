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
    if ($status) { throw 'Commit the source before creating a traceable Windows bundle.' }
    $versionMatch = [regex]::Match((Get-Content pubspec.yaml -Raw), '(?m)^version:\s*(\S+)')
    if (-not $versionMatch.Success) { throw 'Cannot determine app version.' }
    $mode = if ($Debug) { 'debug' } else { 'release' }
    $configuration = if ($Debug) { 'Debug' } else { 'Release' }
    $buildArguments = @('build', 'windows', "--$mode")
    if (Test-Path -LiteralPath $DefinesFile) {
        $buildArguments += "--dart-define-from-file=$DefinesFile"
    } elseif (-not $AllowMissingDefines) {
        throw 'Build configuration is missing. Provide -DefinesFile or use -AllowMissingDefines for an offline preview.'
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
    $manifest = @{
        version = $versionMatch.Groups[1].Value
        sourceCommit = $revision
        sourceTree = (& git rev-parse 'HEAD^{tree}').Trim()
        configuration = $mode
        builtAtUtc = $stamp
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
