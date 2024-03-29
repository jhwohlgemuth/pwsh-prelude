[Diagnostics.CodeAnalysis.SuppressMessageAttribute('AdvancedFunctionHelpContent', '')]
[CmdletBinding()]
Param(
    [ValidateSet('windows', 'linux')]
    [String] $Platform = 'windows'
)
if ($Platform -eq 'windows') {
    dotnet tool restore
}
Install-Module -Force -Scope CurrentUser -Name PSScriptAnalyzer
Install-Module -Force -Scope CurrentUser -Name BuildHelpers
Install-Module -Force -Scope CurrentUser -Name Pester -RequiredVersion 5.3.1