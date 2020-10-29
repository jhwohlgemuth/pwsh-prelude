[CmdletBinding()]
Param(
  [Parameter(Position=0)]
  [String] $Name = 'test'
)

"[+] Configuring $Name tests" | Write-Color -Cyan

$ModuleName = 'pwsh-prelude'
if (Get-Module -Name $ModuleName) {
    Remove-Module -Name $ModuleName
}
$Path = Join-Path $PSScriptRoot "..\${ModuleName}.psm1"
Import-Module $Path -Force
