using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using static System.Math;

namespace Prelude {
    public class Matrix {
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
                int rows = Size[0], cols = Size[1];
                if (value.Length > rows) {
                    var limit = Min(value.Length, rows * cols);
                    for (var i = 0; i < limit; ++i) {
                        int row = (int)Floor((double)(i / cols));
                        int col = i % cols;
                        _Rows[row][col] = value[i][0];
                    }
                } else {
                    double[][] temp = Create<double>(rows, cols);
                    for (var row = 0; row < rows; ++row)
                        temp[row] = value[row].Take(cols).ToArray();
                    _Rows = temp;
                }
            }
        }
        public Matrix(int n) {
            Size = new int[] { n, n };
            Rows = Create<double>(n, n);
        }
        public Matrix(int rowCount, int columnCount) {
            Size = new int[] { rowCount, columnCount };
            Rows = Create<double>(rowCount, columnCount);
        }
        public static T[][] Create<T>(int rowCount, int columnCount) {
            T[][] result = new T[rowCount][];
            for (int i = 0; i < rowCount; ++i)
                result[i] = new T[columnCount];
            return result;
        }
        public static Matrix Unit(int n) {
            var temp = new Matrix(n);
            foreach (var index in temp.Indexes()) {
                int i = index[0], j = index[1];
                temp.Rows[i][j] = 1;
            }
            return temp;
        }
        public static Matrix Identity(int n) {
            var temp = new Matrix(n);
            for (int i = 0; i < n; ++i)
                temp.Rows[i][i] = 1;
            return temp;
        }
        public static Matrix Transpose(Matrix a) {
            var temp = new Matrix(a.Size[1], a.Size[0]);
            foreach (var index in a.Indexes()) {
                int i = index[0], j = index[1];
                temp.Rows[j][i] = a.Rows[i][j];
            }
            return temp;
        }
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
        public static Matrix Adj(Matrix a) {
            var temp = a.Clone();
            foreach (var index in temp.Indexes()) {
                int i = index[0], j = index[1];
                temp.Rows[i][j] = a.Cofactor(i, j);
            }
            return Transpose(temp);
        }
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
        public static Matrix Invert(Matrix a) {
            var adjugate = Adj(a);
            var det = Det(a);
            return Multiply(adjugate, 1 / det);
        }
        public static Matrix Multiply(Matrix a, double k) {
            var clone = a.Clone();
            foreach (var index in clone.Indexes()) {
                int i = index[0], j = index[1];
                clone.Rows[i][j] *= k;
            }
            return clone;
        }
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
        public double Cofactor(int i = 0, int j = 0) => Pow(-1, i + j) * Det(RemoveRow(i).RemoveColumn(j));
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
        public Matrix ElementaryRowOperation(int rowIndexA, int rowIndexB, double scalar = 1) {
            int rowCount = Size[0], columnCount = Size[1];
            var temp = new Matrix(rowCount, columnCount);
            temp.Rows[rowIndexB] = Rows[rowIndexA];
            if (scalar != 1) {
                temp = Multiply(temp, scalar);
            }
            return Add(this, temp);
        }
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
        public Matrix MultiplyRowByScalar(int index, double k) {
            var clone = Clone();
            int columnCount = clone.Size[1];
            for (var i = 0; i < columnCount; ++i) {
                var item = clone.Rows[index][i];
                clone.Rows[index][i] = (k * item);
            }
            return clone;
        }
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
        public Matrix SwapRows(int a, int b) {
            var clone = Clone();
            var original = Rows[a];
            clone.Rows[a] = Rows[b];
            clone.Rows[b] = original;
            return clone;
        }
        public override string ToString() {
            var matrix = this;
            int rank = matrix.Size[0];
            var rows = new string[rank];
            for (var i = 0; i < rank; ++i)
                rows[i] = string.Join(",", matrix.Rows[i]);
            return string.Join("\r\n", rows);
        }
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