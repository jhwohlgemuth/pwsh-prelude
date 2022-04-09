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
        "==> [ERROR] Failed to load ${Name} type accelerators" | Write-Warning
    }
}
$Accelerators = [PowerShell].Assembly.GetType('System.Management.Automation.TypeAccelerators')
if (-not ('Complex' -as [Type])) {
    $Accelerators::Add('Complex', 'System.Numerics.Complex')
}
$Name = 'Matrix'
if (-not ("Prelude.${Name}" -as [Type])) {
    Add-TypeData -Name $Name
    $Accelerators::Add($Name, "Prelude.${Name}")
}
$Name = 'Node'
if (-not ("Prelude.${Name}" -as [Type])) {
    Add-TypeData -Name $Name
    $Accelerators::Add($Name, "Prelude.${Name}")
}
$Name = 'Edge'
if (-not ("Prelude.${Name}" -as [Type])) {
    Add-TypeData -Name $Name
    $Accelerators::Add($Name, "Prelude.${Name}")
}
$Name = 'DirectedEdge'
if (-not ("Prelude.${Name}" -as [Type])) {
    Add-TypeData -Name $Name
    $Accelerators::Add($Name, "Prelude.${Name}")
}
$Name = 'Graph'
if (-not ("Prelude.${Name}" -as [Type])) {
    Add-TypeData -Name $Name
    $Accelerators::Add($Name, "Prelude.${Name}")
}
$Name = 'Coordinate'
if (-not ("Prelude.Geodetic.${Name}" -as [Type])) {
    Add-TypeData -Name $Name
    $Accelerators::Add($Name, "Prelude.Geodetic.${Name}")
}
$Name = 'Datum'
if (-not ("Prelude.Geodetic.${Name}" -as [Type])) {
    Add-TypeData -Name $Name
    $Accelerators::Add($Name, "Prelude.Geodetic.${Name}")
}
<#
Import source files
#>
$SourceFiles = Join-Path $PSScriptRoot 'src'
Get-ChildItem -Path $SourceFiles -Recurse -Include *.ps1 | Sort-Object | ForEach-Object { . $_.FullName }
<#
Import Prelude "Plus" files
#>
$PlusFiles = Join-Path $PSScriptRoot 'Plus'
Get-ChildItem -Path $PlusFiles -Recurse -Include *.ps1 | Sort-Object | ForEach-Object { . $_.FullName }