function ConvertTo-Iso8601 {
  [CmdletBinding()]
  Param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [String] $Value
  )
  $Value | Get-Date -UFormat '+%Y-%m-%dT%H:%M:%S.000Z'
}
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
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    $Value,
    [String] $Symbol = '$',
    [Switch] $AsNumber,
    [Switch] $Postfix
  )
  $Function:GetMagnitude = { [Math]::Log([Math]::Abs($args[0]), 10) }
  switch -Wildcard ($Value.GetType()) {
    'Int*' {
      $Sign = [Math]::Sign($Value)
      $Output = [Math]::Abs($Value).ToString()
      $OrderOfMagnitude = GetMagnitude $Value
      if ($OrderOfMagnitude -gt 3) {
        $Position = 3
        $Length = $Output.Length
        1..[Math]::Floor($OrderOfMagnitude / 3) | ForEach-Object {
          $Output = ',' | Invoke-InsertString -To $Output -At ($Length - $Position)
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
      $OrderOfMagnitude = GetMagnitude $Value
      if (($Output | ForEach-Object { $_ -split '\.' } | Select-Object -Skip 1).Length -eq 1) {
        $Output += '0'
      }
      if (($Value - [Math]::Truncate($Value)) -ne 0) {
        if ($OrderOfMagnitude -gt 3) {
          $Position = 6
          $Length = $Output.Length
          1..[Math]::Floor($OrderOfMagnitude / 3) | ForEach-Object {
            $Output = ',' | Invoke-InsertString -To $Output -At ($Length - $Position)
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
function Import-Html {
  <#
  .SYNOPSIS
  Import and parse an a local HTML file or web page.
  .EXAMPLE
  Import-Html example.com | ForEach-Object { $_.body.innerHTML }
  .EXAMPLE
  Import-Html .\bookmarks.html | ForEach-Object { $_.all.tags('a') } | Selelct-Object -ExpandProperty textContent
  #>
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Alias('Uri')]
    [String] $Path
  )
  if (Test-Path $Path) {
    $Content = Get-Content -Path $Path -Raw
  } else {
    $Content = (Invoke-WebRequest -Uri $Path).Content
  }
  $Html = New-Object -ComObject "HTMLFile"
  $Html.IHTMLDocument2_write($Content)
  $Html
}
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
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope='Function')]
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
function Invoke-Reduce {
  <#
  .SYNOPSIS
  Functional helper function intended to approximate some of the capabilities of Reduce (as used in languages like JavaScript and F#)
  .PARAMETER InitialValue
  Starting value for reduce. The type of InitialValue will change the operation of Invoke-Reduce.
  .PARAMETER FileInfo
  The operation of combining many FileInfo objects into one object is common enough to deserve its own switch (see examples)
  .EXAMPLE
  1,2,3,4,5 | Invoke-Reduce -Callback { Param($a, $b) $a + $b } -InitialValue 0

  Compute sum of array of integers
  .EXAMPLE
  'a','b','c' | reduce { Param($a, $b) $a + $b } ''

  Concatenate array of strings
  .EXAMPLE
  1..100 | reduce -InitialValue 0 -Add
  # 5050

  Invoke-Reduce has switches for common callbacks - Add, Every, and Some
  .EXAMPLE
  Get-ChildItem -File | Invoke-Reduce -FileInfo | Show-BarChart

  Combining directory contents into single object and visualize with Show-BarChart - in a single line!
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope='Function')]
  [CmdletBinding()]
  [Alias('reduce')]
  Param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [Array] $Items,
    [Parameter(Position=0)]
    [ScriptBlock] $Callback = { Param($a) $a },
    [Parameter(Position=1)]
    $InitialValue = @{},
    [Switch] $Identity,
    [Switch] $Add,
    [Switch] $Every,
    [Switch] $Some,
    [Switch] $FileInfo
  )
  Begin {
    $Result = $InitialValue
    $CallbackNames = 'Identity','Add','Every','Some','FileInfo'
    $Index = $CallbackNames | Get-Variable | Select-Object -ExpandProperty Value | Find-FirstIndex
    $CallbackName = if ($Index) { $CallbackNames[$Index] } else { 'Identity' }
    $Callback = switch ($CallbackName) {
      'Add' { { Param($a, $b) $a + $b } }
      'Every' { { Param($a, $b) $a -and $b } }
      'Some' { { Param($a, $b) $a -or $b } }
      'FileInfo' { { Param($Acc, $Item) $Acc[$Item.Name] = $Item.Length } }
      Default { $Callback }
    }
  }
  Process {
    $Items | ForEach-Object {
      if ($InitialValue -is [Int] -or $InitialValue -is [String] -or $InitialValue -is [Bool] -or $InitialValue -is [Array]) {
        $Result = & $Callback $Result $_
      } else {
        & $Callback $Result $_
      }
    }
  }
  End {
    $Result
  }
}
function Invoke-WebRequestWithBasicAuth {
  <#
  .SYNOPSIS
  Invoke-WebRequest wrapper that makes it easier to use basic authentication
  .PARAMETER TwoFactorAuthentication
  Name of API that requires 2FA. Use 'none' when 2FA is not required.
  Possible values:
  - 'Github'
  - 'none' [Default]
  .EXAMPLE
  $Uri = 'https://api.github.com/notifications' 
  $Query = @{ 'per_page' = 100; page = 1}
  $Request = Invoke-WebRequestWithBasicAuth $Username $Token -Uri $Uri -Query $Query
  $Request.Content | ConvertFrom-Json | Format-Table -AutoSize
  #>
  [CmdletBinding()]
  Param(
    [Parameter(Position=0)]
    [String] $Username,
    [Parameter(Position=1)]
    [String] $Token,
    [Uri] $Uri,
    [PSObject] $Query,
    [PSObject] $Data,
    [String] $TwoFactorAuthentication = 'none'
  )
  $Credential = [Convert]::ToBase64String([System.Text.Encoding]::Ascii.GetBytes("${Username}:${Token}"))
  $Headers = @{
    Authorization = "Basic $Credential"
  }
  switch ($TwoFactorAuthentication.ToLower()) {
    'github' {
      $Code = '2FA Code:' | Invoke-Input -Number
      $Headers.Accept = 'application/vnd.github.v3+json'
      $Headers['x-github-otp'] = $Code
    }
    Default {
      # Do nothing
    }
  }
  $Parameters = @{
    Uri = $Uri
    Headers = $Headers
  }
  Invoke-WebRequest @Parameters
}
function Invoke-WebRequestWithOAuth {
  [CmdletBinding()]
  Param()
  
}