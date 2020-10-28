[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', 'Global:foo')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', 'Global:bar')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', 'Global:baz')]
Param()

if (Get-Module -Name 'pwsh-handy-helpers') {
    Remove-Module -Name 'pwsh-handy-helpers'
}
Import-Module "${PSScriptRoot}\pwsh-handy-helpers.psm1" -Force

Describe 'Handy Helpers Module' {
    Context 'meta validation' {
        It 'should import exports' {
            (Get-Module -Name pwsh-handy-helpers).ExportedFunctions.Count | Should -Be 74
        }
        It 'should import aliases' {
            (Get-Module -Name pwsh-handy-helpers).ExportedAliases.Count | Should -Be 29
        }
    }
}
Describe 'Application State' {
    It 'can save and get state using ID' {
        $Id = 'pester-test'
        $Value = (New-Guid).Guid
        $State = @{ Data = @{ Value = $Value }}
        $Path = $State | Save-State $Id
        $Expected = Get-State $Id
        $Expected.Id | Should -Be $Id
        $Expected.Data.Value | Should -Be $Value
        Remove-Item $Path
    }
    It 'can save and get state using path' {
        $Path = Join-Path $TestDrive 'state.xml'
        $Id = (New-Guid).Guid
        $Value = (New-Guid).Guid
        $State = @{ Id = $Id; Data = @{ Value = $Value }}
        $State | Save-State -Path $Path
        $Expected = Get-State -Path $Path
        $Expected.Id | Should -Be $Id
        $Expected.Data.Value | Should -Be $Value
        Remove-Item $Path
    }
    It 'can test save using -WhatIf switch' {
        Mock Write-Verbose {}
        $Path = Join-Path $TestDrive 'test.xml'
        @{ Data = 42 } | Save-State -Path $Path -WhatIf
        (Test-Path $Path) | Should -Be $false
    }
}
Describe 'ConvertFrom-ByteArray' {
    it 'can convert an array of bytes to text' {
        $Expected = 'hello world'
        $Bytes = [System.Text.Encoding]::Unicode.GetBytes($Expected)
        $Bytes | ConvertFrom-ByteArray | Should -Be $Expected
        ConvertFrom-ByteArray -Data $Bytes | Should -Be $Expected
    }
    it 'can provide pass-thru for string values' {
        $Expected = 'hello world'
        $Expected | ConvertFrom-ByteArray | Should -Be $Expected
        ConvertFrom-ByteArray -Data $Expected | Should -Be $Expected
    }
}
Describe 'ConvertFrom-Html / Import-Html' {
    It 'can convert HTML strings' {
        try {
            $Supported = New-Object -ComObject "HTMLFile"
        } catch {
            $Supported = $null
        }
        if ($null -ne $Supported) {
            $Html = '<html>
                <body>
                    <a href="#">foo</a>
                    <a href="#">bar</a>
                    <a href="#">baz</a>
                </body>
            </html>' | ConvertFrom-Html
            $Html.all.tags('a') | ForEach-Object textContent | Should -Be 'foo','bar','baz'
        }
    }
    It 'can import local HTML file' {
        try {
            $Supported = New-Object -ComObject "HTMLFile"
        } catch {
            $Supported = $null
        }
        if ($null -ne $Supported) {
            $Path = Join-Path $TestDrive 'foo.html'
            '<html>
                <body>
                    <a href="#">foo</a>
                    <a href="#">bar</a>
                    <a href="#">baz</a>
                </body>
            </html>' | Out-File $Path
            $Html = Import-Html -Path $Path
            $Html.all.tags('a') | ForEach-Object textContent | Should -Be 'foo','bar','baz'
        }
    }
}
Describe 'ConvertFrom-QueryString' {
    It 'can parse single-value inputs as strings' {
        $Expected = 'hello world'
        $Expected | ConvertFrom-QueryString | Should -Be $Expected
        'foo','bar','baz' | ConvertFrom-QueryString | Should -Be 'foo','bar','baz'
    }
    It 'can parse complex query strings as objects' {
        $DeviceCode = 'ac921e83b6d04d0709a627f4ede70dee1f86204f'
        $UserCode = '7B7F-4F10'
        $InputString = "device_code=${DeviceCode}&expires_in=8999&interval=5&user_code=${UserCode}&verification_uri=https%3A%2F%2Fgithub.com%2Flogin%2Fdevice"
        $Result = $InputString | ConvertFrom-QueryString
        $Result['device_code'] | Should -Be $DeviceCode
        $Result['expires_in'] | Should -Be '8999'
        $Result['user_code'] | Should -Be $UserCode
    }
    it 'can easily be chained with other conversions' {
        $Result = [System.Text.Encoding]::Unicode.GetBytes('first=1&second=2&third=last') |
            ConvertFrom-ByteArray |
            ConvertFrom-QueryString
        $Result.first | Should -Be '1'
        $Result.second | Should -Be '2'
        $Result.third | Should -Be 'last'
    }
}
Describe 'ConvertTo-PowershellSyntax' {
    It 'can act as pass-thru for normal strings' {
        $Expected = 'normal string with not mustache templates'
        $Expected | ConvertTo-PowershellSyntax | Should -Be $Expected
    }
    It 'can convert strings with single mustache template' {
        $InputString = 'Hello {{ world }}'
        $Expected = 'Hello $($Data.world)'
        $InputString | ConvertTo-PowershellSyntax | Should -Be $Expected
    }
    It 'can convert strings with multiple mustache templates without regard to spaces' {
        $Expected = '$($Data.hello) $($Data.world)'
        '{{ hello }} {{ world }}' | ConvertTo-PowershellSyntax | Should -Be $Expected
        '{{ hello }} {{ world}}' | ConvertTo-PowershellSyntax | Should -Be $Expected
        '{{hello }} {{world}}' | ConvertTo-PowershellSyntax | Should -Be $Expected
    }
    It 'will not convert mustache helper templates' {
        $Expected = 'The sky is {{#blue blue }}'
        $Expected | ConvertTo-PowershellSyntax | Should -Be $Expected
        $Expected = '{{#red greet }}, my name $($Data.foo) $($Data.foo) is $($Data.name)'
        '{{#red greet }}, my name {{foo }} {{foo}} is {{ name }}' | ConvertTo-PowershellSyntax | Should -Be $Expected
        '{{#red Red}} {{#blue Blue}}' | ConvertTo-PowershellSyntax | Should -Be '{{#red Red}} {{#blue Blue}}'
    }
    It 'supports template variables within mustache helper templates' {
        '{{#green Hello}} {{#red {{ name }}}}' | ConvertTo-PowershellSyntax | Should -Be '{{#green Hello}} {{#red $($Data.name)}}'
        '{{#green Hello}} {{#red {{ name }} }}' | ConvertTo-PowershellSyntax | Should -Be '{{#green Hello}} {{#red $($Data.name) }}'
        '{{#green Hello}} {{#red {{ foo }}{{ bar }}}}' | ConvertTo-PowershellSyntax | Should -Be '{{#green Hello}} {{#red $($Data.foo)$($Data.bar)}}'
        '{{#green Hello}} {{#red {{foo}}{{bar}}}}' | ConvertTo-PowershellSyntax | Should -Be '{{#green Hello}} {{#red $($Data.foo)$($Data.bar)}}'
        '{{#green Hello}} {{#red {{ a }} b {{ c }} }}' | ConvertTo-PowershellSyntax | Should -Be '{{#green Hello}} {{#red $($Data.a) b $($Data.c) }}'
        '{{#green Hello}} {{#red {{a}}b{{c}}}}' | ConvertTo-PowershellSyntax | Should -Be '{{#green Hello}} {{#red $($Data.a)b$($Data.c)}}'
        '{{#green Hello}} {{#red {{ a }} b {{ c }} d}}' | ConvertTo-PowershellSyntax | Should -Be '{{#green Hello}} {{#red $($Data.a) b $($Data.c) d}}'
        '{{#green Hello}} {{#red {{a}}b{{c}}d}}' | ConvertTo-PowershellSyntax | Should -Be '{{#green Hello}} {{#red $($Data.a)b$($Data.c)d}}'
    }
}
Describe 'ConvertTo-Iso8601' {
    It 'can convert values to ISO-8601 format' {
        $Expected = '2020-07-04T00:00:00.000Z'
        'July 4, 2020' | ConvertTo-Iso8601 | Should -Be $Expected
        '07/04/2020' | ConvertTo-Iso8601 | Should -Be $Expected
        '04JUL20' | ConvertTo-Iso8601 | Should -Be $Expected
        '2020-07-04' | ConvertTo-Iso8601 | Should -Be $Expected
    }
}
Describe 'ConvertTo-QueryString' {
    It 'can convert objects into URL-encoded query strings' {
        @{} | ConvertTo-QueryString | Should -Be ''
        @{ foo = '' } | ConvertTo-QueryString | Should -Be 'foo='
        @{ foo = 'bar' } | ConvertTo-QueryString | Should -Be 'foo=bar'
        @{ a = 1; b = 2; c = 3 } | ConvertTo-QueryString | Should -Be 'a=1&b=2&c=3'
        @{ per_page = 100; page = 3 } | ConvertTo-QueryString  | Should -Be 'page=3&per_page=100'
    }
    It 'can convert objects into query strings' {
        @{} | ConvertTo-QueryString -UrlEncode | Should -Be ''
        @{ foo = '' } | ConvertTo-QueryString -UrlEncode | Should -Be 'foo%3d'
        @{ foo = 'a' },@{ bar = 'b'} | ConvertTo-QueryString -UrlEncode | Should -Be 'foo%3da','bar%3db'
        @{ foo = 'bar' } | ConvertTo-QueryString -UrlEncode | Should -Be 'foo%3dbar'
        @{ a = 1; b = 2; c = 3 } | ConvertTo-QueryString -UrlEncode | Should -Be 'a%3d1%26b%3d2%26c%3d3'
        @{ per_page = 100; page = 3 } | ConvertTo-QueryString -UrlEncode | Should -Be 'page%3d3%26per_page%3d100'
    }
}
Describe 'Find-Duplicates' {
    It 'can identify duplicate files' {
        $Same = 'these files have identical content'
        $Same | Out-File 'TestDrive:\foo'
        'unique' | Out-File 'TestDrive:\bar'
        $Same | Out-File 'TestDrive:\baz'
        mkdir 'TestDrive:\sub'
        $Same | Out-File 'TestDrive:\sub\bam'
        'also unique' | Out-File 'TestDrive:\sub\bat'
        Find-Duplicate 'TestDrive:\' | ForEach-Object { Get-Item $_.Path } | Select-Object -ExpandProperty Name | Sort-Object | Should -Be 'bam','baz','foo'
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
Describe 'Find-FirstTrueVariable' {
    It 'should support default value' {
        $Global:foo = $false
        $Global:bar = $true
        $Global:baz = $false
        $Names = 'foo','bar','baz'
        Find-FirstTrueVariable $Names | Should -Be 'bar'
        Find-FirstTrueVariable $Names -DefaultIndex 2 | Should -Be 'bar'
        Find-FirstTrueVariable $Names -DefaultValue 'boo' | Should -Be 'bar'
    }
    It 'should support default value' {
        $Global:foo = $false
        $Global:bar = $false
        $Global:baz = $false
        $Names = 'foo','bar','baz'
        Find-FirstTrueVariable $Names | Should -Be 'foo'
    }
    It 'should support default value passed as index' {
        $Global:foo = $false
        $Global:bar = $false
        $Global:baz = $false
        $Names = 'foo','bar','baz'
        Find-FirstTrueVariable $Names -DefaultIndex 2 | Should -Be 'baz'
    }
    It 'should support default value passed as value' {
        $Global:foo = $false
        $Global:bar = $false
        $Global:baz = $false
        $Names = 'foo','bar','baz'
        Find-FirstTrueVariable $Names -DefaultValue 'boo' | Should -Be 'boo'
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
Describe 'Invoke-RunApplication' {
    It 'can pass state to Init/Loop functions and execute Loop one time' {
        $Script:Count = 0
        $Init = {
            $State = $args[0]
            $State.Id.Length | Should -Be 36
            $State.Data = 'hello world'
            $Script:Count++
        }
        $Loop = {
            $State = $args[0]
            $State.Data | Should -Be 'hello world'
            $Script:Count++
        }
        Invoke-RunApplication $Init $Loop -SingleRun
        $Script:Count | Should -Be 2
    }
    It 'can persist state with -Id switch and clear state with -ClearState switch' {
        # First run with initial state passed to Invoke-RunApplication
        $Script:Count = 0
        $Script:Value = (New-Guid).Guid
        $InitialState = @{ Data = @{ Value = $Script:Value }}
        $Init = {
            $Script:Count++
        }
        $Loop = {
            $State = $args[0]
            $State | Save-State $State.Id | Out-Null
            $Script:Count++
        }
        $Script:ApplicationId = Invoke-RunApplication $Init $Loop $InitialState -SingleRun
        $Script:Count | Should -Be 2
        # Second run that loads state with Get-State
        $Init = {
            $State = $args[0]
            $State.Id | Should -Be $Script:ApplicationId
            $State.Data.Value | Should -Be $Script:Value
            $Script:Count++
        }
        $Loop = {
            $State = $args[0]
            $State.Id | Should -Be $Script:ApplicationId
            $State.Data.Value | Should -Be $Script:Value
            $Script:Count++
        }
        Invoke-RunApplication $Init $Loop -SingleRun -Id $Script:ApplicationId
        $Script:Count | Should -Be 4
        # Third run that should clear state
        $Init = {
            $State = $args[0]
            $State.Id | Should -Be $Script:ApplicationId
            $State.Data.Value | Should -Be $null
            $Script:Count++
        }
        $Loop = {
            $Script:Count++
        }
        $Path = Join-Path $Env:temp "state-$Script:ApplicationId.xml"
        (Test-Path $Path) | Should -Be $true
        Invoke-RunApplication $Init $Loop -SingleRun -Id $Script:ApplicationId -ClearState
        (Test-Path $Path) | Should -Be $false
        $Script:Count | Should -Be 6
    }
    It 'can accept initial state value' {
        $Script:Count = 0
        $Script:Value = (New-Guid).Guid
        $Init = {
            $State = $args[0]
            $State.Id.Length | Should -Be 36
            $State.Data.Value | Should -Be $Script:Value
            $Script:Count++
        }
        $Loop = {
            $State = $args[0]
            $State.Data.Value | Should -Be $Script:Value
            $Script:Count++
        }
        $InitialState = @{ Data = @{ Value = $Script:Value }}
        Invoke-RunApplication $Init $Loop $InitialState -SingleRun
        $Script:Count | Should -Be 2
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
}
# Describe 'Invoke-ListenTo' {
#     AfterEach {
#         'TestEvent' | Invoke-StopListen
#     }
#     It 'can listen to custom events and trigger actions' {
#         function Test-Callback {}
#         $EventName = 'TestEvent'
#         $Times = 5
#         Mock Test-Callback {}
#         { Test-Callback } | Invoke-ListenTo $EventName
#         1..$Times | ForEach-Object { Invoke-FireEvent $EventName -Data 'test' }
#         Assert-MockCalled Test-Callback -Times $Times
#     }
#     It 'can listen to custom events and trigger one-time action' {
#         function Test-Callback {}
#         $EventName = 'TestEvent'
#         Mock Test-Callback {}
#         { Test-Callback } | Invoke-ListenTo $EventName -Once
#         1..10 | ForEach-Object { Invoke-FireEvent $EventName -Data 'test' }
#         Assert-MockCalled Test-Callback -Times 1
#     }
# }
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
    }
    It 'only applies valid methods' {
        'foobar' | Invoke-Method 'FakeMethod' | Should -Be 'foobar'
        { 'foobar' | Invoke-Method 'Fake-Method' } | Should -Throw
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
        $Result.Keys | Should -Contain 'pwsh-handy-helpers.psm1'
        $Result.Keys | Should -Contain 'pwsh-handy-helpers.psd1'
        $Result.Keys | Should -Contain 'pwsh-handy-helpers.Tests.ps1'
        $Result.Values | ForEach-Object { $_ | Should -BeOfType [Long] }
    }
}
Describe 'Invoke-Speak (say)' {
    It 'can passthru text without speaking' {
        $Text = 'this should not be heard'
        Invoke-Speak $Text -Silent | Should -Be $null
        Invoke-Speak $Text -Silent -Output text | Should -Be $Text
    }
    It 'can output SSML' {
        $Text = 'this should not be heard either'
        Invoke-Speak $Text -Silent -Output ssml | Should -match "<p>$Text</p>"
    }
    It 'can output SSML with custom rate' {
        $Text = 'this should not be heard either'
        $Rate = 10
        Invoke-Speak $Text -Silent -Output ssml -Rate $Rate | Should -match "<p>$Text</p>"
        Invoke-Speak $Text -Silent -Output ssml -Rate $Rate | Should -match "<prosody rate=`"$Rate`">"
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
InModuleScope pwsh-handy-helpers {
    Describe 'Invoke-WebRequestBasicAuth' {
        It 'can make a simple request' {
            Mock Invoke-WebRequest { $args }
            $Token = 'token'
            $Uri = 'https://example.com/'
            $Request = Invoke-WebRequestBasicAuth $Token -Uri $Uri
            # Headers
            $Request[1].Authorization | Should -Be "Bearer $Token"
            # Method
            $Request[3] | Should -Be 'Get'
            # Uri
            $Request[5] | Should -Be $Uri
        }
        It 'can make a simple request with a username and password' {
            Mock Invoke-WebRequest { $args }
            $Username = 'user'
            $Token = 'token'
            $Uri = 'https://example.com/'
            $Request = Invoke-WebRequestBasicAuth $Username -Password $Token -Uri $Uri
            # Headers
            $Request[1].Authorization | Should -Be 'Basic dXNlcjp0b2tlbg=='
            # Method
            $Request[3] | Should -Be 'Get'
            # Uri
            $Request[5] | Should -Be $Uri
        }
        It 'can make a simple request with query parameters' {
            Mock Invoke-WebRequest { $args }
            $Token = 'token'
            $Uri = 'https://example.com/'
            $Query = @{ foo = 'bar' }
            $Request = Invoke-WebRequestBasicAuth $Token -Uri $Uri -Query $Query
            $Request[1].Authorization | Should -Be "Bearer $Token"
            $Request[5] | Should -Be "${Uri}?foo=bar"
        }
        It 'can make a simple request with URL-encoded query parameters' {
            Mock Invoke-WebRequest { $args }
            $Token = 'token'
            $Uri = 'https://example.com/'
            $Query = @{ answer = 42 }
            $Request = Invoke-WebRequestBasicAuth $Token -Uri $Uri -Query $Query -UrlEncode
            $Request[1].Authorization | Should -Be "Bearer $Token"
            $Request[5] | Should -Be "${Uri}?answer=42"
        }
        It 'can make a simple PUT request' {
            Mock Invoke-WebRequest { $args }
            $Token = 'token'
            $Uri = 'https://example.com/'
            $Request = Invoke-WebRequestBasicAuth $Token -Put -Uri $Uri -Data @{ answer = 42 }
            $Request[1] | Should -Match '"answer": '
            $Request[3].Authorization | Should -Be "Bearer $Token"
            $Request[5] | Should -Be 'Put'
            $Request[7] | Should -Be $Uri
        }
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
Describe 'New-ApplicationTemplate' {
    It 'can interpolate values into template string' {
        New-ApplicationTemplate | Should -Match 'Start-App'
        New-ApplicationTemplate | Should -Match '\$Init = {'
        New-ApplicationTemplate | Should -Match '\$Init \$Loop \$InitialState'
        New-ApplicationTemplate | Should -not -Match '  \$State = {'
        New-ApplicationTemplate -Name 'Invoke-Awesome' | Should -Match 'Invoke-Awesome'
        New-ApplicationTemplate -Name 'Invoke-Awesome' | Should -not -Match 'Start-App.ps1'
    }
    It 'can be saved to disk' {
        $Name = 'Invoke-Awesome'
        $Path = Join-Path $TestDrive "${Name}.ps1"
        (Test-Path $Path) | Should -Be $false
        New-ApplicationTemplate -Name $Name -Save -Root $TestDrive
        (Test-Path $Path) | Should -Be $true
    }
}
Describe 'New-File (touch)' {
    AfterAll {
        Remove-Item -Path .\SomeFile
    }
    It 'can create a file' {
        $Content = 'testing'
        '.\SomeFile' | Should -not -Exist
        New-File SomeFile
        Write-Output $Content >> .\SomeFile
        '.\SomeFile' | Should -FileContentMatch $Content
    }
}
Describe 'New-Template' {
    Context 'when passed an empty object' {
        $script:Expected = '<div>Hello </div>'
        It 'can return function that accepts positional parameter' {
            $function:render = New-Template '<div>Hello {{ name }}</div>'
            render @{} | Should -Be $Expected
        }
        It 'can return function when instantiated as function variable' {
            $function:render = New-Template -Template '<div>Hello {{ name }}</div>'
            render @{} | Should -Be $Expected
        }
        It 'can return function when instantiated as normal variable' {
            $renderVariable = New-Template -Template '<div>Hello {{ name }}</div>'
            & $renderVariable @{} | Should -Be $Expected
        }
        It 'can support default values' {
            $renderVariable = New-Template -Template '<div>Hello {{ name }}</div>' -DefaultValues @{ name = 'Default' }
            & $renderVariable | Should -Be '<div>Hello Default</div>'
            & $renderVariable @{ name = 'Not Default' } | Should -Be '<div>Hello Not Default</div>'
        }
    }
    It 'can return a string when passed -Data paramter' {
        'Hello {{ name }}' | New-Template -Data @{ name = 'World' } | Should -Be 'Hello World'
        '{{#green Hello}} {{ name }}' | New-Template -Data @{ name = 'World' } | Should -Be '{{#green Hello}} World'
    }
    It 'can create function from template string using mustache notation' {
        $Expected = '<div>Hello World!</div>'
        $function:render = New-Template '<div>Hello {{ name }}!</div>'
        render @{ name = 'World' } | Should -Be $Expected
        @{ name = 'World' } | render | Should -Be $Expected
    }
    It 'can create function from template string using Powershell syntax' {
        $Expected = '<div>Hello World!</div>'
        $function:render = New-Template '<div>Hello $($Data.name)!</div>'
        render @{ name = 'World' } | Should -Be $Expected
        @{ name = 'World' } | render | Should -Be $Expected
    }
    It 'can be nested within other templates' {
        $Expected = '<section>
            <h1>Title</h1>
            <div>Hello World!</div>
        </section>'
        $div = New-Template -Template '<div>{{ text }}</div>'
        $section = New-Template "<section>
            <h1>{{ title }}</h1>
            $(& $div @{text = 'Hello World!'})
        </section>"
        & $section @{ title = 'Title' } | Should -Be $Expected
    }
    It 'can be nested within other templates (with Powershell syntax)' {
        $Expected = '<section>
            <h1>Title</h1>
            <div>Hello World!</div>
        </section>'
        $div = New-Template -Template '<div>{{ text }}</div>'
        $section = New-Template "<section>
            <h1>`$(`$Data.title)</h1>
            $(& $div @{text = 'Hello World!'})
        </section>"
        & $section @{ title = 'Title' } | Should -Be $Expected
    }
    It 'can return pass-thru function that does no string interpolation' {
        $Function:render = '{{#green Hello}} {{ name }}' | New-Template
        render -Data @{ name = 'Jason' } | Should -Be '{{#green Hello}} Jason'
        render -Data @{ name = 'Jason' } -PassThru | Should -Be '{{#green Hello}} {{ name }}'
    }
}
Describe 'Remove-Character' {
    It 'can remove single character from string' {
        '012345' | Remove-Character -At 0 | Should -Be '12345'
        '012345' | Remove-Character -At 2 | Should -Be '01345'
        '012345' | Remove-Character -At 5 | Should -Be '01234'
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
Describe 'Remove-DirectoryForce (rf)' {
    It 'can create a file' {
        New-File SomeFile
        '.\SomeFile' | Should -Exist
        Remove-DirectoryForce .\SomeFile
        '.\SomeFile' | Should -Not -Exist
    }
}
Describe 'Rename-FileExtension' {
    It 'can rename file extensions using -TXT switch' {
        $Path = Join-Path $TestDrive 'foo.bar'
        New-Item $Path
        Get-ChildItem -Path $TestDrive -Name '*.bar' -File | Should -Be 'foo.bar'
        Rename-FileExtension -Path (Join-Path $TestDrive 'foo.bar') -txt
        Get-ChildItem -Path $TestDrive -Name '*.txt' -File | Should -Be 'foo.txt'
        Remove-Item (Join-Path $TestDrive 'foo.txt')
    }
    It 'can rename file extensions using -PNG switch' {
        $Path = Join-Path $TestDrive 'foo.bar'
        New-Item $Path
        Get-ChildItem -Path $TestDrive -Name '*.bar' -File | Should -Be 'foo.bar'
        Rename-FileExtension -Path (Join-Path $TestDrive 'foo.bar') -png
        Get-ChildItem -Path $TestDrive -Name '*.png' -File | Should -Be 'foo.png'
        Remove-Item (Join-Path $TestDrive 'foo.png')
    }
    It 'can rename file extensions using -GIF switch' {
        $Path = Join-Path $TestDrive 'foo.bar'
        New-Item $Path
        Get-ChildItem -Path $TestDrive -Name '*.bar' -File | Should -Be 'foo.bar'
        Rename-FileExtension -Path (Join-Path $TestDrive 'foo.bar') -gif
        Get-ChildItem -Path $TestDrive -Name '*.gif' -File | Should -Be 'foo.gif'
        Remove-Item (Join-Path $TestDrive 'foo.gif')
    }
    It 'can rename file extensions with custom value using -To parameter' {
        $Path = Join-Path $TestDrive 'foo.bar'
        New-Item $Path
        Get-ChildItem -Path $TestDrive -Name '*.bar' -File | Should -Be 'foo.bar'
        Rename-FileExtension -Path (Join-Path $TestDrive 'foo.bar') -To baz
        Get-ChildItem -Path $TestDrive -Name '*.baz' -File | Should -Be 'foo.baz'
        Remove-Item (Join-Path $TestDrive 'foo.baz')
    }
    It 'can rename file extensions with custom value using -To parameter (pipeline syntax)' {
        $Path = Join-Path $TestDrive 'foo.bar'
        New-Item $Path
        Get-ChildItem -Path $TestDrive -Name '*.bar' -File | Should -Be 'foo.bar'
        (Join-Path $TestDrive 'foo.bar') | Rename-FileExtension -To baz
        Get-ChildItem -Path $TestDrive -Name '*.baz' -File | Should -Be 'foo.baz'
        Remove-Item (Join-Path $TestDrive 'foo.baz')
    }
    It 'can rename files extension of multiple files using pipeline' {
        $ExtBefore = 'pre'
        $ExtAfter = 'post'
        $Files = @(
            (Join-Path $TestDrive "bar.$ExtBefore")
            (Join-Path $TestDrive "baz.$ExtBefore")
            (Join-Path $TestDrive "foo.$ExtBefore")
        )
        $Expected = @(
            "bar.$ExtAfter"
            "baz.$ExtAfter"
            "foo.$ExtAfter"
        )
        $Files | ForEach-Object { New-Item $_ }
        $Files | Rename-FileExtension -To 'post'
        Get-ChildItem -Path $TestDrive -Name "*.$ExtAfter" -File | Should -Be $Expected
        $Expected | ForEach-Object { Remove-Item (Join-Path $TestDrive $_) }
    }
}
Describe 'Remove-Indent' {
    It 'can remove leading spaces from single-line strings' {
        '' | Remove-Indent | Should -Be ''
        '  foobar' | Remove-Indent | Should -Be 'foobar'
        '     foobar' | Remove-Indent -Size 5 | Should -Be 'foobar'
        'foobar' | Remove-Indent -Size 0 | Should -Be 'foobar'
    }
    It 'can remove leading spaces from multi-line strings' {
        "`n  foo`n  bar`n" | Remove-Indent | Should -Be "`nfoo`nbar"
        "`n    foo`n    bar`n" | Remove-Indent -Size 4 | Should -Be "`nfoo`nbar"
    }
}
# Describe 'Test-Admin' {
#     It 'should return false if not Administrator' {
#         Test-Admin | Should -Be $false
#     }
# }
Describe 'Test-Empty' {
    It 'should return true for directories with no contents' {
        'TestDrive:\Foo' | Should -not -Exist
        mkdir 'TestDrive:\Foo'
        'TestDrive:\Foo' | Should -Exist
        Test-Empty 'TestDrive:\Foo' | Should -Be $true
        mkdir 'TestDrive:\Foo\Bar'
        mkdir 'TestDrive:\Foo\Bar\Baz'
        Test-Empty 'TestDrive:\Foo' | Should -Be $false
    }
}
Describe 'Test-Equal' {
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
    }
    It 'can compare strings' {
        Test-Equal '' '' | Should -Be $true
        Test-Equal 'foo' 'foo' | Should -Be $true
        Test-Equal 'foo' 'bar' | Should -Be $false
        Test-Equal 'foo' 7 | Should -Be $false
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
        Test-Equal $a $b | Should -Be $true
        Test-Equal $a $c | Should -Be $false
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
Describe 'Test-Installed' {
    It 'should return true if passed module is installed' {
        Test-Installed Pester | Should -Be $true
        Test-Installed NotInstalledModule | Should -Be $false
    }
}
Describe 'Write-Repeat' {
    It 'can create string of repeated characters and strings' {
        Write-Repeat 'O' | Should -Be 'O'
        Write-Repeat 'O' -Times 0 | Should -Be ''
        Write-Repeat 'O' -Times 3 | Should -Be 'OOO'
        Write-Repeat '' -Times 42 | Should -Be ''
    }
}