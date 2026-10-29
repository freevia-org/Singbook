param(
    [switch]$Clipboard,
    [switch]$CredentialStore
)
$ErrorActionPreference = 'Stop'
$workspace = Split-Path -Parent $PSScriptRoot
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
if (-not (Test-Path -LiteralPath $vswhere)) { throw 'Visual Studio Build Tools are required.' }
$installation = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $installation) { throw 'Visual Studio C++ tools are required.' }
$developerShell = Join-Path $installation 'Common7/Tools/Launch-VsDevShell.ps1'
& $developerShell -Arch amd64 -HostArch amd64 -SkipAutomaticLocation
$evidence = Join-Path $workspace ('artifacts/windows-parity/native-' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'))
New-Item -ItemType Directory -Path $evidence | Out-Null
$binary = Join-Path $evidence 'native-check.exe'
$source = Join-Path $workspace 'test/native/windows_clipboard_test.cpp'
$object = Join-Path $evidence 'native-check.obj'
$compileArguments = @('/nologo', '/std:c++17', '/EHsc', '/W4', '/WX', '/DNOMINMAX', $source, "/Fo$object", "/Fe$binary", '/link', 'user32.lib', 'advapi32.lib', 'ole32.lib')
('cl ' + ($compileArguments -join ' ')) | Set-Content -LiteralPath (Join-Path $evidence 'command.txt')
& cl @compileArguments *> (Join-Path $evidence 'compile.log')
if ($LASTEXITCODE -ne 0) { throw "Native compilation failed; see $evidence" }
& $binary *> (Join-Path $evidence 'pure.log')
if ($LASTEXITCODE -ne 0) { throw "Native checks failed; see $evidence" }
if ($CredentialStore) {
    & $binary --credentials *> (Join-Path $evidence 'credentials.log')
    if ($LASTEXITCODE -ne 0) { throw "Isolated credential checks failed; see $evidence" }
}
if ($Clipboard) {
    & $binary --clipboard *> (Join-Path $evidence 'clipboard.log')
    if ($LASTEXITCODE -ne 0) { throw "Native clipboard checks failed; see $evidence" }
}
Write-Output "Native checks passed. Evidence: $evidence"
