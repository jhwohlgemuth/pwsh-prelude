[Diagnostics.CodeAnalysis.SuppressMessageAttribute('RequireDirective', '')]
Param()
$Name = 'pwsh-prelude'
if (Get-Module -Name $Name) {
  Remove-Module -Name $Name
}
Import-Module "${PSScriptRoot}\..\${Name}.psm1"