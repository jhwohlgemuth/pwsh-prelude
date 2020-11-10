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
        $Unit = [MatrixTest]::Unit(2)
        $Unit.Order | Should -Be 2,2
        $Unit.Values[0] | Should -Be 1,0
        $Unit.Values[1] | Should -Be 0,1
        $Unit = [MatrixTest]::Unit(4)
        $Unit.Order | Should -Be 4,4
        $Unit.Values[0] | Should -Be 1,0,0,0
        $Unit.Values[1] | Should -Be 0,1,0,0
        $Unit.Values[2] | Should -Be 0,0,1,0
        $Unit.Values[3] | Should -Be 0,0,0,1
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
        $A = [MatrixTest]::Unit(2)
        $Sum = [MatrixTest]::Add($A,$A)
        $Sum.Values[0] | Should -Be 2,0
        $Sum.Values[1] | Should -Be 0,2
        $Sum = [MatrixTest]::Add($A,$A,$A)
        $Sum.Values[0] | Should -Be 3,0
        $Sum.Values[1] | Should -Be 0,3
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
        $A = [MatrixTest]::Unit(2)
        [MatrixTest]::Add($A,$A,$A) | Test-Equal $A.Multiply(3) | Should -BeTrue
        $Product = $A.Multiply(7)
        $Product.Values[0] | Should -Be 7,0
        $Product.Values[1] | Should -Be 0,7
    }
}