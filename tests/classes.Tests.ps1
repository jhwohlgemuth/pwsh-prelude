& (Join-Path $PSScriptRoot '_setup.ps1') 'classes'

Describe 'Matrix Class' {
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
    It 'can create instances that can create clones' {
        $Matrix = [MatrixTest]::New(2)
        $Matrix.Values[0][0] = 1
        $Matrix.Values[0][1] = 2
        $Matrix.Values[1][0] = 3
        $Matrix.Values[1][1] = 4
        $Clone = $Matrix.Clone()
        $Clone.Values[0] | Should -Be 1,2
        $Clone.Values[1] | Should -Be 3,4
    }
}