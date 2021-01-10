[Diagnostics.CodeAnalysis.SuppressMessageAttribute('AdvancedFunctionHelpContent', '')]
[CmdletBinding()]
Param()
'PSScriptAnalyzer', 'BuildHelpers', 'Pester' | ForEach-Object {
  Install-Module -Name $_ -Scope CurrentUser -Force
}