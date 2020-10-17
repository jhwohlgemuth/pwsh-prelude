if (Get-Module -Name 'pwsh-handy-helpers') {
    Remove-Module -Name 'pwsh-handy-helpers'
}
Import-Module "${PSScriptRoot}\pwsh-handy-helpers.psm1" -Force

Describe 'Handy Helpers Module' {
    Context 'meta validation' {
        It 'should import exports' {
            (Get-Module -Name pwsh-handy-helpers).ExportedFunctions.Count | Should -Be 51
        }
        It 'should import aliases' {
            (Get-Module -Name pwsh-handy-helpers).ExportedAliases.Count | Should -Be 21
        }
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
        ,($false, $true, $false) | Find-FirstIndex | Should -Be 1
    }
    It 'can determine index of first item that satisfies passed predicate' {
        $Arr = 1,1,1,1,2,1,1
        $Predicate = { $args[0] -eq 2 }
        Find-FirstIndex -Values $Arr | Should -Be $null
        Find-FirstIndex -Values $Arr -Predicate $Predicate | Should -Be 4
        ,$Arr | Find-FirstIndex -Predicate $Predicate | Should -Be 4
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
Describe 'Invoke-Reduce' {
    It 'can accept strings and integers as initial values' {
        $Add = { Param($a, $b) $a + $b }
        1,2,3,4,5 | Invoke-Reduce -Callback $Add -InitialValue 0 | Should -Be 15
        'a','b','c' | Invoke-Reduce -Callback $Add -InitialValue '' | Should -Be 'abc'
        'a','b','c' | Invoke-Reduce -InitialValue 'initial value' | Should -Be 'initial value'
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
        $Result = $a,$b,$c | Invoke-Reduce -Callback $Callback
        $Result.Keys | Sort-Object | Should -Be 'a','b','c'
        $Result.Values | Sort-Object | Should -Be 1,2,3
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