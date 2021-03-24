function Export-GraphData {
    <#
    .SYNOPSIS
    Export graph data to an XML file or a JSON file.
    .PARAMETER Path
    Path to file intended for data export
    .PARAMETER Force
    Overwrite file at destination path, if one exists
    .EXAMPLE
    Export-GraphData 'path/to/file.xml'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Prelude.Graph] $Graph,
        [ValidateScript( { Test-Path $_ })]
        [String] $Path = (Get-Location),
        [String] $Name = 'graph',
        [Switch] $CSV,
        [Switch] $JSON,
        [Switch] $XML,
        [Switch] $Mermaid,
        [ValidateSet('CSV', 'JSON', 'XML', 'Mermaid')]
        [String] $Format,
        [Switch] $PassThru,
        [Switch] $Force
    )
    $Format = if ($Format.Length -gt 0) {
        $Format
    } else {
        Find-FirstTrueVariable 'CSV', 'JSON', 'XML', 'Mermaid'
    }
    switch ($Format) {
        'CSV' {
            $Name = "${Name}.csv"
            $Result = "SourceId,SourceLabel,SourceWeight,TargetId,TargetLabel,TargetWeight`n"
            foreach ($Edge in $Graph.Edges) {
                $Source = $Edge.Source
                $Target = $Edge.Target
                $Result += "$($Source.Id),$($Source.Label),$($Source.Weight),$($Source.IsDirected),$($Target.Id),$($Target.Label),$($Target.Weight),$($Target.IsDirected)`n"
            }
        }
        'JSON' {
            # UNDER CONSTRUCTION
            break
        }
        'XML' {
            # UNDER CONSTRUCTION
            break
        }
        'Mermaid' {
            $Name = "${Name}.mmd"
            $Result = "graph TD`n"
            foreach ($Edge in $Graph.Edges) {
                $Source = $Edge.Source
                $Target = $Edge.Target
                $Arrow = if ($Edge.IsDirected) { '-->' } else { '---' }
                $Result += "`t$($Source.Id)[$($Source.Label)] ${Arrow} $($Target.Id)[$($Target.Label)]`n"
            }
        }
    }
    if ($PassThru) {
        $Result | Write-Verbose
        $Result
    } else {
        $Result | Out-File -FilePath (Join-Path $Path $Name)
    }
}
function Import-GraphData {
    <#
    .SYNOPSIS
    Import graph data from an XML file or a JSON file.
    .PARAMETER Path
    Path to file intended for data import
    .EXAMPLE
    $G = Import-GraphData 'path/to/file.xml'
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter')]
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [ValidateScript( { Test-Path $_ })]
        [String] $Path
    )
    $Extension = [System.IO.Path]::GetExtension($Path).Substring(1).ToUpper()
    switch ($Extension) {
        'JSON' {
            # UNDER CONSTRUCTION
            break
        }
        'TXT' {
            # UNDER CONSTRUCTION
            break
        }
        'XML' {
            # UNDER CONSTRUCTION
            break
        }
        Default {
            # UNDER CONSTRUCTION
            break
        }
    }
}
function New-Edge {
    <#
    .SYNOPSIS
    Helper cmdlet for creating graph edge objects
    .PARAMETER From
    One node of edge. If edge is directed, this node will be the "source" node.
    .PARAMETER To
    One node of edge. If edge is directed, this node will be the "detination" node.
    .PARAMETER Weight
    Edge weight. A graph can be regarded as "un-weighted" when all edges have the same weight.
    .PARAMETER Directed
    Switch to designate an edge as directed.
    .EXAMPLE
    $A = [Node]'a'
    $B = [Node]'b'
    $AB = New-Edge $A $B
    .EXAMPLE
    $AB = New-Edge 'a' 'b'
    #>
    [CmdletBinding()]
    [Alias('edge')]
    [OutputType([Prelude.Edge])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Node] $From,
        [Parameter(Mandatory = $True, Position = 1)]
        [Node] $To,
        [Int] $Weight = 1,
        [Switch] $Directed
    )
    if ($Directed) {
        New-Object 'Prelude.DirectedEdge' @($From, $To, $Weight)
    } else {
        New-Object 'Prelude.Edge' @($From, $To, $Weight)
    }
}
function New-Graph {
    <#
    .SYNOPSIS
    Helper cmdlet for creating graph edge objects
    .PARAMETER Nodes
    Array of graph nodes
    .PARAMETER Edges
    Array of graph edges
    .EXAMPLE
    $G = New-Graph $Nodes $Edges
    .EXAMPLE
    $G = $Edges | New-Graph
    .EXAMPLE
    $K4 = New-Graph -Complete -N 4
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function')]
    [CmdletBinding(DefaultParameterSetName = 'custom')]
    [OutputType([Graph])]
    Param(
        [Parameter(ParameterSetName = 'custom', Position = 0)]
        [Alias('V')]
        [Node[]] $Nodes,
        [Parameter(ParameterSetName = 'custom', Position = 1, ValueFromPipeline = $True)]
        [Alias('E')]
        [Edge[]] $Edges,
        [Parameter(ParameterSetName = 'custom')]
        [Switch] $Custom,
        [Parameter(ParameterSetName = 'complete')]
        [Switch] $Complete,
        [Parameter(ParameterSetName = 'smallworld')]
        [Alias('SWN')]
        [Switch] $SmallWorld,
        [Parameter(ParameterSetName = 'bipartite')]
        [Switch] $Bipartite,
        [Parameter(ParameterSetName = 'bipartite')]
        [Int] $Left,
        [Parameter(ParameterSetName = 'bipartite')]
        [Int] $Right,
        [Parameter(ParameterSetName = 'complete', Mandatory = $True)]
        [Parameter(ParameterSetName = 'smallworld', Mandatory = $True)]
        [Alias('N')]
        [Int] $NodeCount,
        [Parameter(ParameterSetName = 'smallworld', Mandatory = $True)]
        [Alias('K')]
        [Double] $MeanDegree
    )
    Begin {
        $GraphType = Find-FirstTrueVariable 'Custom', 'Complete', 'SmallWorld', 'Bipartite'
        function Invoke-NewGraph {
            Param(
                [Edge[]] $Edges
            )
            switch ($GraphType) {
                'Complete' {
                    "==> Creating complete graph with ${NodeCount} nodes" | Write-Verbose
                    [Graph]::Complete($NodeCount)
                    break
                }
                'SmallWorld' {
                    '==> Creating small world graph' | Write-Verbose
                    break
                }
                'Bipartite' {
                    '==> Creating Bipartite graph' | Write-Verbose
                    [Graph]::Bipartite($Left, $Right)
                    break
                }
                Default {
                    if ($Nodes.Count -gt 0) {
                        "==> Creating custom graph with $($Nodes.Count) nodes and $($Edges.Count) edges" | Write-Verbose
                        [Graph]::New($Nodes, $Edges)
                    } elseif ($Edges.Count -gt 0) {
                        "==> Creating custom graph from $($Edges.Count) edges" | Write-Verbose
                        [Graph]::New($Edges)
                    }
                }
            }
        }
        if ($Edges.Count -gt 0 -or $GraphType -ne 'Custom') {
            Invoke-NewGraph -Edges $Edges
        }
    }
    End {
        if ($Input.Count -gt 0 -and $GraphType -eq 'Custom') {
            Invoke-NewGraph -Edges $Input
        }
    }
}