[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '', Scope = 'Function', Target = 'Invoke-Operator')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Deny-Value')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Find-FirstIndex')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Get-Value')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Invoke-DropWhile_')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Invoke-ObjectMerge')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Invoke-Once')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Invoke-PropertyTransform')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Invoke-Reduce')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Invoke-Zip')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Invoke-ZipWith')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Join-StringsWithGrammar')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'New-PropertyExpression')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'New-RegexString')]
Param()

function ConvertFrom-Pair {
    <#
    .SYNOPSIS
    Creates an object from an array of keys and an array of values. Key/Value pairs with higher index take precedence.
    .EXAMPLE
    @('a', 'b', 'c'), @(1, 2, 3) | fromPair
    # @{ a = 1; b = 2; c = 3 }
    #>
    [CmdletBinding()]
    [Alias('fromPair')]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Array] $InputObject
    )
    Begin {
        function Invoke-FromPair {
            Param(
                [Parameter(Position = 0)]
                [Array] $InputObject
            )
            if ($InputObject.Count -gt 0) {
                $Callback = {
                    Param($Acc, $Item)
                    $Key, $Value = $Item
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
function ConvertTo-OrderedDictionary {
    <#
    .SYNOPSIS
    Converts a hashtable to an ordered hashtable.
    Acts as passthru for odered dictionary inputs.
    .EXAMPLE
    @{ a = 1; b = 2; c = 3 } | ConvertTo-OrderedDictionary
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        $InputObject,
        [Parameter(Mandatory = $False, Position = 1)]
        [String] $Property = 'Key'
    )
    switch ($InputObject) {
        { $_ -is [System.Collections.Specialized.OrderedDictionary] } {
            $InputObject
        }
        { $_ -is [System.Collections.Hashtable] } {
            $Result = [Ordered]@{}
            foreach ($Item in ($InputObject.GetEnumerator() | Sort-Object -Property $Property)) {
                $Key = $Item.Key
                $Result.add($Key, $InputObject[$Key])
            }
            $Result
        }
        { $_ -is [System.Management.Automation.PSCustomObject] } {
            $Result = [Ordered]@{}
            foreach ($Item in $InputObject.PSObject.Properties) {
                $Result.add($Item.Name, $Item.Value)
            }
            $Result
        }
        Default {
            $InputObject
        }
    }
}
function ConvertTo-Pair {
    <#
    .SYNOPSIS
    Converts an object into two arrays - keys and values.
    Note: The order of the output arrays are not guaranteed to be consistent with input object key/value pairs.
    .EXAMPLE
    @{ a = 1; b = 2; c = 3 } | toPair
    # @('c', 'b', 'a'), @(3, 2, 1)
    #>
    [CmdletBinding()]
    [Alias('toPair')]
    [OutputType([Array])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [PSObject] $InputObject
    )
    Process {
        switch ($InputObject.GetType().Name) {
            'PSCustomObject' {
                $Properties = $InputObject.PSObject.Properties
                $Keys = $Properties | Select-Object -ExpandProperty Name
                $Values = $Properties | Select-Object -ExpandProperty Value
                @($Keys, $Values)
            }
            'Hashtable' {
                $Keys = $InputObject.GetEnumerator() | Select-Object -ExpandProperty Name
                $Values = $InputObject.GetEnumerator() | Select-Object -ExpandProperty Value
                @($Keys, $Values)
            }
            Default { $InputObject }
        }
    }
}
function Deny-Empty {
    <#
    .SYNOPSIS
    Remove empty string values from pipeline chains
    .EXAMPLE
    'a', 'b', '', 'd' | Deny-Empty
    # 'a', 'b', 'd'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [AllowNull()]
        [AllowEmptyString()]
        [Array] $InputObject
    )
    Begin {
        $IsNotEmptyString = { -not ($_ -is [String]) -or ($_.Length -gt 0) }
        if ($InputObject.Count -gt 0) {
            $InputObject | Where-Object $IsNotEmptyString
        }
    }
    End {
        if ($Input.Count -gt 0) {
            $Input | Where-Object $IsNotEmptyString
        }
    }
}
function Deny-Null {
    <#
    .SYNOPSIS
    Remove null values from pipeline chains
    .EXAMPLE
    1, 2, $Null, 4 | Deny-Null
    # 1, 2, 4
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [AllowNull()]
        [AllowEmptyString()]
        [Array] $InputObject
    )
    Begin {
        $IsNotNull = { $Null -ne $_ }
        if ($InputObject.Count -gt 0) {
            $InputObject | Where-Object $IsNotNull
        }
    }
    End {
        if ($Input.Count -gt 0) {
            $Input | Where-Object $IsNotNull
        }
    }
}
function Deny-Value {
    <#
    .SYNOPSIS
    Remove string values equal to -Value parameter
    .EXAMPLE
    'a', 'b', 'a', 'a' | Deny-Value -Value 'b'
    # 'a', 'a', 'a'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True, Position = 1)]
        [Array] $InputObject,
        [Parameter(Mandatory = $True, Position = 0)]
        $Value
    )
    Begin {
        $IsNotValue = { $_ -ne $Value }
        if ($InputObject.Count -gt 0) {
            $InputObject | Where-Object $IsNotValue
        }
    }
    End {
        if ($Input.Count -gt 0) {
            $Input | Where-Object $IsNotValue
        }
    }
}
function Find-FirstIndex {
    <#
    .SYNOPSIS
    Helper function to return index of first array item that returns true for a given predicate
    (default predicate returns true if value is $True)
    .EXAMPLE
    Find-FirstIndex -Values $False, $True, $False
    # 1
    .EXAMPLE
    Find-FirstIndex -Values 1, 1, 1, 2, 1, 1 -Predicate { $_ -eq 2 }
    # 3
    .EXAMPLE
    1, 1, 1, 2, 1, 1 | Find-FirstIndex -Predicate { $_ -eq 2 }
    # 3

    Note the use of the unary comma operator
    .EXAMPLE
    1, 1, 1, 2, 1, 1 | Find-FirstIndex -Predicate { Param($X) $X -eq 2 }
    # 3
    #>
    [CmdletBinding()]
    [OutputType([Int])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Array] $Values,
        [ScriptBlock] $Predicate = { $_ -eq $True },
        [Int] $DefaultIndex = -1
    )
    Begin {
        function Find-FirstIndex_ {
            Param(
                [Parameter(Position = 0)]
                [Array] $Values
            )
            if ($Values.Count -gt 0) {
                $Results = New-Object 'System.Collections.ArrayList'
                $UseAutomaticVariable = ($Predicate | Get-ParameterList).Name.Count -eq 0
                foreach ($Value in $Values) {
                    $Condition = if ($UseAutomaticVariable) {
                        $Powershell = [Powershell]::Create()
                        $Null = $Powershell.AddCommand('Set-Variable').AddParameter('Name', '_').AddParameter('Value', $Value).AddScript($Predicate)
                        $Powershell.Invoke()
                    } else {
                        & $Predicate $Value
                    }
                    if ($Condition) {
                        $Index = [Array]::IndexOf($Values, $Value)
                        [Void]$Results.Add($Index)
                    }
                }
                if ($Results.Count -gt 0) {
                    $Results | Select-Object -First 1
                } else {
                    $DefaultIndex
                }
            }
        }
        Find-FirstIndex_ $Values
    }
    End {
        Find-FirstIndex_ $Input
    }
}
function Get-Property {
    <#
    .SYNOPSIS
    Helper function intended to streamline getting property values within pipelines.
    .PARAMETER Name
    Property name (or array index). Also works with dot-separated paths for nested properties.
    For array-like inputs, $X,$Y | prop '0.1.2' is the same as $X[0][1][2],$Y[0][1][2] (see examples)
    .EXAMPLE
    'hello', 'world' | prop 'Length'
    # 5, 5
    .EXAMPLE
    ,@(1, 2, 3, @(4, 5, 6, @(7, 8, 9))) | prop '3.3.2'
    # 9
    # Note the leading comma
    #>
    [CmdletBinding()]
    [Alias('prop')]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        $InputObject,
        [Parameter(Position = 0)]
        [ValidatePattern('^-?[\w\.]+$')]
        [String] $Name
    )
    Begin {
        function Test-NumberLike {
            Param(
                [String] $Value
            )
            $AsNumber = $Value -as [Int]
            $AsNumber -or ($AsNumber -eq 0)
        }
        function Get-PropertyMaybe {
            Param(
                [Parameter(Position = 0)]
                $InputObject,
                [Parameter(Position = 1)]
                [String] $Name
            )
            if ((Test-Enumerable $InputObject) -and (Test-NumberLike $Name)) {
                $InputObject[$Name]
            } else {
                $InputObject.$Name
            }
        }
    }
    Process {
        if ($Name -match '\.') {
            $Result = $InputObject
            $Properties = $Name -split '\.'
            foreach ($Property in $Properties) {
                $Result = Get-PropertyMaybe $Result $Property
            }
            $Result
        } else {
            Get-PropertyMaybe $InputObject $Name
        }
    }
}
function Invoke-Chunk {
    <#
    .SYNOPSIS
    Creates an array of elements split into groups the length of Size. If array can't be split evenly, the final chunk will be the remaining elements.
    .EXAMPLE
    1..10 | chunk -s 3
    # @(1, 2, 3), @(4, 5, 6), @(7, 8, 9), @(10)
    #>
    [CmdletBinding()]
    [Alias('chunk')]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Array] $InputObject,
        [Parameter(Position = 1)]
        [Alias('s')]
        [Int] $Size = 0
    )
    Begin {
        function Invoke-Chunk_ {
            Param(
                [Parameter(Position = 0)]
                [Array] $InputObject,
                [Parameter(Position = 1)]
                [Int] $Size = 0
            )
            $InputSize = $InputObject.Count
            if ($InputSize -gt 0) {
                if ($Size -gt 0 -and $Size -lt $InputSize) {
                    $Index = 0
                    $Arrays = New-Object 'System.Collections.ArrayList'
                    for ($Count = 1; $Count -le ([Math]::Ceiling($InputSize / $Size)); $Count++) {
                        [Void]$Arrays.Add($InputObject[$Index..($Index + $Size - 1)])
                        $Index += $Size
                    }
                    $Arrays
                } else {
                    $InputObject
                }
            }
        }
        Invoke-Chunk_ $InputObject $Size
    }
    End {
        Invoke-Chunk_ $Input $Size
    }
}
function Invoke-DropWhile {
    <#
    .SYNOPSIS
    Create slice of array excluding elements dropped from the beginning
    .PARAMETER Predicate
    Function that returns $True or $False
    .EXAMPLE
    1..10 | dropWhile { $_ -lt 6 }
    # 6, 7, 8, 9, 10
    .EXAMPLE
    40..45 | dropWhile { Param($X) $X -ne 42 }
    # 42, 43, 44, 45
    #>
    [CmdletBinding()]
    [Alias('dropwhile')]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [Array] $InputObject,
        [Parameter(Mandatory = $True, Position = 0)]
        [ScriptBlock] $Predicate
    )
    Begin {
        function Invoke-DropWhile_ {
            Param(
                [Parameter(Position = 0)]
                [Array] $InputObject,
                [Parameter(Position = 1)]
                [ScriptBlock] $Predicate
            )
            if ($InputObject.Count -gt 0) {
                $Continue = $False
                $UseAutomaticVariable = ($Predicate | Get-ParameterList).Name.Count -eq 0
                foreach ($Item in $InputObject) {
                    $Condition = if ($UseAutomaticVariable) {
                        $Powershell = [Powershell]::Create()
                        $Null = $Powershell.AddCommand('Set-Variable').AddParameter('Name', '_').AddParameter('Value', $Item).AddScript($Predicate)
                        $Powershell.Invoke()
                    } else {
                        & $Predicate $Item
                    }
                    if (-not $Condition -or $Continue) {
                        $Continue = $True
                        $Item
                    }
                }
            }
        }
        if ($InputObject.Count -eq 1 -and $InputObject[0].GetType().Name -eq 'String') {
            $Result = Invoke-DropWhile_ $InputObject[0].ToCharArray() $Predicate
            $Result -join ''
        } else {
            Invoke-DropWhile_ $InputObject $Predicate
        }
    }
    End {
        if ($Input.Count -eq 1 -and $Input[0].GetType().Name -eq 'String') {
            $Result = Invoke-DropWhile_ $Input.ToCharArray() $Predicate
            $Result -join ''
        } else {
            Invoke-DropWhile_ $Input $Predicate
        }
    }
}
function Invoke-Flatten {
    <#
    .SYNOPSIS
    Recursively flatten array
    .EXAMPLE
    @(1, @(2, 3, @(4, 5))) | flatten
    # 1, 2, 3, 4, 5
    #>
    [CmdletBinding()]
    [Alias('flatten')]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Array] $Values
    )
    Begin {
        function Invoke-Flat {
            Param(
                [Parameter(Position = 0)]
                [Array] $Values
            )
            if ($Values.Count -gt 0) {
                $MaxCount = $Values | ForEach-Object { $_.Count } | Get-Maximum
                if ($MaxCount -gt 1) {
                    Invoke-Flat ($Values | ForEach-Object { $_ } | Where-Object { $Null -ne $_ })
                } else {
                    $Values
                }
            }
        }
        Invoke-Flat $Values
    }
    End {
        Invoke-Flat $Input
    }
}
function Invoke-InsertString {
    <#
    .SYNOPSIS
    Easily insert strings within other strings
    .PARAMETER At
    Index
    .EXAMPLE
    'abce' | insert 'd' -At 3
    # 'abcde
    #>
    [CmdletBinding()]
    [Alias('insert')]
    [OutputType([String])]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [String] $To,
        [Parameter(Mandatory = $True, Position = 0)]
        [String] $Value,
        [Parameter(Mandatory = $True)]
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
    # 'foo', 'bar', 'baz'
    .EXAMPLE
    1, 2, 3 | method 'CompareTo' 2
    # -1, 0, 1
    .EXAMPLE
    $Arguments = 'Substring', 0, 3
    'abcdef', '123456', 'foobar' | method @Arguments
    # 'abc', '123', 'foo'
    #>
    [CmdletBinding()]
    [Alias('method')]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        $InputObject,
        [Parameter(Mandatory = $True, Position = 0)]
        [ValidatePattern('^-?\w+$')]
        [String] $Name,
        [Parameter(Position = 1)]
        $ArgumentOne,
        [Parameter(Position = 2)]
        $ArgumentTwo
    )
    Process {
        $Methods = $InputObject | Get-Member -MemberType Method | Select-Object -ExpandProperty Name
        $ScriptMethods = $InputObject | Get-Member -MemberType ScriptMethod | Select-Object -ExpandProperty Name
        $ParameterizedProperties = $InputObject | Get-Member -MemberType ParameterizedProperty | Select-Object -ExpandProperty Name
        if ($Name -in ($Methods + $ScriptMethods + $ParameterizedProperties)) {
            if ($Null -ne $ArgumentOne) {
                if ($Null -ne $ArgumentTwo) {
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
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [PSObject] $InputObject
    )
    Process {
        $Data = $InputObject
        $Keys, $Values = $Data | ConvertTo-Pair
        $GroupedData = @($Keys, $Values) | Invoke-Zip | Group-Object { $_[1] }
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
    .PARAMETER Force
    Default behavior is to not overwrite existing values. Set this parameter to $True to overwrite existing values.
    .EXAMPLE
    @{ a = 1 }, @{ b = 2 }, @{ c = 3 } | merge
    # @{ a = 1; b = 2; c = 3 }
    .EXAMPLE
    [PSCustomObject]@{ a = 1 }, [PSCustomObject]@{ b = 2 } | merge
    # [PSCustomObject]@{ a = 1; b = 2 }
    .EXAMPLE
    @{ a = 1 }, @{ a = 3 } | merge
    # @{ a = 1 }

    @{ a = 1 }, @{ a = 3 } | merge -Force
    # @{ a = 3 }
    #>
    [CmdletBinding()]
    [Alias('merge')]
    [OutputType([System.Collections.Hashtable])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Array] $InputObject,
        [Switch] $InPlace,
        [Switch] $Force
    )
    Begin {
        function Set-ObjectKeyValue {
            Param(
                [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
                $InputObject,
                [Parameter(Mandatory = $True)]
                $Key,
                $Value
            )
            $Type = $InputObject.GetType().Name
            if ($Type -eq 'PSCustomObject') {
                $InputObject | Add-Member -MemberType NoteProperty -Name $Key -Value $Value
            } else {
                $InputObject.$Key = $Value
            }
            $InputObject
        }
        function Test-ObjectKeyValueNullEmpty {
            Param(
                [Parameter(Mandatory = $True, Position = 0)]
                $InputObject,
                [Parameter(Mandatory = $True, Position = 1)]
                $Key
            )
            $Type = $InputObject.GetType().Name
            $Keys = if ($Type -eq 'PSCustomObject') {
                $InputObject.PSObject.Properties.Name
            } else {
                $InputObject.keys
            }
            if ($Keys -contains $Key) {
                [String]::IsNullOrEmpty($InputObject.$Key)
            } else {
                $True
            }
        }
        function Invoke-Merge {
            Param(
                [Parameter(Position = 0)]
                [Array] $InputObject
            )
            if ($Null -ne $InputObject) {
                $Result = if ($InputObject.Count -gt 1) {
                    $InputObject | Invoke-Reduce -Callback {
                        Param($Acc, $Item)
                        $Type = $Item.GetType().Name
                        $ItemCount = if ($Type -eq 'PSCustomObject') {
                            $Item.PSObject.Properties.Name.Length
                        } else {
                            $Item.Count
                        }
                        switch ($ItemCount) {
                            0 {
                                # Return nothing
                            }
                            1 {
                                $K, $V = $Item | ConvertTo-Pair
                                if ((Test-ObjectKeyValueNullEmpty $Acc $K) -or $Force) {
                                    $Acc | Set-ObjectKeyValue -Key $K -Value $V | Out-Null
                                }
                            }
                            Default {
                                $Item | ConvertTo-Pair | Invoke-Zip | ForEach-Object {
                                    $Key, $Value = $_
                                    if ((Test-ObjectKeyValueNullEmpty $Acc $Key) -or $Force) {
                                        $Acc | Set-ObjectKeyValue -Key $Key -Value $Value | Out-Null
                                    }
                                }
                            }
                        }
                    }
                } else {
                    $InputObject
                }
                if ($InPlace) {
                    $InputObject = $Result
                } else {
                    if ($InputObject[0].GetType().Name -eq 'PSCustomObject') {
                        [PSCustomObject]$Result
                    } else {
                        $Result
                    }
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
    1..10 | ForEach-Object { test }
    .EXAMPLE
    $Function:greet = Invoke-Once { "Hello $($Args[0])" | Write-Color -Red }
    greet 'World'
    # no subsequent greet functions are executed
    greet 'Jim'
    greet 'Bob'

    # Functions returned by Invoke-Once can accept arguments
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0)]
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
function Invoke-Omit {
    <#
    .SYNOPSIS
    Create an object composed of the omitted object properties
    .EXAMPLE
    @{ a = 1; b = 2; c = 3 } | omit a
    # @{ b = 2; c = 3 }
    #>
    [CmdletBinding()]
    [Alias('omit')]
    [OutputType([Hashtable])]
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [PSObject] $From,
        [Parameter(Position = 0)]
        [Array] $Name
    )
    Process {
        $Type = $From.GetType().Name
        switch ($Type) {
            'PSCustomObject' {
                $Result = [PSCustomObject]@{}
                $Keys = $From.PSObject.Properties.Name
                foreach ($Property in $Keys.Where( { $_ -notin $Name })) {
                    $Result | Add-Member -MemberType NoteProperty -Name $Property -Value $From.$Property
                }
                $Result
            }
            'Hashtable' {
                $Result = @{}
                $Keys = $From.keys
                foreach ($Property in $Keys.Where( { $_ -notin $Name })) {
                    $Result.$Property = $From.$Property
                }
                $Result
            }
            Default {
                $Result = @{}
                $Result
            }
        }
    }
}
function Invoke-Operator {
    <#
    .SYNOPSIS
    Helper function intended mainly for use within quick one-line pipeline chains
    .EXAMPLE
    @(1, 2, 3), @(4, 5, 6), @(7, 8, 9) | op join ''
    # '123', '456', '789'
    #>
    [CmdletBinding()]
    [Alias('op')]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        $InputObject,
        [Parameter(Mandatory = $True, Position = 0)]
        [ValidatePattern('^-?[\w%\+-\/\*]+$')]
        [ValidateLength(1, 12)]
        [String] $Name,
        [Parameter(Mandatory = $True, Position = 1)]
        [Array] $Arguments
    )
    Process {
        try {
            if ($Arguments.Count -eq 1) {
                $Operand = if ([String]::IsNullOrEmpty($Arguments)) { "''" } else { "`"``$Arguments`"" }
                $Expression = "`$InputObject $(if ($Name.Length -eq 1) { '' } else { '-' })$Name $Operand"
                "==> Executing: $Expression" | Write-Verbose
                Invoke-Expression $Expression
            } else {
                $Arguments = $Arguments | ForEach-Object { "`"``$_`"" }
                $Expression = "`$InputObject -$Name $($Arguments -join ',')"
                "==> Executing: $Expression" | Write-Verbose
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
    $IsEven = { Param($X) $X % 2 -eq 0 }
    1..10 | Invoke-Partition $IsEven
    # @(@(2, 4, 6, 8, 10), @(1, 3, 5, 7, 9))
    #>
    [CmdletBinding()]
    [Alias('partition')]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [Array] $InputObject,
        [Parameter(Mandatory = $True, Position = 0)]
        [ScriptBlock] $Predicate
    )
    Begin {
        function Invoke-Partition_ {
            Param(
                [Parameter(Position = 0)]
                [Array] $InputObject,
                [Parameter(Position = 1)]
                [ScriptBlock] $Predicate
            )
            if ($InputObject.Count -gt 1) {
                $Left = @()
                $Right = @()
                foreach ($Item in $InputObject) {
                    $Condition = & $Predicate $Item
                    if ($Condition) {
                        $Left += $Item
                    } else {
                        $Right += $Item
                    }
                }
                @($Left, $Right)
            }
        }
        Invoke-Partition_ $InputObject $Predicate
    }
    End {
        Invoke-Partition_ $Input $Predicate
    }
}
function Invoke-Pick {
    <#
    .SYNOPSIS
    Create an object composed of the picked object properties
    .DESCRIPTION
    This function behaves very much like Select-Object, but with normalized behavior that works on hashtables and custom objects.
    .PARAMETER All
    Include non-existent properties. For non-existent properties, set value to -EmptyValue.
    .EXAMPLE
    @{ a = 1; b = 2; c = 3 } | pick 'a','c'
    # @{ a = 1; c = 3 }
    #>
    [CmdletBinding()]
    [Alias('pick')]
    [OutputType([Hashtable])]
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [PSObject] $From,
        [Parameter(Position = 0)]
        [Array] $Name,
        [Switch] $All,
        [AllowNull()]
        [AllowEmptyString()]
        $EmptyValue = $Null
    )
    Process {
        $Type = $From.GetType().Name
        switch ($Type) {
            'PSCustomObject' {
                $Result = [PSCustomObject]@{}
                $Keys = $From.PSObject.Properties.Name
                foreach ($Property in $Name.Where( { $_ -in $Keys })) {
                    $Result | Add-Member -MemberType NoteProperty -Name $Property -Value $From.$Property
                }
                if ($All) {
                    foreach ($Property in $Name.Where( { $_ -notin $Keys })) {
                        $Result | Add-Member -MemberType NoteProperty -Name $Property -Value $EmptyValue
                    }
                }
                $Result
            }
            'Hashtable' {
                $Result = @{}
                $Keys = $From.keys
                foreach ($Property in $Name.Where( { $_ -in $Keys })) {
                    $Result.$Property = $From.$Property
                }
                if ($All) {
                    foreach ($Property in $Name.Where( { $_ -notin $Keys })) {
                        $Result.$Property = $EmptyValue
                    }
                }
                $Result
            }
            Default {
                $Result = @{}
                if ($All) {
                    foreach ($Property in $Name) {
                        $Result.$Property = $EmptyValue
                    }
                }
                $Result
            }
        }
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
    [CmdletBinding()]
    [Alias('transform')]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        $InputObject,
        [Parameter(Mandatory = $True, Position = 0)]
        [PSObject] $Lookup,
        [Parameter(Position = 1)]
        [ScriptBlock] $Transform = { Param($Value) $Value }
    )
    Begin {
        function New-PropertyExpression {
            Param(
                [Parameter(Mandatory = $True)]
                [String] $Name,
                [Parameter(Mandatory = $True)]
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
    Starting value for reduce.
    The type of InitialValue will change the operation of Invoke-Reduce. If no InitialValue is passed, the first item will be used.
    Note: InitialValue must be passed when using "method" version of Invoke-Reduce. Example: (1..5).Reduce($Add, 0)
    .PARAMETER FileInfo
    The operation of combining many FileInfo objects into one object is common enough to deserve its own switch (see examples)
    .EXAMPLE
    1, 2, 3, 4, 5 | Invoke-Reduce -Callback { Param($A, $B) $A + $B }

    # Compute sum of array of integers
    .EXAMPLE
    'a', 'b', 'c' | reduce { Param($A, $B) $A + $B }

    # Concatenate array of strings
    .EXAMPLE
    1..10 | reduce -Add
    # 5050

    # Invoke-Reduce has switches for common callbacks - Add, Every, and Some
    .EXAMPLE
    1..10 | reduce -Add ''
    # '12345678910'

    # Change the InitialValue to change the Callback and output type
    .EXAMPLE
    Get-ChildItem -File | Invoke-Reduce -FileInfo | Write-BarChart

    # Combining directory contents into single object and visualize with Write-BarChart - in a single line!
    #>
    [CmdletBinding()]
    [Alias('reduce')]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [Array] $Items,
        [Parameter(Position = 0)]
        [ScriptBlock] $Callback = { Param($A) $A },
        [Parameter(Position = 1)]
        $InitialValue,
        [Switch] $Identity,
        [Switch] $Add,
        [Switch] $Multiply,
        [Switch] $Every,
        [Switch] $Some,
        [Switch] $FileInfo
    )
    Begin {
        function Invoke-Reduce_ {
            Param(
                [Parameter(Position = 0)]
                [Array] $Items,
                [Parameter(Position = 1)]
                [ScriptBlock] $Callback,
                [Parameter(Position = 2)]
                $InitialValue
            )
            if ($Items.Count -gt 0) {
                if ($FileInfo) {
                    $InitialValue = @{}
                }
                if ($Null -eq $InitialValue) {
                    $InitialValue = $Items | Select-Object -First 1
                    $Items = $Items[1..($Items.Count - 1)]
                }
                $Index = 0
                $Result = $InitialValue
                $Callback = switch ((Find-FirstTrueVariable 'Identity', 'Add', 'Multiply', 'Every', 'Some', 'FileInfo')) {
                    'Identity' {
                        $Callback
                    }
                    'Add' {
                        { Param($A, $B) $A + $B }
                    }
                    'Multiply' {
                        { Param($A, $B) $A * $B }
                    }
                    'Every' {
                        { Param($A, $B) $A -and $B }
                    }
                    'Some' {
                        { Param($A, $B) $A -or $B }
                    }
                    'FileInfo' {
                        { Param($Acc, $Item) $Acc[$Item.Name] = $Item.Length }
                    }
                    Default { $Callback }
                }
                foreach ($Item in $Items) {
                    $ShouldSaveResult = ([Array], [Bool], [System.Numerics.Complex], [Int], [String] | ForEach-Object { $InitialValue -is $_ }) -contains $True
                    if ($ShouldSaveResult) {
                        $Result = & $Callback $Result $Item $Index $Items
                    } else {
                        & $Callback $Result $Item $Index $Items
                    }
                    $Index++
                }
                $Result
            }
        }
        Invoke-Reduce_ -Items $Items -Callback $Callback -InitialValue $InitialValue
    }
    End {
        Invoke-Reduce_ -Items $Input -Callback $Callback -InitialValue $InitialValue
    }
}
function Invoke-Repeat {
    <#
    .SYNOPSIS
    Create an array with -Times number of items, all equal to $Value
    .EXAMPLE
    'a' | Invoke-Repeat -Times 3
    # 'a', 'a', 'a'
    .EXAMPLE
    1 | repeat -x 5
    # 1, 1, 1, 1, 1
    #>
    [CmdletBinding()]
    [Alias('repeat')]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [AllowEmptyString()]
        $Value,
        [Parameter(Position = 1)]
        [Alias('x')]
        [Int] $Times = 1
    )
    Process {
        [System.Linq.Enumerable]::Repeat($Value, $Times)
    }
}
function Invoke-Reverse {
    <#
    .SYNOPSIS
    Return a reversed version of input array or string
    .EXAMPLE
    1..5 | Invoke-Reverse
    # 5, 4, 3, 2, 1

    Invoke-Reverse -Value @(1, 2, 3, 4, 5)
    # 5, 4, 3, 2, 1
    .EXAMPLE
    'hello world' | reverse
    # 'dlrow olleh'
    #>
    [CmdletBinding()]
    [Alias('reverse')]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [AllowEmptyString()]
        [Array] $InputObject
    )
    Begin {
        function Invoke-Reverse_ {
            Param(
                [Parameter(Position = 0)]
                [Array] $InputObject
            )
            if ($InputObject.Count -gt 0) {
                $Clone = New-Object 'System.Collections.ArrayList'
                foreach ($Item in $InputObject) {
                    [Void]$Clone.Add($Item)
                }
                $Clone.Reverse()
                $Clone
            }
        }
        if ($InputObject.Count -eq 1 -and $InputObject[0].GetType().Name -eq 'String') {
            $Result = Invoke-Reverse_ $InputObject.ToCharArray()
            $Result -join ''
        } else {
            Invoke-Reverse_ $InputObject
        }
    }
    End {
        if ($Input.Count -eq 1 -and $Input[0].GetType().Name -eq 'String') {
            $Result = Invoke-Reverse_ $Input.ToCharArray()
            $Result -join ''
        } else {
            Invoke-Reverse_ $Input
        }
    }
}
function Invoke-TakeWhile {
    <#
    .SYNOPSIS
    Create slice of array with elements taken from the beginning
    .EXAMPLE
    1..10 | takeWhile { $Args[0] -lt 6 }
    # 1, 2, 3, 4, 5
    #>
    [CmdletBinding()]
    [Alias('takeWhile')]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [Array] $InputObject,
        [Parameter(Mandatory = $True, Position = 0)]
        [ScriptBlock] $Predicate
    )
    Begin {
        function Invoke-TakeWhile_ {
            Param(
                [Parameter(Position = 0)]
                [Array] $InputObject,
                [Parameter(Position = 1)]
                [ScriptBlock] $Predicate
            )
            if ($InputObject.Count -gt 0) {
                $Result = [System.Collections.ArrayList]@{}
                $Index = 0
                while ((& $Predicate $InputObject[$Index]) -and ($Index -lt $InputObject.Count)) {
                    [Void]$Result.Add($InputObject[$Index])
                    $Index++
                }
                $Result
            }
        }
        if ($InputObject.Count -eq 1 -and $InputObject[0].GetType().Name -eq 'String') {
            $Result = Invoke-TakeWhile_ $InputObject.ToCharArray() $Predicate
            $Result -join ''
        } else {
            Invoke-TakeWhile_ $InputObject $Predicate
        }
    }
    End {
        if ($Input.Count -eq 1 -and $Input[0].GetType().Name -eq 'String') {
            $Result = Invoke-TakeWhile_ $Input.ToCharArray() $Predicate
            $Result -join ''
        } else {
            Invoke-TakeWhile_ $Input $Predicate
        }
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
    1..10 | Invoke-Tap { $Args[0] | Write-Color -Green } | Invoke-Reduce -Add -InitialValue 0

    # Returns sum of first ten integers and writes each value to the terminal
    .EXAMPLE
    1..10 | Invoke-Tap { Param($X) $X + 1 }

    # Use Invoke-Tap as "map" function to add one to every value
    .EXAMPLE
    1..10 | Invoke-Tap -Verbose | Do-Something

    # Allows you to see the values as they are passed through the pipeline
    #>
    [CmdletBinding()]
    [Alias('tap')]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        $InputObject,
        [Parameter(Position = 0)]
        [ScriptBlock] $Callback
    )
    Process {
        if ($Callback -and $Callback -is [ScriptBlock]) {
            $CallbackResult = & $Callback $InputObject
            if ($Null -ne $CallbackResult) {
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
function Invoke-Unzip {
    <#
    .SYNOPSIS
    The reverse of Invoke-Zip
    .EXAMPLE
    @(@(1, 'a'), @(2, 'b'), @(3, 'c')) | unzip
    # @(1, 2, 3), @('a', 'b', 'c')
    #>
    [CmdletBinding()]
    [Alias('unzip')]
    [OutputType([Array])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Array] $InputObject
    )
    Begin {
        function Invoke-Unzip_ {
            Param(
                [Array] $InputObject
            )
            if ($InputObject.Count -gt 0) {
                $Left = New-Object 'System.Collections.ArrayList'
                $Right = New-Object 'System.Collections.ArrayList'
                foreach ($Item in $InputObject) {
                    [Void]$Left.Add($Item[0])
                    [Void]$Right.Add($Item[1])
                }
                $Left, $Right
            }
        }
        Invoke-Unzip_ $InputObject
    }
    End {
        Invoke-Unzip_ $Input
    }
}
function Invoke-Zip {
    <#
    .SYNOPSIS
    Creates an array of grouped elements, the first of which contains the first elements of the given arrays, the second of which contains the second elements of the given arrays, and so on...
    .EXAMPLE
    @('a', 'a', 'a'), @('b', 'b', 'b'), @('c', 'c', 'c') | Invoke-Zip
    # @('a', 'b', 'c'), @('a', 'b', 'c'), @('a', 'b', 'c')
    .EXAMPLE
    @(1), @(2, 2), @(3, 3, 3) | Invoke-Zip -EmptyValue 0
    # @(1, 2, 3), @(0, 2, 3), @(0, 0, 3)

    # EmptyValue is inserted when passed arrays of different orders
    .EXAMPLE
    @(3, 3, 3), @(2, 2), @(1) | Invoke-Zip -EmptyValue 0
    # @(3, 2, 1), @(3, 2, 0), @(3, 0, 0)

    # EmptyValue is inserted when passed arrays of different orders
    #>
    [CmdletBinding()]
    [Alias('zip')]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Array] $InputObject,
        [String] $EmptyValue = 'empty'
    )
    Begin {
        function Invoke-Zip_ {
            Param(
                [Parameter(Position = 0)]
                [Array] $InputObject
            )
            if ($Null -ne $InputObject -and $InputObject.Count -gt 0) {
                $Data = $InputObject
                $Arrays = New-Object 'System.Collections.ArrayList'
                $MaxLength = $Data | ForEach-Object { $_.Count } | Get-Maximum
                foreach ($Item in $Data) {
                    $Initial = $Item
                    $Offset = $MaxLength - $Initial.Count
                    if ($Offset -gt 0) {
                        for ($Index = 1; $Index -le $Offset; $Index++) {
                            $Initial += $EmptyValue
                        }
                    }
                    [Void]$Arrays.Add($Initial)
                }
                $Result = New-Object 'System.Collections.ArrayList'
                for ($Index = 0; $Index -lt $MaxLength; $Index++) {
                    $Current = $Arrays | ForEach-Object { $_[$Index] }
                    [Void]$Result.Add($Current)
                }
                $Result
            }
        }
        Invoke-Zip_ $InputObject
    }
    End {
        Invoke-Zip_ $Input
    }
}
function Invoke-ZipWith {
    <#
    .SYNOPSIS
    Like Invoke-Zip except that it accepts -Iteratee to specify how grouped values should be combined (via Invoke-Reduce).
    .EXAMPLE
    @(1, 1), @(2, 2) | Invoke-ZipWith { Param($A, $B) $A + $B }
    # @(3, 3)
    #>
    [CmdletBinding()]
    [Alias('zipWith')]
    Param(
        [Parameter(Mandatory = $True, Position = 1, ValueFromPipeline = $True)]
        [Array] $InputObject,
        [Parameter(Mandatory = $True, Position = 0)]
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
    Join-StringsWithGrammar 'a', 'b', 'c'
    # 'a, b, and c'
    #>
    [CmdletBinding()]
    [OutputType([String])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [String[]] $Items,
        [String] $Delimiter = ','
    )

    Begin {
        function Join-StringArray {
            Param(
                [Parameter(Mandatory = $True, Position = 0)]
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
function New-RegexString {
    <#
    .SYNOPSIS
    Create a regular expression using string input and cmdlet parameters
    .EXAMPLE
    # Create a regular expression string that will match a single email
    $Re = New-RegexString -Single -Url
    'https://google.com' -match $Re #True
    .EXAMPLE
    'foo', 'bar', 'baz' | New-RegularExpression

    # Regular expression that matches "foo", "bar", OR "baz"
    #>
    [CmdletBinding()]
    [Alias('re')]
    [OutputType([String])]
    Param(
        [Parameter(ValueFromPipeline = $True)]
        [String[]] $Value,
        [Switch] $Date,
        [Switch] $Duration,
        [Switch] $Email,
        [Switch] $IPv4,
        [Switch] $IPv6,
        [Switch] $ISO8601,
        [Switch] $Time,
        [Switch] $Url,
        [Switch] $And,
        [Switch] $Only
    )
    Begin {
        $Month = @(
            'January'
            'February'
            'March'
            'April'
            'May'
            'June'
            'July'
            'August'
            'September'
            'October'
            'November'
            'December'
        )
        $DD = '(0[1-9])|(1[0-9])|(2[0-9])|(3[0-1])'
        $DD_alt = '(((\b[1-9])|01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31)\b)'
        $Day = '(1(st)?)|(2(nd)?)|(3(rd)?)|([4-9](th)?)'
        $MM = '(0(1|2|3|4|5|6|7|8|9))|(10)|(11)|(12)'
        $MM_alt = '(((\b[1-9])|01|02|03|04|05|06|07|08|09|10|11|12)\b)'
        $MMM = $Month |
            ForEach-Object { $_.Substring(0, 3) } |
            Invoke-Reduce { Param($Str, $Mon) "$Str|$Mon|$($Mon.toUpper())" }
        $Months = $Month -join '|'
        $YYYY = '((?<!\d)[0-9]{2}(?!\d))|([0-9]{4})'
        $DateFormats = @(
            # DDMMMYY
            # DMMMYY
            # DDMMMYYYY
            # DD MMM YYYY
            # DD MMM YY
            # D MMM YYYY
            "(?<day>(((?<!\d)([1-9](?!\d)))|$DD))\s?(?<month>($MMM))\s?(?<year>($YYYY))"
            # YYYYMMDD
            # YYYY-MM-DD
            "(?<year>([012345689]{4}))-?(?<month>($MM))-?(?<day>($DD))"
            # Month Day, YY
            # Month Day, YYYY
            "(?<month>($Months)) (?<day>($Day)),? (?<year>($YYYY))"
            # D Month YY
            # DD Month YY
            # D Month YYYY
            # DD Month YYYY
            "(?<day>$DD_alt)\s+(?<month>($Months))\s+(?<year>($YYYY))"
            # MM.DD.YY
            # MM.DD.YYYY
            # MM/DD/YY
            # MM/DD/YYYY
            # MM-DD-YY
            # MM-DD-YYYY
            "(?<month>$MM_alt)[./-](?<day>$DD)[./-](?<year>$YYYY)"
            # DD MM YYYY
            "(?<day>$DD) (?<month>$MM) (?<year>$YYYY)"
        ) -join '|'
        $TopLevelDomain = @(
            'au'
            'ca'
            'cn'
            'de'
            'in'
            'ir'
            'me'
            'nl'
            'ru'
            'tk'
            'ua'
            'uk'
            'us'
            'biz'
            'com'
            'edu'
            'gov'
            'icu'
            'mil'
            'net'
            'org'
            'top'
            'xyz'
            'info'
            'name'
            'site'
            'tech'
            'online'
        ) -join '|' -join '|'
        function Get-RegexString {
            Param(
                [String[]] $Value = ''
            )
            $ReArray = @()
            switch ($True) {
                { $Date } {
                    $ReArray += "(?<date>($DateFormats))"
                }
                { $Duration } {
                    $Hours = '[0-2][0-9]'
                    $Minutes = '[0-5][0-9]'
                    $Seconds = '[0-5][0-9]'
                    $Start = "(?<start>((?<starthours>($Hours)):?(?<startminutes>($Minutes)):?(?<startseconds>($Seconds))?))(?<startzulu>Z)?(?![:])"
                    $End = "(?<end>((?<endhours>($Hours)):?(?<endminutes>($Minutes)):?(?<endseconds>($Seconds))?))(?<endzulu>Z)?(?![:])"
                    $ReArray += "(?<duration>(($Start)\s?-\s?($End)))"
                }
                { $Email } {
                    # RFC 5322 Official Standard (https://www.emailregex.com/)
                    $ReArray += @(
                        '(?<email>'
                        "(?<username>(?:[.a-zA-Z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|`"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*`"))"
                        '(?<symbol>@)'
                        '(?<domain>(?:(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-zA-Z0-9-]*[a-zA-Z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\]))'
                        ')'
                    ) -join ''
                }
                { $IPv4 } {
                    # https://ihateregex.io/expr/ip/
                    $ReArray += @(
                        '(?<ipv4>'
                        '(?<part1>(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))'
                        '\.(?<part2>((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)))'
                        '\.(?<part3>((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)))'
                        '\.(?<part4>((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)))'
                        ')'
                    ) -join ''
                }
                { $IPv6 } {
                    # https://ihateregex.io/expr/ipv6/
                    $ReArray += @(
                        '(?<ipv6>'
                        '('
                        '([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}'
                        '|([0-9a-fA-F]{1,4}:){1,7}:'
                        '|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}'
                        '|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}'
                        '|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}'
                        '|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}'
                        '|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}'
                        '|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})'
                        '|:((:[0-9a-fA-F]{1,4}){1,7}|:)'
                        '|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}'
                        '|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])'
                        '|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])'
                        ')'
                        ')'
                    ) -join ''
                }
                { $Time } {
                    $ReArray += '(?<hours>([0-2][0-9])):?(?<minutes>([0-5][0-9])):?(?<seconds>([0-5][0-9]))?(?<zulu>Z)?(?![-:.])'
                }
                { $ISO8601 } {
                    $ReArray += @(
                        '(?<year>\d\d\d\d)'
                        '([-])?'
                        '(?<month>\d\d)'
                        '([-])?'
                        '(?<day>\d\d)'
                        '((T|\s+)(?<hours>\d\d)(([:])?(?<minutes>\d\d)(([:])?(?<seconds>\d\d)(([.])?(?<fraction>\d+))?)?)?)?'
                        '((?<tzzulu>Z)|(?<tzoffset>[-+])(?<tzhour>\d\d)([:])?(?<tzminute>\d\d))?'
                    ) -join ''
                }
                { $Url } {
                    $ReArray += @(
                        '(?<url>'
                        '((?<scheme>(ht|f)tp(s?))\:\/\/)'
                        # '?'
                        '(?<subdomain>www|[a-zA-Z](?=\.))?'
                        "\.?(?<authority>[a-zA-Z0-9\-\.]+\.(?<tld>${TopLevelDomain}))"
                        '\:?(?<port>([0-9]+)*)'
                        "(\/($|[a-zA-Z0-9\.\,\;\?\'\\\+&%\$#\=~_\-]+))*"
                        ')'
                    ) -join ''
                }
                Default {
                    $ReArray += $Value
                }
            }
            $Re = if ($And) {
                # (?=.*word1)(?=.*word2)(?=.*word3).*
                @(
                    $ReArray | ForEach-Object { "(?=.*${_})" }
                    '.*'
                ) -join ''
            } else {
                "($($ReArray -join '|'))"
            }
            $Re = if ($Only) { "^${Re}$" } else { $Re }
            $Re
        }
    }
    End {
        if ($Input.Count -gt 0) {
            Get-RegexString -Value $Input
        } elseif ($Value.Count -eq 0) {
            Get-RegexString
        } else {
            Get-RegexString -Value $Value
        }
    }
}
function Remove-Character {
    <#
    .SYNOPSIS
    Remove character from -At index of string -Value
    .EXAMPLE
    'abcd' | remove -At 2
    # 'abd'
    .EXAMPLE
    'abcd' | remove -First
    # 'bcd'
    .EXAMPLE
    'abcd' | remove -Last
    # 'abc'
    #>
    [CmdletBinding()]
    [Alias('remove')]
    [OutputType([String])]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
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
function Test-Enumerable {
    <#
    .SYNOPSIS
    Test if Value is enumerable, like a collection (arrays, objects, etc...)
    #>
    [CmdletBinding()]
    [OutputType([Bool])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        $Value
    )
    Begin {
        function Test-Enumerable_ {
            Param(
                [Parameter(Position = 0)]
                $Value
            )
            $Type = $Value.GetType().Name
            switch ($Type) {
                'Object[]' {
                    $True
                }
                'ArrayList' {
                    $True
                }
                'Hashtable' {
                    $True
                }
                'OrderedDictionary' {
                    $True
                }
                'PSCustomObject' {
                    $True
                }
                Default {
                    $False
                }
            }
        }
        if ($PSBoundParameters.ContainsKey('Value')) {
            Test-Enumerable_ -Value $Value
        }
    }
    End {
        if ($Input.Count -gt 0) {
            Test-Enumerable_ -Value (Invoke-Flatten $Input)
        }
    }
}
function Test-Equal {
    <#
    .SYNOPSIS
    Helper function meant to provide a more robust equality check (beyond just integers and strings)
    Works with numbers, booleans, strings, hashtables, custom objects, and arrays
    Note: Function has limited support for comparing $Null values
    .EXAMPLE
    42, 42, 42, 42 | equal

    'na', 'na', 'na', 'na', 'na', 'na', 'na', 'na' | equal 'batman'

    # Test a list of items
    .EXAMPLE
    'foo' | equal 'bar'

    equal 'foo' 'bar'

    # Test a pair of items using pipelines or parameters
    .EXAMPLE
    equal $Null $Null # Supported

    $Null | equal $Null # NOT supported

    $Null, $Null | equal # NOT supported

    # Limited support for $Null comparisons
    #>
    [CmdletBinding()]
    [Alias('equal')]
    [OutputType([Bool])]
    Param(
        [Parameter(Position = 0)]
        $Left,
        [Parameter(Position = 1)]
        $Right,
        [Parameter(ValueFromPipeline = $True)]
        [Array] $InputObject
    )
    Begin {
        function Test-Equal_ {
            Param(
                $Left,
                $Right,
                [Array] $FromPipeline
            )
            $Compare = {
                Param($Left, $Right)
                $Type = $Left.GetType().Name
                switch -Wildcard ($Type) {
                    'Object`[`]' {
                        $Index = 0
                        $Left | ForEach-Object { Test-Equal $_ $Right[$Index]; $Index++ } | Invoke-Reduce -Every
                    }
                    'Int*`[`]' {
                        $Index = 0
                        $Left | ForEach-Object { Test-Equal $_ $Right[$Index]; $Index++ } | Invoke-Reduce -Every
                    }
                    'Double`[`]*' {
                        $Index = 0
                        $Left | ForEach-Object { Test-Equal $_ $Right[$Index]; $Index++ } | Invoke-Reduce -Every
                    }
                    'PSCustomObject' {
                        $Every = { $Args[0] -and $Args[1] }
                        $LeftKeys = $Left.PSObject.Properties.Name
                        $RightKeys = $Right.PSObject.Properties.Name
                        $LeftValues = $Left.PSObject.Properties.Value
                        $RightValues = $Right.PSObject.Properties.Value
                        $Index = 0
                        $HasSameKeys = $LeftKeys |
                            ForEach-Object { Test-Equal $_ $RightKeys[$Index]; $Index++ } |
                            Invoke-Reduce -Callback $Every -InitialValue $True
                        $Index = 0
                        $HasSameValues = $LeftValues |
                            ForEach-Object { Test-Equal $_ $RightValues[$Index]; $Index++ } |
                            Invoke-Reduce -Callback $Every -InitialValue $True
                        $HasSameKeys -and $HasSameValues
                    }
                    'Hashtable' {
                        $Every = { $Args[0] -and $Args[1] }
                        $Index = 0
                        $RightKeys = $Right.GetEnumerator() | Select-Object -ExpandProperty Name
                        $HasSameKeys = $Left.GetEnumerator() |
                            ForEach-Object { Test-Equal $_.Name $RightKeys[$Index]; $Index++ } |
                            Invoke-Reduce -Callback $Every -InitialValue $True
                        $Index = 0
                        $RightValues = $Right.GetEnumerator() | Select-Object -ExpandProperty Value
                        $HasSameValues = $Left.GetEnumerator() |
                            ForEach-Object { Test-Equal $_.Value $RightValues[$Index]; $Index++ } |
                            Invoke-Reduce -Callback $Every -InitialValue $True
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
                $Count = $Items.Count
                if ($Count -gt 1) {
                    $Head = $Items[0]
                    $Rest = $Items[1..($Count - 1)]
                    @($Head), $Rest |
                        Invoke-Zip -EmptyValue $Head |
                        ForEach-Object { & $Compare $_[0] $_[1] } |
                        Invoke-Reduce -Every -InitialValue $True
                } else {
                    $True
                }
            } else {
                if ($Null -ne $Left) {
                    & $Compare $Left $Right
                } else {
                    Write-Verbose '==> Left value is null'
                    $Left -eq $Right
                }
            }
        }
        if ($PSBoundParameters.ContainsKey('Right')) {
            Test-Equal_ $Left $Right
        }
    }
    End {
        if ($Input.Count -gt 0) {
            $Parameters = @{
                FromPipeline = $Input
            }
            if ($PSBoundParameters.ContainsKey('Left')) {
                $Parameters.Left = $Left
            }
            Test-Equal_ @Parameters
        }
    }
}
function Test-Match {
    <#
    .SYNOPSIS
    Test if passed value matches regular expression(s) of certain format(s)
    .EXAMPLE
    'https://google.com' | Test-Match -Url
    #>
    [CmdletBinding()]
    [OutputType([Bool])]
    [OutputType([System.Collections.Hashtable])]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [ValidateNotNull()]
        [String] $Value,
        [Switch] $Date,
        [Switch] $Duration,
        [Switch] $Email,
        [Switch] $IPv4,
        [Switch] $IPv6,
        [Switch] $ISO8601,
        [Switch] $Time,
        [Switch] $Url,
        [Switch] $Only,
        [Switch] $AsBoolean
    )
    Process {
        $Parameters = @{
            Value = $Value
            Date = $Date
            Duration = $Duration
            Email = $Email
            IPv4 = $IPv4
            IPv6 = $IPv6
            ISO8601 = $ISO8601
            Time = $Time
            Url = $Url
            Only = $Only
        }
        $Re = New-RegexString @Parameters
        if ($AsBoolean) {
            if ($Value -match $Re) {
                $True
            } else {
                $False
            }
        } else {
            $Results = ([Regex]$Re).Matches($Value)
            function Get-Value {
                Param(
                    [String] $Name
                )
                $Results.Groups | Where-Object { $_.Name -eq $Name } | Get-Property 'Value'
            }
            switch ($True) {
                { $Date } {
                    if ($Results.Value) {
                        @{
                            Value = $Results.Value
                            Day = Get-Value -Name 'day'
                            Month = Get-Value -Name 'month'
                            Year = Get-Value -Name 'year'
                        }
                    } else {
                        $Null
                    }
                }
                { $Duration } {
                    if ($Results.Value) {
                        @{
                            Value = $Results.Value
                            Start = Get-Value -Name 'start'
                            End = Get-Value -Name 'end'
                            IsZulu = ((Get-Value -Name 'startzulu') -eq 'Z') -or ((Get-Value -Name 'endzulu') -eq 'Z')
                        }
                    } else {
                        $Null
                    }
                }
                { $Email } {
                    if ($Results.Value) {
                        @{
                            Value = $Results.Value
                            Username = Get-Value -Name 'username'
                            Symbol = Get-Value -Name 'symbol'
                            Domain = Get-Value -Name 'domain'
                        }
                    } else {
                        $Null
                    }
                }
                { $IPv4 } {
                    if ($Results.Value) {
                        @{
                            Value = $Results.Value
                            Version = 4
                            Part1 = Get-Value -Name 'part1'
                            Part2 = Get-Value -Name 'part2'
                            Part3 = Get-Value -Name 'part3'
                            Part4 = Get-Value -Name 'part4'
                        }
                    } else {
                        $Null
                    }
                }
                { $IPv6 } {
                    if ($Results.Value) {
                        @{
                            Value = $Results.Value
                            Version = 6
                        }
                    } else {
                        $Null
                    }
                }
                { $Time } {
                    if ($Results.Value) {
                        @{
                            Value = $Results.Value
                            Hours = Get-Value -Name 'hours'
                            Minutes = Get-Value -Name 'minutes'
                            Seconds = Get-Value -Name 'seconds'
                            IsZulu = (Get-Value -Name 'zulu') -eq 'Z'
                        }
                    } else {
                        $Null
                    }
                }
                { $Url } {
                    if ($Results.Value) {
                        @{
                            Value = $Results.Value
                            Scheme = Get-Value -Name 'scheme'
                            Authority = Get-Value -Name 'authority'
                            TLD = Get-Value -Name 'tld'
                            Port = Get-Value -Name 'port'
                        }
                    } else {
                        $Null
                    }
                }
                Default {
                    $Results
                }
            }
        }
    }
}