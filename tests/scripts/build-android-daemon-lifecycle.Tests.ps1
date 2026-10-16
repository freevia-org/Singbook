param(
    [Parameter()]
    [switch]$RunAsSupervisor,
    [Parameter()]
    [switch]$RunAtomicGate,
    [Parameter()]
    [string]$RecordPath,
    [Parameter()]
    [string]$Fixture,
    [Parameter()]
    [string]$HoldScript,
    [Parameter()]
    [string]$RepoRoot,
    [Parameter()]
    [string]$CreatedEventName,
    [Parameter()]
    [string]$ResumeEventName
)

if ($RunAsSupervisor) {
    $powerShell = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    $jobRunner = Join-Path $RepoRoot 'scripts\invoke-build-in-job.ps1'
    $fixtureArguments = @('-NoProfile', '-File', $Fixture, '-Mode', 'Sleep', '-RecordPath', $RecordPath, '-HoldScript', $HoldScript)
    if ($RunAtomicGate) {
        & $jobRunner -FilePath $powerShell -ArgumentList $fixtureArguments -WorkingDirectory $RepoRoot `
            -TestCreatedEventName $CreatedEventName -TestResumeEventName $ResumeEventName `
            -TestCreatedProcessIdPath $RecordPath | Out-Null
    } else {
        & $jobRunner -FilePath $powerShell -ArgumentList $fixtureArguments -WorkingDirectory $RepoRoot | Out-Null
    }
    return
}

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$buildScript = Join-Path $repoRoot 'scripts\build-android.ps1'
$jobRunner = Join-Path $repoRoot 'scripts\invoke-build-in-job.ps1'
$propertiesPath = Join-Path $repoRoot 'android\gradle.properties'
$properties = Get-Content -LiteralPath $propertiesPath -Raw
if ($properties -notmatch '(?m)^org\.gradle\.daemon=false\s*$') {
    throw 'Gradle persistent daemon is not disabled in android/gradle.properties.'
}
if ($properties -notmatch '(?m)^kotlin\.compiler\.execution\.strategy=in-process\s*$') {
    throw 'Kotlin compiler is not configured to run in process.'
}

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

function Assert-ProcessStopped([int]$ProcessId, [string]$Message, [int]$WaitMilliseconds = 350) {
    if ($WaitMilliseconds -gt 0) { Start-Sleep -Milliseconds $WaitMilliseconds }
    $process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
    if ($process) { throw $Message }
}

