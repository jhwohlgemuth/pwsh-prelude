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
  [CmdletBinding()]
  [OutputType([System.Collections.Hashtable])]
  Param (
    [Parameter(Mandatory=$true)]
    [String] $Path,
    [String] $WorksheetName,
    [Array] $ColumnHeaders,
    [Switch] $FirstRowHeaders,
    [String] $EmptyValue = 'EMPTY',
    [Switch] $ShowProgress
  )
  $FileName = Resolve-Path $Path
  $Excel = New-Object -ComObject 'Excel.Application'
  $Excel.Visible = $false
  if ($ShowProgress) {
    Write-Progress -Activity 'Importing Excel data' -Status "Loading $FileName"
  }
  $Workbook = $Excel.workbooks.open($FileName)
  $Worksheet = if ($WorksheetName) { $Workbook.Worksheets.Item($WorksheetName) } else { $Workbook.Worksheets(1) }
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
      if ($null -eq $Value) { $EmptyValue } else { $Value }
    }
  }
  if ($ShowProgress) {
    Write-Progress -Activity 'Importing Excel data' -Completed
  }
  $Headers = if ($FirstRowHeaders) {
    $RowCount--
    1..$ColumnCount | ForEach-Object {
      $Name = $Worksheet.Cells.Item(1, $_).Value2
      if ($null -eq $Name) { "column${_}" } else { $Name }
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