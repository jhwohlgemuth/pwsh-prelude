﻿& (Join-Path $PSScriptRoot '_setup.ps1') 'matrix'

Describe 'Matrix helper functions' -Tag 'Local', 'Remote' {
    It 'can provide wrapper for matrix creation' {
        $A = 1..9 | New-Matrix 3, 3
        $A.Size | Should -Be 3, 3
        $A.Rows[0] | Should -Be 1, 2, 3
        $A.Rows[1] | Should -Be 4, 5, 6
        $A.Rows[2] | Should -Be 7, 8, 9
        $A = New-Matrix -Size 3, 3 -Values (1..9)
        $A.Size | Should -Be 3, 3
        $A.Rows[0] | Should -Be 1, 2, 3
        $A.Rows[1] | Should -Be 4, 5, 6
        $A.Rows[2] | Should -Be 7, 8, 9
        $A = New-Matrix
        $A.Size | Should -Be 2, 2 -Because '2x2 is the default matrix size'
        $A.Rows[0] | Should -Be 0, 0 -Because 'an empty matrix should be created by default'
        $A.Rows[1] | Should -Be 0, 0 -Because 'an empty matrix should be created by default'
        $A = @(1, 2, 3, @(4, 5, 6)) | New-Matrix 2, 3
        $A = 1..6 | New-Matrix 2, 3
        $A.Rows[0] | Should -Be 1, 2, 3 -Because 'function accepts non-square sizes'
        $A.Rows[1] | Should -Be 4, 5, 6 -Because 'values array should be flattened'
    }
    It 'can create diagonal matrices' {
        $A = 1..3 | New-Matrix 3, 3 -Diagonal
        $A.Size | Should -Be 3, 3
        $A.Rows[0] | Should -Be 1, 0, 0
        $A.Rows[1] | Should -Be 0, 2, 0
        $A.Rows[2] | Should -Be 0, 0, 3
        $A = New-Matrix -Values (1..3) -Size 3, 3 -Diagonal
        $A.Size | Should -Be 3, 3
        $A.Rows[0] | Should -Be 1, 0, 0
        $A.Rows[1] | Should -Be 0, 2, 0
        $A.Rows[2] | Should -Be 0, 0, 3
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