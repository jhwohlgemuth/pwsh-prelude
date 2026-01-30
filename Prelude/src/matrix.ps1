[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'New-ComplexValue')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'New-Matrix')]
Param()

function Format-ComplexValue {
    <#
    .SYNOPSIS
    Utility method for rendering readable output for complex numbers
    .PARAMETER WithColor
    When -WithColor is used, the output will include color templates to add color (see Write-Label)
    #>
    [CmdletBinding()]
    [OutputType([String])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [System.Numerics.Complex] $Value,
        [Switch] $WithColor
    )
    $Real = $Value.Real
    $Imaginary = $Value.Imaginary
    if ($Real -eq 0 -and $Imaginary -eq 0) {
        '0'
    } else {
        $Re = if ($Real -eq 0) { '' } else { $Real }
        $Sign = if ([Math]::Sign($Imaginary) -lt 0) { '-' } else { '+' }
        $Op = if ($Re.Length -gt 0 -and $Imaginary -ne 0) { " $Sign " } else { '' }
        $Minus = if ($Imaginary -lt 0 -and $Re.Length -eq 0) { '-' } else { '' }
        $Im = if ($Imaginary -eq 0) { '' } else { [Math]::Abs($Imaginary) }
        $I = if ($Imaginary -ne 0) { 'i' } else { '' }
        if ($WithColor) {
            $WithI = if ($Imaginary -ne 0) { "{{#cyan $I}}" } else { '' }
            "${Re}${Op}${Minus}${Im}${WithI}"
        } else {
            "${Re}${Op}${Minus}${Im}${I}"
        }
    }
}
function Invoke-MatrixMap {
    <#
    .SYNOPSIS
    Apply passed function to each element of passed matrix and return new matrix with results.
    .EXAMPLE
    $A = 1..4 | matrix
    $AddOne = { Param($X) $X + 1 }
    $B = $A | matmap $AddOne
    #>
    [CmdletBinding()]
    [Alias('matmap')]
    [OutputType([Matrix])]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [Matrix] $InputMatrix,
        [Parameter(Position = 0)]
        [ScriptBlock] $Expression = { },
        [Switch] $Strict
    )
    Process {
        $Parameters = ($Expression | Get-ParameterList).Name
        $Morphism = switch ($Parameters.Count) {
            1 { [System.Func[Complex, Complex]]$Expression }
            3 { [System.Func[Complex, Int, Int, Complex]]$Expression }
            4 { [System.Func[Complex, Int, Int, Matrix, Complex]]$Expression }
            default {
                if ($Strict) {
                    throw 'Expression has wrong number of parameters'
                }
                $Identity = { param($X) $X }
                [System.Func[Complex, Complex]]$Identity
            }
        }
        $InputMatrix.Map($Morphism)
    }
}
function New-ComplexValue {
    <#
    .SYNOPSIS
    Utility method for creating complex values
    .PARAMETER Random
    Return a complex value with random real and imaginary parts
    .PARAMETER Bounds
    Minimum and maximum values for random real and imaginary parts
    .EXAMPLE
    $C = New-ComplexValue 2 3
    .EXAMPLE
    $C = 4, -1.5 | complex
    #>
    [CmdletBinding(DefaultParameterSetName = 'normal')]
    [Alias('complex')]
    [OutputType([System.Numerics.Complex])]
    Param(
        [Parameter(ValueFromPipeline = $True)]
        [Array] $Parts,
        [Parameter(Position = 0)]
        [Alias('Re')]
        [Int] $Real = 0,
        [Parameter(Position = 1)]
        [Alias('Im')]
        [Int] $Imaginary = 0,
        [Parameter(ParameterSetName = 'random')]
        [Switch] $Random,
        [Parameter(ParameterSetName = 'random')]
        [ValidateCount(2, 2)]
        [Double[]] $Bounds = @(-10.0, 10.0)
    )
    End {
        $Re, $Im = if ($Input.Count -ge 2) {
            $Input[0, 1]
        } else {
            if ($Random) {
                $Minimum, $Maximum = $Bounds
                $Parameters = @{ Minimum = $Minimum; Maximum = $Maximum }
                (Get-Random @Parameters), (Get-Random @Parameters)
            } else {
                $Real, $Imaginary
            }
        }
        [System.Numerics.Complex]::New($Re, $Im)
    }
}
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
    .PARAMETER Diagonal
    Add values to matrix along diagonal
    .PARAMETER Unit
    Create unit matrix with size, -Size
    .PARAMETER Random
    Create random matrix with size, -Size
    .PARAMETER Bounds
    Minimum and maximum values for matrix random complex values
    .EXAMPLE
    $Matrix = 1..9 | matrix 3,3
    #>
    [CmdletBinding(DefaultParameterSetName = 'normal')]
    [Alias('matrix')]
    [OutputType([Matrix])]
    Param(
        [Parameter(ValueFromPipeline = $True)]
        [Array] $Values,
        [Parameter(Position = 0)]
        [Array] $Size = @(2, 2),
        [Switch] $Diagonal,
        [Switch] $Identity,
        [Switch] $Unit,
        [Switch] $Custom,
        [Parameter(ParameterSetName = 'random')]
        [Switch] $Random,
        [Parameter(ParameterSetName = 'random')]
        [ValidateCount(2, 2)]
        [Double[]] $Bounds = @(-10.0, 10.0)
    )
    Begin {
        function Update-Matrix {
            param(
                [Matrix] $Matrix,
                [String] $MatrixType,
                [Array] $Values
            )
            switch ($MatrixType) {
                'Diagonal' {
                    $Values = $Values | Invoke-Flatten
                    $Index = 0
                    foreach ($Pair in $Matrix.Indexes()) {
                        $Row, $Column = $Pair
                        if ($Row -eq $Column) {
                            $Matrix[$Row][$Column] = $Values[$Index]
                            $Index++
                        }
                    }
                    break
                }
                'Custom' {
                    $Matrix.Rows = $Values | Invoke-Flatten
                }
                default {
                    # Do nothing
                }
            }
        }
        $M, $N = if ($Size.Count -eq 1) { $Size * 2 } else { $Size }
        $Matrix = New-Object 'Matrix' @($M, $N)
        $MatrixType = Find-FirstTrueVariable 'Custom', 'Diagonal', 'Identity', 'Unit', 'Random'
        if ($Values.Count -gt 0) {
            Update-Matrix -Values $Values -Matrix $Matrix -MatrixType $MatrixType
        }
    }
    End {
        $Values = $Input
        if ($Values.Count -gt 0) {
            Update-Matrix -Values $Values -Matrix $Matrix -MatrixType $MatrixType
        } else {
            switch ($MatrixType) {
                'Unit' {
                    $Matrix = [Matrix]::Unit($M, $N)
                    break
                }
                'Identity' {
                    $Matrix = [Matrix]::Identity($M)
                    break
                }
                'Random' {
                    $Matrix.Rows = 1..($M * $N) | ForEach-Object {
                        New-ComplexValue -Random -Bounds $Bounds
                    }
                    break
                }
                default {
                    # Do nothing
                }
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
    1..4 | New-Matrix 2,2 | Test-Matrix -Square
    # True
    .EXAMPLE
    1..4 | New-Matrix 2,2 | Test-Matrix -Square -Diagonal
    # False
    #>
    [CmdletBinding()]
    [OutputType([Bool])]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        $Value,
        [Switch] $Diagonal,
        [Switch] $Hermitian,
        [Switch] $Square,
        [Switch] $Symmetric
    )
    if ($Value.GetType().Name -eq 'Matrix') {
        $Result = $True
        if ($Diagonal) {
            $Result = $Result -and $Value.IsDiagonal()
        }
        if ($Hermitian) {
            $Result = $Result -and $Value.IsHermitian()
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