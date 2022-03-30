[Diagnostics.CodeAnalysis.SuppressMessageAttribute('AdvancedFunctionHelpContent', '')]
[CmdletBinding()]
Param(
    [ValidateSet('windows', 'linux')]
    [String] $Platform = 'windows'
)
$Modules = Get-Module -ListAvailable | Select-Object -ExpandProperty Name
if ($Platform -eq 'windows') {
    dotnet tool restore
}
if (-not $Modules -contains 'PSScriptAnalyzer') {
    Install-Module -Force -Scope CurrentUser -Name PSScriptAnalyzer
}
if (-not $Modules -contains 'BuildHelpers') {
    Install-Module -Force -Scope CurrentUser -Name BuildHelpers
}
if (-not $Modules -contains 'Pester') {
    Install-Module -Force -Scope CurrentUser -Name Pester -SkipPublisherCheck -RequiredVersion 5.3.1
}