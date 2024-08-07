﻿[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', 'Global:foo')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', 'Global:bar')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', 'Global:baz')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
Param()

& (Join-Path $PSScriptRoot '_setup.ps1') 'productivity'

Describe 'ConvertFrom-FolderStructure' -Tag 'Local', 'Remote' {
    BeforeAll {
        Set-Location $TestDrive
        New-Item (Join-Path $TestDrive 'A.txt') -ItemType 'file'
        New-Item (Join-Path $TestDrive 'B.txt') -ItemType 'file'
        New-Item (Join-Path $TestDrive 'C.txt') -ItemType 'file'
        $D = New-Item (Join-Path $TestDrive 'D') -ItemType 'directory'
        New-Item (Join-Path $D 'E.txt') -ItemType 'file'
        Set-Location (Join-Path $TestDrive 'D')
        New-Item (Join-Path $TestDrive 'D/F.txt') -ItemType 'file'
        New-Item (Join-Path $TestDrive 'D/G.txt') -ItemType 'file'
        New-Item (Join-Path $TestDrive 'D/H.txt') -ItemType 'file'
        $I = New-Item (Join-Path $TestDrive 'D/I') -ItemType 'directory'
        New-Item (Join-Path $I 'J.txt') -ItemType 'file'
    }
    AfterAll {
        Set-Location $PSScriptRoot
        Get-ChildItem $TestDrive | ForEach-Object { Remove-Item $_.FullName -Force -Recurse }
    }
    It 'can convert a folder structure to a nested hashtable' {
        $TestDrive | ConvertFrom-FolderStructure | Out-Tree | Should -Be '├─ A.txt
├─ B.txt
├─ C.txt
└─ D/
   ├─ E.txt
   ├─ F.txt
   ├─ G.txt
   ├─ H.txt
   └─ I/
      └─ J.txt
'
    }
    It 'can convert a folder structure to a nested hashtable (no extensions)' {
        $TestDrive | ConvertFrom-FolderStructure -RemoveExtensions | Out-Tree | Should -Be '├─ A
├─ B
├─ C
└─ D/
   ├─ E
   ├─ F
   ├─ G
   ├─ H
   └─ I/
      └─ J
'
    }
    It 'can limit number of tree levels' {
        $TestDrive | ConvertFrom-FolderStructure | Out-Tree -Limit 1 | Should -Be '├─ A.txt
├─ B.txt
├─ C.txt
└─ D/
'
        $TestDrive | ConvertFrom-FolderStructure | Out-Tree -Limit 2 | Should -Be '├─ A.txt
├─ B.txt
├─ C.txt
└─ D/
   ├─ E.txt
   ├─ F.txt
   ├─ G.txt
   ├─ H.txt
   └─ I/
'
        $TestDrive | ConvertFrom-FolderStructure | Out-Tree -Limit 3 | Should -Be '├─ A.txt
├─ B.txt
├─ C.txt
└─ D/
   ├─ E.txt
   ├─ F.txt
   ├─ G.txt
   ├─ H.txt
   └─ I/
      └─ J.txt
'
    }
}
Describe 'ConvertTo-AbstractSyntaxTree' -Tag 'Local', 'Remote' {
    It 'can convert the content of a file to AST' {
        $Path = Join-Path $TestDrive 'test.ps1'
        New-Item $Path
        $Code = '$Answer = 42'
        $Code | Out-File $Path
        $Ast = ConvertTo-AbstractSyntaxTree $Path
        $Ast.Extent.Text | Should -Match "^\$Code"
        Remove-Item $Path
    }
    It 'can convert a string input to AST' {
        $Code = '$Answer = 42'
        $Ast = $Code | ConvertTo-AbstractSyntaxTree
        $Ast.Extent.Text | Should -Be $Code
    }
}
Describe 'ConvertTo-ParameterString' -Tag 'Local', 'Remote' {
    It 'can convert a hastable to a parameter string (short form)' {
        $Params = [Ordered]@{
            'h' = 'words'
            'help' = 'more words'
            'V' = '42'
        }
        $Params | ConvertTo-ParameterString | Should -Be '-h words --help more words -V 42'
    }
    It 'can convert a hastable to a parameter string (long form)' {
        $Params = [Ordered]@{
            'Foo' = 'Bar'
            'Baz' = 'Qux'
        }
        $Params | ConvertTo-ParameterString | Should -Be '--foo Bar --baz Qux'
    }
    It 'can convert a hastable to a parameter string with switch variables' {
        $Params = [Ordered]@{
            'Foo' = $True
            'Baz' = $True
        }
        $Params | ConvertTo-ParameterString | Should -Be '--foo --baz'
        $Params = [Ordered]@{
            'Foo' = $False
            'Baz' = $True
        }
        $Params | ConvertTo-ParameterString | Should -Be '--baz'
        $Params = [Ordered]@{
            'hello' = 'world'
            'Foo' = $False
            'V' = '42'
            'Baz' = $True
        }
        $Params | ConvertTo-ParameterString | Should -Be '--hello world -V 42 --baz'
    }
    It 'can convert an array of hastables to parameter strings' {
        $Params = @(
            [Ordered]@{
                'Foo' = 'Bar'
                'Baz' = 'Qux'
            },
            [Ordered]@{
                'h' = 'words'
                'help' = 'more words'
                'V' = '42'
            }
        )
        $Params | ConvertTo-ParameterString | Should -Be '--foo Bar --baz Qux', '-h words --help more words -V 42'
    }
}
Describe 'ConvertTo-PlainText' -Tag 'Local', 'Remote' {
    It 'can convert secure strings to plain text strings' {
        $Message = 'PowerShell is awesome'
        $Secure = $Message | ConvertTo-SecureString -AsPlainText -Force
        $Secure.ToString() | Should -Be 'System.Security.SecureString'
        $Secure | ConvertTo-PlainText | Should -Be $Message
    }
}
Describe 'Export-EnvironmentFile' -Tag 'Local', 'Remote' {
    It 'can parse an environment file and export the variables' {
        $File = Join-Path $PSScriptRoot '\fixtures\.env'
        Test-Path Variable:THE_ANSWER | Should -BeFalse
        $File | Export-EnvironmentFile -Scope 'Global'
        Test-Path Variable:THE_ANSWER | Should -BeTrue
        $THE_ANSWER | Should -Be 42
        Remove-Item Variable:THE_ANSWER
    }
}
Describe 'Find-Duplicate' -Tag 'Local', 'Remote', 'LinuxOnly' {
    AfterEach {
        if (Test-Path (Join-Path $TestDrive 'foo')) {
            Remove-Item (Join-Path $TestDrive 'foo')
            Remove-Item (Join-Path $TestDrive 'bar')
            Remove-Item (Join-Path $TestDrive 'baz')
            Remove-Item (Join-Path $TestDrive 'sub') -Recurse -Force
        }
    }
    It 'can identify duplicate files' {
        $Foo = Join-Path $TestDrive 'foo'
        $Bar = Join-Path $TestDrive 'bar'
        $Baz = Join-Path $TestDrive 'baz'
        $Sub = Join-Path $TestDrive 'sub'
        $Same = 'these files have identical content'
        $Same | Out-File $Foo
        'unique' | Out-File $Bar
        $Same | Out-File $Baz
        mkdir $Sub
        $Same | Out-File (Join-Path $Sub 'bam')
        'also unique' | Out-File (Join-Path $Sub 'bat')
        Find-Duplicate -Path $TestDrive | ForEach-Object { Get-Item $_.Path } | Select-Object -ExpandProperty Name | Sort-Object | Should -Be 'bam', 'baz', 'foo'
    }
    It 'can identify duplicate files as a job' {
        $Foo = Join-Path $TestDrive 'foo'
        $Bar = Join-Path $TestDrive 'bar'
        $Baz = Join-Path $TestDrive 'baz'
        $Sub = Join-Path $TestDrive 'sub'
        $Same = 'these files have identical content'
        $Same | Out-File $Foo
        'unique' | Out-File $Bar
        $Same | Out-File $Baz
        mkdir $Sub
        $Same | Out-File (Join-Path $Sub 'bam')
        'also unique' | Out-File (Join-Path $Sub 'bat')
        Find-Duplicate -Path $TestDrive -AsJob
        Wait-Job -Name 'Find-Duplicate'
        $Results = Receive-Job -Name 'Find-Duplicate'
        $Results | ForEach-Object { Get-Item $_.Path } | Select-Object -ExpandProperty Name | Sort-Object | Should -Be 'bam', 'baz', 'foo'
    }
}
Describe 'Find-FirstTrueVariable' -Tag 'Local', 'Remote' {
    AfterEach {
        Remove-Variable -Name 'foo' -Scope 'Global'
        Remove-Variable -Name 'bar' -Scope 'Global'
        Remove-Variable -Name 'baz' -Scope 'Global'
    }
    It 'should support default value' {
        $Global:foo = $False
        $Global:bar = $True
        $Global:baz = $False
        $Names = 'foo', 'bar', 'baz'
        Find-FirstTrueVariable $Names | Should -Be 'bar'
        Find-FirstTrueVariable $Names -DefaultIndex 2 | Should -Be 'bar'
        Find-FirstTrueVariable $Names -DefaultValue 'boo' | Should -Be 'bar'
    }
    It 'should use first value as default value when none are true' {
        $Global:foo = $False
        $Global:bar = $False
        $Global:baz = $False
        $Names = 'foo', 'bar', 'baz'
        Find-FirstTrueVariable $Names -Verbose | Should -Be 'foo'
    }
    It 'should support default value passed as index' {
        $Global:foo = $False
        $Global:bar = $False
        $Global:baz = $False
        $Names = 'foo', 'bar', 'baz'
        Find-FirstTrueVariable $Names -DefaultIndex 2 | Should -Be 'baz'
    }
    It 'should support default value passed as value' {
        $Global:foo = $False
        $Global:bar = $False
        $Global:baz = $False
        $Names = 'foo', 'bar', 'baz'
        Find-FirstTrueVariable $Names -DefaultValue 'boo' | Should -Be 'boo'
    }
}
Describe 'Get-InitializationFileContent' -Tag 'Local', 'Remote' {
    It 'can get the content of a real Firefox profile INI file' {
        $Path = Join-Path $PSScriptRoot '\fixtures\profiles.ini'
        $Content = Get-InitializationFileContent $Path
        $Content.Keys.Count | Should -Be 6
        $Content.Profile2.Name | Should -Be 'default-release-1'
        $Content.Profile0.Name | Should -Be 'Scoop'
        $Content.General.Comment1 | Should -Be 'bar'
    }
    It 'can get the content of a real Firefox profile INI file via piped input' {
        $Path = Join-Path $PSScriptRoot '\fixtures\profiles.ini'
        $Content = $Path | Get-InitializationFileContent
        $Content.Keys.Count | Should -Be 6
        $Content.Profile2.Name | Should -Be 'default-release-1'
        $Content.Profile0.Name | Should -Be 'Scoop'
        $Content.General.Comment1 | Should -Be 'bar'
    }
}
Describe 'Get-ParameterList' -Tag 'Local', 'Remote' {
    It 'can get parameters from input code string' {
        $List = '{ Param($A, $B, $C) $A + $B + $C }' | Get-ParameterList -Verbose
        $List.Name | Should -Be 'A', 'B', 'C'
        $List.Type | Should -Be 'System.Object', 'System.Object', 'System.Object'
        $List = '{ Param([String]$A, [Switch]$B) $A + $B }' | Get-ParameterList
        $List.Name | Should -Be 'A', 'B'
        $List.Type | Should -Be 'System.String', 'System.Management.Automation.SwitchParameter'
    }
    It 'can get parameters from a simple function' {
        $List = 'Get-Maximum' | Get-ParameterList
        $List.Name | Should -Be 'Values'
        $List.Type | Should -Be 'System.Array'
        $List.Required | Should -Be $True
    }
    It 'can get parameters from a complicated function' {
        $List = 'Invoke-Menu' | Get-ParameterList
        $Names = @(
            'FolderContent'
            'HighlightColor'
            'Items'
            'Limit'
            'MultiSelect'
            'SingleSelect'
        )
        $List.Name | Should -Be $Names
    }
    It 'can get parameters from file' {
        $Path = Join-Path $TestDrive 'code.txt'
        '{ Param($A, $B, $C) $A + $B + $C }' | Out-File $Path
        $List = Get-ParameterList -Path $Path
        $List.Name | Should -Be 'A', 'B', 'C'
        $List.Type | Should -Be 'System.Object', 'System.Object', 'System.Object'
        $List.Required | Should -Be $False, $False, $False
        Remove-Item $Path
    }
}
Describe 'Get-StringPath' {
    It 'can convert strings to strings' -Tag 'Local', 'Remote' {
        $Value = 'test value'
        $Value | Get-StringPath | Should -Be $Value
        $Value = 'a', 'b', 'c'
        $Value | Get-StringPath | Should -Be $Value
    }
    It 'can convert string paths to string paths' -Tag 'Local', 'Remote', 'WindowsOnly' {
        $Value = 'C:/'
        $Value | Get-StringPath | Should -Be 'C:\'
    }
    It 'can convert string paths to string paths' -Tag 'Local', 'Remote' {
        $Path = (Get-Location).Path
        (Get-Location) | Get-StringPath | Should -Be $Path
    }
    It 'can convert string paths to string paths' -Tag 'Local', 'Remote' {
        $Item = (Get-Item (Get-Location))
        $Path = $Item.FullName
        $Item | Get-StringPath | Should -Be $Path
    }
    It 'will act as pass-thru for non-string values' -Tag 'Local', 'Remote' {
        $Value = 1
        $Value | Get-StringPath | Should -Be $Value
        $Value = @(1, 2, 3)
        $Value | Get-StringPath | Should -Be $Value
        $Value = [PSCustomObject]@{ a = 1; b = 2; c = 3 }
        $Value | Get-StringPath | Should -Be $Value
    }
}
Describe 'Invoke-GoogleSearch' -Tag 'Local', 'Remote' {
    InModuleScope 'Prelude' {
        It 'can use Out-Browser to open web page' {
            Mock Out-Browser {}
            Assert-MockCalled Out-Browser -Times 0
            Invoke-GoogleSearch 'foo'
            Assert-MockCalled Out-Browser -Times 1
        }
    }
    It 'can create search string for search on single word' {
        Invoke-GoogleSearch 'foo' -PassThru | Should -Be 'foo'
        Invoke-GoogleSearch 'foo' -Private -PassThru | Should -Be 'foo'
        'foo' | Invoke-GoogleSearch -PassThru | Should -Be 'foo'
        'foo' | Invoke-GoogleSearch -Private -PassThru | Should -Be 'foo'
        Invoke-GoogleSearch 'foo' -Exact -PassThru | Should -Be '"foo"'
        'foo' | Invoke-GoogleSearch -Exact -PassThru | Should -Be '"foo"'
        'foo' | Invoke-GoogleSearch -Site 'example.com' -PassThru | Should -Be 'foo site:example.com'
        'foo' | Invoke-GoogleSearch -Site 'example.com' -Exact -PassThru | Should -Be '"foo" site:example.com'
    }
    It 'can create search string from array input via pipe' {
        'foo', 'bar' | Invoke-GoogleSearch -PassThru | Should -Be 'foo OR bar'
        'foo', 'bar' | Invoke-GoogleSearch -BinaryOperation 'AND' -PassThru | Should -Be 'foo AND bar'
    }
    It 'can include and exclude multiple terms' {
        'foo' | Invoke-GoogleSearch -Exclude 'bar', 'baz' -PassThru | Should -Be 'foo -bar -baz'
        'foo' | Invoke-GoogleSearch -Include 'a' -Exclude 'b', 'c' -PassThru | Should -Be 'foo +a -b -c'
    }
    It 'can search site subdomains' {
        Invoke-GoogleSearch -Site 'example.com' -PassThru | Should -Be 'site:example.com'
        Invoke-GoogleSearch -Site 'example.com' -Subdomain -PassThru | Should -Be 'site:example.com -inurl:www'
        'foo' | Invoke-GoogleSearch -Site 'example.com' -PassThru | Should -Be 'foo site:example.com'
        'foo' | Invoke-GoogleSearch -Site 'example.com' -Subdomain -PassThru | Should -Be 'foo site:example.com -inurl:www'
    }
    It 'can add multiple operators' {
        'foo' | Invoke-GoogleSearch -PassThru -Related 'example.com' -Source 'bar' -Text 'baz' -Url 'this' -Type 'pdf' | Should -Be 'foo related:example.com source:bar intext:baz inurl:this filetype:pdf'
    }
    It 'can add custom search operators' {
        'foo' | Invoke-GoogleSearch -Custom '(this AND that)' -PassThru | Should -Be 'foo (this AND that)'
    }
    It 'can URL encode search string' {
        'foo:bar' | Invoke-GoogleSearch -Encode -PassThru | Should -Be 'foo%3abar'
    }
}
Describe 'Invoke-Pack' -Tag 'Local', 'Remote' {
    BeforeEach {
        Set-Location $TestDrive
        $A = New-Item (Join-Path $TestDrive 'A.txt') -ItemType 'file'
        $B = New-Item (Join-Path $TestDrive 'B.txt') -ItemType 'file'
        $C = New-Item (Join-Path $TestDrive 'C.txt') -ItemType 'file'
        $D = New-Item (Join-Path $TestDrive 'D') -ItemType 'directory'
        $E = New-Item (Join-Path $D 'E.txt') -ItemType 'file'
        'AAA' | Set-Content $A
        'BBB' | Set-Content $B
        'CCC' | Set-Content $C
        'EEE' | Set-Content $E
        Set-Location (Join-Path $TestDrive 'D')
        $F = New-Item (Join-Path $TestDrive 'D/F.txt') -ItemType 'file'
        $G = New-Item (Join-Path $TestDrive 'D/G.txt') -ItemType 'file'
        $H = New-Item (Join-Path $TestDrive 'D/H.txt') -ItemType 'file'
        $I = New-Item (Join-Path $TestDrive 'D/I') -ItemType 'directory'
        $J = New-Item (Join-Path $I 'J.txt') -ItemType 'file'
        'FFF' | Set-Content $F
        'GGG' | Set-Content $G
        'HHH' | Set-Content $H
        'JJJ' | Set-Content $J
        Set-Location $TestDrive
    }
    AfterEach {
        Set-Location $PSScriptRoot
        Get-ChildItem $TestDrive | ForEach-Object { Remove-Item $_.FullName -Force -Recurse }
    }
    It 'can pack files within a directory (directoryinfo)' {
        $Path = $TestDrive | Invoke-Pack
        $Expected = 'AAA', 'BBB', 'CCC', 'EEE', 'FFF', 'GGG', 'HHH', 'JJJ'
        $Content = Import-Clixml $Path | ForEach-Object { $_.Content }
        $Content | Should -Be $Expected
    }
    It 'can pack files within a directory (fileinfo array)' {
        $Path = $A, $B, $C, $E | Invoke-Pack
        $Expected = 'AAA', 'BBB', 'CCC', 'EEE'
        $Content = Import-Clixml $Path | ForEach-Object { $_.Content }
        $Content | Should -Be $Expected
    }
    It 'can pack files within a directory (directoryinfo array)' {
        $Path = (Get-Item $TestDrive) | Invoke-Pack
        $Expected = 'AAA', 'BBB', 'CCC', 'EEE', 'FFF', 'GGG', 'HHH', 'JJJ'
        $Content = Import-Clixml $Path | ForEach-Object { $_.Content }
        $Content | Should -Be $Expected
    }
    It 'can pack files within a directory (-PathList)' {
        $Path = Invoke-Pack -Items $TestDrive
        $Expected = 'AAA', 'BBB', 'CCC', 'EEE', 'FFF', 'GGG', 'HHH', 'JJJ'
        $Content = Import-Clixml $Path | ForEach-Object { $_.Content }
        $Content | Should -Be $Expected
    }
    It 'can pack files within a directory (-DirectoryList)' {
        $Path = Invoke-Pack -Items (Get-Item $TestDrive)
        $Expected = 'AAA', 'BBB', 'CCC', 'EEE', 'FFF', 'GGG', 'HHH', 'JJJ'
        $Content = Import-Clixml $Path | ForEach-Object { $_.Content }
        $Content | Should -Be $Expected
    }
}
Describe 'Invoke-Unpack' -Tag 'Local', 'Remote' {
    BeforeEach {
        Set-Location $TestDrive
        $A = New-Item (Join-Path $TestDrive 'A.txt') -ItemType 'file'
        $B = New-Item (Join-Path $TestDrive 'B.txt') -ItemType 'file'
        $C = New-Item (Join-Path $TestDrive 'C.txt') -ItemType 'file'
        New-Item (Join-Path $TestDrive 'D') -ItemType 'directory'
        $E = New-Item (Join-Path $TestDrive 'D/E.txt') -ItemType 'file'
        $F = New-Item (Join-Path $TestDrive 'D/F.txt') -ItemType 'file'
        $G = New-Item (Join-Path $TestDrive 'D/G.txt') -ItemType 'file'
        $H = New-Item (Join-Path $TestDrive 'D/H.txt') -ItemType 'file'
        $I = New-Item (Join-Path $TestDrive 'D/I') -ItemType 'directory'
        $J = New-Item (Join-Path $I 'J.txt') -ItemType 'file'
        New-Item (Join-Path $TestDrive 'K') -ItemType 'directory'
        'AAA' | Set-Content $A
        'BBB' | Set-Content $B
        'CCC' | Set-Content $C
        'EEE' | Set-Content $E
        'FFF' | Set-Content $F
        'GGG' | Set-Content $G
        'HHH' | Set-Content $H
        'JJJ' | Set-Content $J
    }
    AfterEach {
        Set-Location $PSScriptRoot
        Get-ChildItem $TestDrive | ForEach-Object { Remove-Item $_.FullName -Force -Recurse }
    }
    It 'can unpack files from a pack (string)' {
        $PackPath = $TestDrive | Invoke-Pack
        $Expected = 'A.txt', 'B.txt', 'C.txt', 'D', 'E.txt', 'F.txt', 'G.txt', 'H.txt', 'I', 'J.txt'
        Invoke-Unpack $PackPath
        Get-ChildItem (Join-Path $TestDrive 'packed') -Recurse | ForEach-Object 'Name' | Sort-Object | Should -Be $Expected
    }
    It 'can unpack files from a pack (file)' {
        $PackPath = $TestDrive | Invoke-Pack
        $Expected = 'A.txt', 'B.txt', 'C.txt', 'D', 'E.txt', 'F.txt', 'G.txt', 'H.txt', 'I', 'J.txt'
        Invoke-Unpack -File (Get-Item $PackPath)
        Get-ChildItem (Join-Path $TestDrive 'packed') -Recurse | ForEach-Object 'Name' | Sort-Object | Should -Be $Expected
    }
    It 'can unpack from different directory' {
        $PackPath = $TestDrive | Invoke-Pack
        $Expected = 'A.txt', 'B.txt', 'C.txt', 'D', 'E.txt', 'F.txt', 'G.txt', 'H.txt', 'I', 'J.txt'
        Set-Location (Join-Path $TestDrive 'K')
        Invoke-Unpack $PackPath
        Get-ChildItem (Join-Path $TestDrive 'K/packed') -Recurse | ForEach-Object 'Name' | Sort-Object | Should -Be $Expected
    }
}
Describe -Skip:($IsLinux -is [Bool] -and $IsLinux) 'Invoke-Speak (say)' -Tag 'Local', 'Remote' {
    It 'can passthru text without speaking' {
        $Text = 'this should not be heard'
        Invoke-Speak $Text -Silent | Should -BeNullOrEmpty
        Invoke-Speak $Text -Silent -Output text | Should -Be $Text
    }
    It 'can output SSML' {
        $Text = 'this should not be heard either'
        Invoke-Speak $Text -Silent -Output ssml | Should -Match "<p>$Text</p>"
    }
    It 'can output SSML with custom rate' {
        $Text = 'this should not be heard either'
        $Rate = 10
        Invoke-Speak $Text -Silent -Output ssml -Rate $Rate | Should -Match "<p>$Text</p>"
        Invoke-Speak $Text -Silent -Output ssml -Rate $Rate | Should -Match "<prosody rate=`"$Rate`">"
    }
}
Describe 'Measure-Performance' -Tag 'Local', 'Remote' {
    It 'can provide measures of execution performance (ticks or milliseconds)' {
        $Runs = 10
        $Results = { Get-Process } | Measure-Performance -Runs $Runs
        $Results.Runs | Should -HaveCount $Runs
        $Results.Min | Should -BeLessOrEqual $Results.Max
        $ResultsMilliseconds = { Get-Process } | Measure-Performance -Runs $Runs -Milliseconds
        $ResultsMilliseconds.Runs | Should -HaveCount $Runs
        $ResultsMilliseconds.Min | Should -BeLessOrEqual $ResultsMilliseconds.Max
        $Results.Mean | Should -BeGreaterThan $ResultsMilliseconds.Mean
    }
}
Describe 'New-File (touch)' -Tag 'Local', 'Remote' {
    AfterAll {
        Remove-Item -Path ./SomeFile
    }
    It 'can create a file' {
        Mock Write-Color {} -ModuleName 'Prelude'
        $Content = 'testing'
        './SomeFile' | Should -Not -Exist
        New-File SomeFile
        New-File SomeFile
        { New-File SomeFile -WhatIf } | Should -Not -Throw
        Write-Output $Content >> ./SomeFile
        './SomeFile' | Should -FileContentMatch $Content
    }
    It 'supports WhatIf parameter' {
        Mock Write-Color {} -ModuleName 'Prelude'
        { New-File 'foo.txt' -WhatIf } | Should -Not -Throw
    }
}
Describe 'Out-Tree' -Tag 'Local' {
    It 'can handle empty objects' {
        $Expected = $Null
        @() | Out-Tree | Should -Be $Expected
    }
    It 'can create tree for single level object, <Value>' {
        $Expected = '├─ Foo
├─ Bar
└─ Baz
'
        @{
            Foo = 1
            Bar = 2
            Baz = 3
        } | Out-Tree | Should -Be $Expected
    }
    It 'can create tree for single level objects (input passed as parameter)' {
        $Expected = '├─ Foo
├─ Bar
└─ Baz
'
        Out-Tree @{ Foo = 1; Bar = 2; Baz = 3 } | Should -Be $Expected
    }
    It 'can create tree for nested inputs' {
        $Expected = '├─ Foo
├─ Baz/
│  ├─ Bar
│  ├─ Baz
│  └─ Boot/
│     ├─ Bar
│     ├─ Baz
│     └─ Foo
└─ Bar/
   ├─ a
   ├─ b
   └─ c
'
        $InputObject = @{
            Foo = 1
            Baz = @{
                Bar = 2
                Baz = 3
                Boot = @{
                    Foo = 9
                    Bar = 5
                    Baz = 6
                }
            }
            Bar = @{
                a = 10
                b = 20
                c = 30
            }
        }
        $InputObject | Out-Tree | Write-Color -Cyan
        # $InputObject | Out-Tree | Should -Be $Expected
    }
    It 'can output tree structure from Get-ChildItem results' {
        (Get-ChildItem).GetEnumerator() | Out-Tree | Write-Color -Cyan
    }
}
Describe 'Remove-DirectoryForce (rf)' -Tag 'Local', 'Remote' {
    It 'can remove a file' {
        New-File SomeFile
        './SomeFile' | Should -Exist
        Remove-DirectoryForce ./SomeFile
        './SomeFile' | Should -Not -Exist
    }
    It 'can remove multiple files' {
        $Foo = Join-Path $TestDrive 'foo.txt'
        $Bar = Join-Path $TestDrive 'bar.txt'
        $Baz = Join-Path $TestDrive 'baz.txt'
        New-Item $Foo
        New-Item $Bar
        New-Item $Baz
        $Foo | Should -Exist
        $Bar | Should -Exist
        $Baz | Should -Exist
        $Foo, $Bar, $Baz | Remove-DirectoryForce
        $Foo | Should -Not -Exist
        $Bar | Should -Not -Exist
        $Baz | Should -Not -Exist
    }
    It 'supports WhatIf parameter' {
        Mock Write-Color {} -ModuleName 'Prelude'
        $Foo = Join-Path $TestDrive 'foo.txt'
        New-Item $Foo
        { Remove-DirectoryForce $Foo -WhatIf } | Should -Not -Throw
        Remove-Item $Foo
    }
}
Describe 'Rename-FileExtension' -Tag 'Local', 'Remote' {
    It 'can rename file extensions using -TXT switch' {
        $Path = Join-Path $TestDrive 'foo.bar'
        New-Item $Path
        Get-ChildItem -Path $TestDrive -Name '*.bar' -File | Should -Be 'foo.bar'
        Rename-FileExtension -Path (Join-Path $TestDrive 'foo.bar') -TXT
        Get-ChildItem -Path $TestDrive -Name '*.txt' -File | Should -Be 'foo.txt'
        Remove-Item (Join-Path $TestDrive 'foo.txt')
    }
    It 'can rename file extensions using -PNG switch' {
        $Path = Join-Path $TestDrive 'foo.bar'
        New-Item $Path
        Get-ChildItem -Path $TestDrive -Name '*.bar' -File | Should -Be 'foo.bar'
        Rename-FileExtension -Path (Join-Path $TestDrive 'foo.bar') -PNG
        Get-ChildItem -Path $TestDrive -Name '*.png' -File | Should -Be 'foo.png'
        Remove-Item (Join-Path $TestDrive 'foo.png')
    }
    It 'can rename file extensions using -GIF switch' {
        $Path = Join-Path $TestDrive 'foo.bar'
        New-Item $Path
        Get-ChildItem -Path $TestDrive -Name '*.bar' -File | Should -Be 'foo.bar'
        Rename-FileExtension -Path (Join-Path $TestDrive 'foo.bar') -GIF
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
    It 'supports WhatIf parameter' {
        Mock Write-Color {} -ModuleName 'Prelude'
        $Path = Join-Path $TestDrive 'foo.bar'
        New-Item $Path
        Get-ChildItem -Path $TestDrive -Name '*.bar' -File | Should -Be 'foo.bar'
        { Rename-FileExtension -Path (Join-Path $TestDrive 'foo.bar') -TXT -WhatIf } | Should -Not -Throw
        Get-ChildItem -Path $TestDrive -Name '*.txt' -File | Should -BeNullOrEmpty
        Remove-Item (Join-Path $TestDrive 'foo.bar')
    }
}
Describe 'Test-Admin' -Tag 'Local' {
    It 'can test if a user is an administrator' {
        Test-Admin | Should -Be $False
    }
}
Describe 'Test-Command' -Tag 'Local', 'Remote' {
    It 'should determine if a command is available in the current shell' -Tag 'WindowsOnly' {
        Test-Command 'dir' | Should -BeTrue
        Test-Command 'invalidCommand' | Should -BeFalse
    }
    It 'should determine if a command is available in the current shell' -Tag 'LinuxOnly' {
        Test-Command 'which' | Should -BeTrue
        Test-Command 'invalidCommand' | Should -BeFalse
    }
}
Describe 'Test-Empty' -Tag 'Local', 'Remote' {
    It 'should return true for directories with no contents' {
        $Foo = Join-Path $TestDrive 'Foo'
        $Foo | Should -Not -Exist
        mkdir $Foo
        $Foo | Should -Exist
        Test-Empty $Foo | Should -BeTrue
        $Bar = Join-Path $Foo 'Bar'
        $Baz = Join-Path $Bar 'Baz'
        mkdir $Bar
        mkdir $Baz
        Test-Empty $Foo | Should -BeFalse
        Remove-Item $Foo -Recurse
    }
}
Describe 'Test-Installed' -Tag 'Local', 'Remote' {
    It 'should return true if passed module is installed' {
        Test-Installed Pester | Should -BeTrue
        Test-Installed NotInstalledModule | Should -BeFalse
    }
}