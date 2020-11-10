& (Join-Path $PSScriptRoot '_setup.ps1') 'classes'

Describe 'Matrix class static methods' {
    It 'can create an NxN multi-dimensional array' {
        $N = 5
        $Matrix = [MatrixTest]::New($N)
        $Matrix.Values.Count | Should -Be $N
        $Matrix.Values[0].Count | Should -Be $N
    }
    It 'can create an MxN multi-dimensional array' {
        $M = 8
        $N = 6
        $Matrix = [MatrixTest]::New($M,$N)
        $Matrix.Values.Count | Should -Be $M
        $Matrix.Values[0].Count | Should -Be $N
    }
    It 'can create unit matrices' {
        $Unit = [MatrixTest]::Unit(1)
        $Unit.Order | Should -Be 1,1
        $Unit.Values[0] | Should -Be 1
        $Unit = [MatrixTest]::Unit(2)
        $Unit.Order | Should -Be 2,2
        $Unit.Values[0] | Should -Be 1,1
        $Unit.Values[1] | Should -Be 1,1
        $Unit = [MatrixTest]::Unit(3)
        $Unit.Order | Should -Be 3,3
        $Unit.Values[0] | Should -Be 1,1,1
        $Unit.Values[1] | Should -Be 1,1,1
        $Unit.Values[2] | Should -Be 1,1,1
    }
    It 'can create identity matrices' {
        $Identity = [MatrixTest]::Identity(2)
        $Identity.Order | Should -Be 2,2
        $Identity.Values[0] | Should -Be 1,0
        $Identity.Values[1] | Should -Be 0,1
        $Identity = [MatrixTest]::Identity(4)
        $Identity.Order | Should -Be 4,4
        $Identity.Values[0] | Should -Be 1,0,0,0
        $Identity.Values[1] | Should -Be 0,1,0,0
        $Identity.Values[2] | Should -Be 0,0,1,0
        $Identity.Values[3] | Should -Be 0,0,0,1
    }
    It 'can transpose matrices' {
        $Matrix = [MatrixTest]::New(3)
        $Matrix.Values[0][0] = 1
        $Matrix.Values[0][1] = 2
        $Matrix.Values[0][2] = 3
        $Matrix.Values[1][0] = 4
        $Matrix.Values[1][1] = 5
        $Matrix.Values[1][2] = 6
        $Matrix.Values[2][0] = 7
        $Matrix.Values[2][1] = 8
        $Matrix.Values[2][2] = 9
        $Matrix.Values[0] | Should -Be 1,2,3
        $Matrix.Values[1] | Should -Be 4,5,6
        $Matrix.Values[2] | Should -Be 7,8,9
        $Transposed = [MatrixTest]::Transpose($Matrix)
        $Transposed.Values[0] | Should -Be 1,4,7
        $Transposed.Values[1] | Should -Be 2,5,8
        $Transposed.Values[2] | Should -Be 3,6,9
        $Original = [MatrixTest]::Transpose($Transposed)
        $Original.Values[0] | Should -Be 1,2,3
        $Original.Values[1] | Should -Be 4,5,6
        $Original.Values[2] | Should -Be 7,8,9
    }
    It 'can add two or more Matrices' {
        $A = [MatrixTest]::Identity(2)
        $Sum = [MatrixTest]::Add($A,$A)
        $Sum.Values[0] | Should -Be 2,0
        $Sum.Values[1] | Should -Be 0,2
        $Sum = [MatrixTest]::Add($A,$A,$A)
        $Sum.Values[0] | Should -Be 3,0
        $Sum.Values[1] | Should -Be 0,3
    }
    It 'can produce the dot product of two matrices' {
        $Identity = [MatrixTest]::Identity(2)
        $A = $Identity.Clone()
        $A.Values[1][1] = 0
        $B = $Identity.Clone()
        $B.Values[0][0] = 0
        $Product = $A.Dot($B)
        $Product.Order | Should -Be 2,2
        $Product.Values[0] | Should -Be 0,0 -Because 'the dot product of orthogonal matrices should be zero'
        $Product.Values[1] | Should -Be 0,0 -Because 'the dot product of orthogonal matrices should be zero'
        $A.Values[0][0] = 1
        $A.Values[0][1] = 2
        $A.Values[1][0] = 3
        $A.Values[1][1] = 4
        $B.Values[0][0] = 1
        $B.Values[0][1] = 1
        $B.Values[1][0] = 0
        $B.Values[1][1] = 2
        $Product = $A.Dot($B)
        $Product.Values[0] | Should -Be 1,5
        $Product.Values[1] | Should -Be 3,11
        $Product = $B.Dot($A)
        $Product.Values[0] | Should -Be 4,6 -Because 'the dot product is not commutative'
        $Product.Values[1] | Should -Be 6,8 -Because 'the dot product is not commutative'
        $A = [MatrixTest]::New(1,2)
        $A.Values[0][0] = 2
        $A.Values[0][1] = 1
        $B = [MatrixTest]::New(2,3)
        $B.Values[0][0] = 1
        $B.Values[0][1] = -2
        $B.Values[0][2] = 0
        $B.Values[1][0] = 4
        $B.Values[1][1] = 5
        $B.Values[1][2] = -3
        $Product = $A.Dot($B)
        $Product.Order | Should -Be 1,3 -Because 'dot product supports matrices of different sizes'
        $Product.Values[0] | Should -Be 6,1,-3
        $A = [MatrixTest]::New(2)
        $A.Values[0][0] = 2
        $A.Values[0][1] = 5
        $A.Values[1][0] = 1
        $A.Values[1][1] = 3
        $B = [MatrixTest]::New(2)
        $B.Values[0][0] = 3
        $B.Values[0][1] = -5
        $B.Values[1][0] = -1
        $B.Values[1][1] = 2
        $A.Dot($B) | Test-Equal $Identity | Should -BeTrue -Because '$A and $B are invertible'
        $Product.Values | ForEach-Object { $_ -join '-' | Write-Color -Magenta}
    }
}
Describe 'Matrix class instance' {
    It 'can create clones' {
        $Matrix = [MatrixTest]::New(2)
        $Matrix.Values[0][0] = 1
        $Matrix.Values[0][1] = 2
        $Matrix.Values[1][0] = 3
        $Matrix.Values[1][1] = 4
        $Clone = $Matrix.Clone()
        $Clone.Values[0] | Should -Be 1,2
        $Clone.Values[1] | Should -Be 3,4
    }
    It 'can be multiplied by a scalar constant' {
        $A = [MatrixTest]::Identity(2)
        [MatrixTest]::Add($A,$A,$A) | Test-Equal $A.Multiply(3) | Should -BeTrue
        $Product = $A.Multiply(7)
        $Product.Values[0] | Should -Be 7,0
        $Product.Values[1] | Should -Be 0,7
    }
}