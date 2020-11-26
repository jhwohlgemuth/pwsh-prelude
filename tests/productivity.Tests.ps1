[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', 'Global:foo')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', 'Global:bar')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', 'Global:baz')]
Param()

& (Join-Path $PSScriptRoot '_setup.ps1') 'productivity'

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
Describe 'Get-HostsContent / Update-HostsFile' {
  It 'can get content of hosts file from path' {
    $Content = Get-HostsContent (Join-Path $PSScriptRoot "fixtures\hosts")
    $Content.Count | Should -Be 3
    $Content | ForEach-Object Hostname | Should -Be 'foo','bar','foo.bar.baz'
    $Content | ForEach-Object IPAddress | Should -Be '192.168.0.111','127.0.0.1','192.168.0.2'
    $Content | ForEach-Object Comment | Should -Be '','some random comment',''
    $Content = (Join-Path $PSScriptRoot "fixtures\hosts") | Get-HostsContent
    $Content.Count | Should -Be 3
    $Content | ForEach-Object Hostname | Should -Be 'foo','bar','foo.bar.baz'
    $Content | ForEach-Object IPAddress | Should -Be '192.168.0.111','127.0.0.1','192.168.0.2'
    $Content | ForEach-Object Comment | Should -Be '','some random comment',''
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
    $Updated = $A.Clone(),@{ IPAddress = $NewIpAddress; Comment = $NewComment } | Invoke-ObjectMerge
    Update-HostsFile @A -Path $Path
    Get-HostsContent $Path | ConvertTo-Json | Should -Be @"
{
    "LineNumber":  1,
    "IPAddress":  "$($A.IPAddress)",
    "IsValidIP":  true,
    "Hostname":  "$($A.Hostname)",
    "Comment":  "$($A.Comment)"
}
"@
    Update-HostsFile @B -Path $Path
    Get-HostsContent $Path | ConvertTo-Json | Should -Be @"
[
    {
        "LineNumber":  1,
        "IPAddress":  "$($A.IPAddress)",
        "IsValidIP":  true,
        "Hostname":  "$($A.Hostname)",
        "Comment":  "$($A.Comment)"
    },
    {
        "LineNumber":  3,
        "IPAddress":  "$($B.IPAddress)",
        "IsValidIP":  true,
        "Hostname":  "$($B.Hostname)",
        "Comment":  "$($B.Comment)"
    }
]
"@
    Update-HostsFile @Updated -Path $Path
    Get-HostsContent $Path | ConvertTo-Json | Should -Be @"
[
    {
        "LineNumber":  1,
        "IPAddress":  "$NewIpAddress",
        "IsValidIP":  true,
        "Hostname":  "$($A.Hostname)",
        "Comment":  "$NewComment"
    },
    {
        "LineNumber":  3,
        "IPAddress":  "$($B.IPAddress)",
        "IsValidIP":  true,
        "Hostname":  "$($B.Hostname)",
        "Comment":  "$($B.Comment)"
    }
]
"@
    Update-HostsFile @B -Path $Path -PassThru | ConvertTo-Json | Should -Be @"
[
    {
        "LineNumber":  1,
        "IPAddress":  "$NewIpAddress",
        "IsValidIP":  true,
        "Hostname":  "$($A.Hostname)",
        "Comment":  "$NewComment"
    },
    {
        "LineNumber":  3,
        "IPAddress":  "$($B.IPAddress)",
        "IsValidIP":  true,
        "Hostname":  "$($B.Hostname)",
        "Comment":  "$($B.Comment)"
    }
]
"@
    Remove-Item $Path
  }
  It 'supports WhatIf parameter' {
    Mock Write-Color {} -ModuleName 'pwsh-prelude'
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
Describe 'Invoke-Speak (say)' {
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
Describe 'New-File (touch)' {
  AfterAll {
    Remove-Item -Path .\SomeFile
  }
  It 'can create a file' {
    Mock Write-Color {} -ModuleName 'pwsh-prelude'
    $Content = 'testing'
    '.\SomeFile' | Should -not -Exist
    New-File SomeFile
    New-File SomeFile
    { New-File SomeFile -WhatIf } | Should -not -Throw
    Write-Output $Content >> .\SomeFile
    '.\SomeFile' | Should -FileContentMatch $Content
  }
  It 'supports WhatIf parameter' {
    Mock Write-Color {} -ModuleName 'pwsh-prelude'
    { New-File 'foo.txt' -WhatIf } | Should -not -Throw
  }
}
Describe 'Remove-DirectoryForce (rf)' {
  It 'can remove a file' {
    New-File SomeFile
    '.\SomeFile' | Should -Exist
    Remove-DirectoryForce .\SomeFile
    '.\SomeFile' | Should -Not -Exist
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
    $Foo,$Bar,$Baz | Remove-DirectoryForce
    $Foo | Should -not -Exist
    $Bar | Should -not -Exist
    $Baz | Should -not -Exist
  }
  It 'supports WhatIf parameter' {
    Mock Write-Color {} -ModuleName 'pwsh-prelude'
    $Foo = Join-Path $TestDrive 'foo.txt'
    New-Item $Foo
    { Remove-DirectoryForce $Foo -WhatIf } | Should -not -Throw
    Remove-Item $Foo
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
  It 'supports WhatIf parameter' {
    Mock Write-Color {} -ModuleName 'pwsh-prelude'
    $Path = Join-Path $TestDrive 'foo.bar'
    New-Item $Path
    Get-ChildItem -Path $TestDrive -Name '*.bar' -File | Should -Be 'foo.bar'
    { Rename-FileExtension -Path (Join-Path $TestDrive 'foo.bar') -txt -WhatIf } | Should -not -Throw
    Get-ChildItem -Path $TestDrive -Name '*.txt' -File | Should -BeNullOrEmpty
    Remove-Item (Join-Path $TestDrive 'foo.bar')
  }
}
Describe -Skip 'Test-Admin' {
  It 'should return false if not Administrator' {
    Test-Admin | Should -Be $false
  }
}
Describe 'Test-Empty' {
  It 'should return true for directories with no contents' {
    'TestDrive:\Foo' | Should -not -Exist
    mkdir 'TestDrive:\Foo'
    'TestDrive:\Foo' | Should -Exist
    Test-Empty 'TestDrive:\Foo' | Should -BeTrue
    mkdir 'TestDrive:\Foo\Bar'
    mkdir 'TestDrive:\Foo\Bar\Baz'
    Test-Empty 'TestDrive:\Foo' | Should -BeFalse
  }
}
Describe 'Test-Installed' {
  It 'should return true if passed module is installed' {
    Test-Installed Pester | Should -BeTrue
    Test-Installed NotInstalledModule | Should -BeFalse
  }
}