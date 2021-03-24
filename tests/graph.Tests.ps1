& (Join-Path $PSScriptRoot '_setup.ps1') 'graph'

Describe 'Graph helper functions' -Tag 'Local', 'Remote' {
    BeforeAll {
        function Get-TestGraph {
            $A = [Node]::New('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'a')
            $B = [Node]::New('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'b')
            $C = [Node]::New('cccccccc-cccc-cccc-cccc-cccccccccccc', 'c')
            $AB = New-Edge $A $B
            $AC = New-Edge $A $C -Directed
            $BC = New-Edge $B $C
            $Edges = $AB, $BC, $AC
            $Graph = [Graph]::New($Edges)
            $Graph
        }
    }
    It -Skip 'can export graph objects to JSON format' {
        
    }
    It -Skip 'can export graph objects to CSV format' {
        $G = Get-TestGraph
        $Expected = "SourceId,SourceLabel,SourceWeight,TargetId,TargetLabel,TargetWeight`naaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa,a,1,False,bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb,b,1,False`nbbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb,b,1,False,cccccccc-cccc-cccc-cccc-cccccccccccc,c,1,False`naaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa,a,1,False,cccccccc-cccc-cccc-cccc-cccccccccccc,c,1,False`n"
        $G | Export-GraphData -CSV -PassThru | Should -Be $Expected
        $G | Export-GraphData -Format 'CSV' -PassThru | Should -Be $Expected
    }
    It -Skip 'can export graph objects to XML format' {
        
    }
    It 'can export graph objects to mermaid format' {
        $G = Get-TestGraph
        $Expected = "graph TD`n`taaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa[a] --- bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb[b]`n`tbbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb[b] --- cccccccc-cccc-cccc-cccc-cccccccccccc[c]`n`taaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa[a] --> cccccccc-cccc-cccc-cccc-cccccccccccc[c]`n"
        $G | Export-GraphData -Mermaid -PassThru | Should -Be $Expected
        $G | Export-GraphData -Format 'Mermaid' -PassThru | Should -Be $Expected
    }
    It 'can create edges from nodes' {
        $A = [Node]'A'
        $B = [Node]'B'
        $C = [Node]'C'
        $Weight = 42
        $AB = New-Edge $A $B -Weight $Weight
        $AB.Source | Should -Be $A
        $AB.Target | Should -Be $B
        $AB.Contains($C) | Should -BeFalse
        $AB.Weight | Should -Be $Weight
        $BC = $B | New-Edge -To $C
        $BC.Source | Should -Be $B
        $BC.Target | Should -Be $C
        $BC.Weight | Should -Be 1
    }
    It 'can create edges from string values' {
        $AB = New-Edge 'A' 'B'
        $AB.Source.Label | Should -Be 'A'
        $AB.Target.Label | Should -Be 'B'
    }
    It 'can create directed edges' {
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
    It 'can create complete graphs' {
        $G = New-Graph -Complete -NodeCount 3
        $G.Nodes | Should -HaveCount 3
        $G.Edges | Should -HaveCount 3
        $G = New-Graph -Complete -N 3
        $G.Nodes | Should -HaveCount 3
        $G.Edges | Should -HaveCount 3
    }
    It 'can create bipartite graphs' {
        $G = New-Graph -Bipartite -Left 1 -Right 3
        $G.Nodes | Should -HaveCount 4
        $G.Edges | Should -HaveCount 3
    }
    It 'can create custom graphs' {
        $A = [Node]'A'
        $B = [Node]'B'
        $C = [Node]'C"'
        $AB = New-Edge $A $B
        $BC = New-Edge $B $C
        $Edges = $AB, $BC
        $G = New-Graph -Nodes $A, $B, $C -Edges $Edges
        $G.Nodes | Should -HaveCount 3
        $G.Edges | Should -HaveCount 2
        $G = New-Graph -Edges $Edges
        $G.Nodes | Should -HaveCount 3
        $G.Edges | Should -HaveCount 2
        $G = $Edges | New-Graph
        $G.Nodes | Should -HaveCount 3
        $G.Edges | Should -HaveCount 2
    }
}

