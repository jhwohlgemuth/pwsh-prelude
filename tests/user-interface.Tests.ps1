[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', 'repeat')]
Param()

& (Join-Path $PSScriptRoot '_setup.ps1') 'user-interface'

Describe 'Write-Repeat' {
  It 'can create string of repeated characters and strings' {
    Write-Repeat 'O' | Should -Be 'O'
    Write-Repeat 'O' -Times 0 | Should -Be ''
    Write-Repeat 'O' -Times 3 | Should -Be 'OOO'
    Write-Repeat '' -Times 42 | Should -Be ''
    'O' | Write-Repeat | Should -Be 'O'
    'O' | Write-Repeat -Times 0 | Should -Be ''
    'O' | Write-Repeat -Times 3 | Should -Be 'OOO'
    '' | Write-Repeat -Times 42 | Should -Be ''
    10 | Write-Repeat -Times 3 | Should -Be '101010'
    0 | Write-Repeat -Times 6 | Should -Be '000000'
    1,2,3 | Write-Repeat -Times 3 | Should -Be '111','222','333'
  }
  It 'provides aliases for ease of use' {
    'na' | repeat -x 3 | Should -Be 'nanana'
  }
}