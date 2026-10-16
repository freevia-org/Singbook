param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Sleep', 'ExitSuccess', 'ExitFailure')]
    [string]$Mode,
    [Parameter(Mandatory = $true)]
    [string]$RecordPath,
    [Parameter(Mandatory = $true)]
    [string]$HoldScript
)

$ErrorActionPreference = 'Stop'
$powerShell = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
$grandchild = & (Join-Path $PSScriptRoot 'start-hidden-process.ps1') -FilePath $powerShell -ArgumentList @('-NoProfile', '-File', $HoldScript)
[IO.File]::WriteAllText($RecordPath, "$PID`n$($grandchild.Id)")

switch ($Mode) {
    'Sleep' { while ($true) { Start-Sleep -Seconds 1 } }
    'ExitSuccess' { exit 0 }
    'ExitFailure' { exit 17 }
}
