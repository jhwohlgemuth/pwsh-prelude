function Invoke-PropertyTransform {
    <#
    .SYNOPSIS
    Helper function that can be used to rename object keys and transform values.
    .PARAMETER Transform
    The Transform function that can be a simple identity function or complex reducer (as used by Redux.js and React.js)
    The Transform function can use pipeline values or the automatice variables, $Name and $Value which represent the associated old key name and original value, respectively.

    A reducer that would transform the values with the keys, 'foo' or 'bar', migh look something like this:

    $Reducer = {
      Param($Name, $Value)
      switch ($Name) {
        'foo' { ... }
        'bar' { ... }
        Default { $Value }
      }
    }
    .PARAMETER Lookup
    Dictionary lookup object that will map old key names to new key names.

    Example:

    $Lookup = @{
      foobar = 'foo_bar'
      Name = 'first_name'
    }
    .EXAMPLE
    $Data = @{}
    $Data | Add-member -NotePropertyName 'fighter_power_level' -NotePropertyValue 90
    $Lookup = @{
      level = 'fighter_power_level'
    }
    $Reducer = {
      Param($Value)
      ($Value * 100) + 1
    }
    $Data | Invoke-PropertyTransform -Lookup $Lookup -Transform $Reducer
    .EXAMPLE
    $Data = @{
      fighter_power_level = 90
    }
    $Lookup = @{
      level = 'fighter_power_level'
    }
    $Reducer = {
      Param($Value)
      ($Value * 100) + 1
    }
    $Data | transform $Lookup $Reducer
    .EXAMPLE
    $Lookup = @{
      PIID = 'award_id_piid'
      Name = 'recipient_name'
      Program = 'major_program'
      Cost = 'total_dollars_obligated'
      Url = 'usaspending_permalink'
    }
    $Reducer = {
      Param($Name, $Value)
      switch ($Name) {
        'total_dollars_obligated' { ConvertTo-MoneyString $Value }
        Default { $Value }
      }
    }
    (Import-Csv -Path '.\contracts.csv') | Invoke-PropertyTransform -Lookup $Lookup -Transform $Reducer | Format-Table
    #>
    [CmdletBinding()]
    [Alias('transform')]
    Param(
      [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
      $InputObject,
      [Parameter(Mandatory=$true, Position=0)]
      [PSObject] $Lookup,
      [Parameter(Position=1)]
      [ScriptBlock] $Transform = { Param($Value) $Value }
    )
    Begin {
      function New-PropertyExpression {
        [CmdletBinding()]
        Param(
          [Parameter(Mandatory=$true)]
          [String] $Name,
          [Parameter(Mandatory=$true)]
          [ScriptBlock] $Transform
        )
        {
          & $Transform -Name $Name -Value ($_.$Name)
        }.GetNewClosure()
      }
      $Property = $Lookup.GetEnumerator() | ForEach-Object {
        $OldName = $_.Value
        $NewName = $_.Name
        @{
          Name = $NewName
          Expression = (New-PropertyExpression -Name $OldName -Transform $Transform)
        }
      }
    }
    Process {
      $InputObject | Select-Object -Property $Property
    }
  }