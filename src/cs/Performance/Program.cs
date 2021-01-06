using System;
using System.Linq;
using BenchmarkDotNet.Attributes;
using BenchmarkDotNet.Running;
using Prelude;

namespace Performance {
    public class Program {
        [Benchmark]
        public void MatrixTranspose() {
            var A = new Matrix(10);
            double[,] rows = new double[,] {
                { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
                { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
                { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
                { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
                { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
                { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
                { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
                { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
                { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
                { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A.Rows[i][j] = rows[i, j];
            }
            Matrix.Transpose(A);
        }
        [Benchmark]
        public void MatrixDeterminant() {
            var A = new Matrix(10);
            double[,] rows = new double[,] {
                { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
                { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
                { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
                { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
                { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
                { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
                { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
                { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
                { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
                { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A.Rows[i][j] = rows[i, j];
            }
            Matrix.Det(A);
        }
        static void Main(string[] args) {
            var results = BenchmarkRunner.Run<Program>();
            Console.WriteLine(results);
        }
    }
}
