[Diagnostics.CodeAnalysis.SuppressMessageAttribute('AdvancedFunctionHelpContent', '')]
[CmdletBinding()]
Param(
    [ValidateSet('windows', 'linux')]
    [String] $Platform = 'windows'
)
if ($Platform -eq 'windows') {
    dotnet tool install --global dotnet-format
    dotnet tool install --global dotnet-reportgenerator-globaltool
}
Install-Module -Force -Scope CurrentUser -Name PSScriptAnalyzer
Install-Module -Force -Scope CurrentUser -Name BuildHelpers
Install-Module -Force -Scope CurrentUser -Name Pester -SkipPublisherCheck -RequiredVersion 5.0.4