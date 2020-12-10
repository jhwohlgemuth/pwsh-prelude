& (Join-Path $PSScriptRoot '_setup.ps1') 'matrix'

Describe 'Matrix helper functions' {
  It 'can provide wrapper for matrix creation' {
    $A = 1..9 | New-Matrix 3,3
    $A.Size | Should -Be 3,3
    $A.Rows[0] | Should -Be 1,2,3
    $A.Rows[1] | Should -Be 4,5,6
    $A.Rows[2] | Should -Be 7,8,9
    $A = New-Matrix -Size 3,3 -Values (1..9)
    $A.Size | Should -Be 3,3
    $A.Rows[0] | Should -Be 1,2,3
    $A.Rows[1] | Should -Be 4,5,6
    $A.Rows[2] | Should -Be 7,8,9
    $A = New-Matrix
    $A.Size | Should -Be 2,2 -Because '2x2 is the default matrix size'
    $A.Rows[0] | Should -Be 0,0 -Because 'an empty matrix should be created by default'
    $A.Rows[1] | Should -Be 0,0 -Because 'an empty matrix should be created by default'
    $A = @(1,2,3,@(4,5,6)) | New-Matrix 2,3
    $A = 1..6 | New-Matrix 2,3
    $A.Rows[0] | Should -Be 1,2,3 -Because 'function accepts non-square sizes'
    $A.Rows[1] | Should -Be 4,5,6 -Because 'values array should be flattened'
  }
  It 'can create diagonal matrices' {
    $A = 1..3 | New-Matrix 3,3 -Diagonal
    $A.Size | Should -Be 3,3
    $A.Rows[0] | Should -Be 1,0,0
    $A.Rows[1] | Should -Be 0,2,0
    $A.Rows[2] | Should -Be 0,0,3
    $A = New-Matrix -Values (1..3) -Size 3,3 -Diagonal
    $A.Size | Should -Be 3,3
    $A.Rows[0] | Should -Be 1,0,0
    $A.Rows[1] | Should -Be 0,2,0
    $A.Rows[2] | Should -Be 0,0,3
  }
  It 'can test if a matrix is diagonal' {
    1,0,0,
    0,2,0,
    0,0,3 | New-matrix 3,3 | Test-DiagonalMatrix | Should -BeTrue
    1,0,0,
    2,2,0,
    3,0,3 | New-Matrix 3,3 | Test-DiagonalMatrix | Should -BeFalse -Because 'second and third rows have non-zero elements off the main diagonal'
    1,0,0,
    0,2,1,
    0,0,3 | New-Matrix 3,3 | Test-DiagonalMatrix | Should -BeFalse -Because 'second row has a non-zero element off the main diagonal'
    1,0,
    0,1 | New-Matrix | Test-DiagonalMatrix | Should -BeTrue
    1,0,0,
    0,2,0 | New-matrix 2,3 | Test-DiagonalMatrix | Should -BeFalse -Because 'only square matrices can be diagonal'
    1,0,2,
    0,2,2 | New-matrix 2,3 | Test-DiagonalMatrix | Should -BeFalse -Because 'only square matrices can be diagonal'
  }
  It 'can test if a matrix is square' {
    (1..4) | New-Matrix | Test-SquareMatrix | Should -BeTrue
    (1..9) | New-Matrix 3,3 | Test-SquareMatrix | Should -BeTrue
    (1..6) | New-Matrix 3,2 | Test-SquareMatrix | Should -BeFalse -Because 'the # of rows and # of columns are different'
  }
  It 'can test if a matrix is symmetric' {
    1,2,3,
    2,1,4,
    3,4,1 | New-Matrix 3,3 | Test-SymmetricMatrix | Should -BeTrue
    (1..9) | New-Matrix 3,3 | Test-SymmetricMatrix | Should -BeFalse -Because 'elements off main diagonal are not equal'
    1,1,1,1 | New-Matrix | Test-SymmetricMatrix | Should -BeTrue
    1,0,0,0,
    0,1,0,0,
    0,0,1,0,
    0,0,0,1 | New-Matrix 4,4 | Test-SymmetricMatrix | Should -BeTrue -Because 'diagonal matrices are symmetric'
    1,0,0,
    2,2,0,
    3,0,3 | New-Matrix 3,3 | Test-SymmetricMatrix | Should -BeFalse
    1,0,0,
    0,2,1,
    0,0,3 | New-Matrix 2,3 | Test-SymmetricMatrix | Should -BeFalse
    1,0,0,
    0,0,3 | New-Matrix 2,3 | Test-SymmetricMatrix | Should -BeFalse -Because 'only square matrices can be symmetric'
  }
}