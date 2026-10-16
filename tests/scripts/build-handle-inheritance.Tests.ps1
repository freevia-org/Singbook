param([switch]$RunAsLauncher, [string]$FixtureRoot)
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$powerShell = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
$argument = 'two words "quoted" trailing\'
if ($RunAsLauncher) {
    . (Join-Path $PSScriptRoot 'native-handle-probe.ps1') -InitializeOnly
    $sentinel = Join-Path $FixtureRoot ('sentinel-' + [Guid]::NewGuid().ToString('N') + '.txt')
    $file = [IO.File]::Open($sentinel, [IO.FileMode]::CreateNew, [IO.FileAccess]::ReadWrite, [IO.FileShare]::ReadWrite)
    try {
        $handle = $file.SafeFileHandle.DangerousGetHandle()
        if (-not [SingbookHandleProbe]::SetHandleInformation($handle, 1, 1)) { throw 'Cannot mark sentinel handle inheritable.' }
        $positiveControl = [SingbookHandleProbe]::PathFor($handle)
        if (-not $positiveControl.EndsWith([IO.Path]::GetFileName($sentinel))) { throw 'Sentinel identity positive control failed.' }
        $arguments = @('-NoProfile', '-NonInteractive', '-File', (Join-Path $FixtureRoot 'probe with spaces.ps1'),
            '-HandleValue', $handle.ToInt64().ToString(), '-ExpectedFile', $sentinel,
            '-Report', (Join-Path $FixtureRoot 'child report.json'), '-ProbeArgument', $argument)
        $code = & (Join-Path $repoRoot 'scripts\invoke-build-in-job.ps1') -FilePath $powerShell -ArgumentList $arguments -WorkingDirectory $FixtureRoot
        if ($code -ne 0) { throw "Probe failed ($code)." }
    } finally { $file.Dispose() }
    return
}
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('singbook handle proof ' + [Guid]::NewGuid().ToString('N'))
$child = $null
try {
    [IO.Directory]::CreateDirectory($fixture) | Out-Null
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'native-handle-probe.ps1') -Destination (Join-Path $fixture 'probe with spaces.ps1')
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = $powerShell
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardInput = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    foreach ($value in @('-NoProfile', '-NonInteractive', '-File', $PSCommandPath, '-RunAsLauncher', '-FixtureRoot', $fixture)) { $start.ArgumentList.Add($value) }
    $child = [Diagnostics.Process]::Start($start)
    $child.StandardInput.Close()
    $stdout = $child.StandardOutput.ReadToEndAsync()
    $stderr = $child.StandardError.ReadToEndAsync()
    if (-not $child.WaitForExit(30000)) { throw 'Handle probe exceeded its deadline.' }
    $out = $stdout.GetAwaiter().GetResult()
    $err = $stderr.GetAwaiter().GetResult()
    if ($child.ExitCode -ne 0) { throw "Launcher failed ($($child.ExitCode)): $out $err" }
    if (-not $out.Contains('HANDLE_PROBE_STDOUT')) { throw "Redirected stdout lost: $out $err" }
    if (-not $err.Contains('HANDLE_PROBE_STDERR')) { throw "Redirected stderr lost: $out $err" }
    $report = Get-Content -LiteralPath (Join-Path $fixture 'child report.json') -Raw | ConvertFrom-Json
    if ($report.unrelatedHandleInherited) { throw 'Unrelated inheritable file handle leaked into the owned worker.' }
    if ($report.workingDirectory -ne $fixture -or $report.powerShellLocation -ne $fixture) { throw 'Worker did not start in its requested working directory.' }
    if ($report.argument -cne $argument) { throw 'Argument spaces, quotes or trailing backslash were changed.' }
    Write-Output 'PASS: unrelated handle excluded; stdout/stderr, cwd, spaced script path and quoted argument preserved.'
} finally {
    if ($null -ne $child) {
        if (-not $child.HasExited) {
            $child.Kill()
            if (-not $child.WaitForExit(5000)) { throw 'Owned probe launcher did not stop.' }
        }
        $child.Dispose()
    }
    $resolvedFixture = [IO.Path]::GetFullPath($fixture)
    $temporaryRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
    if ([IO.Path]::GetDirectoryName($resolvedFixture) -ne $temporaryRoot -or
        -not [IO.Path]::GetFileName($resolvedFixture).StartsWith('singbook handle proof ')) {
        throw 'Fixture cleanup refused a path outside its exclusive temporary directory.'
    }
    if (Test-Path -LiteralPath $resolvedFixture) { Remove-Item -LiteralPath $resolvedFixture -Recurse -Force }
}
