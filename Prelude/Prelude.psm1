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
if (-not ('Prelude.Matrix' -as [Type])) {
    Add-Type -Path (Join-Path $PSScriptRoot 'bin/Matrix.dll')
    $Accelerators = [PowerShell].Assembly.GetType('System.Management.Automation.TypeAccelerators')
    $Accelerators::Add('Matrix', 'Prelude.Matrix')
}
if (-not ('Prelude.Geodetic' -as [Type])) {
    Add-Type -Path (Join-Path $PSScriptRoot 'bin/Geodetic.dll')
    $Accelerators = [PowerShell].Assembly.GetType('System.Management.Automation.TypeAccelerators')
    $Accelerators::Add('Coordinate', 'Prelude.Geodetic.Coordinate')
    $Accelerators::Add('Datum', 'Prelude.Geodetic.Datum')
}
if (-not ('Prelude.Node' -as [Type])) {
    Add-Type -Path (Join-Path $PSScriptRoot 'bin/Node.dll')
    $Accelerators = [PowerShell].Assembly.GetType('System.Management.Automation.TypeAccelerators')
    $Accelerators::Add('Node', 'Prelude.Node')
}
if (-not ('Prelude.Edge' -as [Type])) {
    Add-Type -Path (Join-Path $PSScriptRoot 'bin/Edge.dll')
    $Accelerators = [PowerShell].Assembly.GetType('System.Management.Automation.TypeAccelerators')
    $Accelerators::Add('Edge', 'Prelude.Edge')
}
if (-not ('Prelude.Graph' -as [Type])) {
    Add-Type -Path (Join-Path $PSScriptRoot 'bin/Graph.dll')
    $Accelerators = [PowerShell].Assembly.GetType('System.Management.Automation.TypeAccelerators')
    $Accelerators::Add('Graph', 'Prelude.Graph')
}
<#
Import source files
#>
$SourceFiles = Join-Path $PSScriptRoot 'src'
Get-ChildItem -Path $SourceFiles -Recurse -Include *.ps1 | Sort-Object | ForEach-Object { . $_.FullName }