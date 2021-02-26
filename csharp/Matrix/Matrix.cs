using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using static System.Math;
using static System.Linq.Enumerable;

namespace Prelude {
    public class Matrix : IEquatable<Matrix>, IComparable<Matrix> {
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
                int rowCount = Size[0], columnCount = Size[1];
                if (value.Length > rowCount) {
                    var limit = Min(value.Length, rowCount * columnCount);
                    for (var i = 0; i < limit; ++i) {
                        int row = (int)Floor((double)(i / columnCount));
                        int col = i % columnCount;
                        _Rows[row][col] = value[i][0];
                    }
                } else {
                    double[][] temp = Create<double>(rowCount, columnCount);
                    for (var row = 0; row < rowCount; ++row)
                        temp[row] = value[row].Take(columnCount).ToArray();
                    _Rows = temp;
                }
            }
        }
        public double[] this[int rowCount] {
            get {
                return Rows[rowCount];
            }
            set {
                Rows[rowCount] = value;
            }
        }
        public double this[int rowCount, int columnCount] {
            get {
                return Rows[rowCount][columnCount];
            }
            set {
                Rows[rowCount][columnCount] = value;
            }
        }
        public IEnumerable<double> Values {
            get {
                foreach (var row in Rows)
                    foreach (var value in row)
                        yield return value;
            }
        }
        public bool Equals(Matrix other) {
            if (other == null)
                return false;
            if (other.Size[0] == Size[0] && other.Size[1] == Size[1]) {
                foreach (var pair in other.Indexes()) {
                    int i = pair[0], j = pair[1];
                    if (other.Rows[i][j] != Rows[i][j])
                        return false;

                }
                return true;
            } else {
                return false;
            }
        }
        /// <summary>
        /// Determines if two matrices are equal
        /// </summary>
        /// <param name="obj"></param>
        /// <seealso cref="operator=="/>
        /// <seealso cref="operator!="/>
        /// <seealso cref="GetHashCode"/>
        public override bool Equals(object obj) {
            Matrix a = obj as Matrix;
            return Equals(a);
        }
        public override int GetHashCode() => Values.GetHashCode();
        public static bool operator ==(Matrix left, Matrix right) {
            if (((object)left) == null || ((object)right == null))
                return Equals(left, right);
            return left.Equals(right);
        }
        public static bool operator !=(Matrix left, Matrix right) {
            if (((object)left) == null || ((object)right == null))
                return !Equals(left, right);
            return !(left.Equals(right));
        }
        /// <summary>
        /// Constructor for creating empty (all values are 0) square (# of rows = # of columns) matrices
        /// </summary>
        /// <param name="n">Number of rows/columns</param>
        public Matrix(int n) {
            Size = new int[] { n, n };
            Rows = Create<double>(n, n);
        }
        /// <summary>
        /// Constructor for creating matrices of arbitrary size
        /// </summary>
        /// <param name="rowCount">Number of rows</param>
        /// <param name="columnCount">Number of columns</param>
        public Matrix(int rowCount, int columnCount) {
            Size = new int[] { rowCount, columnCount };
            Rows = Create<double>(rowCount, columnCount);
        }
        /// <summary>
        /// Add matrices, element by element
        /// </summary>
        /// <param name="addends">Matrices to add</param>
        /// <returns>Matrix</returns>
        public static Matrix Add(params Matrix[] addends) {
            var size = addends[0].Size;
            var sum = new Matrix(size[0], size[1]);
            foreach (Matrix matrix in addends)
                foreach (var index in matrix.Indexes()) {
                    int i = index[0], j = index[1];
                    sum.Rows[i][j] += matrix.Rows[i][j];
                }
            return sum;
        }
        public static Matrix operator +(Matrix left, Matrix right) => Add(left, right);
        public static Matrix operator -(Matrix minuend, Matrix subtrahend) => Add(minuend, Multiply(subtrahend, -1));
        /// <summary>
        /// Calculate classical adjoint matrix (also known as adjugate) of a given matrix
        /// </summary>
        /// <param name="a">Square matrix</param>
        /// <returns>Matrix</returns>
        /// <remarks>
        /// In linear algebra, the classical adjoint is the transpose of the cofactor matrix
        /// </remarks>
        /// <see cref="Cofactor"/>
        public static Matrix Adj(Matrix a) {
            var temp = a.Clone();
            foreach (var index in temp.Indexes()) {
                int i = index[0], j = index[1];
                temp.Rows[i][j] = a.Cofactor(i, j);
            }
            return Transpose(temp);
        }
        public int CompareTo(Matrix other) {
            if (other != null) {
                return (this == other ? 0 : 1);
            } else {
                throw new ArgumentException("Parameter is not a Matrix");
            }
        }
        /// <summary>
        /// Create rows that are used to store matrix elements
        /// </summary>
        /// <typeparam name="T">Type of matrix elements</typeparam>
        /// <param name="rowCount">Number of rows</param>
        /// <param name="columnCount">Number of columns</param>
        /// <returns>Two dimensional array of type, T</returns>
        public static T[][] Create<T>(int rowCount, int columnCount) {
            T[][] result = new T[rowCount][];
            for (int i = 0; i < rowCount; ++i)
                result[i] = new T[columnCount];
            return result;
        }
        /// <summary>
        /// Calculate determinant of a given matrix
        /// </summary>
        /// <param name="a">Input matrix</param>
        /// <returns>Scalar value</returns>
        /// <remarks>
        /// This method uses a recursive algorithm that leverages the relationship between determinants and cofactor matrices to calculate determinants of matrices with more rows/columns than 2.
        /// </remarks>
        /// <see cref="CalculateDeterminantParallel(Matrix)"/>
        /// <see cref="InterlockAddDoubles(ref double, double)"/>
        public static double Det(Matrix a) {
            int rowCount = a.Size[0];
            switch (rowCount) {
                case 1:
                    return a.Rows[0][0];
                case 2:
                    return (a.Rows[0][0] * a.Rows[1][1]) - (a.Rows[0][1] * a.Rows[1][0]);
                default:
                    double sum = 0;
                    Parallel.For(0, rowCount, () => 0, CalculateDeterminantParallel(a), x => InterlockAddDoubles(ref sum, x));
                    return sum;
            }
        }
        /// <summary>
        /// Calculate dot product of two matrices
        /// </summary>
        /// <param name="a">"Left" factor matrix</param>
        /// <param name="b">"Right" factor matrix</param>
        /// <returns>Matrix with same number of rows as left matrix and same number of columns as right matrix</returns>
        /// <seealso cref="operator*"/>
        public static Matrix Dot(Matrix a, Matrix b) {
            int m = a.Size[0], p = a.Size[1], n = b.Size[1];
            var product = new Matrix(m, n);
            foreach (var index in product.Indexes()) {
                int i = index[0], j = index[1];
                double sum = 0;
                for (int k = 0; k < p; ++k) {
                    sum += a.Rows[i][k] * b.Rows[k][j];
                }
                product.Rows[i][j] = sum;
            }
            return product;
        }
        public static Matrix operator *(Matrix left, Matrix right) => Dot(left, right);
        /// <summary>
        /// Change all values of matrix to static value
        /// </summary>
        /// <param name="a">Matrix to fill</param>
        /// <param name="value">Static value to fill matrix with</param>
        /// <returns>Matrix</returns>
        public static Matrix Fill(Matrix a, double value) {
            var temp = a.Clone();
            foreach (var index in temp.Indexes()) {
                int i = index[0], j = index[1];
                temp.Rows[i][j] = value;
            }
            return temp;
        }
        /// <summary>
        /// Perform Gaussian Elimination on input augmented matrix
        /// </summary>
        /// <param name="augmented">For the equation, Ax = y, where A is a square (NxN) matrix and x is a column (Nx1) matrix, the augmented matrix is A "augmented" by adding x as the (N+1)th column</param>
        /// <returns>Column matrix of solutions</returns>
        public static Matrix GaussianElimination(Matrix augmented) {
            int rowCount = augmented.Size[0], columnCount = augmented.Size[1];
            var clone = augmented.ToUpperTriangular();
            var solutions = new Matrix(rowCount, 1);
            for (int i = rowCount - 1; i >= 0; --i) {
                double sum = 0;
                for (int j = i + 1; j <= rowCount - 1; ++j) {
                    sum += (solutions.Rows[j][0] * clone.Rows[i][j]);
                }
                solutions.Rows[i][0] = Round((clone.Rows[i][columnCount - 1] - sum) / clone.Rows[i][i], 2);
            }
            return solutions;
        }
        /// <summary>
        /// Create identity matrix (diagonal elements equal 1, all other elements are zero)
        /// </summary>
        /// <param name="n">Number of rows/columns</param>
        /// <returns>nxn Matrix</returns>
        public static Matrix Identity(int n) {
            var temp = new Matrix(n);
            for (int i = 0; i < n; ++i)
                temp.Rows[i][i] = 1;
            return temp;
        }
        /// <summary>
        /// Calculate inverse of a given matrix
        /// </summary>
        /// <param name="a">Input matrix</param>
        /// <returns>Matrix</returns>
        public static Matrix Invert(Matrix a) {
            var adjugate = Adj(a);
            var det = Det(a);
            return Multiply(adjugate, 1 / det);
        }
        /// <summary>
        /// Multiply a matrix by a scalar value
        /// </summary>
        /// <param name="a">Matrix factor</param>
        /// <param name="k">Scalar factor</param>
        /// <returns>Matrix</returns>
        /// <seealso cref="operator*"/>
        /// <seealso cref="operator/"/>
        public static Matrix Multiply(Matrix a, double k) {
            var clone = a.Clone();
            foreach (var index in clone.Indexes()) {
                int i = index[0], j = index[1];
                clone.Rows[i][j] *= k;
            }
            return clone;
        }
        public static Matrix operator *(double k, Matrix a) => Multiply(a, k);
        public static Matrix operator *(Matrix a, double k) => Multiply(a, k);
        public static Matrix operator /(Matrix a, double k) => Multiply(a, (1 / k));
        /// <summary>
        /// Similar to Math.Pow, but for matrices
        /// </summary>
        /// <param name="a">Matrix to exponentiate</param>
        /// <param name="exponent">Exponent</param>
        /// <returns>Matrix</returns>
        /// <see cref="Dot(Matrix, Matrix)"/>
        public static Matrix Pow(Matrix a, double exponent) {
            if (a.Size[0] == a.Size[1]) {
                var temp = a.Clone();
                for (var index = 0; index < exponent - 1; ++index)
                    temp *= a;
                return temp;
            } else {
                throw new ArgumentException("Matrix exponentiation only supports square matrices");
            }
        }
        /// <summary>
        /// Calculate the sum of diagonal elements (trace) for a given matrix
        /// </summary>
        /// <param name="a">Input matrix</param>
        /// <returns>Scalar value</returns>
        public static double Trace(Matrix a) {
            double trace = 0;
            foreach (var index in a.Indexes()) {
                int i = index[0], j = index[1];
                if (i == j) {
                    trace += a.Rows[i][j];
                }
            }
            return trace;
        }
        /// <summary>
        /// Calculate transpose of a given matrix
        /// </summary>
        /// <param name="a">Input matrix</param>
        /// <returns>Matrix</returns>
        public static Matrix Transpose(Matrix a) {
            var temp = new Matrix(a.Size[1], a.Size[0]);
            foreach (var index in a.Indexes()) {
                int i = index[0], j = index[1];
                temp.Rows[j][i] = a.Rows[i][j];
            }
            return temp;
        }
        /// <summary>
        /// Create matrix with all elements equal to 1, referred to as a "unit" matrix
        /// </summary>
        /// <param name="n">Number of rows/columns</param>
        /// <returns>Matrix</returns>
        public static Matrix Unit(int n) => Fill(new Matrix(n), 1);
        /// <summary>
        /// Create matrix with all elements equal to 1
        /// </summary>
        /// <param name="rowCount">Number of rows</param>
        /// <param name="columnCount">Number of columns</param>
        /// <returns>Matrix</returns>
        public static Matrix Unit(int rowCount, int columnCount) => Fill(new Matrix(rowCount, columnCount), 1);
        private static double InterlockAddDoubles(ref double a, double b) {
            double newCurrentValue = a;
            while (true) {
                double currentValue = newCurrentValue;
                double newValue = currentValue + b;
                newCurrentValue = Interlocked.CompareExchange(ref a, newValue, currentValue);
                if (newCurrentValue == currentValue)
                    return newValue;
            }
        }
        private static Func<int, ParallelLoopState, double, double> CalculateDeterminantParallel(Matrix a) {
            return (i, loop, result) => {
                result += a.Rows[0][i] * a.Cofactor(0, i);
                return result;
            };
        }
        /// <summary>
        /// Create clone copy of calling matrix
        /// </summary>
        /// <returns>Matrix</returns>
        public Matrix Clone() {
            var original = this;
            int rows = original.Size[0], cols = original.Size[1];
            var clone = new Matrix(rows, cols);
            foreach (var index in clone.Indexes()) {
                int i = index[0], j = index[1];
                clone.Rows[i][j] = original.Rows[i][j];
            }
            return clone;
        }
        /// <summary>
        /// Set all values less than passed limit to zero
        /// </summary>
        /// <param name="limit"></param>
        /// <returns>Matrix</returns>
        /// <remarks>
        /// Warning: This method mutates the calling matrix
        /// </remarks>
        public Matrix CoerceZero(double limit = 1E-15) {
            foreach (var pair in Indexes()) {
                int i = pair[0], j = pair[1];
                if (this[i, j] < limit)
                    this[i, j] = 0;
            }
            return this;
        }
        /// <summary>
        /// Calculate cofactor matrix
        /// </summary>
        /// <param name="i">Element row index</param>
        /// <param name="j">Element column index</param>
        /// <returns>Matrix</returns>
        /// <see cref="Det(Matrix)"/>
        public double Cofactor(int i = 0, int j = 0) => Math.Pow(-1, i + j) * Det(RemoveRow(i).RemoveColumn(j));
        /// <summary>
        /// Return list of index pairs
        /// </summary>
        /// <param name="offset"></param>
        /// <returns>List of index pairs. Example: For a 2x2 matrix, the return will be (0, 0), (0, 1), (1, 0), (1, 1)</returns>
        /// <remarks>
        /// This method is useful for performing actions on elements dependent on the element's associated row and/or column
        /// </remarks>
        public List<int[]> Indexes(int offset = 0) {
            int rows = Size[0], cols = Size[1];
            var pairs = new List<int[]>();
            for (var i = 0; i < rows; ++i)
                for (var j = 0; j < cols; ++j) {
                    int[] pair = { i + offset, j + offset };
                    pairs.Add(pair);
                }
            return pairs;
        }
        /// <summary>
        /// Calculate eigenvalue of dominant eigenvector using the Rayleigh Quotient
        /// </summary>
        /// <returns>Scalar value</returns>
        public double Eigenvalue() {
            var A = this;
            var v = Eigenvector();
            return (Transpose(v) * A * v).Values.First() / (Transpose(v) * v).Values.First();
        }
        /// <summary>
        /// Calculate dominant eigenvector for calling matrix
        /// </summary>
        /// <param name="maxIterations">Maximum iterations to perform regardless of tolerance</param>
        /// <returns>Column matrix with same number of rows as calling matrix</returns>
        /// <remarks>
        /// Calling matrix must be a square matrix
        /// </remarks>
        public Matrix Eigenvector(int maxIterations = 100, double tolerance = 1E-5) {
            var A = this;
            int m = Size[0];
            var x = Unit(m, 1);
            for (var count = 0; count < maxIterations; ++count) {
                var prev = x;
                x = (A * x).Normalize();
                double error = Range(0, m).Select(i => Abs(x[i][0] - prev[i][0])).Sum();
                if (error < tolerance)
                    return x;
            }
            throw new Exception("Eigenvector algorithm failed to converge");
        }
        public Matrix ElementaryRowOperation(int rowIndexA, int rowIndexB, double scalar = 1) {
            int rowCount = Size[0], columnCount = Size[1];
            var temp = new Matrix(rowCount, columnCount);
            temp.Rows[rowIndexB] = Rows[rowIndexA];
            if (scalar != 1) {
                temp = Multiply(temp, scalar);
            }
            return Add(this, temp);
        }
        /// <summary>
        /// Calculate Frobenius Norm of calling matrix
        /// </summary>
        /// <returns>Scalar value</returns>
        /// <remarks>
        /// The Frobenius norm is sometimes referred to as the Schur norm
        /// </remarks>
        public double FrobeniusNorm() => Sqrt(Values.Select(x => Math.Pow(Abs(x), 2)).Sum());
        /// <summary>
        /// Return clone of calling matrix with column inserted at passed zero-index column index
        /// </summary>
        /// <param name="index">Index where column should be inserted</param>
        /// <param name="column">Column values</param>
        /// <returns>Matrix</returns>
        public Matrix InsertColumn(int index, double[] column) {
            var original = this;
            int rowCount = original.Size[0], columnCount = original.Size[1];
            if (index < 0 || index > columnCount || column.Length > rowCount) {
                return original;
            } else {
                var updatedColumnCount = columnCount + 1;
                var updated = new Matrix(rowCount, updatedColumnCount);
                for (var i = 0; i < rowCount; ++i)
                    for (var j = 0; j < index; ++j)
                        updated.Rows[i][j] = original.Rows[i][j];
                for (var i = 0; i < column.Length; ++i)
                    updated.Rows[i][index] = column[i];
                for (var i = 0; i < rowCount; ++i)
                    for (var j = index + 1; j < updatedColumnCount; ++j)
                        updated.Rows[i][j] = original.Rows[i][j - 1];
                return updated;
            }
        }
        /// <summary>
        /// Return clone of calling matrix with row inserted at passed zero-index row index
        /// </summary>
        /// <param name="index">Index where row should be inserted</param>
        /// <param name="row">Row values</param>
        /// <returns>Matrix</returns>
        public Matrix InsertRow(int index, double[] row) {
            var original = this;
            int rowCount = original.Size[0], columnCount = original.Size[1];
            if (index < 0 || index > rowCount || row.Length > columnCount) {
                return original;
            } else {
                var updatedRowCount = rowCount + 1;
                var updated = new Matrix(updatedRowCount, columnCount);
                for (var i = 0; i < index; ++i)
                    updated.Rows[i] = original.Rows[i];
                updated.Rows[index] = row;
                for (var i = index + 1; i < updatedRowCount; ++i)
                    updated.Rows[i] = original.Rows[i - 1];
                return updated;
            }
        }
        /// <summary>
        /// Return true if calling matrix is diagonal - for a matrix, A, if i != 0 then A[i, j] == 0
        /// </summary>
        /// <returns>Boolean</returns>
        /// <remarks>
        /// Most often, the term, "diagonal", is applied to square matrices but can be applied to rectangular matrics (M != N)
        /// </remarks>
        public bool IsDiagonal() {
            foreach (var pair in Indexes()) {
                int i = pair[0], j = pair[1];
                if (i != j && this[i][j] != 0)
                    return false;
            }
            return true;
        }
        /// <summary>
        /// Return true if calling matrix is square - for a MxN matrix, M == N
        /// </summary>
        /// <returns>Boolean</returns>
        public bool IsSquare() {
            return Size[0] == Size[1];
        }
        /// <summary>
        /// Return true if calling matrix is symmetric - for a matrix, A, A[i, j] == A[j, i]
        /// </summary>
        /// <returns>Boolean</returns>
        /// <remarks>
        /// A matrix is said to be "symmetric" when it is equal to its own transpose
        /// </remarks>
        public bool IsSymmetric() {
            return IsSquare() && this == Transpose(this);
        }
        /// <summary>
        /// Calculate L1 Norm of calling matrix
        /// </summary>
        /// <returns>Scalar value</returns>
        /// <remarks>
        /// The L1 Norm is also known as the maximum absolute column sum
        /// </remarks>
        public double L1Norm() {
            var largest = 0;
            foreach (var column in Transpose(this).Rows)
                largest = Max(largest, column.Select(x => Abs((int)x)).Sum());
            return largest;
        }
        /// <summary>
        /// Multiple a certain row by a given scalar value
        /// </summary>
        /// <param name="index">Row index</param>
        /// <param name="k">Scalar value</param>
        /// <returns>Matrix</returns>
        public Matrix MultiplyRowByScalar(int index, double k) {
            var clone = Clone();
            int columnCount = clone.Size[1];
            for (var i = 0; i < columnCount; ++i) {
                var item = clone.Rows[index][i];
                clone.Rows[index][i] = (k * item);
            }
            return clone;
        }
        /// <summary>
        /// Return clone of calling matrix that has been normalized using the Frobenius norm
        /// </summary>
        /// <returns>Matrix</returns>
        /// <see cref="FrobeniusNorm"/>
        public Matrix Normalize() => Multiply(this, 1 / FrobeniusNorm());
        /// <summary>
        /// Return clone of calling matrix with column removed at passed zero-index column index
        /// </summary>
        /// <param name="index"></param>
        /// <returns>Matrix</returns>
        public Matrix RemoveColumn(int index) {
            var original = this;
            int rowCount = original.Size[0], columnCount = original.Size[1];
            if (index < 0 || index >= columnCount) {
                return original;
            } else {
                var updatedColumnCount = columnCount - 1;
                var updated = new Matrix(rowCount, updatedColumnCount);
                for (var i = 0; i < rowCount; ++i)
                    for (var j = 0; j < index; ++j)
                        updated.Rows[i][j] = original.Rows[i][j];
                for (var i = 0; i < rowCount; ++i)
                    for (var j = index; j < updatedColumnCount; ++j)
                        updated.Rows[i][j] = original.Rows[i][j + 1];
                return updated;
            }
        }
        /// <summary>
        /// Return clone of calling matrix with row removed at passed zero-index row index
        /// </summary>
        /// <param name="index"></param>
        /// <returns>Matrix</returns>
        public Matrix RemoveRow(int index) {
            var original = this;
            int rowCount = original.Size[0], columnCount = original.Size[1];
            if (index < 0 || index >= rowCount) {
                return original;
            } else {
                var updatedRowCount = rowCount - 1;
                var updated = new Matrix(updatedRowCount, columnCount);
                for (var i = 0; i < index; ++i)
                    updated.Rows[i] = original.Rows[i];
                for (var i = index; i < updatedRowCount; ++i)
                    updated.Rows[i] = original.Rows[i + 1];
                return updated;
            }
        }
        /// <summary>
        /// Return clone of calling matrix with two rows swapped
        /// </summary>
        /// <param name="a"></param>
        /// <param name="b"></param>
        /// <returns>Matrix</returns>
        /// <remarks>
        /// Row swapping is one of the three so called elementary row operations
        /// </remarks>
        public Matrix SwapRows(int a, int b) {
            var clone = Clone();
            var original = Rows[a];
            clone.Rows[a] = Rows[b];
            clone.Rows[b] = original;
            return clone;
        }
        /// <summary>
        /// Output matrix to string
        /// </summary>
        /// <returns>String representation of matrix values</returns>
        public override string ToString() {
            var matrix = this;
            int rank = matrix.Size[0];
            var rows = new string[rank];
            for (var i = 0; i < rank; ++i)
                rows[i] = string.Join(",", matrix.Rows[i]);
            return string.Join("\r\n", rows);
        }
        /// <summary>
        /// Return clone of calling matrix converted to upper triangular form
        /// </summary>
        /// <returns>Matrix</returns>
        /// 
        public Matrix ToUpperTriangular() {
            int rowCount = Size[0];
            Matrix clone = Clone();
            for (int i = 0; i < rowCount; ++i) {
                var pivot = clone.Rows[i][i];
                int j = i;
                for (int k = i + 1; k < rowCount; ++k) {
                    if (pivot < Abs(clone.Rows[k][i])) {
                        pivot = clone.Rows[k][i];
                        j = k;
                    }
                }
                if (j != i) {
                    clone = clone.SwapRows(i, j);
                }
                for (int l = i + 1; l < rowCount; ++l) {
                    var factor = clone.Rows[l][i] / clone.Rows[i][i];
                    clone = clone.ElementaryRowOperation(i, l, -1 * factor);
                }
            }
            return clone;
        }
    }
}