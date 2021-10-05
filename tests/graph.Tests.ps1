[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'G')]
Param()

& (Join-Path $PSScriptRoot '_setup.ps1') 'graph'

Describe 'Graph export helper functions' -Tag 'Local', 'Remote' {
    BeforeAll {
        function Get-TestGraph {
            $A = [Node]::New('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'a')
            $B = [Node]::New('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'b')
            $C = [Node]::New('cccccccc-cccc-cccc-cccc-cccccccccccc', 'c')
            $AB = New-Edge $A $B
            $AC = New-Edge $A $C -Directed -Weight 42
            $BC = New-Edge $B $C
            $Edges = $AB, $BC, $AC
            $Graph = [Graph]::New($Edges)
            $Graph
        }
    }
    BeforeEach {
        $G = Get-TestGraph
    }
    It 'can export graph data to a file' {
        $G | Export-GraphData -Path $TestDrive
        (Get-Content -Path (Join-Path $TestDrive 'graph.csv'))[0] | Should -Be 'SourceId,SourceLabel,TargetId,TargetLabel,Weight,IsDirected'
    }
    It 'can export graph objects to JSON format strings' -Tag 'WindowsOnly' {
        $G | Export-GraphData -JSON -PassThru | Should -Match '"Edges":  \['
        $G | Export-GraphData -Format 'JSON' -PassThru | Should -Match '"Edges":  \['
        $G | Export-GraphData -JSON -Compress -PassThru | Should -Match '{"Edges":\[\{"Target"'
        $Graph = $G | Export-GraphData -JSON -PassThru | ConvertFrom-Json
        $Graph.Nodes | Should -HaveCount 3
        $Graph.Edges | Should -HaveCount 3
    }
    It 'can export graph objects to CSV format strings' {
        $Expected = "SourceId,SourceLabel,TargetId,TargetLabel,Weight,IsDirected`naaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa,a,bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb,b,1,False`nbbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb,b,cccccccc-cccc-cccc-cccc-cccccccccccc,c,1,False`naaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa,a,cccccccc-cccc-cccc-cccc-cccccccccccc,c,42,True`n"
        $G | Export-GraphData -CSV -PassThru | Should -Be $Expected
        $G | Export-GraphData -Format 'CSV' -PassThru | Should -Be $Expected
    }
    It 'can export graph objects to XML format strings' {
        [Xml]$Data = $G | Export-GraphData -XML -PassThru
        $Data.Graph.Edges.Edge | Should -HaveCount 3
        $Data.Graph.Edges.Edge[0].Node[0].id | Should -Be 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
        [Xml]$Data = $G | Export-GraphData -Format 'XML' -PassThru -Compress
        $Data.Graph.Edges.Edge | Should -HaveCount 3
    }
    It 'can export graph objects to mermaid format strings' {
        $Expected = "graph TD`n`taaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa[a] -- 1 --- bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb[b]`n`tbbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb[b] -- 1 --- cccccccc-cccc-cccc-cccc-cccccccccccc[c]`n`taaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa[a] -- 42 --> cccccccc-cccc-cccc-cccc-cccccccccccc[c]`n"
        $G | Export-GraphData -Mermaid -PassThru | Should -Be $Expected
        $G | Export-GraphData -Format 'Mermaid' -PassThru | Should -Be $Expected
    }
}
Describe 'Graph import helper functions' -Tag 'Local', 'Remote' {
    BeforeAll {
        function Get-TestGraph {
            $A = [Node]::New('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'a')
            $B = [Node]::New('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'b')
            $C = [Node]::New('cccccccc-cccc-cccc-cccc-cccccccccccc', 'c')
            $AB = New-Edge $A $B
            $AC = New-Edge $A $C -Directed -Weight 42
            $BC = New-Edge $B $C -Weight 5
            $Edges = $AB, $BC, $AC
            $Graph = [Graph]::New($Edges)
            $Graph
        }
    }
    BeforeEach {
        $G = Get-TestGraph
    }
    AfterEach {
        $Graph = Import-GraphData -FilePath $Path
        $Graph.Nodes.Count | Should -Be 3
        $Graph.Edges.Count | Should -Be 3
        $Graph.Edges.IsDirected | Should -Be $False, $False, $True
        $Graph.Edges.Weight | Should -Be 1, 5, 42
        foreach ($Node in $Graph.Nodes) {
            $Node.Neighbors | Should -HaveCount 2
        }
    }
    It 'can import graph objects from CSV file' {
        $Path = Join-Path $TestDrive 'file.csv'
        $Data = "SourceId,SourceLabel,TargetId,TargetLabel,Weight,IsDirected`naaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa,a,bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb,b,1,False`nbbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb,b,cccccccc-cccc-cccc-cccc-cccccccccccc,c,5,False`naaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa,a,cccccccc-cccc-cccc-cccc-cccccccccccc,c,42,True`n"
        $Data | Out-File -FilePath $Path
    }
    It 'can import graph objects from JSON file' {
        $Path = Join-Path $TestDrive 'file.json'
        $G | Export-GraphData -JSON -PassThru | Out-File -FilePath $Path
    }
    It 'can import graph objects from Mermaid file' {
        $Path = Join-Path $TestDrive 'file.mmd'
        $Data = "graph TD`n`taaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa[a] --   1 --- bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb[b]`n`tbbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb[b] -- 5  --- cccccccc-cccc-cccc-cccc-cccccccccccc[c]`n`taaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa[a] -- 42 --> cccccccc-cccc-cccc-cccc-cccccccccccc[c]`n"
        $Data | Out-File -FilePath $Path
    }
    It 'can import graph objects from XML file' {
        $Path = Join-Path $TestDrive 'file.xml'
        $G | Export-GraphData -XML -PassThru | Out-File -FilePath $Path
    }
}
Describe 'Graph creation helper functions' -Tag 'Local', 'Remote' {
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
