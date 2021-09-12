& (Join-Path $PSScriptRoot '_setup.ps1') 'data'

$ExcelSupported = try {
    New-Object -ComObject 'Excel.Application'
    $True
} catch {
    $False
}

Describe 'Format-MoneyValue' -Tag 'Local', 'Remote' {
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
    It 'can process arrays of values' {
        1..5 | Format-MoneyValue | Should -Be '$1.00', '$2.00', '$3.00', '$4.00', '$5.00'
        '$1.00', '$2.00', '$3.00', '$4.00', '$5.00' | Format-MoneyValue -AsNumber | Should -Be (1..5)
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
        { $False | Format-MoneyValue } | Should -Throw 'Format-MoneyValue only accepts strings and numbers'
    }
}
Describe 'Get-Plural/Singular' -Tag 'Local', 'Remote' {
    It 'can return plural version of a noun' {
        'goose' | Get-Plural | Should -Be 'geese'
        'mouse' | Get-Plural | Should -Be 'mice'
        'house' | Get-Plural | Should -Be 'houses'
        'banana' | Get-Plural | Should -Be 'bananas'
        'quiz' | Get-Plural | Should -Be 'quizzes'
        'geese' | Get-Plural | Should -Be 'geese'
        'houses' | Get-Plural | Should -Be 'houses'
        'quizzes' | Get-Plural | Should -Be 'quizzes'
        'bananas' | Get-Plural | Should -Be 'bananas'
        'buffalo' | Get-Plural | Should -Be 'buffalo'
        'money' | Get-Plural | Should -Be 'money'
        'radius' | Get-Plural | Should -Be 'radii'
        'matrix' | Get-Plural | Should -Be 'matrices'
        'index' | Get-Plural | Should -Be 'indices'
        'vertex' | Get-Plural | Should -Be 'vertices'
    }
    It 'can return singular version of a noun' {
        'geese' | Get-Singular | Should -Be 'goose'
        'mice' | Get-Singular | Should -Be 'mouse'
        'houses' | Get-Singular | Should -Be 'house'
        'bananas' | Get-Singular | Should -Be 'banana'
        'quizzes' | Get-Singular | Should -Be 'quiz'
        'goose' | Get-Singular | Should -Be 'goose'
        'house' | Get-Singular | Should -Be 'house'
        'quiz' | Get-Singular | Should -Be 'quiz'
        'banana' | Get-Singular | Should -Be 'banana'
        'buffalo' | Get-Singular | Should -Be 'buffalo'
        'money' | Get-Singular | Should -Be 'money'
        'radii' | Get-Singular | Should -Be 'radius'
        'matrices' | Get-Singular | Should -Be 'matrix'
        'indices' | Get-Singular | Should -Be 'index'
        'vertices' | Get-Singular | Should -Be 'vertex'
        'aborigines' | Get-Singular | Should -Be 'aborigine'
        'cafes' | Get-Singular | Should -Be 'cafe'
    }
}
Describe 'Get-SyllableCount' {
    It 'can count syllables of simple words' -Tag 'Local', 'Remote' {
        '' | Get-SyllableCount | Should -Be 0
        'a', 'of', 'the', 'and', 'is' | ForEach-Object {
            $_ | Get-SyllableCount | Should -Be 1
        }
        'wine' | Get-SyllableCount | Should -Be 1
        'foo' | Get-SyllableCount | Should -Be 1
        'hello' | Get-SyllableCount | Should -Be 2
        'pizza' | Get-SyllableCount | Should -Be 2
        'bottle' | Get-SyllableCount | Should -Be 2
        'project' | Get-SyllableCount | Should -Be 2
        'syllable' | Get-SyllableCount | Should -Be 3
        'innovation' | Get-SyllableCount | Should -Be 4
    }
    It 'can count syllables of words with uppercase letters' -Tag 'Local', 'Remote' {
        'Foo' | Get-SyllableCount | Should -Be 1
        'Hello' | Get-SyllableCount | Should -Be 2
        'PIZZA' | Get-SyllableCount | Should -Be 2
        'PROJECT' | Get-SyllableCount | Should -Be 2
        'Syllable' | Get-SyllableCount | Should -Be 3
        'Innovation' | Get-SyllableCount | Should -Be 4
    }
    It 'can count syllables for selected "difficult" words' -Tag 'Local', 'Remote' {
        'hybrid' | Get-SyllableCount | Should -Be 2
        'mammal' | Get-SyllableCount | Should -Be 2
        'seemingly' | Get-SyllableCount | Should -Be 3
        'creature' | Get-SyllableCount | Should -Be 2
        'platypus' | Get-SyllableCount | Should -Be 3
        'reptilian' | Get-SyllableCount | Should -Be 4
        'Australian' | Get-SyllableCount | Should -Be 3
        'cliche' | Get-SyllableCount | Should -Be 2
        'christian' | Get-SyllableCount | Should -Be 2
        'scotias' | Get-SyllableCount | Should -Be 3
        'uncreates' | Get-SyllableCount | Should -Be 3
        'viceroyship' | Get-SyllableCount | Should -Be 3
        'accouchements' | Get-SyllableCount | Should -Be 3
        'contrariety' | Get-SyllableCount | Should -Be 4
        'pertinacious' | Get-SyllableCount | Should -Be 5
        'moderatenesses' | Get-SyllableCount | Should -Be 5
    }
    It 'can count syllables for "problematic" words' -Tag 'Local', 'Remote' {
        'queue' | Get-SyllableCount | Should -Be 1
        'anyone' | Get-SyllableCount | Should -Be 3
        'maybe' | Get-SyllableCount | Should -Be 2
        'phoebe' | Get-SyllableCount | Should -Be 2
        'simile' | Get-SyllableCount | Should -Be 3
    }
    It 'can handle hyphenated words' -Tag 'Local', 'Remote' {
        'good-natured' | Get-SyllableCount | Should -Be 3
        'ninety-nine' | Get-SyllableCount | Should -Be 3
    }
    It -Skip 'can count syllables for words with accented letters' -Tag 'Local', 'Remote' {
        'Zoë' | Get-SyllableCount | Should -Be 2
        'Åland' | Get-SyllableCount | Should -Be 2
        'resumé' | Get-SyllableCount | Should -Be 3
    }
    It 'can count syllables for all words supported by ancestor source code' -Tag 'Local' {
        $Data = Get-Content (Join-Path $PSScriptRoot '\fixtures\words.json') | ConvertFrom-Json
        foreach ($Word in $Data.PSObject.Properties.Name) {
            $Word | Get-SyllableCount | Should -Be $Data.$Word
        }
    }
}
Describe -Skip:(-not $ExcelSupported) 'Import-Excel' -Tag 'Local', 'Remote' {
    It 'will import first worksheet by default' {
        $Path = Join-Path $PSScriptRoot '\fixtures\example.xlsx'
        $Data = Import-Excel -Path $Path
        $Data.Size | Should -Be 6, 4
        $Data | Get-Property 'Rows.0.Values' | Sort-Object | Should -Be 'a', 'EMPTY', 'EMPTY', 'foo'
        $Data | Get-Property 'Rows.1.Values' | Sort-Object | Should -Be 1, 'b', 'bar', 'red'
    }
    It 'will import first worksheet by default and display progress' {
        $Path = Join-Path $PSScriptRoot '\fixtures\example.xlsx'
        $Data = Import-Excel -Path $Path -ShowProgress
        $Data.Size | Should -Be 6, 4
        $Data | Get-Property 'Rows.0.Values' | Sort-Object | Should -Be 'a', 'EMPTY', 'EMPTY', 'foo'
        $Data | Get-Property 'Rows.1.Values' | Sort-Object | Should -Be 1, 'b', 'bar', 'red'
    }
    It 'peek data and import only the first row' {
        $Path = Join-Path $PSScriptRoot '\fixtures\example.xlsx'
        $Data = Import-Excel -Path $Path -Peek -WorksheetName 'with-headers'
        $Data.Size | Should -Be 1, 2
        $Data.Cells | Should -Be 'Disciples', 'Gospels'
    }
    It 'can import worksheet by name' {
        $Path = Join-Path $PSScriptRoot '\fixtures\example.xlsx'
        $Data = Import-Excel -Path $Path -WorksheetName 'with-headers'
        $Data.Size | Should -Be 13, 2
        $Data | Get-Property 'Rows.0.Column1' | Should -Be 'Disciples'
        $Data | Get-Property 'Rows.1.Column2' | Should -Be 'Matthew'
    }
    It 'can treat the cells in the first row as headers' {
        $Path = Join-Path $PSScriptRoot '\fixtures\example.xlsx'
        $Data = Import-Excel -Path $Path -WorksheetName 'with-headers' -FirstRowHeaders
        $Data.Size | Should -Be 12, 2
        $Data | Get-Property 'Headers' | Should -Be 'Disciples', 'Gospels'
        $Data | Get-Property 'Rows.0.Disciples' | Should -Be 'Peter'
        $Data | Get-Property 'Rows.1.Gospels' | Should -Be 'Mark'
    }
    It 'can use custom header names' {
        $Path = Join-Path $PSScriptRoot '\fixtures\example.xlsx'
        $Data = Import-Excel -Path $Path -ColumnHeaders 'A', 'B', 'C', 'D'
        $Data.Size | Should -Be 6, 4
        $Data.Headers | Should -Be 'A', 'B', 'C', 'D'
        $Data | Get-Property 'Rows.2.C' | Should -Be 'baz'
        $Data | Get-Property 'Rows.0.Values' | Sort-Object | Should -Be 'a', 'EMPTY', 'EMPTY', 'foo'
    }
    It 'will only use the correct number of custom header names' {
        $Path = Join-Path $PSScriptRoot '\fixtures\example.xlsx'
        $Data = Import-Excel -Path $Path -ColumnHeaders 'A', 'B'
        $Data.Headers | Should -Be 'Column1', 'Column2', 'Column3', 'Column4'
        $Data | Get-Property 'Rows.0.Values' | Sort-Object | Should -Be 'a', 'EMPTY', 'EMPTY', 'foo'
        $Data | Get-Property 'Rows.1.Values' | Sort-Object | Should -Be 1, 'b', 'bar', 'red'
    }
    It 'will provide placeholder headers when missing' {
        $Path = Join-Path $PSScriptRoot '\fixtures\example.xlsx'
        $Data = Import-Excel -Path $Path -FirstRowHeaders
        $Data.Headers | Should -Be 'a', 'Column2', 'foo', 'Column4' -Because 'there are empty cells in the first row'
        $Data | Get-Property 'Rows.0.Values' | Sort-Object | Should -Be 1, 'b', 'bar', 'red'
    }
    It 'supports custom "empty values"' {
        $Path = Join-Path $PSScriptRoot '\fixtures\example.xlsx'
        $Data = Import-Excel -Path $Path -EmptyValue 'BLANK'
        $Data | Get-Property 'Rows.0.Values' | Sort-Object | Should -Be 'a', 'BLANK', 'BLANK', 'foo'
    }
    It 'can open password-protected Workbooks' {
        $Password = '123456'
        $Path = Join-Path $PSScriptRoot '\fixtures\example_protected.xlsx'
        $Data = Import-Excel -Path $Path -Password $Password
        $Data.Size | Should -Be 6, 1
        $Data | Get-Property 'Rows.0.Values' | Should -Be 'secret'
        $Data | Get-Property 'Rows.1.Values' | Should -Be 'restricted'
        $Data = Import-Excel -Path $Path -Password $Password -WorksheetName 'unprotected'
        $Data.Size | Should -Be 5, 1
        $Data | Get-Property 'Rows.0.Values' | Should -Be 'public'
        $Data | Get-Property 'Rows.1.Values' | Should -Be 'open'
        { Import-Excel -Path $Path -Password 'wrong' } | Should -Throw -Because 'the password is not correct'
    }
}
Describe 'Import-Raw' -Tag 'Local', 'Remote' {
    It 'can import lines of a file' {
        $Path = Join-Path $PSScriptRoot '\fixtures\example.html'
        $Data = Import-Raw -File $Path
        $Data.Count | Should -Be 37
        $Data[1] | Should -Be '<html lang="en">'
    }
    It 'can peek first line of a file' {
        $Path = Join-Path $PSScriptRoot '\fixtures\example.html'
        Import-Raw -File $Path -Peek | Should -Be '<!DOCTYPE html>'
    }
    It 'can import lines of a file and apply a transform to each line' {
        $Path = Join-Path $PSScriptRoot '\fixtures\example.txt'
        $Transform = {
            Param($Line)
            $Line.ToUpper()
        }
        $Data = Import-Raw $Path $Transform
        $Data[3] | Should -Be 'GUN SWAB BRIGANTINE.'
    }
}
Describe -Skip 'Invoke-Normalize' -Tag 'Local', 'Remote' {
    It 'can normalize strings to UTF-8' {
        'resumé' | Invoke-Normalize | Should -BeExactly 'resume'
        'Resumé' | Invoke-Normalize | Should -BeExactly 'Resume'
    }
}
Describe 'Measure-Readability' {
    It -Skip 'can measure the readability of given text using various methods on Windows' -Tag 'Local', 'Remote', 'WindowsOnly' {
        $Verbose = $False
        'The Australian platypus is seemingly a hybrid of a mammal and reptilian creature' | Measure-Readability -Verbose:$Verbose | Should -Be 12.2
        $Text = (Get-Content -Path (Join-Path $PSScriptRoot '\fixtures\emma.txt')) -join ' '
        Measure-Readability $Text -Verbose:$Verbose | Should -Be 11.1
        Measure-Readability $Text -Type 'GFI' -Verbose:$Verbose | Should -Be 14
        Measure-Readability $Text -Type 'CLI' -Verbose:$Verbose | Should -Be 9.3
        Measure-Readability $Text -Type 'ARI' -Verbose:$Verbose | Should -Be 12
        Measure-Readability $Text -Type 'SMOG' -Verbose:$Verbose | Should -Be 12.2
    }
    It 'can measure the readability of given text using various methods on Linux' -Tag 'Local', 'Remote', 'LinuxOnly' {
        $Verbose = $False
        'The Australian platypus is seemingly a hybrid of a mammal and reptilian creature' | Measure-Readability -Verbose:$Verbose | Should -Be 12.2
        $Text = (Get-Content -Path (Join-Path $PSScriptRoot '\fixtures\emma.txt')) -join ' '
        Measure-Readability $Text -Verbose:$Verbose | Should -Be 11.1
        Measure-Readability $Text -Type 'GFI' -Verbose:$Verbose | Should -Be 14
        Measure-Readability $Text -Type 'CLI' -Verbose:$Verbose | Should -Be 9.2
        Measure-Readability $Text -Type 'ARI' -Verbose:$Verbose | Should -Be 11.9
        Measure-Readability $Text -Type 'SMOG' -Verbose:$Verbose | Should -Be 12.2
    }
}