#
# Classes
#
$ClassFiles = Join-Path $PSScriptRoot 'classes'
Get-ChildItem -Path $ClassFiles -Recurse -Include *.ps1 | Sort-Object | ForEach-Object { . $_.FullName }
#
# Functions
#
$SourceFiles = Join-Path $PSScriptRoot 'src'
Get-ChildItem -Path $SourceFiles -Recurse -Include *.ps1 | Sort-Object | ForEach-Object { . $_.FullName }
#
# Aliases
#
if (Test-Installed Get-ChildItemColor) {
  Set-Alias -Scope Global -Option AllScope -Name la -Value Get-ChildItemColor
  Set-Alias -Scope Global -Option AllScope -Name ls -Value Get-ChildItemColorFormatWide
}
if (Get-Command -Name git) {
  Set-Alias -Scope Global -Option AllScope -Name g -Value Invoke-GitCommand
  Set-Alias -Scope Global -Option AllScope -Name gcam -Value Invoke-GitCommit
  Set-Alias -Scope Global -Option AllScope -Name gd -Value Invoke-GitDiff
  Set-Alias -Scope Global -Option AllScope -Name glo -Value Invoke-GitLog
  Set-Alias -Scope Global -Option AllScope -Name gpom -Value Invoke-GitPushMaster
  Set-Alias -Scope Global -Option AllScope -Name grbi -Value Invoke-GitRebase
  Set-Alias -Scope Global -Option AllScope -Name gsb -Value Invoke-GitStatus
}