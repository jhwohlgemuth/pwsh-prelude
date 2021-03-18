& (Join-Path $PSScriptRoot '_setup.ps1') 'matrix'

Describe 'Complex value helper functions' -Tag 'Local', 'Remote' {
    It 'can create complex values' {
        $C1 = New-ComplexValue 2 3
        $C2 = New-ComplexValue -Re 5 -Im 9
        $C1.Real | Should -Be 2
        $C1.Imaginary | Should -Be 3
        $C2.Real | Should -Be 5
        $C2.Imaginary | Should -Be 9
    }
    It 'can format complex values as strings' {
        
    }
    It 'can format complex values as strings, with color' {

    }
}
Describe 'Matrix helper functions' -Tag 'Local', 'Remote' {
    It 'can provide wrapper for matrix creation' {
        $A = 1..9 | New-Matrix 3, 3
        $A.Size | Should -Be 3, 3
        $A[0] | Should -Be 1, 2, 3
        $A[1] | Should -Be 4, 5, 6
        $A[2] | Should -Be 7, 8, 9
        $A = New-Matrix -Size 3, 3 -Values (1..9)
        $A.Size | Should -Be 3, 3
        $A[0] | Should -Be 1, 2, 3
        $A[1] | Should -Be 4, 5, 6
        $A[2] | Should -Be 7, 8, 9
        $A = New-Matrix
        $A.Size | Should -Be 2, 2 -Because '2x2 is the default matrix size'
        $A[0] | Should -Be 0, 0 -Because 'an empty matrix should be created by default'
        $A[1] | Should -Be 0, 0 -Because 'an empty matrix should be created by default'
        $A = @(1, 2, 3, @(4, 5, 6)) | New-Matrix 2, 3
        $A = 1..6 | New-Matrix 2, 3
        $A[0] | Should -Be 1, 2, 3 -Because 'function accepts non-square sizes'
        $A[1] | Should -Be 4, 5, 6 -Because 'values array should be flattened'
    }
    It 'can create diagonal matrices' {
        $A = 1..3 | New-Matrix 3, 3 -Diagonal
        $A.Size | Should -Be 3, 3
        $A[0] | Should -Be 1, 0, 0
        $A[1] | Should -Be 0, 2, 0
        $A[2] | Should -Be 0, 0, 3
        $A = New-Matrix -Values (1..3) -Size 3, 3 -Diagonal
        $A.Size | Should -Be 3, 3
        $A[0] | Should -Be 1, 0, 0
        $A[1] | Should -Be 0, 2, 0
        $A[2] | Should -Be 0, 0, 3
    }
    It 'can create identity matrices' {
        $A = New-Matrix 3, 3 -Identity
        $A.Size | Should -Be 3, 3
        $A[0] | Should -Be 1, 0, 0
        $A[1] | Should -Be 0, 1, 0
        $A[2] | Should -Be 0, 0, 1
    }
    It 'can create unit matrices' {
        $A = New-Matrix 3, 3 -Unit
        $A.Size | Should -Be 3, 3
        $A[0] | Should -Be 1, 1, 1
        $A[1] | Should -Be 1, 1, 1
        $A[2] | Should -Be 1, 1, 1
    }
    It 'can test matrix properties' {
        $A = 1..3 | New-Matrix 3, 3 -Diagonal
        $A | Test-Matrix -Diagonal | Should -BeTrue
        $A | Test-Matrix -Diagonal -Square -Symmetric | Should -BeTrue
        $A = 1..4 | New-Matrix 2, 2
        $A | Test-Matrix -Square | Should -BeTrue
        $A | Test-Matrix -Square -Symmetric | Should -BeFalse
        $A | Test-Matrix -Symmetric | Should -BeFalse
        42 | Test-Matrix | Should -BeFalse
        42 | Test-Matrix -Square | Should -BeFalse
    }
}