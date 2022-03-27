[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'ForegroundColor')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Text')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Color')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'NoNewLine')]
Param()

& (Join-Path $PSScriptRoot '_setup.ps1') 'user-interface'

Describe -Skip 'Write-Color' -Tag 'Local', 'Remote' {
    BeforeAll {
        It 'should write nothing when passed an empty string' {
            Mock Write-Host {} -ModuleName Prelude
            '' | Write-Color -Cyan
            Should -Invoke Write-Host -Exactly 1 -ModuleName Prelude
        }
    }
    It 'should function like Write-Host and allow passing color as a string or switch' {
        Mock Write-Host {
            Param(
                [String] $ForegroundColor
            )
        } -ModuleName Prelude -ParameterFilter { $ForegroundColor -eq 'Cyan' }
        $Expected = 'Hello World'
        $Expected | Write-Color -Cyan
        $Expected | Write-Color -Color 'Cyan'
        $Expected | Write-Color -Cyan -PassThru | Should -Be $Expected
        Should -Invoke Write-Host -Exactly 3 -ModuleName Prelude
    }
    It 'can interpolate values using mustache template syntax' {
        Mock Write-Host {} -ModuleName Prelude
        'a {{#red b}}' | Write-Color -Cyan
        '{{#blue a}} {{#red b}}' | Write-Color -Cyan
        '{{#blue a}} {{#red b}} c' | Write-Color -Cyan
        Should -Invoke Write-Host -Exactly 11 -ModuleName Prelude
    }
}
Describe -Skip 'Write-Label' -Tag 'Local', 'Remote' {
    It 'uses Write-Color to write label text' {
        $Expected = 'Hello World'
        $Filter = { ($Text -eq "${Expected} ") -and ($Color -eq 'Magenta') }
        Mock Write-Color {
            Param(
                [Parameter(Position = 0)]
                [String] $Text,
                [String] $Color,
                [Switch] $NoNewLine
            )
        } -ModuleName Prelude -ParameterFilter $Filter
        $Expected | Write-Label -Color 'Magenta'
        Should -Invoke Write-Color -Exactly 1 -ModuleName Prelude
    }
}
Describe -Skip 'Write-Title' -Tag 'Local', 'Remote' {
    It 'provides pass-thru parameter' {
        Mock Write-Host {} -ModuleName Prelude
        $Expected = 'This is a test string'
        $Expected | Write-Title -PassThru | Should -Be $Expected
    }
    It 'uses Write-Color to write title text' {
        Mock Write-Color {} -ModuleName Prelude
        $Expected = 'This is a test string'
        $Expected | Write-Title
        Should -Invoke Write-Color -Exactly 3 -ModuleName Prelude
    }
    It 'uses Write-Color to write title text (with TextColor)' {
        Mock Write-Color {} -ModuleName Prelude
        $Expected = 'This is a test string'
        $Expected | Write-Title -TextColor 'Red'
        Should -Invoke Write-Color -Exactly 3 -ModuleName Prelude
    }
}
Describe -Skip 'Write-BarChart' -Tag 'Local', 'Remote' {
    It 'creates horizontal bar charts' {
        Mock Write-Color {} -ModuleName Prelude
        @{ red = 55; white = 30; blue = 200 } | Write-BarChart -WithColor -ShowValues
        'red', 55, 'white', 30, 'blue', 200 | Write-BarChart
        1..8 | New-Matrix 4, 2 | Write-BarChart
        Should -Invoke Write-Color -Exactly 20 -ModuleName Prelude
    }
}