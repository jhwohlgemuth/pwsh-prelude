$ModuleName = 'pwsh-prelude'
if (Get-Module -Name $ModuleName) {
    Remove-Module -Name $ModuleName
}
$Path = Join-Path $PSScriptRoot "..\${ModuleName}.psm1"
Import-Module $Path -Force
