#Requires -RunAsAdministrator

function Uninstall-Pester ([switch]$All) {
    if ([IntPtr]::Size * 8 -ne 64) { throw 'Run this script from 64bit PowerShell.' }

    #Requires -RunAsAdministrator
    $PesterPath = foreach ($ProgramFiles in ($Env:ProgramFiles, ${Env:ProgramFiles(x86)})) {
        $Path = "$ProgramFiles\WindowsPowerShell\Modules\Pester"
        if ($Null -ne $ProgramFiles -and (Test-Path $Path)) {
            if ($All) { 
                Get-Item $Path
            } 
            else {
                Get-ChildItem "$Path\3.*"
            }
        }
    }


    if (-not $PesterPath) {
        "There are no Pester$(if (-not $All) {' 3'}) installations in Program Files and Program Files (x86) doing nothing."
        return
    }

    foreach ($PesterPath in $PesterPath) {
        takeown /F $PesterPath /A /R
        icacls $PesterPath /reset
        # grant permissions to Administrators group, but use SID to do
        # it because it is localized on non-us installations of Windows
        icacls $PesterPath /grant '*S-1-5-32-544:F' /inheritance:d /T
        Remove-Item -Path $PesterPath -Recurse -Force -Confirm:$False
    }
}

Uninstall-Pester