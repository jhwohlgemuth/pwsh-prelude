Import-Module ./pwsh-handy-helpers.psm1

Describe "Find-Duplicates" {
    It "can identify duplicate files" {
        # Under construction
    }
}
Describe "Join-StringsWithGrammar" {
    It "accepts one parameter" {
        Join-StringsWithGrammar @("one") | Should -Be "one"
    }
    It "accepts two parameter" {
        Join-StringsWithGrammar @("one", "two") | Should -Be "one and two"
    }
    It "accepts three or more parameters" {
        Join-StringsWithGrammar @("one", "two", "three") | Should -Be "one, two, and three"
        Join-StringsWithGrammar @("one", "two", "three", "four") | Should -be "one, two, three, and four"
    }
}
Describe "New-File (touch)" {
    AfterAll {
        Remove-Item -Path .\SomeFile
    }
    It "can create a file" {
        $Content = "testing"
        ".\SomeFile" | Should -Not -Exist
        New-File SomeFile
        Write-Output $Content >> .\SomeFile
        ".\SomeFile" | Should -FileContentMatch $Content
    }
}
Describe "Remove-DirectoryForce (rf)" {
    It "can create a file" {
        New-File SomeFile
        ".\SomeFile" | Should -Exist
        Remove-DirectoryForce .\SomeFile
        ".\SomeFile" | Should -Not -Exist
    }
}
# Describe "Test-Admin" {
#     It "should return false if not Administrator" {
#         Test-Admin | Should -Be $false
#     }
# }
Describe "Test-Empty" {
    It "should return true for directories with no contents" {
        "TestDrive:\Foo" | Should -Not -Exist
        mkdir "TestDrive:\Foo"
        "TestDrive:\Foo" | Should -Exist
        Test-Empty "TestDrive:\Foo" | Should -Be $true
        mkdir "TestDrive:\Foo\Bar"
        mkdir "TestDrive:\Foo\Bar\Baz"
        Test-Empty "TestDrive:\Foo" | Should -Be $false
    }
}
Describe "Test-Installed" {
    It "should return true if passed module is installed" {
        Test-Installed Pester | Should -Be $true
        Test-Installed NotInstalledModule | Should -Be $false
    }
}
Describe "Invoke-Speak (say)" {
    It "can passthru text without speaking" {
        $Text = "this should not be heard"
        Invoke-Speak $Text -Silent | Should -Be $Text
    }
    It "can output SSML" {
        $Text = "this should not be heard either"
        Invoke-Speak $Text -Silent -Output ssml | Should -Match "<p>$Text</p>"
    }
    It "can output SSML with custom rate" {
        $Text = "this should not be heard either"
        $Rate = 10
        Invoke-Speak $Text -Silent -Output ssml -Rate $Rate | Should -Match "<p>$Text</p>"
        Invoke-Speak $Text -Silent -Output ssml -Rate $Rate | Should -Match "<prosody rate=`"$Rate`">"
    }
}