& (Join-Path $PSScriptRoot '_setup.ps1') 'graph'

Describe 'Graph helper functions' -Tag 'Local', 'Remote' {
    It 'can create edges from nodes' {
        $A = [Node]'A'
        $B = [Node]'B'
        $C = [Node]'C'
        $Weight = 42
        $AB = New-Edge $A $B -Weight $Weight
        $AB.Source | Should -Be $A
        $AB.Destination | Should -Be $B
        $AB.Contains($C) | Should -BeFalse
        $AB.Weight | Should -Be $Weight
        $BC = $B | New-Edge -To $C
        $BC.Source | Should -Be $B
        $BC.Destination | Should -Be $C
        $BC.Weight | Should -Be 1
    }
    It 'can create edges from string values' {
        $AB = New-Edge 'A' 'B'
        $AB.Source.Label | Should -Be 'A'
        $AB.Destination.Label | Should -Be 'B'
    }
    It -Skip 'can create directed edges' {
        $A = [Node]'A'
        $B = [Node]'B'
        $C = [Node]'C'
        $Weight = 42
        $AB = New-Edge $A $B -Weight $Weight -Directed
        $AB.Contains($A) | Should -BeTrue
        $AB.Contains($B) | Should -BeTrue
        $AB.Contains($C) | Should -BeFalse
        $AB.Weight | Should -Be $Weight
    }
}

