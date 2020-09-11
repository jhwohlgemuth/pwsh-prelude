Import-Module ./pwsh-handy-helpers.psm1

Describe "Join-StringsWithGrammar" {
    It "accepts one parameter" {
        Join-StringsWithGrammar @("one") | Should -Be "one"
    }
    It "accepts two parameter" {
        Join-StringsWithGrammar @("one", "two") | Should -Be "one and two"
    }
    It "accepts three or more parameters" {
        Join-StringsWithGrammar @("one", "two", "three") | Should -Be "one, two, and three"
        Join-StringsWithGrammar @("one", "two", "three", "four") | Should -Be "one, two, three, and four"
    }
}
Describe "New-File (touch)" {
    AfterAll {
        Remove-Item -Path .\SomeFile
    }
    It "can create a file" {
        $Content = "testing"
        New-File SomeFile
        Write-Output $Content >> .\SomeFile
        ".\SomeFile" | Should -FileContentMatch $Content
    }
}