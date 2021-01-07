[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', 'Global:foo')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', 'Global:bar')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', 'Global:baz')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
Param()

& (Join-Path $PSScriptRoot '_setup.ps1') 'productivity'

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
Describe 'ConvertTo-PlainText' -Tag 'Local', 'Remote' {
  It 'can convert secure strings to plain text strings' {
    $Message = 'Powershell is awesome'
    $Secure = $Message | ConvertTo-SecureString -AsPlainText -Force
    $Secure.ToString() | Should -Be 'System.Security.SecureString'
    $Secure | ConvertTo-PlainText | Should -Be $Message
  }
}
Describe -Skip:($IsLinux -is [Bool] -and $IsLinux) 'Find-Duplicate' -Tag 'Local', 'Remote' {
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
  It 'should support default value' {
    $Global:foo = $False
    $Global:bar = $True
    $Global:baz = $False
    $Names = 'foo', 'bar', 'baz'
    Find-FirstTrueVariable $Names | Should -Be 'bar'
    Find-FirstTrueVariable $Names -DefaultIndex 2 | Should -Be 'bar'
    Find-FirstTrueVariable $Names -DefaultValue 'boo' | Should -Be 'bar'
  }
  It 'should support default value' {
    $Global:foo = $False
    $Global:bar = $False
    $Global:baz = $False
    $Names = 'foo', 'bar', 'baz'
    Find-FirstTrueVariable $Names | Should -Be 'foo'
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
Describe 'Get-HostsContent / Update-HostsFile' -Tag 'Local', 'Remote' {
  It 'can get content of hosts file from path' {
    $Content = Get-HostsContent (Join-Path $PSScriptRoot 'fixtures/hosts')
    $Content.Count | Should -Be 3
    $Content | ForEach-Object Hostname | Should -Be 'foo', 'bar', 'foo.bar.baz'
    $Content | ForEach-Object IPAddress | Should -Be '192.168.0.111', '127.0.0.1', '192.168.0.2'
    $Content | ForEach-Object Comment | Should -Be '', 'some random comment', ''
    $Content = (Join-Path $PSScriptRoot 'fixtures/hosts') | Get-HostsContent
    $Content.Count | Should -Be 3
    $Content | ForEach-Object Hostname | Should -Be 'foo', 'bar', 'foo.bar.baz'
    $Content | ForEach-Object IPAddress | Should -Be '192.168.0.111', '127.0.0.1', '192.168.0.2'
    $Content | ForEach-Object Comment | Should -Be '', 'some random comment', ''
  }
  It 'can add an entry to a hosts file' {
    $Path = Join-Path $TestDrive 'hosts'
    New-Item $Path
    $A = @{
      Hostname = 'home'
      IPAddress = '127.0.0.1'
    }
    $B = @{
      Hostname = 'foo'
      IPAddress = '127.0.0.2'
      Comment = 'bar'
    }
    $NewIpAddress = '127.0.0.42'
    $NewComment = 'this is an updated comment'
    $Updated = $A.Clone(), @{ IPAddress = $NewIpAddress; Comment = $NewComment } | Invoke-ObjectMerge
    Update-HostsFile @A -Path $Path
    $Content = Get-HostsContent $Path
    $Content.LineNumber | Should -Be 1
    $Content.IPAddress | Should -Be $A.IPAddress
    $Content.IsValidIP | Should -Be $True
    $Content.Hostname | Should -Be $A.Hostname
    $Content.Comment | Should -Be ''
    Update-HostsFile @B -Path $Path
    $Content = Get-HostsContent $Path
    $Content[0].LineNumber | Should -Be 1
    $Content[0].IPAddress | Should -Be $A.IPAddress
    $Content[0].IsValidIP | Should -Be $True
    $Content[0].Hostname | Should -Be $A.Hostname
    $Content[0].Comment | Should -Be ''
    $Content[1].LineNumber | Should -Be 3
    $Content[1].IPAddress | Should -Be $B.IPAddress
    $Content[1].IsValidIP | Should -Be $True
    $Content[1].Hostname | Should -Be $B.Hostname
    $Content[1].Comment | Should -Be $B.Comment
    Update-HostsFile @Updated -Path $Path
    $Content = Get-HostsContent $Path
    $Content[0].LineNumber | Should -Be 1
    $Content[0].IPAddress | Should -Be $NewIpAddress
    $Content[0].IsValidIP | Should -Be $True
    $Content[0].Hostname | Should -Be $A.Hostname
    $Content[0].Comment | Should -Be $NewComment
    $Content[1].LineNumber | Should -Be 3
    $Content[1].IPAddress | Should -Be $B.IPAddress
    $Content[1].IsValidIP | Should -Be $True
    $Content[1].Hostname | Should -Be $B.Hostname
    $Content[1].Comment | Should -Be $B.Comment
    $Content = Update-HostsFile @B -Path $Path -PassThru
    $Content[0].LineNumber | Should -Be 1
    $Content[0].IPAddress | Should -Be $NewIpAddress
    $Content[0].IsValidIP | Should -Be $True
    $Content[0].Hostname | Should -Be $A.Hostname
    $Content[0].Comment | Should -Be $NewComment
    $Content[1].LineNumber | Should -Be 3
    $Content[1].IPAddress | Should -Be $B.IPAddress
    $Content[1].IsValidIP | Should -Be $True
    $Content[1].Hostname | Should -Be $B.Hostname
    $Content[1].Comment | Should -Be $B.Comment
    Remove-Item $Path
  }
  It 'supports WhatIf parameter' {
    Mock Write-Color {} -ModuleName 'Prelude'
    $Path = Join-Path $TestDrive 'hosts'
    New-Item $Path
    $A = @{
      Hostname = 'home'
      IPAddress = '127.0.0.1'
    }
    $B = @{
      Hostname = 'home'
      IPAddress = '192.168.1.1'
    }
    $C = @{
      Hostname = 'foo'
      IPAddress = '127.0.0.2'
      Comment = 'bar'
    }
    Update-HostsFile @A -Path $Path
    { Update-HostsFile @B -Path $Path -WhatIf | Out-Null } | Should -not -Throw
    { Update-HostsFile @C -Path $Path -WhatIf | Out-Null } | Should -not -Throw
    Remove-Item $Path
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
    Invoke-Speak $Text -Silent -Output ssml | Should -match "<p>$Text</p>"
  }
  It 'can output SSML with custom rate' {
    $Text = 'this should not be heard either'
    $Rate = 10
    Invoke-Speak $Text -Silent -Output ssml -Rate $Rate | Should -match "<p>$Text</p>"
    Invoke-Speak $Text -Silent -Output ssml -Rate $Rate | Should -match "<prosody rate=`"$Rate`">"
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
    './SomeFile' | Should -not -Exist
    New-File SomeFile
    New-File SomeFile
    { New-File SomeFile -WhatIf } | Should -not -Throw
    Write-Output $Content >> ./SomeFile
    './SomeFile' | Should -FileContentMatch $Content
  }
  It 'supports WhatIf parameter' {
    Mock Write-Color {} -ModuleName 'Prelude'
    { New-File 'foo.txt' -WhatIf } | Should -not -Throw
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
    $Foo | Should -not -Exist
    $Bar | Should -not -Exist
    $Baz | Should -not -Exist
  }
  It 'supports WhatIf parameter' {
    Mock Write-Color {} -ModuleName 'Prelude'
    $Foo = Join-Path $TestDrive 'foo.txt'
    New-Item $Foo
    { Remove-DirectoryForce $Foo -WhatIf } | Should -not -Throw
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
    { Rename-FileExtension -Path (Join-Path $TestDrive 'foo.bar') -TXT -WhatIf } | Should -not -Throw
    Get-ChildItem -Path $TestDrive -Name '*.txt' -File | Should -BeNullOrEmpty
    Remove-Item (Join-Path $TestDrive 'foo.bar')
  }
}
Describe 'Test-Empty' -Tag 'Local', 'Remote' {
  It 'should return true for directories with no contents' {
    $Foo = Join-Path $TestDrive 'Foo'
    $Foo | Should -not -Exist
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