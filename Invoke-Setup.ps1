[Diagnostics.CodeAnalysis.SuppressMessageAttribute('AdvancedFunctionHelpContent', '')]
[CmdletBinding()]
Param()
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser  -Force
Install-Module -Name BuildHelpers -Scope CurrentUser -Force
Install-Module -Name Pester -SkipPublisherCheck -RequiredVersion 5.0.4 -Scope CurrentUser -Force