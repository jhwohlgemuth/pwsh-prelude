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
    [OutputType([String])]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [String] $Path,
        [Switch] $Force
    )
    # UNDER CONSTRUCTION
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
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [ValidateScript( { Test-Path $_ })]
        [String] $Path
    )
    # UNDER CONSTRUCTION
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
        [Parameter(Mandatory = $True, Position = 0)]
        [Prelude.Node] $From,
        [Parameter(Mandatory = $True, Position = 1)]
        [Prelude.Node] $To,
        [Int] $Weight = 1,
        [Switch] $Directed
    )
    # UNDER CONSTRUCTION
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
    #>
    [CmdletBinding()]
    [OutputType([Prelude.Graph])]
    Param(
        [Parameter(Position = 0)]
        [Prelude.Node[]] $Nodes,
        [Parameter(Position = 1, ValueFromPipeline = $True)]
        [Prelude.Edge[]] $Edges
    )
    # UNDER CONSTRUCTION
}