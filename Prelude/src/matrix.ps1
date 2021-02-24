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
    Test is a matrix value is one or more of the following
    #>
    [CmdletBinding()]
    [OutputType([Bool])]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [Matrix] $Value,
        [Switch] $Diagonal,
        [Switch] $Square,
        [Switch] $Symmetric
    )
    $Result = $True
    $Result
}
function Test-DiagonalMatrix {
    <#
    .SYNOPSIS
    Return true if passed value is a "diagonal" matrix
    .DESCRIPTION
    A diagonal matrix is a matrix in which the entries outside the main diagonal are all zero.
    Example:
        1 0
        0 1

    The primary purpose of this function is to be used as a Matrix object type extension.
    #>
    [CmdletBinding()]
    [OutputType([Bool])]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [Matrix] $Value
    )
    Process {
        (Test-SquareMatrix $Value) -and ($Value.Indexes() | ForEach-Object {
                $Row, $Col = $_
                ($Row -eq $Col) -or ($Value.Rows[$Row][$Col] -eq 0)
            } | Invoke-Reduce -Every)
    }
}
function Test-SquareMatrix {
    <#
    .SYNOPSIS
    Return true if passed value is a "square" matrix
    .DESCRIPTION
    A square matrix is a matrix that has the same number of rows as columns.
    Example:
        1 1
        1 1

    The primary purpose of this function is to be used as a Matrix object type extension.
    #>
    [CmdletBinding()]
    [OutputType([Bool])]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [Matrix] $Value
    )
    Process {
        $Rows, $Columns = $Value.Size
        $Rows -eq $Columns
    }
}
function Test-SymmetricMatrix {
    <#
    .SYNOPSIS
    Return true if passed value is a "symmetric" matrix
    .DESCRIPTION
    A symmetric matrix is a matrix for which every element of the matrix (a_ij -eq a_ji) is true
    Example:
        1 2 3
        2 1 4
        3 4 1

    The primary purpose of this function is to be used as a Matrix object type extension.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'Result')]
    [CmdletBinding()]
    [OutputType([Bool])]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [Matrix] $Value
    )
    Process {
        (Test-SquareMatrix $Value) -and (0..($Value.Size[0] - 1) | ForEach-Object {
                $Row = $_
                0..$Row | ForEach-Object { $Value.Rows[$Row][$_] -eq $Value.Rows[$_][$Row] }
            } | Invoke-Reduce -Every)
    }
}