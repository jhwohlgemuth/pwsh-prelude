<#
██████╗░██████╗░███████╗██╗░░░░░██╗░░░██╗██████╗░███████╗
██╔══██╗██╔══██╗██╔════╝██║░░░░░██║░░░██║██╔══██╗██╔════╝
██████╔╝██████╔╝█████╗░░██║░░░░░██║░░░██║██║░░██║█████╗░░
██╔═══╝░██╔══██╗██╔══╝░░██║░░░░░██║░░░██║██║░░██║██╔══╝░░
██║░░░░░██║░░██║███████╗███████╗╚██████╔╝██████╔╝███████╗
╚═╝░░░░░╚═╝░░╚═╝╚══════╝╚══════╝░╚═════╝░╚═════╝░╚══════╝
#>
function Add-TypeData {
    Param(
        [Parameter(Mandatory = $True, Position = 0)]
        [String] $Name
    )
    $Path = Join-Path $PSScriptRoot "bin/${Name}.dll"
    if (Test-Path $Path) {
        Add-Type -Path $Path
    } else {
        "==> [ERROR] Failed to load ${Name} type accelerators" | Write-Warning
    }
}
<#
Import link libraries and create type accelarators
#>
$Accelerators = [PowerShell].Assembly.GetType('System.Management.Automation.TypeAccelerators')
if (-not ('Complex' -as [Type])) {
    $Accelerators::Add('Complex', 'System.Numerics.Complex')
}
'Matrix', 'Node', 'Edge', 'DirectedEdge', 'Graph' | ForEach-Object {
    if (-not ("Prelude.${_}" -as [Type])) {
        Add-TypeData $_
        $Accelerators::Add($_, "Prelude.${_}")
    }
}
'Datum', 'Coordinate' | ForEach-Object {
    if (-not ("Prelude.Geodetic.${_}" -as [Type])) {
        Add-TypeData $_
        $Accelerators::Add($_, "Prelude.Geodetic.${_}")
    }
}
<#
Import source files
#>
'src', 'Plus' | ForEach-Object {
    $SourceFiles = Join-Path $PSScriptRoot $_
    Get-ChildItem -Path $SourceFiles -Recurse -Include *.ps1 |
        Sort-Object |
        ForEach-Object { . $_.FullName }
}