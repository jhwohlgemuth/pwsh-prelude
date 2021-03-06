using Xunit;
using FsCheck;
using FsCheck.Xunit;
using System;
using System.Collections.Generic;
using System.Numerics;
using Prelude;

namespace MatrixTests {
    public class UnitTests {
        [Property]
        public Property NxN_matrix_has_N_rows_and_N_columns(PositiveInt n) {
            var size = n.Get;
            var matrix = new Matrix(size);
            return (matrix.Size[0] == matrix.Size[1]).Label("NxN matrix has square shape")
                .And(matrix.Rows.Length == matrix.Rows[0].Length).Label("NxN matrix has same number of rows and columns")
                .And(matrix.Size[0] == matrix.Rows.Length).Label("NxN is characterized by N rows and N columns");
        }
        [Property]
        public Property MxN_matrix_has_M_rows_and_N_columns(PositiveInt m, PositiveInt n) {
            var rows = m.Get;
            var cols = n.Get;
            var matrix = new Matrix(rows, cols);
            return (matrix.Size[0] == rows && (matrix.Rows.Length == rows)).Label("MxN matrix has M rows")
                .And(matrix.Size[1] == cols && (matrix.Rows[0].Length == cols)).Label("MxN matrix has N columns");
        }
        [Property]
        public Property Identity_matrix_is_square(PositiveInt n) {
            var matrix = new Matrix(n.Get);
            return (matrix.IsSymmetric()).Label("Identity matrix has same number of rows and columns");
        }
        [Property]
        [Trait("Category", "Determinant")]
        public Property Multiplying_row_by_K_multiplies_determinant_by_K(NonZeroInt k, NonZeroInt a, NonZeroInt b, NonZeroInt c, NonZeroInt d) {
            var A = new Matrix(2);
            var B = new Matrix(2);
            A[0] = new Complex[] { a.Get, b.Get };
            A[1] = new Complex[] { c.Get, d.Get };
            B[0] = new Complex[] { (k.Get * a.Get), (k.Get * b.Get) };
            B[1] = new Complex[] { c.Get, d.Get };
            return (Matrix.Det(B) == (k.Get * Matrix.Det(A))).Label("Multiply row in A by k ==> k * Det(A)");
        }
        [Property]
        [Trait("Category", "Determinant")]
        public Property Determinant_transposition_invariance(NonZeroInt a, NonZeroInt b, NonZeroInt c, NonZeroInt d) {
            var A = new Matrix(2);
            A[0] = new Complex[] { a.Get, b.Get };
            A[1] = new Complex[] { c.Get, d.Get };
            return (Matrix.Det(A) == Matrix.Det(Matrix.Transpose(A))).Label("Determinant is invariant under matrix transpose");
        }
        [Property]
        [Trait("Category", "Determinant")]
        public Property Two_identical_rows_makes_determinant_zero(NonZeroInt a, NonZeroInt b, NonZeroInt c, NonZeroInt d, NonZeroInt e, NonZeroInt f) {
            var A = new Matrix(3);
            A[0] = new Complex[] { a.Get, b.Get, c.Get };
            A[1] = new Complex[] { d.Get, e.Get, f.Get };
            A[2] = new Complex[] { a.Get, b.Get, c.Get };
            return (Matrix.Det(A) == 0).Label("A has two identical rows ==> Det(A) == 0");
        }
        [Property]
        public void Can_enumerate_matrix_values(NormalFloat a, NormalFloat b, NormalFloat c, NormalFloat d) {
            var A = new Matrix(2);
            double[,] rows = new double[2, 2] {
                { a.Get, b.Get },
                { c.Get, d.Get }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            Assert.Equal(new List<Complex> { a.Get, b.Get, c.Get, d.Get }, A.Values);
            A = new Matrix(1, 4);
            rows = new double[1, 4] {
                { a.Get, b.Get, c.Get, d.Get }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            Assert.Equal(new List<Complex> { a.Get, b.Get, c.Get, d.Get }, A.Values);
        }
        [Property]
        public Property Frobenius_norm_positivity(NormalFloat a, NormalFloat b, NormalFloat c, NormalFloat d) {
            var A = new Matrix(2);
            double[,] rows = new double[2, 2] {
                { a.Get, b.Get },
                { c.Get, d.Get }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            var norm = A.FrobeniusNorm();
            return (norm > 0 || (a.Get == 0 && b.Get == 0 && c.Get == 0 && d.Get == 0)).Label("Frobenius norm positivity property");
        }
        [Property]
        public Property Spectral_norm_positivity(PositiveInt a, PositiveInt b, PositiveInt c, PositiveInt d) {
            var A = new Matrix(2);
            double[,] rows = new double[2, 2] {
                { a.Get, b.Get },
                { c.Get, d.Get }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            var norm = A.SpectralNorm();
            return (norm.Magnitude > 0 || (a.Get == 0 && b.Get == 0 && c.Get == 0 && d.Get == 0)).Label("Frobenius norm positivity property");
        }
        [Property]
        public Property Spectral_norm_less_than_or_equal_to_Frobenius_norm(PositiveInt a, PositiveInt b, PositiveInt c, PositiveInt d) {
            var A = new Matrix(2);
            double[,] rows = new double[2, 2] {
                { a.Get, b.Get },
                { c.Get, d.Get }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            var spectral = A.SpectralNorm();
            var frobenius = A.FrobeniusNorm();
            return (spectral.Magnitude <= frobenius).Label("Spectral norm is equal to or less than the Frobenius norm");
        }
        [Property]
        public Property Matrix_equivalence_relation(NormalFloat a, NormalFloat b, NormalFloat c, NormalFloat d) {
            var A = new Matrix(2);
            var B = new Matrix(2);
            var C = new Matrix(2);
            double[,] rows = new double[2, 2] {
                { a.Get, b.Get },
                { c.Get, d.Get }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
                B[i][j] = rows[j, i];
                C = A;
            }
#pragma warning disable CS1718 // Comparison made to same variable
            return (A == A).Label("Reflexive property")
#pragma warning restore CS1718 // Comparison made to same variable
                .And((A == C && C == A)).Label("Symmetric property (always same)")
                .And((A == B && B == A) || (A != B)).Label("Symmetric property (not always same)")
                .And((A == B && B == C && A == C) || (A != B || B != C)).Label("Transitive property");
        }
        [Property]
        public void Can_be_compared_in_various_contexts(PositiveInt a, PositiveInt b, PositiveInt c, PositiveInt d) {
            var A = new Matrix(2);
            var B = new Matrix(2);
            var C = new Matrix(1, 2);
            double[,] rows = new double[2, 2] {
                { a.Get, b.Get },
                { c.Get, d.Get }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            rows = new double[2, 2] {
                { a.Get + 1, b.Get + 1 },
                { c.Get + 1, d.Get + 1 }
            };
            foreach (var Index in B.Indexes()) {
                int i = Index[0], j = Index[1];
                B[i][j] = rows[i, j];
            }
            rows = new double[1, 2] {
                { a.Get + 2, b.Get + 2 }
            };
            foreach (var Index in C.Indexes()) {
                int i = Index[0], j = Index[1];
                C[i][j] = rows[i, j];
            }
            Assert.True(A.Equals(A));
            Assert.False(A.Equals(B));
            Assert.False(A.Equals(C));
            Assert.False(A.Equals(null));
            Assert.True(Equals(A, A));
            Assert.False(Equals(A, B));
            Assert.False(Equals(A, C));
            Assert.False(Equals(null, A));
            Assert.False(Equals(A, null));
            Assert.True(Equals(null, null));
#pragma warning disable CS1718 // Comparison made to same variable
            Assert.True(A == A);
            Assert.False(A != A);
#pragma warning restore CS1718 // Comparison made to same variable
            Assert.False(A == B);
            Assert.True(A != B);
            Assert.True(A != C);
            Assert.True(A != null);
            Assert.True(null != A);
            var values = new List<Matrix> { A, B, C };
            values.Sort();
            Assert.Contains(A, values);
            values = new List<Matrix> { A, B, null };
            Assert.Throws<InvalidOperationException>(() => values.Sort());
        }
        [Property]
        public void Can_identity_dot_product_invariance(NonZeroInt k) {
            var I = Matrix.Identity(3);
            Assert.Equal(I, Matrix.Pow(I, k.Get));
        }
        [Fact]
        public void Can_get_and_set_elements_via_direct_interface() {
            var A = new Matrix(3);
            double[,] rows = new double[,] {
                { 1, 2, 3 },
                { 4, 5, 6 },
                { 7, 8, 9 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            Assert.Equal(3, A[0][2]);
            Assert.Equal(5, A[1][1]);
            Assert.Equal(9, A[2][2]);
            Assert.Equal(3, A[0, 2]);
            Assert.Equal(5, A[1, 1]);
            Assert.Equal(9, A[2, 2]);
            A[2] = new Complex[] { 0, 0, 0 };
            Assert.Equal(0, A[2, 0]);
            Assert.Equal(0, A[2, 1]);
            Assert.Equal(0, A[2, 2]);
        }
        [Fact]
        public void Can_check_if_matrix_is_diagonal() {
            var A = new Matrix(3);
            double[,] rows = new double[,] {
                { 1, 0, 0 },
                { 0, 5, 0 },
                { 0, 0, 9 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            var B = new Matrix(3);
            rows = new double[,] {
                { 1, 0, 3 },
                { 0, 5, 0 },
                { 7, 0, 0 }
            };
            foreach (var Index in B.Indexes()) {
                int i = Index[0], j = Index[1];
                B[i][j] = rows[i, j];
            }
            var C = new Matrix(2, 4);
            rows = new double[,] {
                { 1, 0, 0, 0 },
                { 0, 5, 0, 0 }
            };
            foreach (var Index in C.Indexes()) {
                int i = Index[0], j = Index[1];
                C[i][j] = rows[i, j];
            }
            var U = Matrix.Unit(3);
            var I = Matrix.Identity(3);
            Assert.True(A.IsDiagonal());
            Assert.False(B.IsDiagonal());
            Assert.True(C.IsDiagonal());
            Assert.False(U.IsDiagonal());
            Assert.True(I.IsDiagonal());
        }
        [Fact]
        public void Can_check_if_matrix_is_hermitian() {
            var A = new Matrix(3);
            Complex[,] rows = new Complex[,] {
                { 1, 0, 0 },
                { 0, 5, 0 },
                { 0, 0, 9 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            var B = new Matrix(3);
            var x = new Complex(7, 3);
            var y = Complex.Conjugate(x);
            rows = new Complex[,] {
                { 1, 0, x },
                { 0, 5, 0 },
                { y, 0, 0 }
            };
            foreach (var Index in B.Indexes()) {
                int i = Index[0], j = Index[1];
                B[i][j] = rows[i, j];
            }
            var C = new Matrix(3);
            rows = new Complex[,] {
                { 1, 0, 9 },
                { 0, 5, 0 },
                { 4, 0, 2 }
            };
            foreach (var Index in C.Indexes()) {
                int i = Index[0], j = Index[1];
                C[i][j] = rows[i, j];
            }
            var D = new Matrix(3);
            rows = new Complex[,] {
                { 1, 0, 4 },
                { 0, x, 0 },
                { 4, 0, 0 }
            };
            foreach (var Index in D.Indexes()) {
                int i = Index[0], j = Index[1];
                D[i][j] = rows[i, j];
            }
            var U = Matrix.Unit(3);
            var I = Matrix.Identity(3);
            Assert.True(A.IsHermitian());
            Assert.True(B.IsHermitian());
            Assert.False(C.IsHermitian());
            Assert.False(D.IsHermitian());
            Assert.True(D.IsSymmetric());
            Assert.True(U.IsHermitian());
            Assert.True(I.IsHermitian());
        }
        [Fact]
        public void Can_check_if_matrix_is_orthogonal() {
            var I = Matrix.Identity(3);
            Assert.True(I.IsOrthogonal());
            var A = new Matrix(3);
            double[,] rows = new double[,] {
                { 0, 0, 1 },
                { 1, 0, 0 },
                { 0, 1, 0 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            Assert.True(A.IsOrthogonal());
        }
        [Fact]
        public void Can_check_if_matrix_is_square() {
            var A = Matrix.Unit(2);
            var B = Matrix.Unit(1, 3);
            var C = Matrix.Unit(4, 2);
            Assert.True(A.IsSquare());
            Assert.False(B.IsSquare());
            Assert.False(C.IsSquare());
        }
        [Fact]
        public void Can_check_if_matrix_is_symmetric() {
            var A = new Matrix(3);
            double[,] rows = new double[,] {
                { 1, 0, 0 },
                { 0, 5, 0 },
                { 0, 0, 9 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            var B = new Matrix(3);
            rows = new double[,] {
                { 1, 0, 3 },
                { 0, 5, 0 },
                { 7, 0, 0 }
            };
            foreach (var Index in B.Indexes()) {
                int i = Index[0], j = Index[1];
                B[i][j] = rows[i, j];
            }
            var C = new Matrix(2, 3);
            rows = new double[,] {
                { 1, 0, 0 },
                { 0, 5, 0 }
            };
            foreach (var Index in C.Indexes()) {
                int i = Index[0], j = Index[1];
                C[i][j] = rows[i, j];
            }
            var D = new Matrix(3);
            rows = new double[,] {
                { 1, 2, 3 },
                { 2, 5, 0 },
                { 3, 0, 9 }
            };
            foreach (var Index in D.Indexes()) {
                int i = Index[0], j = Index[1];
                D[i][j] = rows[i, j];
            }
            var U = Matrix.Unit(3);
            var I = Matrix.Identity(3);
            Assert.True(A.IsSymmetric());
            Assert.False(B.IsSymmetric());
            Assert.False(C.IsSymmetric());
            Assert.True(D.IsSymmetric());
            Assert.True(U.IsSymmetric());
            Assert.True(I.IsSymmetric());
        }
        [Theory]
        [InlineData(1)]
        [InlineData(2)]
        [InlineData(3)]
        public void Can_create_square_unit_matrices(int N) {
            var unit = Matrix.Unit(N);
            Assert.Equal(new int[] { N, N }, unit.Size);
            var expected = new Complex[N];
            Array.Fill(expected, 1);
            foreach (Complex[] Row in unit.Rows) {
                Assert.Equal(expected, Row);
            }
        }
        [Theory]
        [InlineData(1, 2)]
        [InlineData(2, 1)]
        [InlineData(3, 7)]
        public void Can_create_rectangular_unit_matrices(int M, int N) {
            var unit = Matrix.Unit(M, N);
            Assert.Equal(new int[] { M, N }, unit.Size);
            var expected = new Complex[N];
            Array.Fill(expected, 1);
            foreach (Complex[] Row in unit.Rows) {
                Assert.Equal(expected, Row);
            }
        }
        [Fact]
        public void Can_create_identity_matrices() {
            var identity2 = Matrix.Identity(2);
            Assert.Equal(new Complex[] { 1, 0 }, identity2[0]);
            Assert.Equal(new Complex[] { 0, 1 }, identity2[1]);
            var identity4 = Matrix.Identity(4);
            Assert.Equal(new Complex[] { 1, 0, 0, 0 }, identity4[0]);
            Assert.Equal(new Complex[] { 0, 1, 0, 0 }, identity4[1]);
            Assert.Equal(new Complex[] { 0, 0, 1, 0 }, identity4[2]);
            Assert.Equal(new Complex[] { 0, 0, 0, 1 }, identity4[3]);
        }
        [Fact]
        public void Can_transpose_NxN_matrices() {
            var A = new Matrix(3);
            double[,] rows = new double[3, 3] {
                { 1, 2, 3 },
                { 4, 5, 6 },
                { 7, 8, 9 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            var T = Matrix.Transpose(A);
            Assert.Equal(new Complex[] { 1, 4, 7 }, T[0]);
            Assert.Equal(new Complex[] { 2, 5, 8 }, T[1]);
            Assert.Equal(new Complex[] { 3, 6, 9 }, T[2]);
            var B = Matrix.Transpose(T);
            Assert.Equal(new Complex[] { 1, 2, 3 }, B[0]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, B[1]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, B[2]);
        }
        [Fact]
        public void Can_transpose_MxN_matrices() {
            var A = new Matrix(2, 3);
            double[,] rows = new double[2, 3] {
                { 1, 2, 3 },
                { 4, 5, 6 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            var T = Matrix.Transpose(A);
            Assert.Equal(new Complex[] { 1, 4 }, T[0]);
            Assert.Equal(new Complex[] { 2, 5 }, T[1]);
            Assert.Equal(new Complex[] { 3, 6 }, T[2]);
            var B = Matrix.Transpose(T);
            Assert.Equal(new Complex[] { 1, 2, 3 }, B[0]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, B[1]);
        }
        [Theory]
        [InlineData(2)]
        [InlineData(3)]
        [InlineData(4)]
        public void Can_add_matrices(int N) {
            var sum = new Matrix(N);
            var unit = Matrix.Unit(N);
            for (int i = 0; i < N; ++i) {
                sum = Matrix.Add(sum, unit);
            }
            var expected = new Complex[N];
            Array.Fill(expected, N);
            foreach (var Row in sum.Rows)
                Assert.Equal(expected, Row);
        }
        [Theory]
        [InlineData(2)]
        [InlineData(3)]
        [InlineData(4)]
        public void Can_add_matrices_with_operators(int N) {
            var sum = new Matrix(N);
            var unit = Matrix.Unit(N);
            for (int i = 0; i < N; ++i) {
                sum += unit;
            }
            var expected = new Complex[N];
            Array.Fill(expected, N);
            foreach (var Row in sum.Rows)
                Assert.Equal(expected, Row);
        }
        [Theory]
        [InlineData(2)]
        [InlineData(10)]
        [InlineData(16)]
        public void Can_subtract_matrices_with_operators(int N) {
            var difference = Matrix.Fill(new Matrix(N), 10);
            var unit = Matrix.Unit(N);
            for (int i = 0; i < N; ++i) {
                difference -= unit;
            }
            var expected = new Complex[N];
            Array.Fill(expected, 10 - N);
            foreach (var Row in difference.Rows)
                Assert.Equal(expected, Row);
        }
        [Fact]
        public void Can_augment_matrices() {

            var A = new Matrix(3);
            double[,] rows = new double[,] {
                { 3, -2, -5 },
                { -5, 2, 8 },
                { -2, 4, 7 },
                { 2, -3, -5 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            var x = new Matrix(3, 1);
            rows = new double[,] {
                { 3 },
                { -5 },
                { -2 },
                { 2 }
            };
            foreach (var Index in x.Indexes()) {
                int i = Index[0], j = Index[1];
                x[i][j] = rows[i, j];
            }
            var augment = A.Augment(x);
            Assert.Equal(new Complex[] { 3, -2, -5, 3 }, augment[0]);
        }
        [Fact]
        public void Can_calculate_dot_product_of_two_NxN_matrices() {
            var A = Matrix.Identity(2);
            A[1][1] = 0;
            var B = Matrix.Identity(2);
            B[0][0] = 0;
            var product = Matrix.Dot(A, B);
            Assert.Equal(new int[] { 2, 2 }, product.Size);
            Assert.Equal(new Complex[] { 0, 0 }, product[0]);
            Assert.Equal(new Complex[] { 0, 0 }, product[1]);
            Complex[,] rows = new Complex[,] {
                { 1, 2 },
                { 3, 4 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            rows = new Complex[,] {
                { 1, 1 },
                { 0, 2 }
            };
            foreach (var Index in B.Indexes()) {
                int i = Index[0], j = Index[1];
                B[i][j] = rows[i, j];
            }
            product = Matrix.Dot(A, B);
            Assert.Equal(new Complex[] { 1, 5 }, product[0]);
            Assert.Equal(new Complex[] { 3, 11 }, product[1]);
            product = Matrix.Dot(B, A);
            Assert.Equal(new Complex[] { 4, 6 }, product[0]);
            Assert.Equal(new Complex[] { 6, 8 }, product[1]);
        }
        [Fact]
        public void Can_calculate_dot_product_of_two_NxN_matrices_with_operators() {
            var A = Matrix.Identity(2);
            A[1][1] = 0;
            var B = Matrix.Identity(2);
            B[0][0] = 0;
            var product = A * B;
            Assert.Equal(new int[] { 2, 2 }, product.Size);
            Assert.Equal(new Complex[] { 0, 0 }, product[0]);
            Assert.Equal(new Complex[] { 0, 0 }, product[1]);
            double[,] rows = new double[,] {
                { 1, 2 },
                { 3, 4 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            rows = new double[,] {
                { 1, 1 },
                { 0, 2 }
            };
            foreach (var Index in B.Indexes()) {
                int i = Index[0], j = Index[1];
                B[i][j] = rows[i, j];
            }
            product = A * B;
            Assert.Equal(new Complex[] { 1, 5 }, product[0]);
            Assert.Equal(new Complex[] { 3, 11 }, product[1]);
            product = B * A;
            Assert.Equal(new Complex[] { 4, 6 }, product[0]);
            Assert.Equal(new Complex[] { 6, 8 }, product[1]);
        }
        [Fact]
        public void Can_calculate_dot_product_of_two_MxN_matrices() {
            var A = new Matrix(1, 2);
            var B = new Matrix(2, 3);
            double[,] rowsA = new double[,] {
                { 2, 1 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rowsA[i, j];
            }
            double[,] rowsB = new double[,] {
                { 1, -2, 0 },
                { 4, 5, -3 }
            };
            foreach (var Index in B.Indexes()) {
                int i = Index[0], j = Index[1];
                B[i][j] = rowsB[i, j];
            }
            var product = Matrix.Dot(A, B);
            Assert.Equal(new int[] { 1, 3 }, product.Size);
            Assert.Equal(new Complex[] { 6, 1, -3 }, product[0]);
        }
        [Fact]
        public void Can_verify_the_dot_product_of_a_matrix_and_inverse_is_identity() {
            var A = new Matrix(2);
            var B = new Matrix(2);
            double[,] rowsA = new double[,] {
                { 2, 5 },
                { 1, 3 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rowsA[i, j];
            }
            double[,] rowsB = new double[,] {
                { 3, -5 },
                { -1, 2 }
            };
            foreach (var Index in B.Indexes()) {
                int i = Index[0], j = Index[1];
                B[i][j] = rowsB[i, j];
            }
            var product = Matrix.Dot(A, B);
            Assert.Equal(new int[] { 2, 2 }, product.Size);
            Assert.Equal(Matrix.Identity(2).Rows, product.Rows);
        }
        [Fact]
        public void Can_calcuate_dot_exponential() {
            var A = Matrix.Unit(2);
            var result = Matrix.Pow(A, 1);
            Assert.Equal(new Complex[] { 1, 1 }, result[0]);
            Assert.Equal(new Complex[] { 1, 1 }, result[1]);
            result = Matrix.Pow(A, 2);
            Assert.Equal(new Complex[] { 2, 2 }, result[0]);
            Assert.Equal(new Complex[] { 2, 2 }, result[1]);
            result = Matrix.Pow(A, 3);
            Assert.Equal(new Complex[] { 4, 4 }, result[0]);
            Assert.Equal(new Complex[] { 4, 4 }, result[1]);
            result = Matrix.Pow(A, 4);
            Assert.Equal(new Complex[] { 8, 8 }, result[0]);
            Assert.Equal(new Complex[] { 8, 8 }, result[1]);
            var B = Matrix.Unit(2, 4);
            Assert.Throws<ArgumentException>(() => Matrix.Pow(B, 2));
        }
        [Theory]
        [InlineData(1)]
        [InlineData(7)]
        public void Can_multiply_matrix_by_scalar_constant(int k) {
            var sum = new Matrix(2);
            var identity = Matrix.Identity(2);
            for (int i = 0; i < k; ++i) {
                sum += identity;
            }
            var A = Matrix.Identity(2);
            var product = A * k;
            Assert.Equal(sum.Rows, product.Rows);
            Assert.Equal(new Complex[] { k, 0 }, product[0]);
            Assert.Equal(new Complex[] { 0, k }, product[1]);
            var c = new Complex(k, 1);
            product = A * c;
            Assert.Equal(new Complex[] { c, 0 }, product[0]);
            Assert.Equal(new Complex[] { 0, c }, product[1]);
            product = c * A;
            Assert.Equal(new Complex[] { c, 0 }, product[0]);
            Assert.Equal(new Complex[] { 0, c }, product[1]);
        }
        [Theory]
        [InlineData(3)]
        [InlineData(8)]
        public void Can_multiply_matrix_by_scalar_constant_with_operators(int k) {
            var sum = new Matrix(2);
            var identity = Matrix.Identity(2);
            for (int i = 0; i < k; ++i) {
                sum += identity;
            }
            var A = Matrix.Identity(2);
            var product = A * k;
            Assert.Equal(sum.Rows, product.Rows);
            Assert.Equal(new Complex[] { k, 0 }, product[0]);
            Assert.Equal(new Complex[] { 0, k }, product[1]);
            product = k * A;
            Assert.Equal(sum.Rows, product.Rows);
            Assert.Equal(new Complex[] { k, 0 }, product[0]);
            Assert.Equal(new Complex[] { 0, k }, product[1]);
        }
        [Theory]
        [InlineData(2)]
        [InlineData(5)]
        public void Can_divide_matrix_by_scalar_constant_with_operators(int k) {
            var A = Matrix.Fill(Matrix.Unit(2), 10);
            var quotient = A / k;
            Assert.Equal(new Complex[] { 10 / k, 10 / k }, quotient[0]);
            Assert.Equal(new Complex[] { 10 / k, 10 / k }, quotient[1]);
        }
        [Fact]
        public void Can_calculate_matrix_inverse() {
            var A = new Matrix(3);
            double[,] rows = new double[,] {
                { 1, 2, 3 },
                { 2, 3, 4 },
                { 1, 5, 7 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            var inverse = Matrix.Invert(A);
            Assert.Equal(Matrix.Identity(3).Rows, Matrix.Dot(A, inverse).Rows);
            Assert.Equal(new Complex[] { 0.5, 0.5, -0.5 }, inverse[0]);
            Assert.Equal(new Complex[] { -5, 2, 1 }, inverse[1]);
            Assert.Equal(new Complex[] { 3.5, -1.5, -0.5 }, inverse[2]);
            var B = new Matrix(2);
            Complex[,] rowsB = new Complex[,] {
                { new Complex(1, 2), new Complex(7, -2) },
                { new Complex(12, 3), new Complex(3, 1) }
            };
            foreach (var Index in B.Indexes()) {
                int i = Index[0], j = Index[1];
                B[i][j] = rowsB[i, j];
            }
            inverse = Matrix.Invert(B);
            Assert.Equal(new Complex[] { new Complex(-0.03204089265677597, -0.01483605535469393), new Complex(0.08016456800897645, -0.01346465527989029) }, inverse[0]);
            Assert.Equal(new Complex[] { new Complex(0.12941029796783443, 0.04824834808627353), new Complex(-0.008602418651041019, -0.023438474005734948) }, inverse[1]);
        }
        [Fact]
        public void Can_calculate_matrix_trace() {
            var A = new Matrix(3);
            double[,] rowsA = new double[,] {
                { 1, 2, 3 },
                { 4, 5, 6 },
                { 7, 8, 9 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rowsA[i, j];
            }
            Assert.Equal(15, Matrix.Trace(A));
            var B = new Matrix(2);
            var x = new Complex(1, 3);
            var y = new Complex(5, 2);
            var expected = new Complex(6, 5);
            Complex[,] rowsB = new Complex[,] {
                { x, 2 },
                { 4, y }
            };
            foreach (var Index in B.Indexes()) {
                int i = Index[0], j = Index[1];
                B[i][j] = rowsB[i, j];
            }
            Assert.Equal(expected, Matrix.Trace(B));
        }
        [Fact]
        public void Can_solve_system_of_equations() {
            var A = new Matrix(3, 4);
            double[,] rows = new double[,] {
                { 9, 3, 4, 7 },
                { 4, 3, 4, 8 },
                { 1, 1, 1, 3 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            var solutions = Matrix.Solve(A);
            Assert.Equal(new int[] { 3, 1 }, solutions.Size);
            Assert.Equal(new Complex[] { -0.2 }, solutions[0]);
            Assert.Equal(new Complex[] { 4 }, solutions[1]);
            Assert.Equal(new Complex[] { -0.8 }, solutions[2]);
            A = new Matrix(3);
            rows = new double[,] {
                { 4, 3, 4 },
                { 1, 1, 1 },
                { 9, 3, 4 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            var b = new Matrix(3, 1);
            rows = new double[,] {
                { 8 },
                { 3 },
                { 7 }
            };
            foreach (var Index in b.Indexes()) {
                int i = Index[0], j = Index[1];
                b[i][j] = rows[i, j];
            }
            solutions = Matrix.Solve(A, b);
            Assert.Equal(new int[] { 3, 1 }, solutions.Size);
            Assert.Equal(new Complex[] { -0.2 }, solutions[0]);
            Assert.Equal(new Complex[] { 4 }, solutions[1]);
            Assert.Equal(new Complex[] { -0.8 }, solutions[2]);
        }
        [Fact]
        public void Can_solve_system_of_equations_directly_with_gaussian_elimination() {
            var A = new Matrix(3, 4);
            double[,] rows = new double[,] {
                { 9, 3, 4, 7 },
                { 4, 3, 4, 8 },
                { 1, 1, 1, 3 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            var B = Matrix.GaussianElimination(A);
            Assert.Equal(new int[] { 3, 1 }, B.Size);
            Assert.Equal(new Complex[] { -0.2 }, B[0]);
            Assert.Equal(new Complex[] { 4 }, B[1]);
            Assert.Equal(new Complex[] { -0.8 }, B[2]);
            A = new Matrix(3, 4);
            rows = new double[,] {
                { 4, 3, 4, 8 },
                { 1, 1, 1, 3 },
                { 9, 3, 4, 7 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            B = Matrix.GaussianElimination(A);
            Assert.Equal(new int[] { 3, 1 }, B.Size);
            Assert.Equal(new Complex[] { -0.2 }, B[0]);
            Assert.Equal(new Complex[] { 4 }, B[1]);
            Assert.Equal(new Complex[] { -0.8 }, B[2]);
        }
        [Fact]
        [Trait("Category", "Instance")]
        public void Can_create_clones() {
            var A = new Matrix(2);
            double[,] rows = new double[,] {
                { 1, 2 },
                { 3, 4 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            var B = A.Clone();
            Assert.Equal(new Complex[] { 1, 2 }, B[0]);
            Assert.Equal(new Complex[] { 3, 4 }, B[1]);
        }
        [Fact]
        public void Can_coerce_arbitrarily_small_values_to_zero() {
            var A = Matrix.Fill(new Matrix(1, 2), 1E-14);
            var B = Matrix.Fill(new Matrix(1, 2), 1E-15);
            var C = Matrix.Fill(new Matrix(1, 2), 1E-16);
            var C1 = Matrix.Fill(new Matrix(1, 2), new Complex(1E-16, 1E-17));
            var D = Matrix.Fill(new Matrix(1, 2), 1E-16);
            Assert.Equal(new Complex[] { 1E-14, 1E-14 }, A.CoerceZero()[0]);
            Assert.Equal(new Complex[] { 1E-15, 1E-15 }, B.CoerceZero()[0]);
            Assert.Equal(new Complex[] { 0, 0 }, C.CoerceZero()[0]);
            Assert.Equal(new Complex[] { 0, 0 }, C1.CoerceZero()[0]);
            Assert.Equal(new Complex[] { 0, 0 }, A.CoerceZero(1E-13)[0]);
            Assert.Equal(new Complex[] { 1E-16, 1E-16 }, D.CoerceZero(1E-16)[0]);
        }
        [Fact]
        [Trait("Category", "Instance")]
        public void Can_perform_elementary_row_operations() {
            var A = new Matrix(2);
            double[,] rows = new double[,] {
                { 1, 2 },
                { 3, 4 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A.Rows[i][j] = rows[i, j];
            }
            var B = A.ElementaryRowOperation(0, 1);
            Assert.Equal(new Complex[] { 1, 2 }, B[0]);
            Assert.Equal(new Complex[] { 4, 6 }, B[1]);
            B = A.ElementaryRowOperation(0, 1, 5);
            Assert.Equal(new Complex[] { 1, 2 }, B[0]);
            Assert.Equal(new Complex[] { 8, 14 }, B[1]);
            B = A.ElementaryRowOperation(0, 1, -3);
            Assert.Equal(new Complex[] { 1, 2 }, B[0]);
            Assert.Equal(new Complex[] { 0, -2 }, B[1]);
        }
        [Fact]
        public void Can_calculate_L1_Norm() {
            var A = new Matrix(3);
            double[,] rows = new double[,] {
                { -3, 5, 7 },
                { 2, 6, 4 },
                { 0, 2, 8 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            Assert.Equal(19, A.L1Norm());
        }
        [Fact]
        public void Can_calculate_Frobenius_norm() {
            var A = new Matrix(3);
            double[,] rows = new double[,] {
                { 2, -2, 1 },
                { -1, 3, -1 },
                { 2, -4, 1 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            Assert.Equal(6.4, A.FrobeniusNorm(), 2);
            rows = new double[,] {
                { -4, -3, -2 },
                { -1, 0, 1 },
                { 2, 3, 4 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            Assert.Equal(7.75, A.FrobeniusNorm(), 2);
        }
        [Fact]
        public void Can_calculate_Spectral_Norm() {
            var A = new Matrix(2);
            double[,] rows = new double[,] {
                { 1, 1 },
                { 2, 1 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            //Assert.Equal(2.6180, A.SpectralNorm(), 4);
        }
        [Fact]
        public void Can_normalize_matrix_values() {
            var A = new Matrix(2);
            double[,] rows = new double[,] {
                { 1, 1 },
                { 1, 0 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            var normalized = A.Normalize();
            Assert.Equal(new List<Complex> { 0.5773502691896258, 0.5773502691896258 }, normalized[0]);
            Assert.Equal(new List<Complex> { 0.5773502691896258, 0 }, normalized[1]);
        }
        //[Fact(Skip = "Does not support Complex numbers")]
        //public void Can_calculate_dominant_eigenvector() {
        //    var A = new Matrix(2);
        //    double[,] rows = new double[,] {
        //        { 1, 1 },
        //        { 1, 0 }
        //    };
        //    foreach (var Index in A.Indexes()) {
        //        int i = Index[0], j = Index[1];
        //        A[i][j] = rows[i, j];
        //    }
        //    var eigenvector = A.Eigenvector();
        //    Assert.Equal(0.8507, eigenvector[0][0], 4);
        //    Assert.Equal(0.5257, eigenvector[1][0], 4);
        //}
        //[Fact(Skip = "Does not support Complex numbers")]
        //public void Can_calculate_dominant_eigenvalue() {
        //    var A = new Matrix(2);
        //    double[,] rows = new double[,] {
        //        { 1, 1 },
        //        { 1, 0 }
        //    };
        //    foreach (var Index in A.Indexes()) {
        //        int i = Index[0], j = Index[1];
        //        A[i][j] = rows[i, j];
        //    }
        //    var eigenvalue = A.Eigenvalue();
        //    Assert.Equal(1.618, eigenvalue, 3);
        //}
        [Fact]
        [Trait("Category", "Instance")]
        public void Can_multiply_row_by_scalar() {
            var A = new Matrix(2);
            double[,] rows = new double[,] {
                { 1, 2 },
                { 3, 4 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            var B = A.MultiplyRowByScalar(1, 4);
            Assert.Equal(new Complex[] { 1, 2 }, B[0]);
            Assert.Equal(new Complex[] { 12, 16 }, B[1]);
            var C = A.MultiplyRowByScalar(1, 4).MultiplyRowByScalar(0, 5);
            Assert.Equal(new Complex[] { 5, 10 }, C[0]);
            Assert.Equal(new Complex[] { 12, 16 }, C[1]);
        }
        [Fact]
        [Trait("Category", "Instance")]
        public void Can_insert_columns() {
            var A = new Matrix(3);
            double[,] rows = new double[,] {
                { 1, 2, 3 },
                { 4, 5, 6 },
                { 7, 8, 9 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            var edited = A.InsertColumn(0, new Complex[] { 11, 22, 33 });
            Assert.Equal(new int[] { 3, 4 }, edited.Size);
            Assert.Equal(new Complex[] { 11, 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 22, 4, 5, 6 }, edited[1]);
            Assert.Equal(new Complex[] { 33, 7, 8, 9 }, edited[2]);
            edited = A.InsertColumn(1, new Complex[] { 11, 22, 33 });
            Assert.Equal(new int[] { 3, 4 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 11, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 22, 5, 6 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 33, 8, 9 }, edited[2]);
            edited = A.InsertColumn(3, new Complex[] { 11, 22, 33 });
            Assert.Equal(new int[] { 3, 4 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3, 11 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 5, 6, 22 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 8, 9, 33 }, edited[2]);
            edited = A.InsertColumn(4, new Complex[] { 11, 22, 33 });
            Assert.Equal(new int[] { 3, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[2]);
            edited = A.InsertColumn(4, new double[] { 11, 22, 33 });
            Assert.Equal(new int[] { 3, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[2]);
            edited = A.InsertColumn(3, new Complex[] { 11, 22, 33 }).InsertColumn(3, new double[] { 44, 55, 66 });
            Assert.Equal(new int[] { 3, 5 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3, 44, 11 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 5, 6, 55, 22 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 8, 9, 66, 33 }, edited[2]);
            edited = A.InsertColumn(1, new Complex[] { 11, 22, 33 }).InsertColumn(4, new double[] { 44, 55, 66 });
            Assert.Equal(new int[] { 3, 5 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 11, 2, 3, 44 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 22, 5, 6, 55 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 33, 8, 9, 66 }, edited[2]);
        }
        [Fact]
        [Trait("Category", "Instance")]
        public void Can_insert_rows() {
            var A = new Matrix(3);
            double[,] rows = new double[,] {
                { 1, 2, 3 },
                { 4, 5, 6 },
                { 7, 8, 9 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A.Rows[i][j] = rows[i, j];
            }
            var edited = A.InsertRow(0, new Complex[] { 11, 22, 33 });
            Assert.Equal(new int[] { 4, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 11, 22, 33 }, edited[0]);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[1]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[2]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[3]);
            edited = A.InsertRow(1, new Complex[] { 11, 22, 33 });
            Assert.Equal(new int[] { 4, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 11, 22, 33 }, edited[1]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[2]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[3]);
            edited = A.InsertRow(1, new double[] { 11, 22, 33 });
            Assert.Equal(new int[] { 4, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 11, 22, 33 }, edited[1]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[2]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[3]);
            edited = A.InsertRow(3, new Complex[] { 11, 22, 33 });
            Assert.Equal(new int[] { 4, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[2]);
            Assert.Equal(new Complex[] { 11, 22, 33 }, edited[3]);
            edited = A.InsertRow(4, new Complex[] { 11, 22, 33 });
            Assert.Equal(new int[] { 3, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[2]);
            edited = A.InsertRow(4, new double[] { 11, 22, 33 });
            Assert.Equal(new int[] { 3, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[2]);
            edited = A.InsertRow(1, new Complex[] { 11, 22, 33 }).InsertRow(1, new Complex[] { 44, 55, 66 });
            Assert.Equal(new int[] { 5, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 44, 55, 66 }, edited[1]);
            Assert.Equal(new Complex[] { 11, 22, 33 }, edited[2]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[3]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[4]);
            edited = A.InsertRow(1, new Complex[] { 11, 22, 33 }).InsertRow(4, new Complex[] { 44, 55, 66 });
            Assert.Equal(new int[] { 5, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 11, 22, 33 }, edited[1]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[2]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[3]);
            Assert.Equal(new Complex[] { 44, 55, 66 }, edited[4]);
            edited = A.InsertRow(1, new double[] { 11, 22, 33 }).InsertRow(4, new double[] { 44, 55, 66 });
            Assert.Equal(new int[] { 5, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 11, 22, 33 }, edited[1]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[2]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[3]);
            Assert.Equal(new Complex[] { 44, 55, 66 }, edited[4]);
            edited = A.InsertRow(1, new double[] { 11, 22, 33 }).InsertRow(4, new Complex[] { 44, 55, 66 });
            Assert.Equal(new int[] { 5, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 11, 22, 33 }, edited[1]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[2]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[3]);
            Assert.Equal(new Complex[] { 44, 55, 66 }, edited[4]);
        }
        [Fact]
        [Trait("Category", "Instance")]
        public void Can_remove_columns() {
            var A = new Matrix(3);
            double[,] rows = new double[,] {
                { 1, 2, 3 },
                { 4, 5, 6 },
                { 7, 8, 9 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            var edited = A.RemoveColumn(0);
            Assert.Equal(new int[] { 3, 2 }, edited.Size);
            Assert.Equal(new Complex[] { 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 5, 6 }, edited[1]);
            Assert.Equal(new Complex[] { 8, 9 }, edited[2]);
            edited = A.RemoveColumn(1);
            Assert.Equal(new int[] { 3, 2 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 6 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 9 }, edited[2]);
            edited = A.RemoveColumn(2);
            Assert.Equal(new int[] { 3, 2 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 5 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 8 }, edited[2]);
            edited = A.RemoveColumn(3);
            Assert.Equal(new int[] { 3, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[2]);
            edited = A.RemoveColumn(-1);
            Assert.Equal(new int[] { 3, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[2]);
            edited = A.RemoveColumn(0).RemoveRow(0);
            Assert.Equal(new int[] { 2, 2 }, edited.Size);
            Assert.Equal(new Complex[] { 5, 6 }, edited[0]);
            Assert.Equal(new Complex[] { 8, 9 }, edited[1]);
        }
        [Fact]
        [Trait("Category", "Instance")]
        public void Can_remove_rows() {
            var A = new Matrix(3);
            double[,] rows = new double[,] {
                { 1, 2, 3 },
                { 4, 5, 6 },
                { 7, 8, 9 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            var edited = A.RemoveRow(0);
            Assert.Equal(new int[] { 2, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[0]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[1]);
            edited = A.RemoveRow(1);
            Assert.Equal(new int[] { 2, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[1]);
            edited = A.RemoveRow(2);
            Assert.Equal(new int[] { 2, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[1]);
            edited = A.RemoveRow(3);
            Assert.Equal(new int[] { 3, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[2]);
            edited = A.RemoveRow(-1);
            Assert.Equal(new int[] { 3, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[2]);
            edited = A.RemoveRow(2).RemoveColumn(0);
            Assert.Equal(new int[] { 2, 2 }, edited.Size);
            Assert.Equal(new Complex[] { 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 5, 6 }, edited[1]);
        }
        [Fact]
        [Trait("Category", "Instance")]
        public void Can_swap_rows() {
            var A = new Matrix(2);
            double[,] rows = new double[,] {
                { 1, 2 },
                { 3, 4 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            var B = A.SwapRows(0, 1);
            Assert.Equal(new Complex[] { 3, 4 }, B[0]);
            Assert.Equal(new Complex[] { 1, 2 }, B[1]);
            B = A.SwapRows(1, 0);
            Assert.Equal(new Complex[] { 3, 4 }, B[0]);
            Assert.Equal(new Complex[] { 1, 2 }, B[1]);
            Assert.Throws<IndexOutOfRangeException>(() => A.SwapRows(-1, 0));
            Assert.Throws<IndexOutOfRangeException>(() => A.SwapRows(3, 1));
        }
        [Fact]
        [Trait("Category", "Instance")]
        public void Can_be_converted_to_string() {
            var A = new Matrix(2);
            double[,] rows = new double[,] {
                { 1, 2 },
                { 3, 4 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            string output = A.ToString();
            Assert.Equal("(1, 0),(2, 0)\r\n(3, 0),(4, 0)", output);
        }
        [Fact]
        public void Can_be_converted_to_upper_triangular() {
            var A = new Matrix(3, 3);
            double[,] rows = new double[,] {
                { 1, 1, 1 },
                { 4, 3, 4 },
                { 9, 3, 4 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            var B = A.ToUpperTriangular();
            Assert.Equal(new int[] { 3, 3 }, B.Size);
            Assert.Equal(new Complex[] { 9, 3, 4 }, B[0]);
            Assert.Equal(new Complex[] { 0, 1.6666666666666667, 2.2222222222222223 }, B[1]);
            Assert.Equal(new Complex[] { 0, 0, -0.33333333333333337 }, B[2]);
            A = new Matrix(3, 3);
            rows = new double[,] {
                { 9, 3, 4 },
                { 4, 3, 4 },
                { 1, 1, 1 },
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            B = A.ToUpperTriangular();
            Assert.Equal(new int[] { 3, 3 }, B.Size);
            Assert.Equal(new Complex[] { 9, 3, 4 }, B[0]);
            Assert.Equal(new Complex[] { 0, 1.6666666666666667, 2.2222222222222223 }, B[1]);
            Assert.Equal(new Complex[] { 0, 0, -0.33333333333333337 }, B[2]);
            A = new Matrix(3, 4);
            rows = new double[,] {
                { 9, 3, 4, 7 },
                { 4, 3, 4, 8 },
                { 1, 1, 1, 3 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            B = A.ToUpperTriangular();
            Assert.Equal(new int[] { 3, 4 }, B.Size);
            Assert.Equal(new Complex[] { 9, 3, 4, 7 }, B[0]);
            Assert.Equal(new Complex[] { 0, 1.6666666666666667, 2.2222222222222223, 4.888888888888889 }, B[1]);
            Assert.Equal(new Complex[] { 0, 0, -0.33333333333333337, 0.2666666666666666 }, B[2]);
            A = new Matrix(3, 4);
            rows = new double[,] {
                { 1, 1, 1, 3 },
                { 4, 3, 4, 8 },
                { 9, 3, 4, 7 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            B = A.ToUpperTriangular();
            Assert.Equal(new int[] { 3, 4 }, B.Size);
            Assert.Equal(new Complex[] { 9, 3, 4, 7 }, B[0]);
            Assert.Equal(new Complex[] { 0, 1.6666666666666667, 2.2222222222222223, 4.888888888888889 }, B[1]);
            Assert.Equal(new Complex[] { 0, 0, -0.33333333333333337, 0.2666666666666666 }, B[2]);
        }
        [Fact]
        [Trait("Category", "Determinant")]
        public void Can_calculate_determinant_for_1x1_matrices() {
            var A = new Matrix(1);
            double[,] rows = new double[1, 1] {
                { 1 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            Assert.Equal(1, Matrix.Det(A));
        }
        [Fact]
        [Trait("Category", "Determinant")]
        public void Can_calculate_determinant_for_2x2_matrices() {
            Assert.Equal(0, Matrix.Det(Matrix.Unit(2)));
            var A = new Matrix(2);
            double[,] rows = new double[2, 2] {
                { 1, 2 },
                { 3, 4 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            Assert.Equal(-2, Matrix.Det(A));
        }
        [Theory]
        [InlineData(3)]
        [Trait("Category", "Determinant")]
        public void Can_calculate_determinant_for_3x3_matrices(int N) {
            Assert.Equal(0, Matrix.Det(Matrix.Unit(N)));
            Assert.Equal(1, Matrix.Det(Matrix.Identity(N)));
            var A = new Matrix(N);
            double[,] rows = new double[,] {
                { 2, 3, -4 },
                { 0, -4, 2 },
                { 1, -1, 5 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            Assert.Equal(-46, Matrix.Det(A));
            A = new Matrix(N);
            rows = new double[,] {
                { 1, 2, 3 },
                { 4, -2, 3 },
                { 2, 5, -1 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            Assert.Equal(79, Matrix.Det(A));
        }
        [Theory]
        [InlineData(4)]
        [Trait("Category", "Determinant")]
        public void Can_calculate_determinant_for_4x4_matrices(int N) {
            Assert.Equal(0, Matrix.Det(Matrix.Unit(N)));
            Assert.Equal(1, Matrix.Det(Matrix.Identity(N)));
            var A = new Matrix(N);
            double[,] rows = new double[,] {
                { 3, -2, -5, 4 },
                { -5, 2, 8, -5 },
                { -2, 4, 7, -3 },
                { 2, -3, -5, 8 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            Assert.Equal(-54, Matrix.Det(A));
            A = new Matrix(N);
            rows = new double[,] {
                { 5, 4, 2, 1 },
                { 2, 3, 1, -2 },
                { -5, -7, -3, 9 },
                { 1, -2, -1, 4 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            Assert.Equal(38, Matrix.Det(A));
        }
        [Theory]
        [InlineData(6)]
        [Trait("Category", "Determinant")]
        [Trait("Category", "LongDuration")]
        public void Can_calculate_determinant_for_matrices_larger_than_4x4(int N) {
            Assert.Equal(0, Matrix.Det(Matrix.Unit(10)));
            Assert.Equal(1, Matrix.Det(Matrix.Identity(10)));
            var A = new Matrix(N);
            double[,] rows = new double[,] {
                { 12, 22, 14, 17, 20, 10 },
                { 16, -4, 7, 1,-2, 15 },
                { 10, -3, -2, 3, -2, 8 },
                { 7, 12, 8, 9, 11, 6 },
                { 11, 2, 4, -8, 1, 9 },
                { 24, 6, 6, 3, 4, 22 }
            };
            foreach (var Index in A.Indexes()) {
                int i = Index[0], j = Index[1];
                A[i][j] = rows[i, j];
            }
            Assert.Equal(12228, Matrix.Det(A));
        }
    }
}