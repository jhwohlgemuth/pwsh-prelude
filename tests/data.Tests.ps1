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
    $Data | Get-Property 'Rows.0' | Should -Be 'a','EMPTY','foo','EMPTY'
    $Data | Get-Property 'Rows.1' | Should -Be 'b',1,'bar','red'
  }
  It 'will import first worksheet by default and display progress' {
    $Path = Join-Path $PSScriptRoot '\fixtures\example.xlsx'
    $Data = Import-Excel -Path $Path -ShowProgress
    $Data.Size | Should -Be 6,4
    $Data | Get-Property 'Rows.0' | Should -Be 'a','EMPTY','foo','EMPTY'
    $Data | Get-Property 'Rows.1' | Should -Be 'b',1,'bar','red'
  }
  It 'can import worksheet by name' {
    $Path = Join-Path $PSScriptRoot '\fixtures\example.xlsx'
    $Data = Import-Excel -Path $Path -WorksheetName 'with-headers'
    $Data.Size | Should -Be 13,2
    $Data | Get-Property 'Rows.0' | Should -Be 'Disciples','Gospels'
    $Data | Get-Property 'Rows.1' | Should -Be 'Peter','Matthew'
  }
  It 'can treat the cells in the first row as headers' {
    $Path = Join-Path $PSScriptRoot '\fixtures\example.xlsx'
    $Data = Import-Excel -Path $Path -WorksheetName 'with-headers' -FirstRowHeaders
    $Data.Size | Should -Be 12,2
    $Data | Get-Property 'Headers' | Should -Be 'Disciples','Gospels'
    $Data | Get-Property 'Rows.0' | Should -Be 'Peter','Matthew'
    $Data | Get-Property 'Rows.1' | Should -Be 'Andrew','Mark'
  }
  It 'can use custom header names' {
    $Path = Join-Path $PSScriptRoot '\fixtures\example.xlsx'
    $Data = Import-Excel -Path $Path -ColumnHeaders 'A','B','C','D'
    $Data.Size | Should -Be 6,4
    $Data.Headers | Should -Be 'A','B','C','D'
    $Data | Get-Property 'Rows.0' | Should -Be 'a','EMPTY','foo','EMPTY'
  }
  It 'will only use the correct number of custom header names' {
    $Path = Join-Path $PSScriptRoot '\fixtures\example.xlsx'
    $Data = Import-Excel -Path $Path -ColumnHeaders 'A','B'
    $Data.Headers | Should -BeNullOrEmpty -Because 'there should be 4 headers'
    $Data | Get-Property 'Rows.0' | Should -Be 'a','EMPTY','foo','EMPTY'
  }
  It 'will provide placeholder headers when missing' {
    $Path = Join-Path $PSScriptRoot '\fixtures\example.xlsx'
    $Data = Import-Excel -Path $Path -FirstRowHeaders
    $Data.Headers | Should -Be 'a','column2','foo','column4' -Because 'there are empty cells in the first row'
    $Data | Get-Property 'Rows.0' | Should -Be 'b',1,'bar','red'
  }
  It 'supports custom "empty values"' {
    $Path = Join-Path $PSScriptRoot '\fixtures\example.xlsx'
    $Data = Import-Excel -Path $Path -EmptyValue 'BLANK'
    $Data | Get-Property 'Rows.0' | Should -Be 'a','BLANK','foo','BLANK'
  }
}