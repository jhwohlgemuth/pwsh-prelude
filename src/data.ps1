function Format-MoneyValue {
  <#
  .SYNOPSIS
  Helper function to create human-readable money (USD) values as strings.
  .EXAMPLE
  42 | ConvertTo-MoneyString
  # Returns "$42.00"
  .EXAMPLE
  55000123.50 | ConvertTo-MoneyString -Symbol ¥
  # Returns '¥55,000,123.50'
  .EXAMPLE
  700 | ConvertTo-MoneyString -Symbol £ -Postfix
  # Returns '700.00£'
  #>
  [CmdletBinding()]
  [Alias('money')]
  [OutputType([String])]
  Param(
    [Parameter(Mandatory=$True, Position=0, ValueFromPipeline=$True)]
    $Value,
    [String] $Symbol = '$',
    [Switch] $AsNumber,
    [Switch] $Postfix
  )
  Process {
    function Get-Magnitude {
      Param($Value)
      [Math]::Log([Math]::Abs($Value), 10)
    }
    switch -Wildcard ($Value.GetType()) {
      'Int*' {
        $Sign = [Math]::Sign($Value)
        $Output = [Math]::Abs($Value).ToString()
        $OrderOfMagnitude = Get-Magnitude $Value
        if ($OrderOfMagnitude -gt 3) {
          $Position = 3
          $Length = $Output.Length
          1..[Math]::Floor($OrderOfMagnitude / 3) | ForEach-Object {
            $Output = $Output | Invoke-InsertString ',' -At ($Length - $Position)
            $Position += 3
          }
        }
        if ($Postfix) {
          "$(if ($Sign -lt 0) { '-' } else { '' })${Output}.00$Symbol"
        } else {
          "$(if ($Sign -lt 0) { '-' } else { '' })$Symbol${Output}.00"
        }
      }
      'Double' {
        $Sign = [Math]::Sign($Value)
        $Output = [Math]::Abs($Value).ToString('#.##')
        $OrderOfMagnitude = Get-Magnitude $Value
        if (($Output | ForEach-Object { $_ -split '\.' } | Select-Object -Skip 1).Length -eq 1) {
          $Output += '0'
        }
        if (($Value - [Math]::Truncate($Value)) -ne 0) {
          if ($OrderOfMagnitude -gt 3) {
            $Position = 6
            $Length = $Output.Length
            1..[Math]::Floor($OrderOfMagnitude / 3) | ForEach-Object {
              $Output = $Output | Invoke-InsertString ',' -At ($Length - $Position)
              $Position += 3
            }
          }
          if ($Postfix) {
            "$(if ($Sign -lt 0) { '-' } else { '' })$Output$Symbol"
          } else {
            "$(if ($Sign -lt 0) { '-' } else { '' })$Symbol$Output"
          }
        } else {
          ($Value.ToString() -as [Int]) | Format-MoneyValue
        }
      }
      'String' {
        $Value = $Value -replace ',', ''
        $Sign = if (([Regex]'\-\$').Match($Value).Success) { -1 } else { 1 }
        if (([Regex]'\$').Match($Value).Success) {
          $Output = (([Regex]'(?<=(\$))[0-9]*\.?[0-9]{0,2}').Match($Value)).Value
        } else {
          $Output = (([Regex]'[\-]?[0-9]*\.?[0-9]{0,2}').Match($Value)).Value
        }
        $Type = if ($Output.Contains('.')) { [Double] } else { [Int] }
        $Output = $Sign * ($Output -as $Type)
        if (-not $AsNumber) {
          $Output = $Output | Format-MoneyValue
        }
        $Output
      }
      Default { throw 'Format-MoneyValue only accepts strings and numbers' }
    }
  }
}
function Import-Excel {
  <#
  .SYNOPSIS
  Import the rows of an Excel worksheet as a 2-dimensional array
  .PARAMETER ColumnHeaders
  Custom values to be used as header names. Must have same count as Excel data columns.
  .PARAMETER FirstRowHeaders
  Treat first row as headers. Exclude first row cells from Cells and Rows in output.
  Note: When an empty cell is encountered, a placeholder will be used of the form, column<COLUMN NUMBER>
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'EmptyValue')]
  [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', 'Password')]
  [CmdletBinding()]
  [OutputType([System.Collections.Hashtable])]
  Param(
    [Parameter(Mandatory=$True)]
    [String] $Path,
    [String] $WorksheetName,
    [Array] $ColumnHeaders,
    [String] $Password,
    [Switch] $FirstRowHeaders,
    [String] $EmptyValue = 'EMPTY',
    [Switch] $ShowProgress
  )
  $FileName = Resolve-Path $Path
  $Excel = New-Object -ComObject 'Excel.Application'
  $Excel.Visible = $False
  if ($ShowProgress) {
    Write-Progress -Activity 'Importing Excel data' -Status "Loading $FileName"
  }
  $Workbook = if (-not $Password) {
    $Excel.workbooks.open($FileName)
  } else {
    $Excel.workbooks.open($FileName,0,0,$True,$Password)
  }
  $Worksheet = if ($WorksheetName) {
    $Workbook.Worksheets.Item($WorksheetName)
  } else {
    $Workbook.Worksheets(1)
  }
  $RowCount = $Worksheet.UsedRange.Rows.Count
  $ColumnCount = $Worksheet.UsedRange.Columns.Count
  $StartIndex = if ($FirstRowHeaders) { 2 } else { 1 }
  $Cells = $StartIndex..$RowCount | ForEach-Object {
    $RowIndex = $_
    if ($ShowProgress) {
      Write-Progress -Activity 'Importing Excel data' -Status "Processing row ($RowIndex of ${RowCount})" -PercentComplete (($RowIndex / $RowCount) * 100)
    }
    1..$ColumnCount | ForEach-Object {
      $Value = $Worksheet.Cells.Item($RowIndex, $_).Value2
      if ($Null -eq $Value) { $EmptyValue } else { $Value }
    }
  }
  if ($ShowProgress) {
    Write-Progress -Activity 'Importing Excel data' -Completed
  }
  $Headers = if ($FirstRowHeaders) {
    $RowCount--
    1..$ColumnCount | ForEach-Object {
      $Name = $Worksheet.Cells.Item(1, $_).Value2
      if ($Null -eq $Name) { "column${_}" } else { $Name }
    }
  } elseif ($ColumnHeaders.Count -eq $ColumnCount) {
    $ColumnHeaders
  } else {
    @()
  }
  $Workbook.Close()
  $Excel.Quit()
  @{
    Size = @($RowCount, $ColumnCount)
    Headers = $Headers
    Cells = $Cells
    Rows = $Cells | Invoke-Chunk -Size $ColumnCount
  }
}