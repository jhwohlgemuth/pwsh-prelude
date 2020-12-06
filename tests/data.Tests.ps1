& (Join-Path $PSScriptRoot '_setup.ps1') 'data'

$ExcelSupported = try {
  New-Object -ComObject 'Excel.Application'
  $True
} catch {
  $False
}

Describe 'Format-MoneyValue' {
  It 'can convert numbers' {
    0 | Format-MoneyValue | Should -Be '$0.00'
    0.0 | Format-MoneyValue | Should -Be '$0.00'
    1 | Format-MoneyValue | Should -Be '$1.00'
    42 | Format-MoneyValue | Should -Be '$42.00'
    42.75 | Format-MoneyValue | Should -Be '$42.75'
    42.00 | Format-MoneyValue | Should -Be '$42.00'
    100 | Format-MoneyValue | Should -Be '$100.00'
    123.45 | Format-MoneyValue | Should -Be '$123.45'
    700 | Format-MoneyValue | Should -Be '$700.00'
    1042 | Format-MoneyValue | Should -Be '$1,042.00'
    1255532042 | Format-MoneyValue | Should -Be '$1,255,532,042.00'
    1042.00 | Format-MoneyValue | Should -Be '$1,042.00'
    432565.55 | Format-MoneyValue | Should -Be '$432,565.55'
    55000042.10 | Format-MoneyValue | Should -Be '$55,000,042.10'
    -42 | Format-MoneyValue | Should -Be '-$42.00'
    -42.75 | Format-MoneyValue | Should -Be '-$42.75'
    -42.00 | Format-MoneyValue | Should -Be '-$42.00'
    -1042.00 | Format-MoneyValue | Should -Be '-$1,042.00'
    -55000042.10 | Format-MoneyValue | Should -Be '-$55,000,042.10'
  }
  It 'can convert strings' {
    '0' | Format-MoneyValue | Should -Be '$0.00'
    '-0' | Format-MoneyValue | Should -Be '$0.00'
    '$100.00' | Format-MoneyValue | Should -Be '$100.00'
    '$100' | Format-MoneyValue | Should -Be '$100.00'
    '100' | Format-MoneyValue | Should -Be '$100.00'
    '123.45' | Format-MoneyValue | Should -Be '$123.45'
    '100,000,000' | Format-MoneyValue | Should -Be '$100,000,000.00'
    '100000000.00' | Format-MoneyValue | Should -Be '$100,000,000.00'
    '$3,100,000,000.89' | Format-MoneyValue | Should -Be '$3,100,000,000.89'
    '524123.45' | Format-MoneyValue | Should -Be '$524,123.45'
    '$567,123.45' | Format-MoneyValue | Should -Be '$567,123.45'
    '-$100.00' | Format-MoneyValue | Should -Be '-$100.00'
    '-$100' | Format-MoneyValue | Should -Be '-$100.00'
    '-100' | Format-MoneyValue | Should -Be '-$100.00'
  }
  It 'can process arrays of values' {
    1..5 | Format-MoneyValue | Should -Be '$1.00','$2.00','$3.00','$4.00','$5.00'
    '$1.00','$2.00','$3.00','$4.00','$5.00' | Format-MoneyValue -AsNumber | Should -Be (1..5)
  }
  It 'can retrieve numerical values from string input' {
    '0' | Format-MoneyValue -AsNumber | Should -Be 0
    '-0' | Format-MoneyValue -AsNumber | Should -Be 0
    '$100.00' | Format-MoneyValue -AsNumber | Should -Be 100
    '$100' | Format-MoneyValue -AsNumber | Should -Be 100
    '100' | Format-MoneyValue -AsNumber | Should -Be 100
    '123.45' | Format-MoneyValue -AsNumber | Should -Be 123.45
    '$123.45' | Format-MoneyValue -AsNumber | Should -Be 123.45
    '100,000,000' | Format-MoneyValue -AsNumber | Should -Be 100000000
    '100000000.00' | Format-MoneyValue -AsNumber | Should -Be 100000000
    '$3,100,000,000.89' | Format-MoneyValue -AsNumber | Should -Be 3100000000.89
    '524123.45' | Format-MoneyValue -AsNumber | Should -Be 524123.45
    '$567,123.45' | Format-MoneyValue -AsNumber | Should -Be 567123.45
    '-$100.00' | Format-MoneyValue -AsNumber | Should -Be -100
    '-$100' | Format-MoneyValue -AsNumber | Should -Be -100
    '-100' | Format-MoneyValue -AsNumber | Should -Be -100
  }
  It 'supports custom currency symbols' {
    55000123.50 | Format-MoneyValue -Symbol ¥ | Should -Be '¥55,000,123.50'
    700 | Format-MoneyValue -Symbol £ -Postfix | Should -Be '700.00£'
    123.45 | Format-MoneyValue -Symbol £ -Postfix | Should -Be '123.45£'
  }
  It 'will throw an error if input is not a string or number' {
    { $False | Format-MoneyValue } | Should -Throw 'Format-MoneyValue only accepts strings and numbers'
  }
}
Describe -Skip:(-not $ExcelSupported) 'Import-Excel' {
  It 'will import first worksheet by default' {
    $Path = Join-Path $PSScriptRoot '\fixtures\example.xlsx'
    $Data = Import-Excel -Path $Path
    $Data.Size | Should -Be 6,4
    $Data | Get-Property 'Rows.0' | Should -Be 'a','EMPTY','foo','EMPTY'
    $Data | Get-Property 'Rows.1' | Should -Be 'b',1,'bar','red'
  }
  It 'peek data and import only the first row' {
    $Path = Join-Path $PSScriptRoot '\fixtures\example.xlsx'
    $Data = Import-Excel -Path $Path -Peek -WorksheetName 'with-headers'
    $Data.Size | Should -Be 1,2
    $Data.Cells | Should -Be 'Disciples','Gospels'
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
  It 'can open password-protected Workbooks' {
    $Password = '123456'
    $Path = Join-Path $PSScriptRoot '\fixtures\example_protected.xlsx'
    $Data = Import-Excel -Path $Path -Password $Password
    $Data.Size | Should -Be 6,1
    $Data | Get-Property 'Rows.0' | Should -Be 'secret'
    $Data | Get-Property 'Rows.1' | Should -Be 'restricted'
    $Data = Import-Excel -Path $Path -Password $Password -WorksheetName 'unprotected'
    $Data.Size | Should -Be 5,1
    $Data | Get-Property 'Rows.0' | Should -Be 'public'
    $Data | Get-Property 'Rows.1' | Should -Be 'open'
    { Import-Excel -Path $Path -Password 'wrong' } | Should -Throw -Because 'the password is not correct'
  }
}
Describe 'Import-Raw' {
  It 'can import lines of a file' {
    $Path = Join-Path $PSScriptRoot '\fixtures\example.html'
    $Data = Import-Raw -File $Path
    $Data.Count | Should -Be 37
    $Data[1] | Should -Be '<html lang="en">'
  }
  It 'can peek first line of a file' {
    $Path = Join-Path $PSScriptRoot '\fixtures\example.html'
    Import-Raw -File $Path -Peek | Should -Be '<!DOCTYPE html>'
  }
  It 'can import lines of a file and apply a transform to each line' {
    $Path = Join-Path $PSScriptRoot '\fixtures\example.txt'
    $Transform = {
      Param($Line)
      $Line.ToUpper()
    }
    $Data = Import-Raw $Path $Transform
    $Data[3] | Should -Be 'GUN SWAB BRIGANTINE.'
  }
}