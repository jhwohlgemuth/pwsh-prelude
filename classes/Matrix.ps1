# Need to parameterize class with "id" in order to re-load class during testing
$Id = if ($Env:ProjectName -eq 'pwsh-prelude') { 'Test' } else { '' }
if ("Matrix${Id}" -as [Type]) {
  return
}
Add-Type -TypeDefinition @"
    using System;

    public class Matrix${Id} {

        public int[] Order;
        public double[][] Values;

        public Matrix${Id}(int n) {
            this.Order = new int[2];
            this.Order[0] = n;
            this.Order[1] = n;
            this.Values = Matrix${Id}.Create(n,n);
        }
        public Matrix${Id}(int m, int n) {
            this.Order = new int[2];
            this.Order[0] = m;
            this.Order[1] = n;
            this.Values = Matrix${Id}.Create(m,n);
        }
        public static double[][] Create(int m, int n) {
            double[][] result = new double[m][];
            for (var i = 0; i < m; ++i)
                result[i] = new double[n];
            return result;
        }
        public static Matrix${Id} Unit(int size) {
            var unit = new Matrix${Id}(size);
            var m = unit.Order[0];
            var n = unit.Order[1];
            for (var i = 0; i < m; ++i)
                for (var j = 0; j < n; ++j)
                    unit.Values[i][j] = 1;
            return unit;
        }
        public static Matrix${Id} Identity(int size) {
            var temp = new Matrix${Id}(size,size);
            for (var i = 0; i < temp.Order[0]; ++i)
                temp.Values[i][i] = 1;
            return temp;
        }
        public static Matrix${Id} Transpose(Matrix${Id} a) {
            var clone = a.Clone();
            var m = clone.Order[0];
            var n = clone.Order[1];
            for (var i = 0; i < m; ++i)
                for (var j = 0; j < n; ++j)
                    clone.Values[i][j] = a.Values[j][i];
            return clone;
        }
        public static Matrix${Id} Add(params Matrix${Id}[] addends) {
            var order = addends[0].Order;
            var m = order[0];
            var n = order[1];
            var sum = new Matrix${Id}(m,n);
            foreach (Matrix${Id} matrix in addends)
                for (var i = 0; i < m; ++i)
                    for (var j = 0; j < n; ++j)
                        sum.Values[i][j] += matrix.Values[i][j];
            return sum;
        }
        public Matrix${Id} Clone() {
            var original = this;
            var m = original.Order[0];
            var n = original.Order[1];
            var clone = new Matrix${Id}(m,n);
            for (var i = 0; i < m; ++i)
                for (var j = 0; j < n; ++j)
                    clone.Values[i][j] = original.Values[i][j];
            return clone;
        }
        public Matrix${Id} Multiply(Double k) {
            var clone = this.Clone();
            var m = clone.Order[0];
            var n = clone.Order[1];
            for (var i = 0; i < m; ++i)
                for (var j = 0; j < n; ++j)
                    clone.Values[i][j] *= k;
            return clone;
        }

        public Matrix${Id} Dot(Matrix${Id} operand) {
            var a = this;
            var b = operand;
            var m = a.Order[0];
            var p = a.Order[1];
            var n = b.Order[1];
            var product = new Matrix${Id}(m,n);
            for (var i = 0; i < m; ++i) {
                for (var j = 0; j < n; ++j) {
                    Double sum = 0;
                    for (var k = 0; k < p; ++k) {
                        sum += (a.Values[i][k] * b.Values[k][j]);
                    }
                    product.Values[i][j] = sum;
                }
            }
            return product;
        }
        public override string ToString() {
            var matrix = this;
            var rank = matrix.Order[0];
            var rows = new string[rank];
            for (var i = 0; i < rank; ++i)
                rows[i] = string.Join(",",matrix.Values[i]);
            return string.Join(";",rows);
        }
    }
"@