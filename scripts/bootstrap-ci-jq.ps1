[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
if ($env:RUNNER_OS -ne 'Windows') {
    throw 'This bootstrap is for Windows Actions jobs only.'
}
if ([string]::IsNullOrWhiteSpace($env:RUNNER_TEMP) -or
    [string]::IsNullOrWhiteSpace($env:GITHUB_PATH)) {
    throw 'RUNNER_TEMP and GITHUB_PATH are required.'
}

# Official jq release; verification precedes execution and PATH publication.
$jqVersion = '1.8.2'
$jqSha256 = 'a6fc67fedaf9128a3309a1e2ebb8b986aeccf70122ee46d2cb4849e423f0c627'
$jqTempRoot = [System.IO.Path]::GetFullPath($env:RUNNER_TEMP)
$jqToolDir = Join-Path $jqTempRoot "singbook-ci-jq-$jqVersion"
New-Item -ItemType Directory -Path $jqToolDir -Force | Out-Null
$jqDownloadPath = Join-Path $jqToolDir 'jq.download'
$jqExePath = Join-Path $jqToolDir 'jq.exe'
$jqUri = "https://github.com/jqlang/jq/releases/download/jq-$jqVersion/jq-windows-amd64.exe"
Invoke-WebRequest -Uri $jqUri -OutFile $jqDownloadPath -TimeoutSec 60
if ((Get-Item -LiteralPath $jqDownloadPath).Length -ne 1035264) {
    throw 'The jq release artifact has an unexpected size.'
}
if ((Get-FileHash -LiteralPath $jqDownloadPath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $jqSha256) {
    throw 'The jq release artifact failed SHA-256 verification.'
}
Move-Item -LiteralPath $jqDownloadPath -Destination $jqExePath -Force
$jqReportedVersion = (& $jqExePath --version).Trim()
if ($LASTEXITCODE -ne 0 -or $jqReportedVersion -ne "jq-$jqVersion") {
    throw 'The verified jq executable did not report the pinned version.'
}
Add-Content -LiteralPath $env:GITHUB_PATH -Value $jqToolDir -Encoding utf8
Write-Output "Verified jq-$jqVersion for this job."
