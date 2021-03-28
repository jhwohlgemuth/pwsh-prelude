function Export-GraphData {
    <#
    .SYNOPSIS
    Export graph data to an XML file or a JSON file.
    .PARAMETER Path
    Path to file intended for data export
    .PARAMETER Force
    Overwrite file at destination path, if one exists
    .EXAMPLE
    # Export graph data to ./graph.csv
    $Graph | Export-GraphData
    .EXAMPLE
    # Write mermaid format graph data to terminal
    $Graph | Export-GraphData -Mermaid -PassThru | Write-Color -Cyan
    .EXAMPLE
    # Export compressed JSON data (compress also works with XML format)
    $Graph | Export-GraphData -JSON -Compress
    .EXAMPLE
    # Supports passing format as string paramter
    $Graph | Export-GraphData -Format 'XML'
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
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
        [Switch] $Compress,
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
            $Result = "SourceId,SourceLabel,TargetId,TargetLabel,Weight,IsDirected`n"
            foreach ($Edge in $Graph.Edges) {
                $Source = $Edge.Source
                $Target = $Edge.Target
                $Result += "$($Source.Id),$($Source.Label),$($Target.Id),$($Target.Label),$($Edge.Weight),$($Edge.IsDirected)`n"
            }
        }
        'JSON' {
            function Format-Node {
                Param(
                    [Parameter(ValueFromPipeline = $True)]
                    [Node] $Node
                )
                Process {
                    $Node | Select-Object 'Id', 'Label'
                }
            }
            $Name = "${Name}.json"
            $Nodes = $Graph.Nodes | Format-Node
            $Edges = $Graph.Edges
            $Result = @{
                Nodes = $Nodes
                Edges = $Edges | ForEach-Object {
                    @{
                        Source = $_.Source | Format-Node
                        Target = $_.Target | Format-Node
                        Weight = $_.Weight
                        IsDirected = $_.IsDirected
                    }
                }
            } | ConvertTo-Json -Depth 3 -Compress:$Compress
        }
        'XML' {
            $Name = "${Name}.xml"
            $Break = if ($Compress) { '' } else { "`n" }
            $Tab = if ($Compress) { '' } else { '    ' }
            $Header = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>${Break}"
            $Result = "${Header}<Graph>${Break}${Tab}<Edges>${Break}"
            $Edges = $Graph.Edges | ForEach-Object {
                $EdgeOpen = "<Edge id=`"$($_.Id)`" weight=`"$($_.Weight)`" directed=`"$($_.IsDirected.ToString().ToLower())`">${Break}"
                $Source = "${Tab}${Tab}${Tab}<Node type=`"source`" id=`"$($_.Source.Id)`" label=`"$($_.Source.Label)`"/>"
                $Target = "${Tab}${Tab}${Tab}<Node type=`"target`" id=`"$($_.Target.Id)`" label=`"$($_.Target.Label)`"/>"
                "${Tab}${Tab}${EdgeOpen}${Source}${Break}${Target}${Break}${Tab}${Tab}</Edge>"
            }
            $Result += ($Edges -join $Break)
            $Result += "${Break}${Tab}</Edges>${Break}</Graph>"
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
    [CmdletBinding()]
    [OutputType([Prelude.Graph])]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [ValidateScript( { Test-Path $_ })]
        [String] $FilePath
    )
    $Extension = [System.IO.Path]::GetExtension($FilePath).Substring(1).ToUpper()
    switch ($Extension) {
        'CSV' {
            $Rows = Import-Csv -Path $FilePath
            $Graph = [Graph]::New()
            foreach ($Row in $Rows) {
                $Source = [Node]::New($Row.SourceId, $Row.SourceLabel)
                $Target = [Node]::New($Row.TargetId, $Row.TargetLabel)
                $From = if ($Graph.GetNode($Source.Id)) { $Graph.GetNode($Source.Id) } else { $Source }
                $To = if ($Graph.GetNode($Target.Id)) { $Graph.GetNode($Target.Id) } else { $Target }
                $IsDirected = if ($Row.IsDirected -eq 'True') { $True } else { $False }
                $Edge = New-Edge -From $From -To $To -Weight $Row.Weight -Directed:$IsDirected
                $Graph.Add($From, $To).Add($Edge) | Out-Null
            }
            $Graph
        }
        'JSON' {
            # UNDER CONSTRUCTION
            break
        }
        'MMD' {
            $IsNotSquareBracket = { Param($X) $X -ne '[' }
            $_, $Lines = (Get-Content -Path $FilePath) -split "`n" | Invoke-Method 'Trim' | Deny-Empty
            $Data = $Lines | Invoke-Operator split ' ' | Invoke-Chunk -Size 3
            $Graph = [Graph]::New()
            foreach ($Item in $Data) {
                $SourceId = $Item[0] | Invoke-TakeWhile $IsNotSquareBracket
                $TargetId = $Item[2] | Invoke-TakeWhile $IsNotSquareBracket
                $SourceLabel = if (($Item[0] -match '\[.*\]')) { $Matches[0] } else { 'source' }
                $TargetLabel = if (($Item[1] -match '\[.*\]')) { $Matches[0] } else { 'target' }
                $Source = [Node]::New($SourceId, $SourceLabel)
                $Target = [Node]::New($TargetId, $TargetLabel)
                $From = if ($Graph.GetNode($Source.Id)) { $Graph.GetNode($Source.Id) } else { $Source }
                $To = if ($Graph.GetNode($Target.Id)) { $Graph.GetNode($Target.Id) } else { $Target }
                $IsDirected = if ($Item[1] -eq '-->') { $True } else { $False }
                $Edge = New-Edge -From $From -To $To -Directed:$IsDirected
                $Graph.Add($From, $To).Add($Edge) | Out-Null
            }
            $Graph
        }
        'XML' {
            [Xml]$Data = Get-Content -Path $FilePath
            $Graph = [Graph]::New()
            foreach ($Item in $Data.Graph.Edges.Edge) {
                $Source = [Node]::New($Item.Node[0].id, $Item.Node[0].label)
                $Target = [Node]::New($Item.Node[1].id, $Item.Node[1].label)
                $From = if ($Graph.GetNode($Source.Id)) { $Graph.GetNode($Source.Id) } else { $Source }
                $To = if ($Graph.GetNode($Target.Id)) { $Graph.GetNode($Target.Id) } else { $Target }
                $IsDirected = if ($Item.directed -eq 'true') { $True } else { $False }
                $Edge = New-Edge -From $From -To $To -Weight $Item.weight -Directed:$IsDirected
                $Graph.Add($From, $To).Add($Edge) | Out-Null
            }
            $Graph
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