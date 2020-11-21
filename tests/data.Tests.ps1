& (Join-Path $PSScriptRoot '_setup.ps1') 'data'

$ExcelSupported = try {
  New-Object -ComObject 'Excel.Application'
  $true
} catch {
  $false
}

Describe -Skip:(-not $ExcelSupported) 'Import-Excel' {
  It 'will import first worksheet by default' {
    $Path = Join-Path $PSScriptRoot '\fixtures\example.xlsx'
    $Data = Import-Excel -Path $Path
    $Data.Size | Should -Be 6,4
  }
}