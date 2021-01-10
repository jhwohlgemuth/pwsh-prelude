[Diagnostics.CodeAnalysis.SuppressMessageAttribute('AdvancedFunctionHelpContent', '')]
[CmdletBinding()]
Param()
function Test-Installed {
  $Name = $Args[0]
  Get-Module -ListAvailable -Name $Name
}
'PSScriptAnalyzer', 'BuildHelpers', 'Pester' | ForEach-Object {
  $Installed = Test-Installed $_
  if (-not $Installed) {
    Install-Module -Name $_ -Scope CurrentUser -Force
  }
}