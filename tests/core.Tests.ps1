[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', 'chunk')]
Param()

& (Join-Path $PSScriptRoot '_setup.ps1') 'core'

Describe 'Powershell Prelude Module' {
    Context 'meta validation' {
        It 'should import exports' {
            (Get-Module -Name pwsh-prelude).ExportedFunctions.Count | Should -Be 90
        }
        It 'should import aliases' {
            (Get-Module -Name pwsh-prelude).ExportedAliases.Count | Should -Be 42
        }
    }
}
Describe 'ConvertFrom-Pair' {
    It 'can create and object from two arrays' {
        $Result = @('a','b','c'),@(1,2,3) | ConvertFrom-Pair
        $Result.a | Should -Be 1
        $Result.b | Should -Be 2
        $Result.c | Should -Be 3
        $Result = @('a','b','a','c'),@(1,2,3,4) | ConvertFrom-Pair
        $Result.a | Should -Be 3
        $Result.b | Should -Be 2
        $Result.c | Should -Be 4
        $Result = ConvertFrom-Pair @('a','b','c'),@(1,2,3)
        $Result.a | Should -Be 1
        $Result.b | Should -Be 2
        $Result.c | Should -Be 3
    }
    It 'provides aliases for ease of use' {
        $Result = @('a','b','c'),@(1,2,3) | ConvertFrom-Pair
        $Result.a | Should -Be 1
        $Result.b | Should -Be 2
        $Result.c | Should -Be 3
    }
}
Describe 'ConvertTo-Pair' {
    It 'can create key and value arrays from an object' {
        $Expected = @('c','b','a'),@(3,2,1)
        @{ a = 1; b = 2; c = 3 } | ConvertTo-Pair | Should -Be $Expected
        ConvertTo-Pair @{ a = 1; b = 2; c = 3 } | Should -Be $Expected
        [PSCustomObject]@{ a = 1; b = 2; c = 3 } | ConvertTo-Pair | Should -Be @('a','b','c'),@(1,2,3)
    }
    It 'should provide passthru for non-object values' {
        'Not an object' | ConvertTo-Pair | Should -Be 'Not an object'
    }
    It 'should be the inverse for ConvertFrom-Pair' {
        @('c','b','a'),@(3,2,1) | ConvertFrom-Pair | ConvertTo-Pair | Should -Be @('c','a','b'),@(3,1,2)
    }
    It 'provides aliases for ease of use' {
        @{ a = 1; b = 2; c = 3 } | ConvertTo-Pair | Should -Be @('c','b','a'),@(3,2,1)
    }
}
Describe 'Find-FirstIndex' {
    It 'can determine index of first item that satisfies default predicate' {
        Find-FirstIndex -Values $false,$true,$false | Should -Be 1
        $false,$true,$false | Find-FirstIndex | Should -Be 1
        Find-FirstIndex -Values $true,$true,$false | Should -Be 0
        $true,$true,$false | Find-FirstIndex | Should -Be 0
        $true,$false,$false | Find-FirstIndex | Should -Be 0
    }
    It 'can determine index of first item that satisfies passed predicate' {
        $Arr = 0,0,0,0,2,0,0
        $Predicate = { $args[0] -eq 2 }
        Find-FirstIndex -Values $Arr | Should -Be $null
        Find-FirstIndex -Values $Arr -Predicate $Predicate | Should -Be 4
        $Arr | Find-FirstIndex -Predicate $Predicate | Should -Be 4
        Find-FirstIndex -Values 2,0,0,0,2,0,0 -Predicate $Predicate | Should -Be 0
    }
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
        { $false | Format-MoneyValue } | Should -Throw 'Format-MoneyValue only accepts strings and numbers'
    }
}
Describe 'Get-Extremum' {
    It 'can return maximum value from array of numbers' {
        $Max = 5
        $Values = 1,2,2,1,$Max,2,3
        $Values | Get-Extremum -Max | Should -Be $Max
        Get-Extremum -Max $Values | Should -Be $Max
        0,-1,4,2,7,2,0 | Get-Extremum -Max | Should -Be 7
    }
    It 'can return minimum value from array of numbers' {
        $Min = 0
        $Values = 1,2,2,1,$Min,2,3
        $Values | Get-Extremum -Min | Should -Be $Min
        Get-Extremum -Min $Values | Should -Be $Min
        0,-1,4,2,7,2,0 | Get-Extremum -Min | Should -Be -1
    }
    It 'Get-Maximum' {
        $Max = 5
        $Values = 1,2,2,1,$Max,2,3
        $Values | Get-Maximum | Should -Be $Max
        Get-Maximum $Values | Should -Be $Max
        0,-1,4,2,7,2,0 | Get-Maximum | Should -Be 7
    }
    It 'Get-Minimum' {
        $Min = 0
        $Values = 1,2,2,1,$Min,2,3
        $Values | Get-Minimum | Should -Be $Min
        Get-Minimum $Values | Should -Be $Min
        0,-1,4,2,7,2,0 | Get-Minimum | Should -Be -1
    }
}
Describe 'Get-Permutation' {
    It 'can return permutations for a given group of items' {
        'a','b' | Get-Permutation | Should -Be @(@('a','b'),@('b','a'))
        # 1..3 | Get-Permutation | Should -Be @(1,2,3),@(1,3,2),@(2,1,3),@(2,3,1),@(3,1,2),@(3,2,1)
        # 1..3 | Get-Permutation -Choose 2 | Should -Be @(1,2)@(1,3),@(2,1),@(2,3),@(3,1),@(3,2)
    }
}
Describe 'Invoke-Chunk' {
    It 'should passthru input object when size is 0 or bigger than the input size' {
        1..10 | Invoke-Chunk -Size 0 | Should -Be (1..10)
        1..10 | Invoke-Chunk -Size 10 | Should -Be (1..10)
        1..10 | Invoke-Chunk -Size 11 | SHould -Be (1..10)
    }
    It 'can break an array into smaller arrays of a given size' {
        1,2,3 | Invoke-Chunk -Size 1 | Should -Be @(1),@(2),@(3)
        1,1,2,2,3,3 | Invoke-Chunk -Size 2 | Should -Be @(1,1),@(2,2),@(3,3)
        1,2,3,1,2 | Invoke-Chunk -Size 3 | Should -Be @(1,2,3),@(1,2)
        Invoke-Chunk 1,2,3 -Size 1 | Should -Be @(1),@(2),@(3)
        Invoke-Chunk 1,1,2,2,3,3 -Size 2 | Should -Be @(1,1),@(2,2),@(3,3)
        Invoke-Chunk 1,2,3,1,2 -Size 3 | Should -Be @(1,2,3),@(1,2)
        Invoke-Chunk @(1,2,3) 1 | Should -Be @(1),@(2),@(3)
        Invoke-Chunk @(1,1,2,2,3,3) 2 | Should -Be @(1,1),@(2,2),@(3,3)
        Invoke-Chunk @(1,2,3,1,2) 3 | Should -Be @(1,2,3),@(1,2)
    }
    It 'provides aliases for ease of use' {
        1..5 | chunk -s 3 | Should -Be @(1,2,3),@(4,5)
    }
}
Describe 'Invoke-DropWhile' {
    It 'can drop elements until passed predicate is False' {
        $LessThan3 = { Param($x) $x -lt 3 }
        $GreaterThan10 = { Param($x) $x -gt 10 }
        1..5 | Invoke-DropWhile $LessThan3 | Should -Be 3,4,5
        1,2,3,4,5,1,1,1 | Invoke-DropWhile $LessThan3 | Should -Be 3,4,5,1,1,1
        Invoke-DropWhile -InputObject (1..5) -Predicate $LessThan3 | Should -Be 3,4,5
        1..5 | Invoke-DropWhile $GreaterThan10 | Should -Be 1,2,3,4,5
        Invoke-DropWhile -InputObject (1..5) -Predicate $GreaterThan10 | Should -Be 1,2,3,4,5
    }
}
Describe 'Invoke-Flatten' {
    It 'can flatten multi-dimensional arrays' {
        @(1,@(2,3)) | Invoke-Flatten | Should -Be 1,2,3
        @(1,@(2,3,@(4,5))) | Invoke-Flatten | Should -Be 1,2,3,4,5
        @(1,@(2,3,@(4,5,@(6,7)))) | Invoke-Flatten | Should -Be 1,2,3,4,5,6,7
        @(1,@(2,3,@(4,5,@(6,7,@(8,9))))) | Invoke-Flatten | Should -Be 1,2,3,4,5,6,7,8,9
        @(1,@(2,3,@(4,5,@(6,7,@(8,9)),10,@(11)))) | Invoke-Flatten | Should -Be 1,2,3,4,5,6,7,8,9,10,11
    }
}
Describe 'Invoke-GetProperty' {
    It 'can get object properties within a pipeline' {
        'foo','bar','baz' | Invoke-GetProperty 'Length' | Should -Be 3,3,3
        'a','ab','abc' | Invoke-GetProperty 'Length' | Should -Be 1,2,3
        @{ a = 1; b = 2; c = 3 } | Invoke-GetProperty 'Keys' | Should -Be 'c','b','a'
    }
}
Describe 'Invoke-InsertString' {
    It 'can insert string into a string at a given index' {
        Invoke-InsertString -Value 'C' -To 'ABDE' -At 2 | Should -Be 'ABCDE'
        'C' | Invoke-InsertString -To 'ABDE' -At 2 | Should -Be 'ABCDE'
        '234' | Invoke-InsertString -To '15' -At 1 | Should -Be '12345'
        'bar' | Invoke-InsertString -To 'foo' -At 3 | Should -Be 'foobar'
        'bar' | Invoke-InsertString -To 'foo' -At 4 | Should -Be 'foo'
    }
    It 'can process an array of strings' {
        'b','b','b' | Invoke-InsertString -To 'ac' -At 1 | Should -Be 'abc','abc','abc'
        'Joe ','Jim ','John ' | Invoke-InsertString -To 'First Last' -At 6 | Should -Be 'First Joe Last','First Jim Last','First John Last'
    }
}
Describe 'Invoke-Method' {
    It 'can apply a method within a pipeline' {
        '  foo','  bar','  baz' | Invoke-Method 'TrimStart' | Should -Be 'foo','bar','baz'
        $true,$false,42 | Invoke-Method 'ToString' | Should -Be 'True','False','42'
    }
    It 'can apply a method with arguments within a pipeline' {
        'a','b','c' | Invoke-Method 'StartsWith' 'b' | Should -Be $false,$true,$false
        1,2,3 | Invoke-Method 'CompareTo' 2 | Should -Be -1,0,1
        @{ x = 1 } | Invoke-Method 'ContainsKey' 'x' | Should -Be $true
        @{ x = 1 } | Invoke-Method 'ContainsKey' 'y' | Should -Be $false
        @{ x = 1 },@{ x = 2 },@{ x = 3 } | Invoke-Method 'Item' 'x' | Should -Be 1,2,3
        $Arguments = 'Substring',0,3
        'abcdef','123456','foobar' | Invoke-Method @Arguments | Should -Be 'abc','123','foo'
        'abcdef','123456','foobar' | Invoke-Method 'Substring' 0 3 | Should -Be 'abc','123','foo'
    }
    It 'only applies valid methods' {
        'foobar' | Invoke-Method 'FakeMethod' | Should -Be 'foobar'
        { 'foobar' | Invoke-Method 'Fake-Method' } | Should -Throw
    }
}
Describe 'Invoke-ObjectInvert' {
    It 'can invert objects with one key/value' {
        $Result = @{ foo = 'bar' } | Invoke-ObjectInvert
        $Result.bar | Should -Be 'foo'
        $Result.foo | Should -Be $null
        $Result = [PSCustomObject]@{ foo = 'bar' } | Invoke-ObjectInvert
        $Result.bar | Should -Be 'foo'
        $Result.foo | Should -Be $null
    }
    It 'can invert objects with more than one key/value pairs' {
        $Result = @{ a = 1; b = 2; c = 3 } | Invoke-ObjectInvert
        $Result['1'] | Should -Be 'a'
        $Result.a | Should -Be $null
        $Result = [PSCustomObject]@{ a = 1; b = 2; c = 3 } | Invoke-ObjectInvert
        $Result['1'] | Should -Be 'a'
        $Result.a | Should -Be $null
    }
    It 'can invert objects and group duplicate values' {
        $Result = @{ a = 1; b = 2; c = 1; d = 1 } | Invoke-ObjectInvert
        $Result['1'] | Should -Be 'a','c','d'
        $Result['2'] | Should -Be 'b'
        $Result.a | Should -Be $null
        $Result.b | Should -Be $null
        $Result.c | Should -Be $null
        $Result.d | Should -Be $null
        $Result = [PSCustomObject]@{ a = 1; b = 2; c = 2; d = 1 } | Invoke-ObjectInvert
        $Result['1'] | Should -Be 'a','d'
        $Result['2'] | Should -Be 'b','c'
        $Result.a | Should -Be $null
        $Result.b | Should -Be $null
        $Result.c | Should -Be $null
        $Result.d | Should -Be $null
    }
}
Describe 'Invoke-ObjectMerge' {
    It 'should function as passthru for one object' {
        $Result = @{ foo = 'bar' } | Invoke-ObjectMerge
        $Result.foo | Should -Be 'bar'
        $Result = [PSCustomObject]@{ foo = 'bar' } | Invoke-ObjectMerge
        $Result.foo | Should -Be 'bar'
    }
    It 'can merge two hashtables' {
        $Result = @{ a = 1 },@{ b = 2 } | Invoke-ObjectMerge
        $Result.a | Should -Be 1
        $Result.b | Should -Be 2
        $Result.Keys | Should -Be 'a','b'
        $Result.Values | Should -Be 1,2
        $Result = @{ a = 1; x = 'this' },@{ b = 2; y = 'that' } | Invoke-ObjectMerge
        $Result.a | Should -Be 1
        $Result.b | Should -Be 2
        $Result.x | Should -Be 'this'
        $Result.y | Should -Be 'that'
        $Result.Keys | Sort-Object | Should -Be 'a','b','x','y'
        $Result.Values | Sort-Object | Should -Be 1,2,'that','this'
    }
    It 'can merge two custom objects' {
        $Result = [PSCustomObject]@{ a = 1 },[PSCustomObject]@{ b = 2 } | Invoke-ObjectMerge
        $Result.a | Should -Be 1
        $Result.b | Should -Be 2
        $Result.PSObject.Properties.Name | Should -Be 'a','b'
        $Result.PSObject.Properties.Value | Sort-Object | Should -Be 1,2
        $Result = [PSCustomObject]@{ a = 1; x = 3 },[PSCustomObject]@{ b = 2; y = 4 } | Invoke-ObjectMerge
        $Result.a | Should -Be 1
        $Result.b | Should -Be 2
        $Result.x | Should -Be 3
        $Result.y | Should -Be 4
        $Result.PSObject.Properties.Name | Sort-Object | Should -Be 'a','b','x','y'
        $Result.PSObject.Properties.Value | Sort-Object | Should -Be 1,2,3,4
    }
    It 'can merge more than two hashtables' {
        $Result = @{ a = 1 },@{ b = 2 },@{ c = 3 } | Invoke-ObjectMerge
        $Result.a | Should -Be 1
        $Result.b | Should -Be 2
        $Result.c | Should -Be 3
        $Result.Keys | Sort-Object | Should -Be 'a','b','c'
        $Result.Values | Sort-Object | Should -Be 1,2,3
        $Result = @{ a = 1; x = 4 },@{ b = 2; y = 5 },@{ c = 3; z = 6 } | Invoke-ObjectMerge
        $Result.a | Should -Be 1
        $Result.b | Should -Be 2
        $Result.c | Should -Be 3
        $Result.x | Should -Be 4
        $Result.y | Should -Be 5
        $Result.z | Should -Be 6
        $Result.Keys | Sort-Object | Should -Be 'a','b','c','x','y','z'
        $Result.Values | Sort-Object | Should -Be 1,2,3,4,5,6
    }
    It 'can merge more than two custom objects' {
        $Result = [PSCustomObject]@{ a = 1 },[PSCustomObject]@{ b = 2 },[PSCustomObject]@{ c = 3 } | Invoke-ObjectMerge
        $Result.a | Should -Be 1
        $Result.b | Should -Be 2
        $Result.c | Should -Be 3
        $Result.PSObject.Properties.Name | Sort-Object | Should -Be 'a','b','c'
        $Result.PSObject.Properties.Value | Sort-Object | Should -Be 1,2,3
        $Result = [PSCustomObject]@{ a = 1; x = 4 },[PSCustomObject]@{ b = 2; y = 5 },[PSCustomObject]@{ c = 3; z = 6 } | Invoke-ObjectMerge
        $Result.a | Should -Be 1
        $Result.b | Should -Be 2
        $Result.c | Should -Be 3
        $Result.x | Should -Be 4
        $Result.y | Should -Be 5
        $Result.z | Should -Be 6
        $Result.PSObject.Properties.Name | Sort-Object | Should -Be 'a','b','c','x','y','z'
        $Result.PSObject.Properties.Value | Sort-Object | Should -Be 1,2,3,4,5,6
    }
    It 'will overwrite values with same key' {
        $Result = @{ a = 1 },@{ b = 2 },@{ a = 3 } | Invoke-ObjectMerge
        $Result.a | Should -Be 3
        $Result.b | Should -Be 2
    }
}
Describe 'Invoke-Once' {
    It 'will return a function that will only be executed once' {
        function Test-Callback {}
        $Function:test = Invoke-Once { Test-Callback }
        Mock Test-Callback {}
        1..10 | ForEach-Object { test }
        Assert-MockCalled Test-Callback -Times 1
    }
    It 'will return a function that will only be executed a certain number of times' {
        function Test-Callback {}
        $Times = 5
        $Function:test = Invoke-Once -Times $Times { Test-Callback }
        Mock Test-Callback {}
        1..10 | ForEach-Object { test }
        Assert-MockCalled Test-Callback -Times $Times
    }
}
Describe 'Invoke-Operator' {
    It 'can use operators within a pipeline' {
        'one,two' | Invoke-Operator 'split' ',' | Should -Be 'one','two'
        ,(1,2,3) | Invoke-Operator 'join' ',' | Should -Be '1,2,3'
        ,(1,2,3) | Invoke-Operator 'join' "'" | Should -Be "1'2'3"
        ,(1,2,3) | Invoke-Operator 'join' "`"" | Should -Be '1"2"3'
        ,(1,2,3) | Invoke-Operator 'join' '"' | Should -Be '1"2"3'
        'abd' | Invoke-Operator 'replace' 'd','c' | Should -Be 'abc'
    }
    It 'can use arithmetic operators within a pipeline' {
        1,2,3,4,5 | Invoke-Operator '%' 2 | Should -Be 1,0,1,0,1
        1,2,3,4,5 | Invoke-Operator '+' 1 | Should -Be 2,3,4,5,6
    }
    It 'only applies valid operators' {
        'foobar' | Invoke-Operator 'fake' 'operator' | Should -Be 'foobar'
        { 'foobar' | Invoke-Operator 'WayTooLongForAn' 'operator' } | Should -Throw
        { 'foobar' | Invoke-Operator 'has space' 'operator' } | Should -Throw
    }
}
Describe 'Invoke-Partition' {
    It 'can separate an array of objects into two arrays' {
        $IsPositive = { Param($x) $x -gt 0 }
        $IsNegative = { Param($x) $x -lt 0 }
        1..10 | Invoke-Partition $IsPositive | Should -Be @(@(1,2,3,4,5,6,7,8,9,10),@())
        1..10 | Invoke-Partition $IsNegative | Should -Be @(@(),@(1,2,3,4,5,6,7,8,9,10))
        $IsEven = { Param($x) $x % 2 -eq 0 }
        0..9 | Invoke-Partition $IsEven | Should -Be @(0,2,4,6,8),@(1,3,5,7,9)
    }
}
Describe 'Invoke-PropertyTransform' {
    It 'can transform hashtable property names and values' {
        $Data = @{}
        $Data | Add-member -NotePropertyName 'fighter_power_level' -NotePropertyValue 90
        $Lookup = @{
          level = 'fighter_power_level'
        }
        $Reducer = {
          Param($Value)
          ($Value * 100) + 1
        }
        $Result = $Data | Invoke-PropertyTransform -Lookup $Lookup -Transform $Reducer
        $Result.level | Should -Be 9001
    }
    It 'can transform custom objects property names and values' {
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
        $Result = $Data | Invoke-PropertyTransform $Lookup $Reducer
        $Result.level | Should -Be 9001
    }
}
Describe 'Invoke-Reduce' {
    It 'can accept strings and integers as initial values' {
        $Add = { Param($a, $b) $a + $b }
        1,2,3,4,5 | Invoke-Reduce -Callback $Add -InitialValue 0 | Should -Be 15
        'a','b','c' | Invoke-Reduce -Callback $Add -InitialValue '' | Should -Be 'abc'
        'a','b','c' | Invoke-Reduce -InitialValue 'initial value' | Should -Be 'initial value'
        1,2,3,4,5 | Invoke-Reduce $Add 0 | Should -Be 15
        'a','b','c' | Invoke-Reduce $Add '' | Should -Be 'abc'
        'a','b','c' | Invoke-Reduce -InitialValue 'initial value' | Should -Be 'initial value'
        1,2,3,4,5 | Invoke-Reduce -Add -InitialValue 0 | Should -Be 15
        'a','b','c' | Invoke-Reduce -Add -InitialValue '' | Should -Be 'abc'
    }
    It 'can accept boolean values' {
        $Every = { Param($a, $b) $a -and $b }
        $Some = { Param($a, $b) $a -or $b }
        $AllTrue = $true,$true,$true
        $OneFalse = $true,$false,$true
        $AllTrue | Invoke-Reduce -Callback $Every -InitialValue $true | Should -Be $true
        $OneFalse | Invoke-Reduce -Callback $Some -InitialValue $true | Should -Be $true
        $AllTrue | Invoke-Reduce -Callback $Some -InitialValue $true | Should -Be $true
        $OneFalse | Invoke-Reduce -Callback $Every -InitialValue $true | Should -Be $false
        $AllTrue | Invoke-Reduce -Every -InitialValue $true | Should -Be $true
        $AllTrue | Invoke-Reduce -Some -InitialValue $true | Should -Be $true
        $OneFalse | Invoke-Reduce -Every -InitialValue $true | Should -Be $false
        $OneFalse | Invoke-Reduce -Some -InitialValue $true | Should -Be $true
    }
    It 'can accept objects as initial values' {
        $a = @{ name = 'a'; value = 1 }
        $b = @{ name = 'b'; value = 2 }
        $c = @{ name = 'c'; value = 3 }
        $Callback = { Param($Acc, $Item) $Acc[$Item.Name] = $Item.Value }
        # with inline scriptblock
        $Result = $a,$b,$c | Invoke-Reduce -Callback { Param($Acc, $Item) $Acc[$Item.Name] = $Item.Value }
        $Result.Keys | Sort-Object | Should -Be 'a','b','c'
        $Result.Values | Sort-Object | Should -Be 1,2,3
        # with scriptblock variable
        $Result = $a,$b,$c | Invoke-Reduce $Callback
        $Result.Keys | Sort-Object | Should -Be 'a','b','c'
        $Result.Values | Sort-Object | Should -Be 1,2,3
    }
    It 'should pass item index to -Callback function' {
        $Callback = {
            Param($Acc, $Item, $Index)
            $Acc + $Item +  $Index
        }
        1,2,3 | Invoke-Reduce $Callback 0 | Should -Be 9
    }
    It 'should pass -Items value to -Callback function' {
        $Callback = {
            Param($Acc, $Item, $Index, $Items)
            $Items.Length | Should -Be 3
            $Acc + $Item +  $Index
        }
        Invoke-Reduce -Items 1,2,3 $Callback 0 | Should -Be 9
    }
    It 'can combine FileInfo objects' {
        $Result = Get-ChildItem -File | Invoke-Reduce -FileInfo
        $Result.Keys | Should -Contain 'pwsh-prelude.psm1'
        $Result.Keys | Should -Contain 'pwsh-prelude.psd1'
        $Result.Values | ForEach-Object { $_ | Should -BeOfType [Long] }
    }
}
Describe 'Invoke-TakeWhile' {
    It 'can take elements until passed predicate is False' {
        $LessThan3 = { Param($x) $x -lt 3 }
        $GreaterThan10 = { Param($x) $x -gt 10 }
        1..5 | Invoke-TakeWhile $LessThan3 | Should -Be 1,2
        1,2,3,4,5,1,1 | Invoke-TakeWhile $LessThan3 | Should -Be 1,2
        Invoke-TakeWhile -InputObject (1..5) -Predicate $LessThan3 | Should -Be 1,2
        13..8 | Invoke-TakeWhile $GreaterThan10 | Should -Be 13,12,11
        Invoke-TakeWhile -InputObject (1..5) -Predicate $GreaterThan10 | Should -Be 13,12,11
    }
}
Describe 'Invoke-Tap' {
    It 'can execute a scriptblock and passthru values' {
        function Test-Function {}
        Mock Test-Function { $args }
        $Times = 10
        1..$Times | Invoke-Tap { Test-Function } | Should -Be (1..$Times)
        Assert-MockCalled Test-Function -Times $Times
        1,2,3 | Invoke-Tap { Param($x) $x + 1 } | Should -Be 2,3,4
    }
}
Describe 'Invoke-Zip(With)' {
    It 'can zip two arrays' {
        $Zipped = @('a'),@(1) | Invoke-Zip
        $Zipped.Length | Should -Be 2
        $Zipped[0] | Should -Be 'a'
        $Zipped[1] | Should -Be 1
        @('x'),@('a','b','c') | Invoke-Zip | Should -Be @('x','a'),@('empty','b'),@('empty','c')
        @('x'),@('a','b','c') | Invoke-Zip -EmptyValue '?' | Should -Be @('x','a'),@('?','b'),@('?','c')
        @(1),@(1,2,3) | Invoke-Zip -EmptyValue 0 | Should -Be @(1,1),@(0,2),@(0,3)
        @('a','b','c'),@('x') | Invoke-Zip | Should -Be @('a','x'),@('b','empty'),@('c','empty')
        @('a','b','c'),@(1,2,3) | Invoke-Zip | Should -Be @('a',1),@('b',2),@('c',3)
        Invoke-Zip @('x'),@('a','b','c') | Should -Be @('x','a'),@('empty','b'),@('empty','c')
        Invoke-Zip @('a','b','c'),@('x') | Should -Be @('a','x'),@('b','empty'),@('c','empty')
        Invoke-Zip @('a','b','c'),@(1,2,3) | Should -Be @('a',1),@('b',2),@('c',3)
        @('foo','aaa'),@('bar','bbb') | Invoke-Zip | Should -Be @('foo','bar'),@('aaa','bbb')
        'foo'.ToCharArray(),'bar'.ToCharArray() | Invoke-Zip | Should -Be @('f','b'),@('o','a'),@('o','r')
    }
    It 'can zip more than two arrays' {
        $Zipped = @('a'),@('b'),@('c') | Invoke-Zip
        $Zipped.Length | Should -Be 3
        $Zipped[0] | Should -Be 'a'
        $Zipped[1] | Should -Be 'b'
        $Zipped[2] | Should -Be 'c'
        @(1,2),@(1,2),@(1,2) | Invoke-Zip | Should -Be @(1,1,1),@(2,2,2)
        @(1,1,1),@(2,2,2),@(3,3,3) | Invoke-Zip | Should -Be @(1,2,3),@(1,2,3),@(1,2,3)
        @(1),@(2,2),@(3,3,3) | Invoke-Zip | Should -Be @(1,2,3),@('empty',2,3),@('empty','empty',3)
    }
    It 'can zip two arrays with an iteratee function' {
        $Add = { Param($a,$b) $a + $b }
        @(1,2),@(1,2) | Invoke-ZipWith $Add | Should -Be @(2,4)
        Invoke-ZipWith $Add @(1,2),@(1,2) | Should -Be @(2,4)
        @('a','a'),@('b','b') | Invoke-ZipWith $Add | Should -Be @('ab','ab')
        Invoke-ZipWith $Add @('a','a'),@('b','b') | Should -Be @('ab','ab')
        @(2,2,2),@(2,2,2) | Invoke-ZipWith $Add | Should -Be @(4,4,4)
    }
    It 'can zip more than two arrays with an iteratee function' {
        $Add = { Param($a,$b) $a + $b }
        @('1','1'),@('2','2'),@('3','3') | Invoke-ZipWith $Add | Should -Be @('123','123')
        @(1,1,1),@(2,2,2),@(3,3,3),@(4,4,4) | Invoke-ZipWith $Add | Should -Be @(10,10,10)
        @(1,1,1,1),@(2,2,2,2),@(3,3,3,3),@(4,4,4,4) | Invoke-ZipWith $Add | Should -Be @(10,10,10,10)
        Invoke-ZipWith $Add @(1,2),@(1,2),@(1,2) | Should -Be @(3,6)
        Invoke-ZipWith $Add @('a','a'),@('b','b'),@('c','c') | Should -Be @('abc','abc')
        Invoke-ZipWith $Add @('a','a'),@('b','b'),@('c','c','c') | Should -Be @('abc','abc', 'c')
        Invoke-ZipWith $Add @('a','a'),@('b','b'),@('c','c','c') -EmptyValue '#' | Should -Be @('abc','abc', '##c')
    }
}
Describe 'Join-StringsWithGrammar' {
    It 'accepts one parameter' {
        Join-StringsWithGrammar 'one' | Should -Be 'one'
        Join-StringsWithGrammar -Items 'one' | Should -Be 'one'
        'one' | Join-StringsWithGrammar | Should -Be 'one'
        Join-StringsWithGrammar @('one') | Should -Be 'one'
    }
    It 'accepts two parameter' {
        Join-StringsWithGrammar 'one','two' | Should -Be 'one and two'
        Join-StringsWithGrammar -Items 'one','two' | Should -Be 'one and two'
        'one','two' | Join-StringsWithGrammar | Should -Be 'one and two'
        Join-StringsWithGrammar @('one', 'two') | Should -Be 'one and two'
    }
    It 'accepts three or more parameters' {
        Join-StringsWithGrammar 'one','two','three' | Should -Be 'one, two, and three'
        Join-StringsWithGrammar -Items 'one','two','three' | Should -Be 'one, two, and three'
        Join-StringsWithGrammar 'one','two','three','four' | Should -be 'one, two, three, and four'
        'one','two','three' | Join-StringsWithGrammar | Should -Be 'one, two, and three'
        'one','two','three','four' | Join-StringsWithGrammar | Should -be 'one, two, three, and four'
        Join-StringsWithGrammar @('one', 'two', 'three') | Should -Be 'one, two, and three'
        Join-StringsWithGrammar @('one', 'two', 'three', 'four') | Should -Be 'one, two, three, and four'
    }
}
Describe 'Remove-Character' {
    It 'can remove single character from string' {
        '012345' | Remove-Character -At 0 | Should -Be '12345'
        '012345' | Remove-Character -At 2 | Should -Be '01345'
        '012345' | Remove-Character -At 5 | Should -Be '01234'
    }
    It 'can process an array of strings' {
        'abcc','1233' | Remove-Character -At 2 | Should -Be 'abc','123'
    }
    It 'will return entire string if out-of-bounds index' {
        '012345' | Remove-Character -At 10 | Should -Be '012345'
    }
    It 'can remove the first character of a string' {
        'XOOOOO' | Remove-Character -First | Should -Be 'OOOOO'
    }
    It 'can remove the last character of a string' {
        'OOOOOX' | Remove-Character -Last | Should -Be 'OOOOO'
    }
    It 'can remove last character from a string' {
        'A' | Remove-Character -At 0 | Should -Be ''
    }
}
Describe 'Test-Equal' {
    It 'should return true for single items (from pipeline only)' {
        42 | Test-Equal | Should -Be $true
        'foobar' | Test-Equal | Should -Be $true
        @{ foo = 'bar' } | Test-Equal | Should -Be $true
    }
    It 'can compare numbers' {
        Test-Equal 0 0 | Should -Be $true
        Test-Equal 42 42 | Should -Be $true
        Test-Equal -42 -42 | Should -Be $true
        Test-Equal 42 43 | Should -Be $false
        Test-Equal -43 -42 | Should -Be $false
        Test-Equal 3 'not a number' | Should -Be $false
        Test-Equal 4.2 4.2 | Should -Be $true
        Test-Equal 4 4.0 | Should -Be $true
        Test-Equal 4.1 4.2 | Should -Be $false
        42,42 | Test-Equal | Should -Be $true
        42 | Test-Equal 42 | Should -Be $true
        42,42,42 | Test-Equal | Should -Be $true
        43,42,42 | Test-Equal | Should -Be $false
        42,43,42 | Test-Equal | Should -Be $false
        42,42,43 | Test-Equal | Should -Be $false
        42,42 | Test-Equal 42 | Should -Be $true
        43,42 | Test-Equal 42 | Should -Be $false
        42,43 | Test-Equal 42 | Should -Be $false
        42,42 | Test-Equal 43 | Should -Be $false
    }
    It 'can compare strings' {
        Test-Equal '' '' | Should -Be $true
        Test-Equal 'foo' 'foo' | Should -Be $true
        Test-Equal 'foo' 'bar' | Should -Be $false
        Test-Equal 'foo' 7 | Should -Be $false
        'na','na','na' | Test-Equal 'na' | Should -Be $true
        'na','na','na' | Test-Equal 'meh' | Should -Be $false
        'na','meh','na' | Test-Equal 'na' | Should -Be $false
    }
    It 'can compare arrays' {
        $a = 1,2,3
        $b = 1,2,3
        $c = 5,6,7
        Test-Equal $a $b | Should -Be $true
        Test-Equal $a $c | Should -Be $false
        $a = 'a','b','c'
        $b = 'a','b','c'
        $c = 'x','y','z'
        Test-Equal $a $b | Should -Be $true
        Test-Equal $b $c | Should -Be $false
    }
    It 'can compare multi-dimensional arrays' {
        $x = 1,(1,2,3),(4,5,6),7
        $y = 1,(1,2,3),(4,5,6),7
        $z = (1,2,3),(1,2,3),(1,2,3)
        Test-Equal $x $y | Should -Be $true
        Test-Equal $x $z | Should -Be $false
        Test-Equal $x 1,(1,2,3),(4,5,6),8 | Should -Be $false
    }
    It 'can compare hashtables' {
        $A = @{ a = 'A'; b = 'B'; c = 'C' }
        $B = @{ a = 'A'; b = 'B'; c = 'C' }
        $C = @{ foo = 'bar'; bin = 'baz'; }
        Test-Equal $A $B | Should -Be $true
        Test-Equal $A $C | Should -Be $false
        $A,$B | Test-Equal | Should -Be $true
        $A,$C | Test-Equal | Should -Be $false
        $A | Test-Equal $B | Should -Be $true
        $A | Test-Equal $C | Should -Be $false
    }
    It 'can compare nested hashtables' {
        $A = @{ a = 'A'; b = 'B'; c = 'C' }
        $B = @{ a = 'A'; b = 'B'; c = 'C' }
        $C = @{ foo = 'bar'; bin = 'baz'; }
        $M = @{ a = $A; b = $B; c = $C }
        $N = @{ a = $A; b = $B; c = $C }
        $O = @{ a = $C; b = $A; c = $B }
        Test-Equal $M $N | Should -Be $true
        Test-Equal $M $O | Should -Be $false
    }
    It 'can compare custom objects' {
        $A = [PSCustomObject]@{ a = 'A'; b = 'B'; c = 'C' }
        $B = [PSCustomObject]@{ a = 'A'; b = 'B'; c = 'C' }
        $C = [PSCustomObject]@{ foo = 'bar'; bin = 'baz' }
        Test-Equal $A $B | Should -Be $true
        Test-Equal $A $C | Should -Be $false
        $A,$B | Test-Equal | Should -Be $true
        $A,$C | Test-Equal | Should -Be $false
        $A | Test-Equal $B | Should -Be $true
        $A | Test-Equal $C | Should -Be $false
    }
    It 'can compare nested custom objects' {
        $A = [PSCustomObject]@{ a = 'A'; b = 'B'; c = 'C' }
        $B = [PSCustomObject]@{ a = 'A'; b = 'B'; c = 'C' }
        $C = [PSCustomObject]@{ foo = 'bar'; bin = 'baz' }
        $M = [PSCustomObject]@{ a = $A; b = $B; c = $C }
        $N = [PSCustomObject]@{ a = $A; b = $B; c = $C }
        $O = [PSCustomObject]@{ a = $C; b = $A; c = $B }
        Test-Equal $M $N | Should -Be $true
        Test-Equal $M $O | Should -Be $false
    }
    It 'can compare other types' {
        Test-Equal $true $true | Should -Be $true
        Test-Equal $false $false | Should -Be $true
        Test-Equal $true $false | Should -Be $false
        Test-Equal $null $null | Should -Be $true
    }
}