[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'ForegroundColor')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Text')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Color')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'NoNewLine')]
Param()

& (Join-Path $PSScriptRoot '_setup.ps1') 'user-interface'

Describe 'ConvertTo-SpectreMarkup' -Tag 'Local', 'Remote' {
    It 'can handle empty imput' {
        '' | ConvertTo-SpectreMarkup | Should -Be ''
        ConvertTo-SpectreMarkup -Value $Null | Should -Be ''
    }
    It 'can convert to markup' {
        '{{#red hello}}' | ConvertTo-SpectreMarkup | Should -Be '[red]hello[/]'
        '{{#bold hello}} world' | ConvertTo-SpectreMarkup | Should -Be '[bold]hello[/] world'
        '{{#green hello}} world {{#blue again}}' | ConvertTo-SpectreMarkup | Should -Be '[green]hello[/] world [blue]again[/]'
        'hello world {{#blue again}}' | ConvertTo-SpectreMarkup | Should -Be 'hello world [blue]again[/]'
        'hello {{#white world}} again' | ConvertTo-SpectreMarkup | Should -Be 'hello [white]world[/] again'
    }
}
Describe 'Format-FileSize' -Tag 'Local', 'Remote' {
    It 'can format file sizes' {
        100 | Format-FileSize | Should -Be '100.0B'
        1024 | Format-FileSize | Should -Be '1.0KB'
        3000 | Format-FileSize | Should -Be '2.9KB'
        50000 | Format-FileSize | Should -Be '48.8KB'
        700000 | Format-FileSize | Should -Be '683.6KB'
        2000000 | Format-FileSize | Should -Be '1.9MB'
        4000000000 | Format-FileSize | Should -Be '3.7GB'
        60000000000 | Format-FileSize | Should -Be '55.9GB'
        9000000000000 | Format-FileSize | Should -Be '8.2TB'
    }
}
Describe 'Format-MinimumWidth' -Tag 'Local', 'Remote' {
    It 'should support empty strings' {
        '' | Format-MinimumWidth -Width 10 | Should -BeExactly '          '
    }
    It 'should support string values longer than the desired length' {
        $Value = 'foobar'
        $Value | Format-MinimumWidth -Width 3 | Should -BeExactly $Value
    }
    It 'should support string values equal to the desired length' {
        'foobar' | Format-MinimumWidth -Width 6 | Should -BeExactly 'foobar'
    }
    It 'should support string values shorter than the desired length' {
        'foobar' | Format-MinimumWidth -Width 10 | Should -BeExactly '  foobar  '
        'foobar' | Format-MinimumWidth -Width 11 | Should -BeExactly '  foobar   '
        'foo' | Format-MinimumWidth -Width 10 | Should -BeExactly '   foo    '
    }
    It 'should support strings with handlebars helpers' {
        $WithoutTemplate = '{{#blue b}}' | Format-MinimumWidth 13 -Padding '*'
        $WithoutTemplate | Should -Be '*{{#blue b}}*'
        $WithTemplate = '{{#blue b}}' | Format-MinimumWidth 13 -Padding '*' -Template
        $WithTemplate | Should -Be '******b******'
    }
    It 'should support left and right alignment' {
        '1.6B' | Format-MinimumWidth 10 -Align Left | Should -Be '1.6B      '
        '100.0B' | Format-MinimumWidth 10 -Align Left | Should -Be '100.0B    '
        '100.0B' | Format-MinimumWidth 10 -Align Right | Should -Be '    100.0B'
        '100.0KB' | Format-MinimumWidth 10 -Align Left | Should -Be '100.0KB   '
        '100.0KB' | Format-MinimumWidth 10 -Align Right | Should -Be '   100.0KB'
    }
}
Describe 'Remove-HandlebarsHelper' -Tag 'Local', 'Remote' {
    It 'should unwrap a template string and return internal <Value>' -TestCases @(
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
        @{ Value = 'RED {{#white WHITE}} {{#blue BLUE}}' }
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