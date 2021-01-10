[Diagnostics.CodeAnalysis.SuppressMessageAttribute('AdvancedFunctionHelpContent', '')]
[CmdletBinding()]
Param()
dotnet tool install -g dotnet-format
Install-Module -Force -Scope CurrentUser -Name PSScriptAnalyzer
Install-Module -Force -Scope CurrentUser -Name BuildHelpers
Install-Module -Force -Scope CurrentUser -Name Pester -SkipPublisherCheck -RequiredVersion 5.0.4