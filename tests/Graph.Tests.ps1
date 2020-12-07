& (Join-Path $PSScriptRoot '_setup.ps1') 'graph'

Describe 'Graph class static methods' {
  It 'can create a new graph object' {
    $E = [EdgeTest]::New()
    $E.Id | Should -Be 43
    $E.Weight | Should -Be 1
    $G = [GraphTest]::New()
    $G.Id | Should -Be 42
  }
}