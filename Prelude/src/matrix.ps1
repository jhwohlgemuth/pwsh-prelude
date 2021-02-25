function New-Matrix {
    <#
    .SYNOPSIS
    Utility wrapper function for creating matrices
    .DESCRIPTION
    New-Matrix is a wrapper function for the [Matrix] class and is intended to reduce the effort required to create [Matrix] objects.

    Use "New-Matrix | Get-Member" to see available methods:

    Adj: Return matrix adjugate ("classical adjoint")
    > Note: Available as a class method - [Matrix]::Adj

    Det: Return matrix determinant (even matrices larger than 3x3
    > Note: Available as a class method - [Matrix]::Det

    Dot: Return dot product between matrix and one other matrix (with compatible size)
    > Note: Available as a class method - [Matrix]::Dot

    Clone: Return new matrix with identical values as original matrix

    Cofactor: Return cofactor for given row and column index pair
    > Example: $Matrix.Cofactor(0, 1)

    Indexes: Return list of "ij" pairs (useful for iterating through matrix values)
    > Example: (New-Matrix).Indexes() | ForEach-Object { "(i,j) = ($($_[0]),$($_[1]))" }

    Inverse: Return matrix inverse (Note: Det() must return non-zero value)
    > Note: Available as a class method - [Matrix]::Invert

    Multiply: Return result of multiplying matrix by scalar value (ex: 42)
    > Note: Available as a class method - [Matrix]::Multiply

    RemoveColumn: Return matrix with selected column removed

    RemoveRow: Return matrix with selected column removed

    Transpose: Return matrix transpose
    > Note: Available as a class method - [Matrix]::Transpose

    Trace: Return matrix trace (sum of diagonal elements)
    > Note: Available as a class method - [Matrix]::Trace

    *** All methods that return a [Matrix] object provide a "fluent" interface and can be chained ***

    *** All methods are "non destructive" and will return a clone of the original matrix (when applicable) ***

    .PARAMETER Size
    Size = @(number of rows, number of columns)
    .EXAMPLE
    $Matrix = 1..9 | matrix 3,3
    #>
    [CmdletBinding()]
    [Alias('matrix')]
    [OutputType([Matrix])]
    Param(
        [Parameter(ValueFromPipeline = $True)]
        [Array] $Values,
        [Parameter(Position = 0)]
        [Array] $Size = @(2, 2),
        [Switch] $Diagonal
    )
    Begin {
        $Matrix = New-Object 'Matrix' @($Size[0], $Size[1])
        if ($Values.Count -gt 0) {
            $Values = $Values | Invoke-Flatten
            if ($Diagonal) {
                $Index = 0
                foreach ($Pair in $Matrix.Indexes()) {
                    $Row, $Column = $Pair
                    if ($Row -eq $Column) {
                        $Matrix.Rows[$Row][$Column] = $Values[$Index]
                        $Index++
                    }
                }
            } else {
                $Matrix.Rows = $Values
            }
        }
    }
    End {
        if ($Input.Count -gt 0) {
            $Values = $Input | Invoke-Flatten
            if ($Diagonal) {
                $Index = 0
                foreach ($Pair in $Matrix.Indexes()) {
                    $Row, $Column = $Pair
                    if ($Row -eq $Column) {
                        $Matrix.Rows[$Row][$Column] = $Values[$Index]
                        $Index++
                    }
                }
            } else {
                $Matrix.Rows = $Values
            }
        }
        $Matrix
    }
}
function Test-Matrix {
    <#
    .SYNOPSIS
    Test if a matrix is one or more of the following:
      - Diagonal
      - Square
      - Symmetric
    .EXAMPLE
    $A = 1..4 | New-Matrix 2,2
    $A | Test-Matrix -Square
    # Returns True
    .EXAMPLE
    $A = 1..4 | New-Matrix 2,2
    $A | Test-Matrix -Square -Diagonal
    # Returns False
    #>
    [CmdletBinding()]
    [OutputType([Bool])]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        $Value,
        [Switch] $Diagonal,
        [Switch] $Square,
        [Switch] $Symmetric
    )
    if ($Value.GetType().Name -eq 'Matrix') {
        $Result = $True
        if ($Diagonal) {
            $Result = $Result -and $Value.IsDiagonal()
        }
        if ($Square) {
            $Result = $Result -and $Value.IsSquare()
        }
        if ($Symmetric) {
            $Result = $Result -and $Value.IsSymmetric()
        }
        return $Result
    }
    $False
}