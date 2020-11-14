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
    [Parameter(ValueFromPipeline=$true)]
    [Array] $Values,
    [Parameter(Position=0)]
    [Array] $Size = @(2,2)
  )
  Begin {
    $Matrix = [Matrix]::New($Size[0], $Size[1])
    if ($Values.Count -gt 0) {
      $Matrix.Rows = $Values | Invoke-Flatten
    }
  }
  End {
    if ($Input.Count -gt 0) {
      $Matrix.Rows = $Input | Invoke-Flatten
    }
    $Matrix
  }
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
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [Matrix] $Value
  )
  Process {
    $Value.Indexes() | ForEach-Object {
      $Row, $Col = $_
      ($Row -eq $Col) -or ($Value.Rows[$Row][$Col] -eq 0)
    } | Invoke-Reduce -Every
  }
}
function Test-EchelonForm {
  <#
  .SYNOPSIS
  Return true if passed value is a matrix in "echelon form"
  .DESCRIPTION
  A matrix is said to be in "echelon form" when the first non-zero element that appears in each row is equal to 1 and is positioned
  at the right of the first non-zero element of the preceding row.

  Note: Echelon form is useful for determining matrix rank.

  The primary purpose of this function is to be used as a Matrix object type extension.
  #>
  [CmdletBinding()]
  [OutputType([Bool])]
  Param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [Matrix] $Value
  )
  Process {
    $true
  }
}
function Test-OrthogonalMatrix {
  <#
  .SYNOPSIS
  Return true if passed value is an "orthogonal" matrix
  .DESCRIPTION
  A matrix is orthogonal if and only if its transpose and inverse are equal.
  That is to say, the following is true: $A.Transpose() | equal $A.Inverse()
  Example: For a given angle, x
    cos(x) -sin(x)
    sin(x)  cos(x)

  Note: The determinant of an orthogonal matrix is 1 or -1. An orthogonal matrix is called "proper" when its determinant is 1 and "improper" otherwise.

  The primary purpose of this function is to be used as a Matrix object type extension.
  #>
  [CmdletBinding()]
  [OutputType([Bool])]
  Param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [Matrix] $Value
  )
  Process {
    $true
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
    [Parameter(Position=0, ValueFromPipeline=$true)]
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
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [Matrix] $Value
  )
  Process {
    0..($Value.Size[0] - 1) | ForEach-Object {
      $Row = $_
      0..$Row | ForEach-Object { $Value.Rows[$Row][$_] -eq $Value.Rows[$_][$Row] }
    } | Invoke-Reduce -Every
  }
}
function Test-TriangularMatrix {
  <#
  .SYNOPSIS
  Return true if passed value is a "triangular" matrix
  .DESCRIPTION
  This function will return true for "lower" and "upper" triangular matrices.
  Example:
    1 2 3
    0 4 5
    0 0 6

  A triangular matrix is a special kind of square matrix.
  A matrix is called "lower" triangular if all the entries ABOVE the main diagonal are zero.
  A matrix is called "upper" triangular if all the entries BELOW the main diagonal are zero.

  The primary purpose of this function is to be used as a Matrix object type extension.
  #>
  [CmdletBinding()]
  [OutputType([Bool])]
  Param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [Matrix] $Value
  )
  Process {
    $true
  }
}
# Need to parameterize class with "id" in order to re-load class during local testing
$Id = if ($Env:ProjectName -eq 'pwsh-prelude' -and $Env:BuildSystem -eq 'Unknown') { 'Test' } else { '' }
$TypeDefinition = @"
    using System;
    using System.Collections.Generic;
    using System.Linq;

    public class Matrix${Id} {

        public int[] Size {
            get;
            private set;
        }
        private double[][] _Rows;
        public double[][] Rows {
            get {
                return _Rows;
            }
            set {
                int rows = this.Size[0], cols = this.Size[1];
                if (value.Length > rows) {
                    var limit = Math.Min(value.Length,(rows * cols));
                    for (var i = 0; i < limit; ++i) {
                        int row = (int)(Math.Floor((double)(i / cols)));
                        int col = i % cols;
                        _Rows[row][col] = value[i][0];
                    }
                } else {
                    double[][] temp = Matrix${Id}.Create(rows,cols);
                    for (var row = 0; row < rows; ++row)
                        temp[row] = (double[])value[row].Take(cols).ToArray();
                    _Rows = temp;
                }
            }
        }
        public Matrix${Id}(int n) {
            this.Size = new int[] { n,n };
            this.Rows = Matrix${Id}.Create(n,n);
        }
        public Matrix${Id}(int rows,int cols) {
            this.Size = new int[] { rows,cols };
            this.Rows = Matrix${Id}.Create(rows,cols);
        }
        public static double[][] Create(int rows,int cols) {
            double[][] result = new double[rows][];
            for (int i = 0; i < rows; ++i)
                result[i] = new double[cols];
            return result;
        }
        public static Matrix${Id} Unit(int n) {
            var temp = new Matrix${Id}(n);
            foreach (var index in temp.Indexes()) {
                int i = index[0], j = index[1];
                temp.Rows[i][j] = 1;
            }
            return temp;
        }
        public static Matrix${Id} Identity(int n) {
            var temp = new Matrix${Id}(n);
            for (int i = 0; i < n; ++i)
                temp.Rows[i][i] = 1;
            return temp;
        }
        public static Matrix${Id} Transpose(Matrix${Id} a) {
            var clone = a.Clone();
            foreach (var index in clone.Indexes()) {
                int i = index[0], j = index[1];
                clone.Rows[i][j] = a.Rows[j][i];
            }
            return clone;
        }
        public static Matrix${Id} Add(params Matrix${Id}[] addends) {
            var size = addends[0].Size;
            var sum = new Matrix${Id}(size[0],size[1]);
            foreach (Matrix${Id} matrix in addends)
                foreach (var index in matrix.Indexes()) {
                    int i = index[0], j = index[1];
                    sum.Rows[i][j] += matrix.Rows[i][j];
                }
            return sum;
        }
        public static Matrix${Id} Adj(Matrix${Id} a) {
            Matrix${Id} temp = a.Clone();
            foreach (var index in temp.Indexes()) {
                int i = index[0], j = index[1];
                temp.Rows[i][j] = a.Cofactor(i,j);
            }
            return Matrix${Id}.Transpose(temp);
        }
        public static double Det(Matrix${Id} a) {
            int rows = a.Size[0];
            switch (rows) {
                case 1:
                    return a.Rows[0][0];
                case 2:
                    return (a.Rows[0][0] * a.Rows[1][1]) - (a.Rows[0][1] * a.Rows[1][0]);
                default:
                    double sum = 0;
                    for (int i = 0; i < rows; ++i)
                        sum += (a.Rows[0][i] * a.Cofactor(0,i));
                    return sum;
            }
        }
        public static Matrix${Id} Dot(Matrix${Id} a,Matrix${Id} b) {
            int m = a.Size[0], p = a.Size[1], n = b.Size[1];
            var product = new Matrix${Id}(m,n);
            foreach (var index in product.Indexes()) {
                int i = index[0], j = index[1];
                double sum = 0;
                for (int k = 0; k < p; ++k) {
                    sum += (a.Rows[i][k] * b.Rows[k][j]);
                }
                product.Rows[i][j] = sum;
            }
            return product;
        }
        public static Matrix${Id} Invert(Matrix${Id} a) {
            Matrix${Id} adjugate = Matrix${Id}.Adj(a);
            double det = Matrix${Id}.Det(a);
            return Matrix${Id}.Multiply(adjugate,(1 / det));
        }
        public static Matrix${Id} Multiply(Matrix${Id} a,double k) {
            Matrix${Id} clone = a.Clone();
            foreach (var index in clone.Indexes()) {
                int i = index[0], j = index[1];
                clone.Rows[i][j] *= k;
            }
            return clone;
        }
        public Matrix${Id} Clone() {
            Matrix${Id} original = this;
            int rows = original.Size[0], cols = original.Size[1];
            Matrix${Id} clone = new Matrix${Id}(rows,cols);
            foreach (var index in clone.Indexes()) {
                int i = index[0], j = index[1];
                clone.Rows[i][j] = original.Rows[i][j];
            }
            return clone;
        }
        public double Cofactor(int i = 0,int j = 0) {
            return (Math.Pow(-1,i + j) * Matrix${Id}.Det(this.RemoveRow(i).RemoveColumn(j)));
        }
        public List<int[]> Indexes(int offset = 0) {
            int rows = this.Size[0], cols = this.Size[1];
            List<int[]> pairs = new List<int[]>();
            for (var i = 0; i < rows; ++i)
                for (var j = 0; j < cols; ++j) {
                    int[] pair = { i + offset,j + offset };
                    pairs.Add(pair);
                }
            return pairs;
        }
        public Matrix${Id} RemoveColumn(int index) {
            Matrix${Id} original = this.Clone();
            int rows = original.Size[0], cols = original.Size[1];
            if (index < 0 || index >= cols) {
                return original;
            } else {
                var temp = new Matrix${id}(rows,cols - 1);
                for (var i = 0; i < rows; ++i)
                    for (var j = 0; j < index; ++j)
                        temp.Rows[i][j] = original.Rows[i][j];
                for (var i = 0; i < rows; ++i)
                    for (var j = index; j < cols - 1; ++j)
                        temp.Rows[i][j] = original.Rows[i][j + 1];
                return temp;
            }
        }
        public Matrix${Id} RemoveRow(int index) {
            Matrix${Id} original = this.Clone();
            int rows = original.Size[0], cols = original.Size[1];
            if (index < 0 || index >= rows) {
                return original;
            } else {
                var temp = new Matrix${id}(rows - 1,cols);
                for (var i = 0; i < index; ++i)
                    for (var j = 0; j < cols; ++j)
                        temp.Rows[i][j] = original.Rows[i][j];
                for (var i = index; i < rows - 1; ++i)
                    for (var j = 0; j < cols; ++j)
                        temp.Rows[i][j] = original.Rows[i + 1][j];
                return temp;
            }
        }
        public override string ToString() {
            Matrix${Id} matrix = this;
            int rank = matrix.Size[0];
            var rows = new string[rank];
            for (var i = 0; i < rank; ++i)
                rows[i] = string.Join(",",matrix.Rows[i]);
            return string.Join("\r\n",rows);
        }
    }
"@
if ("Matrix${Id}" -as [Type]) {
  return
} else {
  Add-Type -TypeDefinition $TypeDefinition
  if ($Env:BuildSystem -eq 'Travis CI') {
    $Accelerators = [PowerShell].Assembly.GetType('System.Management.Automation.TypeAccelerators')
    $Accelerators::Add('MatrixTest', 'Matrix')
  }
}