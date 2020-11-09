& (Join-Path $PSScriptRoot '_setup.ps1') 'classes'

Describe 'Matrix Class' {
    It 'can create an NxN multi-dimensional array' {
        $N = 5
        $Matrix = [Matrix]::New($N)
        $Matrix.Values.Count | Should -Be $N
        $Matrix.Values[0].Count | Should -Be $N
    }
    It 'can create an MxN multi-dimensional array' {
        $M = 8
        $N = 6
        $Matrix = [Matrix]::New($M,$N)
        $Matrix.Values.Count | Should -Be $M
        $Matrix.Values[0].Count | Should -Be $N
    }
}