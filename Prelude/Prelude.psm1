<#
██████╗░░█████╗░░██╗░░░░░░░██╗███████╗██████╗░░██████╗██╗░░██╗███████╗██╗░░░░░██╗░░░░░
██╔══██╗██╔══██╗░██║░░██╗░░██║██╔════╝██╔══██╗██╔════╝██║░░██║██╔════╝██║░░░░░██║░░░░░
██████╔╝██║░░██║░╚██╗████╗██╔╝█████╗░░██████╔╝╚█████╗░███████║█████╗░░██║░░░░░██║░░░░░
██╔═══╝░██║░░██║░░████╔═████║░██╔══╝░░██╔══██╗░╚═══██╗██╔══██║██╔══╝░░██║░░░░░██║░░░░░
██║░░░░░╚█████╔╝░░╚██╔╝░╚██╔╝░███████╗██║░░██║██████╔╝██║░░██║███████╗███████╗███████╗
╚═╝░░░░░░╚════╝░░░░╚═╝░░░╚═╝░░╚══════╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝╚══════╝╚══════╝╚══════╝

██████╗░██████╗░███████╗██╗░░░░░██╗░░░██╗██████╗░███████╗
██╔══██╗██╔══██╗██╔════╝██║░░░░░██║░░░██║██╔══██╗██╔════╝
██████╔╝██████╔╝█████╗░░██║░░░░░██║░░░██║██║░░██║█████╗░░
██╔═══╝░██╔══██╗██╔══╝░░██║░░░░░██║░░░██║██║░░██║██╔══╝░░
██║░░░░░██║░░██║███████╗███████╗╚██████╔╝██████╔╝███████╗
╚═╝░░░░░╚═╝░░╚═╝╚══════╝╚══════╝░╚═════╝░╚═════╝░╚══════╝
#>
<#
Import link libraries and create type accelarators
#>
function Add-TypeData {
    Param(
        [String] $Name
    )
    $Path = Join-Path $PSScriptRoot "bin/${Name}.dll"
    if (Test-Path $Path) {
        Add-Type -Path $Path
    } else {
        "==> Failed to load ${Name} type accelerators" | Write-Warning
    }
}
$Accelerators = [PowerShell].Assembly.GetType('System.Management.Automation.TypeAccelerators')
if (-not 'Complex' -as [Type]) {
    $Accelerators::Add('Complex', 'System.Numerics.Complex')
}
if (-not ('Prelude.Matrix' -as [Type])) {
    Add-TypeData -Name 'Matrix'
    $Accelerators::Add('Matrix', 'Prelude.Matrix')
}
if (-not ('Prelude.Geodetic' -as [Type])) {
    Add-TypeData -Name 'Geodetic'
    $Accelerators::Add('Coordinate', 'Prelude.Geodetic.Coordinate')
    $Accelerators::Add('Datum', 'Prelude.Geodetic.Datum')
}
if (-not ('Prelude.Node' -as [Type])) {
    Add-TypeData -Name 'Node'
    $Accelerators::Add('Node', 'Prelude.Node')
}
if (-not ('Prelude.Edge' -as [Type])) {
    Add-TypeData -Name 'Edge'
    $Accelerators::Add('Edge', 'Prelude.Edge')
}
if (-not ('Prelude.DirectedEdge' -as [Type])) {
    Add-TypeData -Name 'DirectedEdge'
    $Accelerators::Add('DirectedEdge', 'Prelude.DirectedEdge')
}
if (-not ('Prelude.Graph' -as [Type])) {
    Add-TypeData -Name 'Graph'
    $Accelerators::Add('Graph', 'Prelude.Graph')
}
<#
Import source files
#>
$SourceFiles = Join-Path $PSScriptRoot 'src'
Get-ChildItem -Path $SourceFiles -Recurse -Include *.ps1 | Sort-Object | ForEach-Object { . $_.FullName }