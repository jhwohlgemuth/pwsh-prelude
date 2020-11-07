if (Get-Module -Name $Env:ProjectName) {
  Remove-Module -Name $Env:ProjectName
}
$Path = Join-Path $Env:ProjectPath "${Env:ProjectName}.psm1"
Import-Module $Path -Force
