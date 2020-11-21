function Import-Excel {
  <#
  .SYNOPSIS
  Import the rows of an Excel worksheet as a 2-dimensional array
  .DESCRIPTION

  .PARAMETER FirstRowHeaders
  Treat first row as headers. Exclude first row cells from Cells and Rows in output.
  #>
  [CmdletBinding()]
  [OutputType([PSObject])]
  Param (
    [Parameter(Mandatory=$true)]
    [String] $Path,
    [String] $WorksheetName,
    [Array] $ColumnHeaders,
    [Switch] $FirstRowHeaders,
    [String] $EmptyValue = 'EMPTY',
    [Switch] $DisplayProgress
  )
  $FileName = Resolve-Path $Path
  $Excel = New-Object -ComObject 'Excel.Application'
  $Excel.Visible = $false
  $Workbook = $Excel.workbooks.open($FileName)
  $Worksheet = if ($WorksheetName) { $Workbook.Worksheets.Item($WorksheetName) } else { $Workbook.Worksheets(1) }
  $RowCount = $Worksheet.UsedRange.Rows.Count
  $ColumnCount = $Worksheet.UsedRange.Columns.Count
  $StartIndex = if ($FirstRowHeaders) { 2 } else { 1 }
  $Cells = $StartIndex..$RowCount | ForEach-Object {
    $RowIndex = $_
    1..$ColumnCount | ForEach-Object {
      # Write-Progress -Activity 'Importing Excel data'
      $Value = $Worksheet.Cells.Item($RowIndex, $_).Value2 
      if ($null -eq $_) { $EmptyValue } else { $Value }
    }
  }
  $Headers = if ($FirstRowHeaders) {
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
    # Rows = $Cells | Invoke-Chunk -Size $ColumnCount
  }
}