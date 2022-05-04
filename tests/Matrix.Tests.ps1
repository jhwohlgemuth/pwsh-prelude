& (Join-Path $PSScriptRoot '_setup.ps1') 'matrix'

Describe 'Invoke-MatrixMap' -Tag 'Local', 'Remote' {
    It 'can accept 1-ary functions' {
        $A = 1..4 | New-Matrix
        $AddOne = { Param($X) $X + 1 }
        $B = $A | Invoke-MatrixMap $AddOne
        $B[0].Real | Should -Be 2, 3
        $B[1].Real | Should -Be 4, 5
    }
    It 'can accept 3-ary functions' {
        $A = 1..4 | New-Matrix
        $Ex = { Param($X, $I, $J) $X + $I + $J }
        $B = $A | Invoke-MatrixMap $Ex
        $B[0].Real | Should -Be 1, 3
        $B[1].Real | Should -Be 4, 6
    }
    It 'can accept 4-ary functions' {
        $A = 1..4 | New-Matrix
        $Ex = { Param($X, $I, $J, $M) $X + $I + $J + $M.Size[0] }
        $B = $A | Invoke-MatrixMap $Ex
        $B[0].Real | Should -Be 3, 5
        $B[1].Real | Should -Be 6, 8
    }
    It 'will use identity for input functions with wrong arity' {
        $A = 1..4 | New-Matrix
        $B = $A | Invoke-MatrixMap { }
        $B[0].Real | Should -Be 1, 2
        $B[1].Real | Should -Be 3, 4
        $B = $A | Invoke-MatrixMap { Param($A, $B, $C, $D, $E) $A + $B + $C + $D + $E }
        $B[0].Real | Should -Be 1, 2
        $B[1].Real | Should -Be 3, 4
    }
    It 'will use identity function when no function is passed' {
        $A = 1..4 | New-Matrix
        $B = $A | Invoke-MatrixMap
        $B[0].Real | Should -Be 1, 2
        $B[1].Real | Should -Be 3, 4
    }
    It 'will throw error when input function has wrong arity and Strict parameter is used' {
        $A = 1..4 | New-Matrix
        $Ex = { }
        { $A | Invoke-MatrixMap $Ex -Strict } | Should -Throw 'Expression has wrong number of parameters'
    }
}
Describe 'New-ComplexValue / Format-ComplexValue' -Tag 'Local', 'Remote' {
    BeforeAll {
        function Test-ValidRandomValue {
            Param(
                [Parameter(ValueFromPipeline = $True)]
                $Value,
                [Int] $Minimum,
                [Int] $Maximum
            )
            $Value | Should -BeGreaterOrEqual $Minimum
            $Value | Should -BeLessOrEqual $Maximum
        }
    }
    It 'can create complex values' {
        $C1 = New-ComplexValue 2 3
        $C2 = New-ComplexValue -Re 5 -Im 9
        $C1.Real | Should -Be 2
        $C1.Imaginary | Should -Be 3
        $C2.Real | Should -Be 5
        $C2.Imaginary | Should -Be 9
    }
    It 'can format complex values as strings' {
        New-ComplexValue -Re 5 -Im 9 | Format-ComplexValue | Should -Be '5 + 9i'
        New-ComplexValue -Re -5 -Im 9 | Format-ComplexValue | Should -Be '-5 + 9i'
        New-ComplexValue -Re -5 -Im -9 | Format-ComplexValue | Should -Be '-5 - 9i'
        New-ComplexValue -Re 5 -Im -9 | Format-ComplexValue | Should -Be '5 - 9i'
        5, 9 | New-ComplexValue | Format-ComplexValue | Should -Be '5 + 9i'
        -5, 9 | New-ComplexValue | Format-ComplexValue | Should -Be '-5 + 9i'
        -5, -9 | New-ComplexValue | Format-ComplexValue | Should -Be '-5 - 9i'
        5, -9 | New-ComplexValue | Format-ComplexValue | Should -Be '5 - 9i'
        New-ComplexValue -Re 5 | Format-ComplexValue | Should -Be '5'
        New-ComplexValue -Im 9 | Format-ComplexValue | Should -Be '9i'
        New-ComplexValue -Im -9 | Format-ComplexValue | Should -Be '-9i'
        New-ComplexValue -Re 0 -Im 0 | Format-ComplexValue | Should -Be '0'
    }
    It 'can format complex values as strings, with color' {
        New-ComplexValue -Re 5 -Im 9 | Format-ComplexValue -WithColor | Should -Be '5 + 9{{#cyan i}}'
        New-ComplexValue -Re -5 -Im 9 | Format-ComplexValue -WithColor | Should -Be '-5 + 9{{#cyan i}}'
        New-ComplexValue -Re -5 -Im -9 | Format-ComplexValue -WithColor | Should -Be '-5 - 9{{#cyan i}}'
        New-ComplexValue -Re 5 -Im -9 | Format-ComplexValue -WithColor | Should -Be '5 - 9{{#cyan i}}'
        New-ComplexValue -Re 5 | Format-ComplexValue -WithColor | Should -Be '5'
        New-ComplexValue -Im 9 | Format-ComplexValue -WithColor | Should -Be '9{{#cyan i}}'
        New-ComplexValue -Im -9 | Format-ComplexValue -WithColor | Should -Be '-9{{#cyan i}}'
        New-ComplexValue -Re 0 -Im 0 | Format-ComplexValue -WithColor | Should -Be '0'
    }
    It 'can be randomly generated' -TestCases (1..25) {
        $C = New-ComplexValue -Random
        $C.Real | Test-ValidRandomValue -Minimum -10 -Maximum 10
        $C.Imaginary | Test-ValidRandomValue -Minimum -10 -Maximum 10
    }
    It 'can be randomly generated with custom bounds' -TestCases (1..25) {
        $C = New-ComplexValue -Random -Bounds -1, 1
        $C.Real | Test-ValidRandomValue -Minimum -10 -Maximum 10
        $C.Imaginary | Test-ValidRandomValue -Minimum -1 -Maximum 1
    }
}
Describe 'New-Matrix' -Tag 'Local', 'Remote' {
    BeforeAll {
        function Test-ValidRandomValue {
            Param(
                [Parameter(ValueFromPipeline = $True)]
                $Value,
                [Int] $Minimum,
                [Int] $Maximum
            )
            $Value | Should -BeGreaterOrEqual $Minimum
            $Value | Should -BeLessOrEqual $Maximum
        }
    }
    It 'can provide wrapper for matrix creation' {
        $A = 1..9 | New-Matrix 3, 3
        $A.Size | Should -Be 3, 3
        $A[0].Real | Should -Be 1, 2, 3
        $A[1].Real | Should -Be 4, 5, 6
        $A[2].Real | Should -Be 7, 8, 9
        $A = New-Matrix -Size 3, 3 -Values (1..9)
        $A.Size | Should -Be 3, 3
        $A[0].Real | Should -Be 1, 2, 3
        $A[1].Real | Should -Be 4, 5, 6
        $A[2].Real | Should -Be 7, 8, 9
        $A = New-Matrix
        $A.Size | Should -Be 2, 2 -Because '2x2 is the default matrix size'
        $A[0].Real | Should -Be 0, 0 -Because 'an empty matrix should be created by default'
        $A[1].Real | Should -Be 0, 0 -Because 'an empty matrix should be created by default'
        $A = @(1, 2, 3, @(4, 5, 6)) | New-Matrix 2, 3
        $A = 1..6 | New-Matrix 2, 3
        $A[0].Real | Should -Be 1, 2, 3 -Because 'function accepts non-square sizes'
        $A[1].Real | Should -Be 4, 5, 6 -Because 'values array should be flattened'
    }
    It 'will create a square matrix if passed only one dimension' {
        $A = 1..4 | New-Matrix
        $A.Size | Should -Be 2, 2
        $A[0].Real | Should -Be 1, 2
        $A[1].Real | Should -Be 3, 4
        $A = 1..9 | New-Matrix 3
        $A.Size | Should -Be 3, 3
        $A[0].Real | Should -Be 1, 2, 3
        $A[1].Real | Should -Be 4, 5, 6
        $A[2].Real | Should -Be 7, 8, 9
    }
    It 'can create diagonal matrices' {
        $A = 1..3 | New-Matrix 3, 3 -Diagonal
        $A.Size | Should -Be 3, 3
        $A[0].Real | Should -Be 1, 0, 0
        $A[1].Real | Should -Be 0, 2, 0
        $A[2].Real | Should -Be 0, 0, 3
        $A = New-Matrix -Values (1..3) -Size 3, 3 -Diagonal
        $A.Size | Should -Be 3, 3
        $A[0].Real | Should -Be 1, 0, 0
        $A[1].Real | Should -Be 0, 2, 0
        $A[2].Real | Should -Be 0, 0, 3
    }
    It 'can create identity matrices' {
        $A = New-Matrix 3, 3 -Identity
        $A.Size | Should -Be 3, 3
        $A[0].Real | Should -Be 1, 0, 0
        $A[1].Real | Should -Be 0, 1, 0
        $A[2].Real | Should -Be 0, 0, 1
    }
    It 'can create unit matrices' {
        $A = New-Matrix 3, 3 -Unit
        $A.Size | Should -Be 3, 3
        $A[0].Real | Should -Be 1, 1, 1
        $A[1].Real | Should -Be 1, 1, 1
        $A[2].Real | Should -Be 1, 1, 1
    }
    It 'can be randomly generated' -TestCases (1..25) {
        $A = New-Matrix -Random
        $A.Size | Should -Be 2, 2
        $A.Values.Real | ForEach-Object {
            $_ | Test-ValidRandomValue -Minimum -10 -Maximum 10
        }
        $A.Values.Imaginary | ForEach-Object {
            $_ | Test-ValidRandomValue -Minimum -10 -Maximum 10
        }
    }
    It 'can be randomly generated with custom bounds' -TestCases (1..25) {
        $A = New-Matrix -Random -Bounds -1, 1
        $A.Size | Should -Be 2, 2
        $A.Values.Real | ForEach-Object {
            $_ | Test-ValidRandomValue -Minimum -1 -Maximum 1
        }
        $A.Values.Imaginary | ForEach-Object {
            $_ | Test-ValidRandomValue -Minimum -1 -Maximum 1
        }
    }
}
Describe 'Test-Matrix' -Tag 'Local', 'Remote' {
    It 'can test matrix properties' {
        $A = 1..3 | New-Matrix 3, 3 -Diagonal
        $A | Test-Matrix -Diagonal | Should -BeTrue
        $A | Test-Matrix -Diagonal -Square -Symmetric | Should -BeTrue
        $A | Test-Matrix -Hermitian | Should -BeTrue
        $A = 1..4 | New-Matrix 2, 2
        $A | Test-Matrix -Hermitian | Should -BeFalse
        $A | Test-Matrix -Square | Should -BeTrue
        $A | Test-Matrix -Square -Symmetric | Should -BeFalse
        $A | Test-Matrix -Symmetric | Should -BeFalse
        42 | Test-Matrix | Should -BeFalse
        42 | Test-Matrix -Square | Should -BeFalse
        $C = New-ComplexValue 1 2
        $D = [System.Numerics.Complex]::Conjugate($C)
        1, $C, $D, 1 | New-Matrix | Test-Matrix -Hermitian | Should -BeTrue
        1, $C, $C, 1 | New-Matrix | Test-Matrix -Hermitian | Should -BeFalse
    }
}