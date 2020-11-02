function ConvertFrom-Pair {
  <#
  .SYNOPSIS
  Creates an object from an array of keys and an array of values. Key/Value pairs with higher index take precedence.

  .EXAMPLE
  @('a','b','c'),@(1,2,3) | fromPair
  # @{ a = 1; b = 2; c = 3 }

  #>
  [CmdletBinding()]
  [Alias('fromPair')]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Array] $InputObject
  )
  Begin {
    function Invoke-FromPair {
      Param(
        [Parameter(Position=0)]
        [Array] $InputObject
      )
      if ($InputObject.Count -gt 0) {
        $Callback = {
          Param($Acc, $Item)
          $Key,$Value = $Item
          $Acc.$Key = $Value
        }
        Invoke-Reduce -Items ($InputObject | Invoke-Zip) -Callback $Callback -InitialValue @{}
      }
    }
    Invoke-FromPair $InputObject
  }
  End {
    Invoke-FromPair $Input
  }
}
function ConvertTo-Pair {
  <#
  .SYNOPSIS
  Converts an object into two arrays - keys and values.

  Note: The order of the output arrays are not guaranteed to be consistent with input object key/value pairs.

  .EXAMPLE
  @{ a = 1; b = 2; c = 3 } | toPair
  # @('c','b','a'),@(3,2,1)

  #>
  [CmdletBinding()]
  [Alias('toPair')]
  [OutputType([Array])]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [PSObject] $InputObject
  )
  Process {
    switch ($InputObject.GetType().Name) {
      'PSCustomObject' {
        $Properties = $InputObject.PSObject.Properties
        $Keys = $Properties | Select-Object -ExpandProperty Name
        $Values = $Properties | Select-Object -ExpandProperty Value
        @($Keys,$Values)
      }
      'Hashtable' {
        $Keys = $InputObject.GetEnumerator() | Select-Object -ExpandProperty Name
        $Values = $InputObject.GetEnumerator() | Select-Object -ExpandProperty Value
        @($Keys,$Values)
      }
      Default { $InputObject }
    }
  }
}
function Find-FirstIndex {
  <#
  .SYNOPSIS
  Helper function to return index of first array item that returns true for a given predicate
  (default predicate returns true if value is $true)
  .EXAMPLE
  Find-FirstIndex -Values $false,$true,$false
  # Returns 1
  .EXAMPLE
  Find-FirstIndex -Values 1,1,1,2,1,1 -Predicate { $args[0] -eq 2 }
  # Returns 3
  .EXAMPLE
  1,1,1,2,1,1 | Find-FirstIndex -Predicate { $args[0] -eq 2 }
  # Returns 3

  Note the use of the unary comma operator
  .EXAMPLE
  1,1,1,2,1,1 | Find-FirstIndex -Predicate { $args[0] -eq 2 }
  # Returns 3
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Predicate')]
  [CmdletBinding()]
  [OutputType([Int])]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Array] $Values,
    [ScriptBlock] $Predicate = { $args[0] -eq $true }
  )
  End {
    if ($Input.Length -gt 0) {
      $Values = $Input
    }
    $Values | ForEach-Object { if (& $Predicate $_) { [Array]::IndexOf($Values, $_) } } | Select-Object -First 1
  }
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
        $OrderOfMagnitude = Get-Magnitude $Value
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
}
function Get-Extremum {
  <#
  .SYNOPSIS
  Function to return extremum (maximum or minimum) of an array of numbers
  .EXAMPLE
  $Maximum = 1,2,3,4,5 | Get-Extremum -Max
  # 5

  .EXAMPLE
  $Minimum = 1,2,3,4,5 | Get-Extremum -Min
  # 1

  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Maximum')]
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Minimum')]
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Array] $InputObject,
    [Alias('Max')]
    [Switch] $Maximum,
    [Alias('Min')]
    [Switch] $Minimum
  )
  Begin {
    function Invoke-GetExtremum {
      param (
        [Parameter(Position=0)]
        [Array] $Values
      )
      if ($Values.Count -gt 0) {
        $Type = Find-FirstTrueVariable 'Maximum','Minimum'
        $Values | Measure-Object -Maximum:$Maximum -Minimum:$Minimum | Invoke-GetProperty $Type
      }
    }
    Invoke-GetExtremum $InputObject
  }
  End {
    Invoke-GetExtremum $Input
  }
}
function Get-Maximum {
  <#
  .SYNOPSIS
  Wrapper for Get-Extremum with the -Maximum switch
  #>
  [CmdletBinding()]
  [Alias('max')]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Array] $Values
  )
  Begin {
    if ($Values.Count -gt 0) {
      Get-Extremum -Maximum $Values
    }
  }
  End {
    if ($Input.Count -gt 0) {
      $Input | Get-Extremum -Maximum
    }
  }
}
function Get-Minimum {
  <#
  .SYNOPSIS
  Wrapper for Get-Extremum with the -Minimum switch
  #>
  [CmdletBinding()]
  [Alias('min')]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Array] $Values
  )
  Begin {
    if ($Values.Count -gt 0) {
      Get-Extremum -Minimum $Values
    }
  }
  End {
    if ($Input.Count -gt 0) {
      $Input | Get-Extremum -Minimum
    }
  }
}
function Get-Permutation {
  <#
  .SYNOPSIS
  Return an array of R-Permutations of given group of items

  .EXAMPLE
  1,2,3 | permute -r 2
  # @(1,2),@(1,3),@(2,1),@(2,3),@(3,1),@(3,2)

  .EXAMPLE
  'cat' | permute
  # 'cat','cta','atc','act','tca','tac'

  .EXAMPLE
  1..5 | Get-Permutation -Choose 3

  #>
  [CmdletBinding()]
  [Alias('permute')]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Array] $InputObject,
    [Parameter(Position=1)]
    [Alias('r')]
    [Int] $Choose
  )
  Begin {
    function Remove-Item {
      Param(
        [Parameter(Position=0)]
        [Array] $Values,
        [Parameter(Position=1)]
        [Int] $Index
      )
      $Values[0..($Index - 1)] + $Values[($Index + 1)..($Values.Length -1)]
    }
    function Invoke-Permutation {
      Param(
        [Parameter(Position=0)]
        [Array] $Values
      )
      switch ($Values.Count) {
        1 {
          return
        }
        2 {
          $a,$b = $Values
          $Permutation = [System.Collections.ArrayList]::New()
          [Void]$Permutation.Add(@($a,$b))
          [Void]$Permutation.Add(@($b,$a))
          $Permutation
        }
        Default {
          Invoke-Permutation $Values[1..($Values.Count - 1)]
        }
      }
    }
    if ($InputObject.Count -gt 0) {
      Invoke-Permutation $InputObject
    }
  }
  End {
    $Items = $Input
    $Count = $Items.Count
    if ($Count -gt 0) {
      if ($Count -eq 2) {
        $Result = Invoke-Permutation $Input
      } else {
        $Result = [System.Collections.ArrayList]::New()
        $Temp = [System.Collections.ArrayList](0..($Count - 1))
        $Temp | ForEach-Object {
          [Void]$Result.Add($_)
          $Permutation = Invoke-Permutation (Remove-Item $Temp $_)
          [Void]$Result.Add($Permutation)
        }
      }
    }
    $Output = [System.Collections.ArrayList]::New()
    $Result | Invoke-Chunk -Size 2 | ForEach-Object {
      [Void]$Output.Add($_)
    }
    $Output
  }
}
function Invoke-Chunk {
  <#
  .SYNOPSIS
  Creates an array of elements split into groups the length of Size. If array can't be split evenly, the final chunk will be the remaining elements.

  .EXAMPLE
  1..10 | chunk -s 3
  # @(1,2,3),@(4,5,6),@(7,8,9),@(10)

  #>
  [CmdletBinding()]
  [Alias('chunk')]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Array] $InputObject,
    [Parameter(Position=1)]
    [Alias('s')]
    [Int] $Size = 0
  )
  Begin {
    function Invoke-InternalChunk {
      Param(
        [Parameter(Position=0)]
        [Array] $InputObject,
        [Parameter(Position=1)]
        [Int] $Size = 0
      )
      $InputSize = $InputObject.Count
      if ($InputSize -gt 0) {
        if ($Size -gt 0 -and $Size -lt $InputSize) {
          $Index = 0
          $Arrays = [System.Collections.ArrayList]::New()
          1..[Math]::Ceiling($InputSize / $Size) | ForEach-Object {
            [Void]$Arrays.Add($InputObject[$Index..($Index + $Size - 1)])
            $Index += $Size
          }
          $Arrays
        } else {
          $InputObject
        }
      }
    }
    Invoke-InternalChunk $InputObject $Size
  }
  End {
    Invoke-InternalChunk $Input $Size
  }
}
function Invoke-DropWhile {
  [CmdletBinding()]
  [Alias('dropwhile')]
  Param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [Array] $InputObject,
    [Parameter(Mandatory=$true, Position=0)]
    [ScriptBlock] $Predicate
  )
  Begin {
    function Invoke-InternalDropWhile {
      [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Predicate', Scope='Function')]
      Param(
        [Parameter(Position=0)]
        [Array] $InputObject,
        [Parameter(Position=1)]
        [scriptblock] $Predicate
      )
      if ($InputObject.Count -gt 0) {
        $Continue = $false
        $InputObject | ForEach-Object {
          if (-not (& $Predicate $_) -or $Continue) {
            $Continue = $true
            $_
          }
        }
      }
    }
    Invoke-InternalDropWhile $InputObject $Predicate
  }
  End {
    Invoke-InternalDropWhile $Input $Predicate
  }
}
function Invoke-Flatten {
  [CmdletBinding()]
  [Alias('flat')]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Array] $Values
  )
  Begin {
    function Invoke-Flat {
      Param(
        [Parameter(Position=0)]
        [Array] $Values
      )
      if ($Values.Count -gt 0) {
        $Values |
          ForEach-Object { $_ } |
          Where-Object { $_ -ne $null }
      }
    }
    Invoke-Flat $Values
  }
  End {
    Invoke-Flat $Input
  }
}
function Invoke-GetProperty {
  [CmdletBinding()]
  [Alias('prop')]
  Param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    $InputObject,
    [Parameter(Position=0)]
    [ValidatePattern('^-?\w+$')]
    [String] $Name
  )
  Process {
    $Properties = $InputObject | Get-Member -MemberType Property | Select-Object -ExpandProperty Name
    if ($Properties -contains $Name) {
      $InputObject.$Name
    } else {
      $InputObject
    }
  }
}
function Invoke-InsertString {
  [CmdletBinding()]
  [Alias('insert')]
  [OutputType([String])]
  Param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [String] $Value,
    [Parameter(Mandatory=$true)]
    [String] $To,
    [Parameter(Mandatory=$true)]
    [Int] $At
  )
  Process {
    if ($At -le $To.Length -and $At -ge 0) {
      $To.Substring(0, $At) + $Value + $To.Substring($At, $To.length - $At)
    } else {
      $To
    }
  }
}
function Invoke-Method {
  <#
  .SYNOPSIS
  Invokes method with pased name of a given object. The next two positional arguments after the method name are provided to the invoked method.

  .EXAMPLE
  '  foo','  bar','  baz' | method 'TrimStart'
  # 'foo','bar','baz'

  .EXAMPLE
  1,2,3 | method 'CompareTo' 2
  # -1,0,1

  .EXAMPLE
  $Arguments = 'Substring',0,3
  'abcdef','123456','foobar' | method @Arguments
  # 'abc','123','foo'

  #>
  [CmdletBinding()]
  [Alias('method')]
  Param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    $InputObject,
    [Parameter(Mandatory=$true, Position=0)]
    [ValidatePattern('^-?\w+$')]
    [String] $Name,
    [Parameter(Position=1)]
    $ArgumentOne,
    [Parameter(Position=2)]
    $ArgumentTwo
  )
  Process {
    $Methods = $InputObject | Get-Member -MemberType Method | Select-Object -ExpandProperty Name
    $ParameterizedProperties = $InputObject | Get-Member -MemberType ParameterizedProperty | Select-Object -ExpandProperty Name
    if ($Name -in ($Methods + $ParameterizedProperties)) {
      if ($null -ne $ArgumentOne) {
        if ($null -ne $ArgumentTwo) {
          $InputObject.$Name($ArgumentOne, $ArgumentTwo)
        } else {
          $InputObject.$Name($ArgumentOne)
        }
      } else {
        $InputObject.$Name()
      }
    } else {
      "==> $InputObject does not have a(n) `"$Name`" method" | Write-Verbose
      $InputObject
    }
  }
}
function Invoke-ObjectInvert {
  <#
  .SYNOPSIS
  Returns a new object with the keys of the given object as values, and the values of the given object, which are coerced to strings, as keys.

  Note: A duplicate value in the passed object will become a key in the inverted object with an array of keys that had the duplicate value as a value.

  .EXAMPLE
  @{ foo = 'bar' } | invert
  # @{ bar = 'foo' }

  .EXAMPLE
  @{ a = 1; b = 2; c = 1 } | invert
  # @{ '1' = 'a','c'; '2' = 'b' }

  #>
  [CmdletBinding()]
  [Alias('invert')]
  [OutputType([System.Collections.Hashtable])]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [PSObject] $InputObject
  )
  Process {
    $Data = $InputObject
    $Keys,$Values = $Data | ConvertTo-Pair
    $GroupedData = @($Keys,$Values) | Invoke-Zip | Group-Object { $_[1] }
    if ($Keys.Count -gt 1) {
      $Callback = {
        Param($Acc, [String]$Key)
        $Acc.$Key = $GroupedData |
          Where-Object { $_.Name -eq $Key } |
          Select-Object -ExpandProperty Group |
          ForEach-Object { $_[0] } |
          Sort-Object
      }
      $GroupedData |
        Select-Object -ExpandProperty Name |
        Invoke-Reduce -Callback $Callback -InitialValue @{}
    } else {
      if ($Data.GetType().Name -eq 'PSCustomObject') {
        [PSCustomObject]@{ $Values = $Keys }
      } else {
        @{ $Values = $Keys }
      }
    }
  }
}
function Invoke-ObjectMerge {
  <#
  .SYNOPSIS
  Merge two or more hashtables or custom objects. The result will be of the same type as the first item passed.

  .EXAMPLE
  @{ a = 1 },@{ b = 2 },@{ c = 3 } | merge
  # @{ a = 1; b = 2; c = 3 }

  .EXAMPLE
  [PSCustomObject]@{ a = 1 },[PSCustomObject]@{ b = 2 } | merge
  # [PSCustomObject]@{ a = 1; b = 2 }

  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Acc', Scope='Function')]
  [CmdletBinding()]
  [Alias('merge')]
  [OutputType([System.Collections.Hashtable])]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Array] $InputObject
  )
  Begin {
    function Invoke-Merge {
      Param(
        [Parameter(Position=0)]
        [Array] $InputObject
      )
      if ($null -ne $InputObject) {
        $Result = if ($InputObject.Count -gt 1) {
          $InputObject | Invoke-Reduce -InitialValue @{} -Callback {
            Param($Acc,$Item)
            $Item | ConvertTo-Pair | Invoke-Zip | ForEach-Object {
              [String]$Key,$Value = $_
              $Acc.$Key = $Value
            }
          }
        } else {
          $InputObject
        }
        if ($InputObject[0].GetType().Name -eq 'PSCustomObject') {
          [PSCustomObject]$Result
        } else {
          $Result
        }
      }
    }
    Invoke-Merge $InputObject
  }
  End {
    Invoke-Merge $Input
  }
}
function Invoke-Once {
  <#
  .SYNOPSIS
  Higher-order function that takes a function and returns a function that can only be executed a certain number of times
  .PARAMETER Times
  Number of times passed function can be called (default is 1, hence the name - Once)
  .EXAMPLE
  $Function:test = Invoke-Once { 'Should only see this once' | Write-Color -Red }
  1..10 | ForEach-Object {
    test
  }
  .EXAMPLE
  $Function:greet = Invoke-Once {
    "Hello $($args[0])" | Write-Color -Red
  }
  greet 'World'
  # no subsequent greet functions are executed
  greet 'Jim'
  greet 'Bob'

  Functions returned by Invoke-Once can accept arguments
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope='Function')]
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true, Position=0)]
    [ScriptBlock] $Function,
    [Int] $Times = 1
  )
  {
    if ($Script:Count -lt $Times) {
      & $Function @Args
      $Script:Count++
    }
  }.GetNewClosure()
}
function Invoke-Operator {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '', Scope='Function')]
  [CmdletBinding()]
  [Alias('op')]
  Param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    $InputObject,
    [Parameter(Mandatory=$true, Position=0)]
    [ValidatePattern('^-?[\w%\+-\/\*]+$')]
    [ValidateLength(1,12)]
    [String] $Name,
    [Parameter(Mandatory=$true, Position=1)]
    [Array] $Arguments
  )
  Process {
    try {
      if ($Arguments.Count -eq 1) {
        $Expression = "`$InputObject $(if ($Name.Length -eq 1) { '' } else { '-' })$Name `"``$Arguments`""
        "==> Executing: $Expression" | Write-Verbose
        Invoke-Expression $Expression
      } else {
        $Arguments = $Arguments | ForEach-Object { "`"``$_`"" }
        $Expression = "`$InputObject -$Name $($Arguments -join ',')"
        "==> Executing: $Expression" | Write-Verbose
        $Expression | Write-Verbose
        Invoke-Expression $Expression
      }
    } catch {
      "==> $InputObject does not support the `"$Name`" operator" | Write-Verbose
      $InputObject
    }
  }
}
function Invoke-Partition {
  <#
  .SYNOPSIS
  Creates an array of elements split into two groups, the first of which contains elements that the predicate returns truthy for, the second of which contains elements that the predicate returns falsey for.

  The predicate is invoked with one argument (each element of the passed array)

  .EXAMPLE
  $IsEven = { Param($x) $x % 2 -eq 0 }
  1..10 | Invoke-Partition $IsEven

  # Returns @(@(2,4,6,8,10),@(1,3,5,7,9))

  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Predicate', Scope='Function')]
  [CmdletBinding()]
  [Alias('partition')]
  Param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [Array] $InputObject,
    [Parameter(Mandatory=$true, Position=0)]
    [ScriptBlock] $Predicate
  )
  Begin {
    function Invoke-InternalPartition {
      Param(
        [Parameter(Position=0)]
        [Array] $InputObject,
        [Parameter(Position=1)]
        [ScriptBlock] $Predicate
      )
      if ($InputObject.Count -gt 1) {
        $Left = @()
        $Right = @()
        $InputObject | ForEach-Object {
          $Condition = & $Predicate $_
          if ($Condition) {
            $Left += $_
          } else {
            $Right += $_
          }
        }
        @($Left,$Right)
      }
    }
    Invoke-InternalPartition $InputObject $Predicate
  }
  End {
    Invoke-InternalPartition $Input $Predicate
  }
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
    $Index = 0
    $Result = $InitialValue
    $Callback = switch ((Find-FirstTrueVariable 'Identity','Add','Every','Some','FileInfo')) {
      'Identity' { $Callback }
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
        $Result = & $Callback $Result $_ $Index $Items
      } else {
        & $Callback $Result $_ $Index $Items
      }
      $Index++
    }
  }
  End {
    $Result
  }
}
function Invoke-TakeWhile {
  [CmdletBinding()]
  [Alias('takewhile')]
  Param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [Array] $InputObject,
    [Parameter(Mandatory=$true, Position=0)]
    [ScriptBlock] $Predicate
  )
  Begin {
    function Invoke-InternalTakeWhile {
      [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Predicate', Scope='Function')]
      Param(
        [Parameter(Position=0)]
        [Array] $InputObject,
        [Parameter(Position=1)]
        [scriptblock] $Predicate
      )
      if ($InputObject.Count -gt 0) {
        $InputObject | ForEach-Object {
          if (& $Predicate $_) {
            $_
          } else {
            break
          }
        }
      }
    }
    Invoke-InternalTakeWhile $InputObject $Predicate
  }
  End {
    Invoke-InternalTakeWhile $Input $Predicate
  }
}
function Invoke-Tap {
  <#
  .SYNOPSIS
  Runs the passed function with the piped object, then returns the object.

  .DESCRIPTION
  Intercepts pipeline value, executes Callback with value as argument. If the Callback returns a non-null value, that value is returned; otherwise, the original value is passed thru the pipeline.
  The purpose of this function is to "tap into" a pipeline chain sequence in order to modify the results or view the intermediate values in the pipeline.

  This function is mostly meant for testing and development, but could also be used as a "map" function - a simpler alternative to ForEach-Object.

  .EXAMPLE
  1..10 | Invoke-Tap { $args[0] | Write-Color -Green } | Invoke-Reduce -Add -InitialValue 0
  # Returns sum of first ten integers and writes each value to the terminal

  .EXAMPLE
  # Use Invoke-Tap as "map" function to add one to every value
  1..10 | Invoke-Tap { Param($x) $x + 1 }

  .EXAMPLE
  # Allows you to see the values as they are passed through the pipeline
  1..10 | Invoke-Tap -Verbose | Do-Something

  #>
  [CmdletBinding()]
  [Alias('tap')]
  Param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    $InputObject,
    [Parameter(Position=0)]
    [ScriptBlock] $Callback
  )
  Process {
    if ($Callback -and $Callback -is [ScriptBlock]) {
      $CallbackResult = & $Callback $InputObject
      if ($null -ne $CallbackResult) {
        $Result = $CallbackResult
      } else {
        $Result = $InputObject
      }
    } else {
      "[tap] `$PSItem = $InputObject" | Write-Verbose
      $Result = $InputObject
    }
    $Result
  }
}
function Invoke-Zip {
  <#
  .SYNOPSIS
  Creates an array of grouped elements, the first of which contains the first elements of the given arrays, the second of which contains the second elements of the given arrays, and so on...
  .EXAMPLE
  @('a','a','a'),@('b','b','b'),@('c','c','c') | Invoke-Zip
  # Returns @('a','b','c'),@('a','b','c'),@('a','b','c')

  .EXAMPLE
  # EmptyValue is inserted when passed arrays of different orders

  @(1),@(2,2),@(3,3,3) | Invoke-Zip -EmptyValue 0
  # Returns @(1,2,3),@(0,2,3),@(0,0,3)

  @(3,3,3),@(2,2),@(1) | Invoke-Zip -EmptyValue 0
  # Returns @(3,2,1),@(3,2,0),@(3,0,0)

  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'EmptyValue')]
  [CmdletBinding()]
  [Alias('zip')]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Array] $InputObject,
    [String] $EmptyValue = 'empty'
  )
  Begin {
    function Invoke-InternalZip {
      Param(
        [Parameter(Position=0)]
        [Array] $InputObject
      )
      if ($null -ne $InputObject -and $InputObject.Count -gt 0) {
        $Data = $InputObject
        $Arrays = [System.Collections.ArrayList]::New()
        $MaxLength = $Data | ForEach-Object { $_.Count } | Get-Maximum
        $Data | ForEach-Object {
          $Initial = $_
          $Offset = $MaxLength - $Initial.Count
          if ($Offset -gt 0) {
            1..$Offset | ForEach-Object { $Initial += $EmptyValue }
          }
          [Void]$Arrays.Add($Initial)
        }
        $Result = [System.Collections.ArrayList]::New()
        0..($MaxLength - 1) | ForEach-Object {
          $Index = $_
          $Current = $Arrays | ForEach-Object { $_[$Index] }
          [Void]$Result.Add($Current)
        }
        $Result
      }
    }
    Invoke-InternalZip $InputObject
  }
  End {
    Invoke-InternalZip $Input
  }
}
function Invoke-ZipWith {
  <#
  .SYNOPSIS
  Like Invoke-Zip except that it accepts -Iteratee to specify how grouped values should be combined (via Invoke-Reduce).
  .EXAMPLE
  @(1,1),@(2,2) | Invoke-ZipWith { Param($a,$b) $a + $b }
  # Returns @(3,3)

  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Iteratee')]
  [CmdletBinding()]
  [Alias('zipWith')]
  Param(
    [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true)]
    [Array] $InputObject,
    [Parameter(Mandatory=$true, Position=0)]
    [ScriptBlock] $Iteratee,
    [String] $EmptyValue = ''
  )
  Begin {
    if ($InputObject.Count -gt 0) {
      Invoke-Zip $InputObject -EmptyValue $EmptyValue | ForEach-Object {
        $_[1..$_.Count] | Invoke-Reduce -Callback $Iteratee -InitialValue $_[0]
      }
    }
  }
  End {
    if ($Input.Count -gt 0) {
      $Input | Invoke-Zip -EmptyValue $EmptyValue | ForEach-Object {
        $_[1..$_.Count] | Invoke-Reduce -Callback $Iteratee -InitialValue $_[0]
      }
    }
  }
}
function Join-StringsWithGrammar {
  <#
  .SYNOPSIS
  Helper function that creates a string out of a list that properly employs commands and "and"
  .EXAMPLE
  Join-StringsWithGrammar @('a', 'b', 'c')

  Returns "a, b, and c"
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Delimiter')]
  [CmdletBinding()]
  [OutputType([String])]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [String[]] $Items,
    [String] $Delimiter = ','
  )

  Begin {
    function Join-StringArray {
      Param(
        [Parameter(Mandatory=$true, Position=0)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [String[]] $Items
      )
      $NumberOfItems = $Items.Length
      if ($NumberOfItems -gt 0) {
        switch ($NumberOfItems) {
          1 {
            $Items -join ''
          }
          2 {
            $Items -join ' and '
          }
          Default {
            @(
              ($Items[0..($NumberOfItems - 2)] -join ', ') + ','
              'and'
              $Items[$NumberOfItems - 1]
            ) -join ' '
          }
        }
      }
    }
    Join-StringArray $Items
  }
  End {
    Join-StringArray $Input
  }
}
function Remove-Character {
  [CmdletBinding()]
  [Alias('remove')]
  [OutputType([String])]
  Param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [String] $Value,
    [Int] $At,
    [Switch] $First,
    [Switch] $Last
  )
  Process {
    $At = if ($First) { 0 } elseif ($Last) { $Value.Length - 1 } else { $At }
    if ($At -lt $Value.Length -and $At -ge 0) {
      $Value.Substring(0, $At) + $Value.Substring($At + 1, $Value.length - $At - 1)
    } else {
      $Value
    }
  }
}
function Test-Equal {
  <#
  .SYNOPSIS
  Helper function meant to provide a more robust equality check (beyond just integers and strings)
  .EXAMPLE
  Test-Equal 42 43 # False
  Test-Equal 0 0 # True

  Also works with booleans, strings, objects, and arrays
  .EXAMPLE
  $a = @{a = 1; b = 2; c = 3}
  $b = @{a = 1; b = 2; c = 3}
  Test-Equal $a $b # True
  #>
  [CmdletBinding(DefaultParameterSetName='named')]
  [Alias('equal')]
  [OutputType([Bool])]
  Param(
    [Parameter(ParameterSetName='named', Position=0)]
    $Left,
    [Parameter(ParameterSetName='named', Position=1)]
    $Right,
    [Parameter(ParameterSetName='piped', ValueFromPipeline=$true)]
    [Array] $InputObject
  )
  Begin {
    function Test-InternalEqual {
      Param(
        $Left,
        $Right,
        [Array] $FromPipeline
      )
      $Compare = {
        Param($Left,$Right)
        $Type = $Left.GetType().Name
        switch -Wildcard ($Type) {
          'String' { $Left -eq $Right }
          'Int*' { $Left -eq $Right }
          'Double' { $Left -eq $Right }
          'Object*' {
            $Every = { $args[0] -and $args[1] }
            $Index = 0
            $Left | ForEach-Object { Test-Equal $_ $Right[$Index]; $Index++ } | Invoke-Reduce -Callback $Every -InitialValue $true
          }
          'PSCustomObject' {
            $Every = { $args[0] -and $args[1] }
            $LeftKeys = $Left.psobject.properties | Select-Object -ExpandProperty Name
            $RightKeys = $Right.psobject.properties | Select-Object -ExpandProperty Name
            $LeftValues = $Left.psobject.properties | Select-Object -ExpandProperty Value
            $RightValues = $Right.psobject.properties | Select-Object -ExpandProperty Value
            $Index = 0
            $HasSameKeys = $LeftKeys |
              ForEach-Object { Test-Equal $_ $RightKeys[$Index]; $Index++ } |
              Invoke-Reduce -Callback $Every -InitialValue $true
            $Index = 0
            $HasSameValues = $LeftValues |
              ForEach-Object { Test-Equal $_ $RightValues[$Index]; $Index++ } |
              Invoke-Reduce -Callback $Every -InitialValue $true
            $HasSameKeys -and $HasSameValues
          }
          'Hashtable' {
            $Every = { $args[0] -and $args[1] }
            $Index = 0
            $RightKeys = $Right.GetEnumerator() | Select-Object -ExpandProperty Name
            $HasSameKeys = $Left.GetEnumerator() |
              ForEach-Object { Test-Equal $_.Name $RightKeys[$Index]; $Index++ } |
              Invoke-Reduce -Callback $Every -InitialValue $true
            $Index = 0
            $RightValues = $Right.GetEnumerator() | Select-Object -ExpandProperty Value
            $HasSameValues = $Left.GetEnumerator() |
              ForEach-Object { Test-Equal $_.Value $RightValues[$Index]; $Index++ } |
              Invoke-Reduce -Callback $Every -InitialValue $true
            $HasSameKeys -and $HasSameValues
          }
          Default { $Left -eq $Right }
        }
      }
      if ($FromPipeline.Count -gt 0) {
        $Items = $FromPipeline
        if ($PSBoundParameters.ContainsKey('Left')) {
          $Items += $Left
        }
        if ($PSBoundParameters.ContainsKey('Right')) {
          $Items += $Right
        }
        # Use Get-Permutation (choose 2) and reduce pairs with $Compare
      } else {
        if ($null -ne $Left) {
          & $Compare $Left $Right
        } else {
          Write-Verbose '==> Left value is null'
          $Left -eq $Right
        }
      }
    }
    if ($PSBoundParameters.ContainsKey('Right')) {
      Test-InternalEqual $Left $Right
    }
  }
  End {
    if ($Input.Count -gt 0) {
      $Input.Count | Write-Color -Red
      Test-InternalEqual $Left $Right -FromPipeline $Input
    }
  }
}