$saved = @{}
foreach ($key in @('JAVA_HOME', 'PATH', 'ORG_GRADLE_PROJECT_requireReleaseSigning', 'ORG_GRADLE_PROJECT_allowDebugSigning', 'SINGBOOK_BUILD_JOB_FIXTURE_MODE', 'SINGBOOK_BUILD_JOB_FIXTURE_EXIT', 'SINGBOOK_FLUTTER_LOG')) {
    $saved[$key] = @{
        Exists = Test-Path -LiteralPath "Env:$key"
        Value = [Environment]::GetEnvironmentVariable($key, 'Process')
    }
}
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ("singbook-build-job-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot | Out-Null
$fixture = Join-Path $PSScriptRoot 'build-job-fixture.ps1'
$holdScript = Join-Path $PSScriptRoot 'hold-process.ps1'
$powerShell = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
$sibling = $null
$supervisor = $null

try {
    # Exercise the build script in this runspace with a fake Flutter command so
    # the finally path and caller environment can be checked exactly.
    $env:JAVA_HOME = 'fixture-jdk'
    $env:ORG_GRADLE_PROJECT_requireReleaseSigning = 'caller-require-value'
    $env:ORG_GRADLE_PROJECT_allowDebugSigning = 'caller-debug-value'
    function global:flutter {
        $global:SingbookFlutterArguments = @($args)
        $global:SingbookFlutterRequireSigning = [Environment]::GetEnvironmentVariable('ORG_GRADLE_PROJECT_requireReleaseSigning', 'Process')
        $global:SingbookFlutterAllowDebugSigning = [Environment]::GetEnvironmentVariable('ORG_GRADLE_PROJECT_allowDebugSigning', 'Process')
        switch ($env:SINGBOOK_BUILD_JOB_FIXTURE_MODE) {
            'failure' { $global:LASTEXITCODE = 17 }
            'interrupt' { throw [OperationCanceledException]::new('fixture interruption') }
            default { $global:LASTEXITCODE = 0 }
        }
    }

    $env:SINGBOOK_BUILD_JOB_FIXTURE_MODE = 'success'
    & $buildScript -AllowMissingDefines -BuildWorker
    Assert-True ($SingbookFlutterArguments -contains 'build' -and $SingbookFlutterArguments -contains 'apk' -and $SingbookFlutterArguments -contains '--release') 'Build arguments were not forwarded to fake Flutter.'
    Assert-True ($SingbookFlutterAllowDebugSigning -eq 'true') 'The release preview did not scope its debug-signing override to Flutter.'
    Assert-True ($env:ORG_GRADLE_PROJECT_requireReleaseSigning -eq 'caller-require-value') 'The caller require-signing value changed after success.'
    Assert-True ($env:ORG_GRADLE_PROJECT_allowDebugSigning -eq 'caller-debug-value') 'The caller debug-signing value changed after success.'

    $env:SINGBOOK_BUILD_JOB_FIXTURE_MODE = 'failure'
    $failed = $false
    try { & $buildScript -AllowMissingDefines -BuildWorker } catch { $failed = $true }
    Assert-True $failed 'A fake Flutter nonzero exit was not surfaced as a build failure.'
    Assert-True ($env:ORG_GRADLE_PROJECT_requireReleaseSigning -eq 'caller-require-value' -and $env:ORG_GRADLE_PROJECT_allowDebugSigning -eq 'caller-debug-value') 'Caller signing values were not restored after failure.'

    $env:SINGBOOK_BUILD_JOB_FIXTURE_MODE = 'interrupt'
    $interrupted = $false
    try { & $buildScript -AllowMissingDefines -BuildWorker } catch { $interrupted = $true }
    Assert-True $interrupted 'A fake cancellation was not propagated.'
    Assert-True ($env:ORG_GRADLE_PROJECT_requireReleaseSigning -eq 'caller-require-value' -and $env:ORG_GRADLE_PROJECT_allowDebugSigning -eq 'caller-debug-value') 'Caller signing values were not restored after interruption.'

    # Variables absent before the call stay absent after a failing build.
    Remove-Item Env:ORG_GRADLE_PROJECT_requireReleaseSigning, Env:ORG_GRADLE_PROJECT_allowDebugSigning -ErrorAction SilentlyContinue
    $env:SINGBOOK_BUILD_JOB_FIXTURE_MODE = 'failure'
    try { & $buildScript -AllowMissingDefines -BuildWorker } catch { }
    Assert-True (-not (Test-Path Env:ORG_GRADLE_PROJECT_requireReleaseSigning) -and -not (Test-Path Env:ORG_GRADLE_PROJECT_allowDebugSigning)) 'Previously absent signing variables were not removed after failure.'
    Remove-Item Function:flutter -ErrorAction SilentlyContinue

    # Run the real wrapper and worker processes against a fake Flutter batch
    # command to validate native argument quoting, inherited output, and exit propagation.
    $fakeFlutter = Join-Path $testRoot 'flutter.cmd'
    @'
@echo off
echo wrapper-output-marker
echo %*>> "%SINGBOOK_FLUTTER_LOG%"
echo allow=%ORG_GRADLE_PROJECT_allowDebugSigning%>> "%SINGBOOK_FLUTTER_LOG%"
exit /b %SINGBOOK_BUILD_JOB_FIXTURE_EXIT%
'@ | Set-Content -LiteralPath $fakeFlutter -Encoding Ascii
    $env:JAVA_HOME = 'fixture-jdk'
    $env:PATH = "$testRoot;$($env:PATH)"
    $env:SINGBOOK_FLUTTER_LOG = Join-Path $testRoot 'flutter-invocations.txt'
    $env:SINGBOOK_BUILD_JOB_FIXTURE_EXIT = '0'
    $wrapperOutput = & $powerShell -NoLogo -NoProfile -NonInteractive -File $buildScript -Debug
    Assert-True ($LASTEXITCODE -eq 0) "The isolated build wrapper returned $LASTEXITCODE on fake Flutter success."
    Assert-True ($wrapperOutput -contains 'wrapper-output-marker') 'The wrapper did not preserve child stdout.'
    $wrapperLog = Get-Content -LiteralPath $env:SINGBOOK_FLUTTER_LOG -Raw
    Assert-True ($wrapperLog -match 'build apk --debug --dart-define=cronetHttpNoPlay=true') 'The wrapper did not preserve Flutter build arguments.'
    $env:SINGBOOK_BUILD_JOB_FIXTURE_EXIT = '17'
    & $powerShell -NoLogo -NoProfile -NonInteractive -File $buildScript -Debug
    Assert-True ($LASTEXITCODE -ne 0) 'A fake Flutter failure did not propagate through the native job wrapper.'

    # Normal success and failure both close the job and reap a grandchild.
    foreach ($mode in @('ExitSuccess', 'ExitFailure')) {
        $record = Join-Path $testRoot "$mode.pids"
        $code = & $jobRunner -FilePath $powerShell -ArgumentList @('-NoProfile', '-File', $fixture, '-Mode', $mode, '-RecordPath', $record, '-HoldScript', $holdScript) -WorkingDirectory $repoRoot
        $expected = if ($mode -eq 'ExitSuccess') { 0 } else { 17 }
        Assert-True ([int]$code -eq $expected) "Job runner returned $code for $mode; expected $expected."
        $ids = Get-Content -LiteralPath $record | ForEach-Object { [int]$_ }
        Assert-ProcessStopped $ids[0] "$mode fixture process was still active when the runner returned." 0
        Assert-ProcessStopped $ids[1] "$mode fixture grandchild was still active when the runner returned." 0
    }

    # A failure while the primary thread is still suspended must terminate the
    # assigned job and finish cleanup without an unbounded process wait.
    $suspendedFailureRecord = Join-Path $testRoot 'suspended-failure.pid'
    $suspendedFailureTimer = [Diagnostics.Stopwatch]::StartNew()
    $suspendedFailureObserved = $false
    try {
        & $jobRunner -FilePath $powerShell -ArgumentList @('-NoProfile', '-File', $fixture, '-Mode', 'Sleep', '-RecordPath', (Join-Path $testRoot 'unused-pids'), '-HoldScript', $holdScript) -WorkingDirectory $repoRoot -TestCreatedProcessIdPath $suspendedFailureRecord -TestFailBeforeResume
    } catch {
        $suspendedFailureObserved = $true
    }
    $suspendedFailureTimer.Stop()
    Assert-True $suspendedFailureObserved 'Injected suspended-worker failure was not surfaced.'
    Assert-True ($suspendedFailureTimer.Elapsed.TotalSeconds -lt 5) 'Suspended-worker failure cleanup exceeded its bound.'
    Assert-ProcessStopped ([int](Get-Content -LiteralPath $suspendedFailureRecord -Raw)) 'Suspended worker survived failure cleanup.' 0

    # Kill a supervisor without running its finally block; closing its native
    # job handle must still reap both owned processes and leave a sibling alone.
    $sibling = Start-Process -FilePath $powerShell -ArgumentList @('-NoProfile', '-File', $holdScript) -PassThru
    $record = Join-Path $testRoot 'hard-kill.pids'
    $supervisorArguments = @('-NoProfile', '-File', $PSCommandPath, '-RunAsSupervisor', '-RecordPath', $record, '-Fixture', $fixture, '-HoldScript', $holdScript, '-RepoRoot', $repoRoot)
    $supervisor = Start-Process -FilePath $powerShell -ArgumentList $supervisorArguments -PassThru -WindowStyle Hidden
    $deadline = [DateTime]::UtcNow.AddSeconds(15)
    while (-not (Test-Path -LiteralPath $record) -and [DateTime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 100 }
    Assert-True (Test-Path -LiteralPath $record) 'Hard-kill supervisor did not start the worker fixture.'
    $ownedIds = Get-Content -LiteralPath $record | ForEach-Object { [int]$_ }
    Stop-Process -Id $supervisor.Id -Force
    $supervisor = $null
    Assert-ProcessStopped $ownedIds[0] 'Worker survived hard termination of its job owner.'
    Assert-ProcessStopped $ownedIds[1] 'Grandchild survived hard termination of its job owner.'
    Assert-True ($null -ne (Get-Process -Id $sibling.Id -ErrorAction SilentlyContinue)) 'The unrelated sibling process was terminated.'

    # Hold the worker after CreateProcess returns, while its primary thread is
    # still suspended. Killing the owner here verifies atomic job admission.
    $gateId = [Guid]::NewGuid().ToString('N')
    $createdEventName = "Local\SingbookBuildCreated-$gateId"
    $resumeEventName = "Local\SingbookBuildResume-$gateId"
    $createdSignal = [Threading.EventWaitHandle]::new($false, [Threading.EventResetMode]::ManualReset, $createdEventName)
    $resumeSignal = [Threading.EventWaitHandle]::new($false, [Threading.EventResetMode]::ManualReset, $resumeEventName)
    $record = Join-Path $testRoot 'atomic-admission.pids'
    $gateArguments = @('-NoProfile', '-File', $PSCommandPath, '-RunAsSupervisor', '-RunAtomicGate', '-RecordPath', $record, '-Fixture', $fixture, '-HoldScript', $holdScript, '-RepoRoot', $repoRoot, '-CreatedEventName', $createdEventName, '-ResumeEventName', $resumeEventName)
    $supervisor = Start-Process -FilePath $powerShell -ArgumentList $gateArguments -PassThru -WindowStyle Hidden
    try {
        Assert-True ($createdSignal.WaitOne(15000)) 'Atomic-admission owner did not report successful process creation.'
        Assert-True (Test-Path -LiteralPath $record) 'Atomic-admission worker PID was not recorded.'
        $suspendedWorkerId = [int](Get-Content -LiteralPath $record -Raw)
        Stop-Process -Id $supervisor.Id -Force
        $supervisor = $null
        Assert-ProcessStopped $suspendedWorkerId 'Suspended worker survived hard termination of its owner.'
        Assert-True ($null -ne (Get-Process -Id $sibling.Id -ErrorAction SilentlyContinue)) 'Atomic-admission cleanup terminated the unrelated sibling.'
    } finally {
        $createdSignal.Dispose()
        $resumeSignal.Dispose()
    }

    Write-Output 'Build daemon lifecycle regression checks passed.'
} finally {
    if ($supervisor -and -not $supervisor.HasExited) { Stop-Process -Id $supervisor.Id -Force -ErrorAction SilentlyContinue }
    if ($sibling -and -not $sibling.HasExited) { Stop-Process -Id $sibling.Id -Force -ErrorAction SilentlyContinue }
    Remove-Item Function:flutter -ErrorAction SilentlyContinue
    foreach ($key in $saved.Keys) {
        if ($saved[$key].Exists) {
            [Environment]::SetEnvironmentVariable($key, $saved[$key].Value, 'Process')
        } else {
            Remove-Item -LiteralPath "Env:$key" -ErrorAction SilentlyContinue
        }
    }
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}
