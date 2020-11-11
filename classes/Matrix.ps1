﻿# Need to parameterize class with "id" in order to re-load class during testing
$Id = if ($Env:ProjectName -eq 'pwsh-prelude') { 'Test' } else { '' }
if ("Matrix${Id}" -as [Type]) {
  return
}
Add-Type -TypeDefinition @"
    using System;
    using System.Collections.Generic;

    public class Matrix${Id} {

        public int[] Size;
        public double[][] Rows;

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
                        sum += (Math.Pow(-1,i) * a.Rows[0][i] * Matrix${Id}.Det(a.RemoveRow(0).RemoveColumn(i)));
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
        public Matrix${Id} Multiply(double k) {
            Matrix${Id} clone = this.Clone();
            foreach (var index in clone.Indexes()) {
                int i = index[0], j = index[1];
                clone.Rows[i][j] *= k;
            }
            return clone;
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