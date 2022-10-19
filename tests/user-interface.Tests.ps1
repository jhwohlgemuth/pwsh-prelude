[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'ForegroundColor')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Text')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Color')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'NoNewLine')]
Param()

& (Join-Path $PSScriptRoot '_setup.ps1') 'user-interface'


Describe 'Format-MinimumWidth' -Tag 'Local', 'Remote' {
    It 'Should support empty strings' {
        '' | Format-MinimumWidth -Width 10 | Should -BeExactly '          '
    }
}
Describe 'Remove-HandlebarsHelper' -Tag 'Local', 'Remote' {
    It 'Should unwrap a template string and return internal <Value>' -TestCases @(
        @{ Value = '{{#red Hello World}}' }
        @{ Value = '{{#red Hello World }}' }
        @{ Value = '{{#red  Hello World}}' }
        @{ Value = '{{#red  Hello World }}' }
        @{ Value = '{{=white Hello World}}' }
        @{ Value = '{{=white Hello World }}' }
        @{ Value = '{{=white  Hello World}}' }
        @{ Value = '{{=white  Hello World }}' }
        @{ Value = '{{-blue Hello World}}' }
        @{ Value = '{{-blue Hello World }}' }
        @{ Value = '{{-blue  Hello World}}' }
        @{ Value = '{{-blue  Hello World }}' }
    ) {
        $Value | Remove-HandlebarsHelper | Should -Be 'Hello World'
    }
    It 'should support processing string <Value> with multiple templates' -TestCases @(
        @{ Value = '{{#red RED}} WHITE {{#blue BLUE}}' }
        @{ Value = '{{#red RED}} {{#white WHITE}} BLUE' }
        @{ Value = 'RED {{#white WHITE}} BLUE' }
    ) {
        $Value | Remove-HandlebarsHelper | Should -Be 'RED WHITE BLUE'
    }
    It 'should support processing a list of template strings' {
        $Expected = 'RED', 'WHITE', 'BLUE'
        '{{#red RED}}', '{{#white WHITE}}', '{{#blue BLUE}}' | Remove-HandlebarsHelper | Should -Be $Expected
    }
}
Describe 'Write-Color' -Tag 'Local', 'Remote' {
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
Describe 'Write-Label' -Tag 'Local', 'Remote' {
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
Describe 'Write-Title' -Tag 'Local', 'Remote' {
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
Describe 'Write-BarChart' -Tag 'Local' {
    It 'creates horizontal bar charts' {
        Mock Write-Color {} -ModuleName Prelude
        @{ red = 55; white = 30; blue = 200 } | Write-BarChart -WithColor -ShowValues
        'red', 55, 'white', 30, 'blue', 200 | Write-BarChart
        1..8 | New-Matrix 4, 2 | Write-BarChart
        Should -Invoke Write-Color -Exactly 20 -ModuleName Prelude
    }
}