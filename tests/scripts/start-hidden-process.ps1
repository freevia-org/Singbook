param([Parameter(Mandatory = $true)][string]$FilePath, [string[]]$ArgumentList = @())

# SW_HIDE can still allocate a console through Windows Terminal. Prevent
# console creation instead, so force-killed fixtures leave no terminal tabs.
$startInfo = [Diagnostics.ProcessStartInfo]::new()
$startInfo.FileName = $FilePath
$startInfo.UseShellExecute = $false
$startInfo.CreateNoWindow = $true
if ($null -ne $startInfo.PSObject.Properties['ArgumentList']) {
    foreach ($argument in $ArgumentList) { $startInfo.ArgumentList.Add($argument) }
} else {
    # The fixtures pass file paths and simple switches, never embedded quotes.
    foreach ($argument in $ArgumentList) {
        if ($argument.Contains('"') -or $argument.EndsWith('\')) {
            throw 'Unsupported fixture argument.'
        }
    }
    $startInfo.Arguments = ($ArgumentList | ForEach-Object { '"' + $_ + '"' }) -join ' '
}
[Diagnostics.Process]::Start($startInfo)
