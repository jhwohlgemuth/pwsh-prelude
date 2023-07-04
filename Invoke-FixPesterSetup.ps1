#Requires -Modules pester
[CmdletBinding()]
Param()

$OneDriveModulePath = Join-Path $Env:OneDrive 'Documents\PowerShell\Modules'
$Env:PSModulePath = "${OneDriveModulePath};$Env:PSModulePath"
Remove-Module -Name pester
Import-Module -Name pester -RequiredVersion 5.5.0