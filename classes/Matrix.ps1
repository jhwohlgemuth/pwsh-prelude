if ('Matrix' -as [Type]) {
  return
}
Add-Type -TypeDefinition @"
    using System;

    public class Matrix {

        public int[] Order;
        public double[][] Values;

        public Matrix(int n) {
            this.Order = new int[2];
            this.Order[0] = n;
            this.Order[1] = n;
            this.Values = Matrix.Create(n,n);
        }
        public Matrix(int m, int n) {
            this.Order = new int[2];
            this.Order[0] = m;
            this.Order[1] = n;
            this.Values = Matrix.Create(m,n);
        }
        public static double[][] Create(int m, int n) {
            double[][] result = new double[m][];
            for (var i = 0; i < m; ++i)
                result[i] = new double[n];
            return result;
        }
    }
"@