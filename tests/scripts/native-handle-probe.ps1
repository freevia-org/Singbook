param([switch]$InitializeOnly, [long]$HandleValue, [string]$ExpectedFile, [string]$Report, [string]$ProbeArgument)
$ErrorActionPreference = 'Stop'
if (-not ('SingbookHandleProbe' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class SingbookHandleProbe {
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool SetHandleInformation(IntPtr handle, uint mask, uint flags);
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    private static extern uint GetFinalPathNameByHandle(IntPtr handle, StringBuilder path, uint length, uint flags);
    public static string PathFor(IntPtr handle) {
        var path = new StringBuilder(32768);
        uint result = GetFinalPathNameByHandle(handle, path, (uint)path.Capacity, 0);
        return result == 0 || result >= path.Capacity ? null : path.ToString();
    }
}
'@
}
if ($InitializeOnly) { return }
$observedPath = [SingbookHandleProbe]::PathFor([IntPtr]::new($HandleValue))
$matches = $null -ne $observedPath -and $observedPath.EndsWith([IO.Path]::GetFileName($ExpectedFile), [StringComparison]::OrdinalIgnoreCase)
[IO.File]::WriteAllText($Report, (@{
    unrelatedHandleInherited = $matches
    workingDirectory = [Environment]::CurrentDirectory
    powerShellLocation = (Get-Location).ProviderPath
    argument = $ProbeArgument
} | ConvertTo-Json -Compress))
[Console]::Out.WriteLine('HANDLE_PROBE_STDOUT')
[Console]::Error.WriteLine('HANDLE_PROBE_STDERR')
