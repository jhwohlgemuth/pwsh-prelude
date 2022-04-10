// <copyright file="Matrix.Tests.cs" company="Jason Wohlgemuth">
// Copyright (c) 2022 Jason Wohlgemuth. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
// </copyright>

namespace MatrixTests {
    using System;
    using System.Collections.Generic;
    using System.Numerics;
    using FsCheck;
    using FsCheck.Xunit;
    using Prelude;
    using Xunit;

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
            return matrix.IsSymmetric().Label("Identity matrix has same number of rows and columns");
        }

        [Property]
        [Trait("Category", "Determinant")]
        public Property Multiplying_row_by_K_multiplies_determinant_by_K(NonZeroInt k, NonZeroInt a, NonZeroInt b, NonZeroInt c, NonZeroInt d) {
            var x = new Matrix(2);
            var y = new Matrix(2);
            x[0] = new Complex[] { a.Get, b.Get };
            x[1] = new Complex[] { c.Get, d.Get };
            y[0] = new Complex[] { (k.Get * a.Get), (k.Get * b.Get) };
            y[1] = new Complex[] { c.Get, d.Get };
            return (Matrix.Det(y) == (k.Get * Matrix.Det(x))).Label("Multiply row in A by k ==> k * Det(A)");
        }

        [Property]
        [Trait("Category", "Determinant")]
        public Property Determinant_transposition_invariance(NonZeroInt a, NonZeroInt b, NonZeroInt c, NonZeroInt d) {
            var x = new Matrix(2);
            x[0] = new Complex[] { a.Get, b.Get };
            x[1] = new Complex[] { c.Get, d.Get };
            return (Matrix.Det(x) == Matrix.Det(Matrix.Transpose(x))).Label("Determinant is invariant under matrix transpose");
        }

        [Property]
        [Trait("Category", "Determinant")]
        public Property Two_identical_rows_makes_determinant_zero(NonZeroInt a, NonZeroInt b, NonZeroInt c, NonZeroInt d, NonZeroInt e, NonZeroInt f) {
            var x = new Matrix(3);
            x[0] = new Complex[] { a.Get, b.Get, c.Get };
            x[1] = new Complex[] { d.Get, e.Get, f.Get };
            x[2] = new Complex[] { a.Get, b.Get, c.Get };
            return (Matrix.Det(x) == 0).Label("A has two identical rows ==> Det(A) == 0");
        }

        [Property]
        public void Can_enumerate_matrix_values(NormalFloat a, NormalFloat b, NormalFloat c, NormalFloat d) {
            var x = new Matrix(2);
            var y = new Matrix(1, 4);
            Helpers.Populate(x, new[,] {
                { a.Get, b.Get },
                { c.Get, d.Get },
            });
            Assert.Equal(new List<Complex> { a.Get, b.Get, c.Get, d.Get }, x.Values);
            Helpers.Populate(y, new[,] {
                { a.Get, b.Get, c.Get, d.Get },
            });
            Assert.Equal(new List<Complex> { a.Get, b.Get, c.Get, d.Get }, y.Values);
        }

        [Property]
        public Property Frobenius_norm_positivity(NormalFloat a, NormalFloat b, NormalFloat c, NormalFloat d) {
            var x = new Matrix(2);
            Helpers.Populate(x, new[,] {
                { a.Get, b.Get },
                { c.Get, d.Get },
            });
            var norm = x.FrobeniusNorm();
            return (norm > 0 || (a.Get == 0 && b.Get == 0 && c.Get == 0 && d.Get == 0)).Label("Frobenius norm positivity property");
        }

        [Property]
        public Property Spectral_norm_positivity(PositiveInt a, PositiveInt b, PositiveInt c, PositiveInt d) {
            var x = new Matrix(2);
            Helpers.Populate(x, new double[,] {
                { a.Get, b.Get },
                { c.Get, d.Get },
            });
            var norm = x.SpectralNorm();
            return (norm.Magnitude > 0 || (a.Get == 0 && b.Get == 0 && c.Get == 0 && d.Get == 0)).Label("Frobenius norm positivity property");
        }

        [Property]
        public Property Spectral_norm_less_than_or_equal_to_Frobenius_norm(PositiveInt a, PositiveInt b, PositiveInt c, PositiveInt d) {
            var x = new Matrix(2);
            Helpers.Populate(x, new double[,] {
                { a.Get, b.Get },
                { c.Get, d.Get },
            });
            var spectral = x.SpectralNorm();
            var frobenius = x.FrobeniusNorm();
            return (spectral.Magnitude <= frobenius).Label("Spectral norm is equal to or less than the Frobenius norm");
        }

        [Property]
        public Property Matrix_equivalence_relation(NormalFloat a, NormalFloat b, NormalFloat c, NormalFloat d) {
            var x = new Matrix(2);
            var y = new Matrix(2);
            var z = new Matrix(2);
            double[,] rows = {
                { a.Get, b.Get },
                { c.Get, d.Get },
            };
            foreach (var index in x.Indexes()) {
                int i = index[0], j = index[1];
                x[i][j] = rows[i, j];
                y[i][j] = rows[j, i];
                z = x;
            }
#pragma warning disable CS1718 // Comparison made to same variable
            return (x == x).Label("Reflexive property")
#pragma warning restore CS1718 // Comparison made to same variable
                .And(x == z && z == x).Label("Symmetric property (always same)")
                .And((x == y && y == x) || (x != y)).Label("Symmetric property (not always same)")
                .And((x == y && y == z && x == z) || (x != y || y != z)).Label("Transitive property");
        }

        [Property]
        public void Can_be_compared_in_various_contexts(PositiveInt a, PositiveInt b, PositiveInt c, PositiveInt d) {
            var x = new Matrix(2);
            var y = new Matrix(2);
            var z = new Matrix(1, 2);
            Helpers.Populate(x, new double[,] {
                { a.Get, b.Get },
                { c.Get, d.Get },
            });
            Helpers.Populate(y, new double[,] {
                { a.Get + 1, b.Get + 1 },
                { c.Get + 1, d.Get + 1 },
            });
            Helpers.Populate(z, new double[,] {
                { a.Get + 2, b.Get + 2 },
            });
            Assert.True(x.Equals(x));
            Assert.False(x.Equals(y));
            Assert.False(x.Equals(z));
            Assert.False(x.Equals(null));
            Assert.True(Equals(x, x));
            Assert.False(Equals(x, y));
            Assert.False(Equals(x, z));
            Assert.False(Equals(null, x));
            Assert.False(Equals(x, null));
            Assert.True(Equals(null, null));
#pragma warning disable CS1718 // Comparison made to same variable
            Assert.True(x == x);
            Assert.False(x != x);
#pragma warning restore CS1718 // Comparison made to same variable
            Assert.False(x == y);
            Assert.True(x != y);
            Assert.True(x != z);
            Assert.True(x != null);
            var values = new List<Matrix> { x, y, z };
            values.Sort();
            Assert.Contains(x, values);
            values = new List<Matrix> { x, y, null };
            Assert.Throws<InvalidOperationException>(() => values.Sort());
        }

        [Property]
        public void Can_identity_dot_product_invariance(NonZeroInt k) {
            var identity = Matrix.Identity(3);
            Assert.Equal(identity, Matrix.Pow(identity, k.Get));
        }

        [Fact]
        public void Can_generate_matrix_index_pairs() {
            var a = new Matrix(2);
            var pairs = a.Indexes();
            Assert.Equal(new List<int> { 0, 0 }, pairs[0]);
            Assert.Equal(new List<int> { 0, 1 }, pairs[1]);
            Assert.Equal(new List<int> { 1, 0 }, pairs[2]);
            Assert.Equal(new List<int> { 1, 1 }, pairs[3]);
            var pairsWithOffset = a.Indexes(3);
            Assert.Equal(new List<int> { 3, 3 }, pairsWithOffset[0]);
            Assert.Equal(new List<int> { 3, 4 }, pairsWithOffset[1]);
            Assert.Equal(new List<int> { 4, 3 }, pairsWithOffset[2]);
            Assert.Equal(new List<int> { 4, 4 }, pairsWithOffset[3]);
        }

        [Fact]
        public void Can_get_and_set_elements_via_direct_interface() {
            var a = new Matrix(3);
            Helpers.Populate(a, new double[,] {
                { 1, 2, 3 },
                { 4, 5, 6 },
                { 7, 8, 9 },
            });
            Assert.Equal(3, a[0][2]);
            Assert.Equal(5, a[1][1]);
            Assert.Equal(9, a[2][2]);
            Assert.Equal(3, a[0, 2]);
            Assert.Equal(5, a[1, 1]);
            Assert.Equal(9, a[2, 2]);
            a[2] = new Complex[] { 0, 0, 0 };
            Assert.Equal(0, a[2, 0]);
            Assert.Equal(0, a[2, 1]);
            Assert.Equal(0, a[2, 2]);
        }

        [Fact]
        public void Can_check_if_matrix_is_diagonal() {
            var a = new Matrix(3);
            var b = new Matrix(3);
            var c = new Matrix(2, 4);
            var unit = Matrix.Unit(3);
            var identity = Matrix.Identity(3);
            Helpers.Populate(a, new double[,] {
                { 1, 0, 0 },
                { 0, 5, 0 },
                { 0, 0, 9 },
            });
            Helpers.Populate(b, new double[,] {
                { 1, 0, 3 },
                { 0, 5, 0 },
                { 7, 0, 0 },
            });
            Helpers.Populate(c, new double[,] {
                { 1, 0, 0, 0 },
                { 0, 5, 0, 0 },
            });
            Assert.True(a.IsDiagonal());
            Assert.False(b.IsDiagonal());
            Assert.True(c.IsDiagonal());
            Assert.False(unit.IsDiagonal());
            Assert.True(identity.IsDiagonal());
        }

        [Fact]
        public void Can_check_if_matrix_is_hermitian() {
            var a = new Matrix(3);
            var b = new Matrix(3);
            var c = new Matrix(3);
            var d = new Matrix(3);
            var x = new Complex(7, 3);
            var y = Complex.Conjugate(x);
            var unit = Matrix.Unit(3);
            var identity = Matrix.Identity(3);
            Helpers.Populate(a, new Complex[,] {
                { 1, 0, 0 },
                { 0, 5, 0 },
                { 0, 0, 9 },
            });
            Helpers.Populate(b, new[,] {
                { 1, 0, x },
                { 0, 5, 0 },
                { y, 0, 0 },
            });
            Helpers.Populate(c, new Complex[,] {
                { 1, 0, 9 },
                { 0, 5, 0 },
                { 4, 0, 2 },
            });
            Helpers.Populate(d, new[,] {
                { 1, 0, 4 },
                { 0, x, 0 },
                { 4, 0, 0 },
            });
            Assert.True(a.IsHermitian());
            Assert.True(b.IsHermitian());
            Assert.False(c.IsHermitian());
            Assert.False(d.IsHermitian());
            Assert.True(d.IsSymmetric());
            Assert.True(unit.IsHermitian());
            Assert.True(identity.IsHermitian());
        }

        [Fact]
        public void Can_check_if_matrix_is_orthogonal() {
            var a = new Matrix(3);
            var identity = Matrix.Identity(3);
            Helpers.Populate(a, new double[,] {
                { 0, 0, 1 },
                { 1, 0, 0 },
                { 0, 1, 0 },
            });
            Assert.True(a.IsOrthogonal());
            Assert.True(identity.IsOrthogonal());
        }

        [Fact]
        public void Can_check_if_matrix_is_unitary() {
            var a = new Matrix(3);
            var identity = Matrix.Identity(3);
            Helpers.Populate(a, new double[,] {
                { 0, 0, 1 },
                { 1, 0, 0 },
                { 0, 1, 0 },
            });
            Assert.True(a.IsOrthogonal());
            Assert.True(identity.IsOrthogonal());
            Assert.True(a.IsUnitary());
            Assert.True(identity.IsUnitary());
        }

        [Fact]
        public void Can_check_if_matrix_is_square() {
            var a = Matrix.Unit(2);
            var b = Matrix.Unit(1, 3);
            var c = Matrix.Unit(4, 2);
            Assert.True(a.IsSquare());
            Assert.False(b.IsSquare());
            Assert.False(c.IsSquare());
        }

        [Fact]
        public void Can_check_if_matrix_is_symmetric() {
            var a = new Matrix(3);
            var b = new Matrix(3);
            var c = new Matrix(2, 3);
            var d = new Matrix(3);
            var unit = Matrix.Unit(3);
            var identity = Matrix.Identity(3);
            Helpers.Populate(a, new double[,] {
                { 1, 0, 0 },
                { 0, 5, 0 },
                { 0, 0, 9 },
            });
            Helpers.Populate(b, new double[,] {
                { 1, 0, 3 },
                { 0, 5, 0 },
                { 7, 0, 0 },
            });
            Helpers.Populate(c, new double[,] {
                { 1, 0, 0 },
                { 0, 5, 0 },
            });
            Helpers.Populate(d, new double[,] {
                { 1, 2, 3 },
                { 2, 5, 0 },
                { 3, 0, 9 },
            });
            Assert.True(a.IsSymmetric());
            Assert.False(b.IsSymmetric());
            Assert.False(c.IsSymmetric());
            Assert.True(d.IsSymmetric());
            Assert.True(unit.IsSymmetric());
            Assert.True(identity.IsSymmetric());
        }

        [Theory]
        [InlineData(1)]
        [InlineData(2)]
        [InlineData(3)]
        public void Can_create_square_unit_matrices(int n) {
            var unit = Matrix.Unit(n);
            Assert.Equal(new[] { n, n }, unit.Size);
            var expected = new Complex[n];
            Array.Fill(expected, 1);
            foreach (Complex[] row in unit.Rows) {
                Assert.Equal(expected, row);
            }
        }

        [Theory]
        [InlineData(1, 2)]
        [InlineData(2, 1)]
        [InlineData(3, 7)]
        public void Can_create_rectangular_unit_matrices(int m, int n) {
            var unit = Matrix.Unit(m, n);
            Assert.Equal(new[] { m, n }, unit.Size);
            var expected = new Complex[n];
            Array.Fill(expected, 1);
            foreach (Complex[] row in unit.Rows) {
                Assert.Equal(expected, row);
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
            var a = new Matrix(3);
            Helpers.Populate(a, new double[,] {
                { 1, 2, 3 },
                { 4, 5, 6 },
                { 7, 8, 9 },
            });
            var t = Matrix.Transpose(a);
            Assert.Equal(new Complex[] { 1, 4, 7 }, t[0]);
            Assert.Equal(new Complex[] { 2, 5, 8 }, t[1]);
            Assert.Equal(new Complex[] { 3, 6, 9 }, t[2]);
            var b = Matrix.Transpose(t);
            Assert.Equal(new Complex[] { 1, 2, 3 }, b[0]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, b[1]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, b[2]);
        }

        [Fact]
        public void Can_transpose_MxN_matrices() {
            var a = new Matrix(2, 3);
            Helpers.Populate(a, new double[,] {
                { 1, 2, 3 },
                { 4, 5, 6 },
            });
            var t = Matrix.Transpose(a);
            Assert.Equal(new Complex[] { 1, 4 }, t[0]);
            Assert.Equal(new Complex[] { 2, 5 }, t[1]);
            Assert.Equal(new Complex[] { 3, 6 }, t[2]);
            var b = Matrix.Transpose(t);
            Assert.Equal(new Complex[] { 1, 2, 3 }, b[0]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, b[1]);
        }

        [Theory]
        [InlineData(2)]
        [InlineData(3)]
        [InlineData(4)]
        public void Can_add_matrices(int n) {
            var sum = new Matrix(n);
            var unit = Matrix.Unit(n);
            for (var i = 0; i < n; ++i) {
                sum = Matrix.Add(sum, unit);
            }

            var expected = new Complex[n];
            Array.Fill(expected, n);
            foreach (var row in sum.Rows)
                Assert.Equal(expected, row);
        }

        [Theory]
        [InlineData(2)]
        [InlineData(3)]
        [InlineData(4)]
        public void Can_add_matrices_with_operators(int n) {
            var sum = new Matrix(n);
            var unit = Matrix.Unit(n);
            for (var i = 0; i < n; ++i) {
                sum += unit;
            }

            var expected = new Complex[n];
            Array.Fill(expected, n);
            foreach (var row in sum.Rows)
                Assert.Equal(expected, row);
        }

        [Theory]
        [InlineData(2)]
        [InlineData(3)]
        [InlineData(4)]
        public void Can_add_matrices_and_integers_with_operators(int n) {
            var sum = new Matrix(n);
            for (var i = 0; i < n; ++i) {
                sum += 1;
            }

            var expected = new Complex[n];
            Array.Fill(expected, n);
            foreach (var row in sum.Rows)
                Assert.Equal(expected, row);
            sum = new Matrix(n);
            for (var i = 0; i < n; ++i) {
                sum = 1 + sum;
            }

            foreach (var row in sum.Rows)
                Assert.Equal(expected, row);
        }

        [Theory]
        [InlineData(2)]
        [InlineData(3)]
        [InlineData(4)]
        public void Can_subtract_integers_from_matrices_with_operators(int n) {
            var sum = Matrix.Fill(new Matrix(n), n);
            for (var i = 0; i < n; ++i) {
                sum -= 1;
            }

            var expected = new Complex[n];
            Array.Fill(expected, 0);
            foreach (var row in sum.Rows)
                Assert.Equal(expected, row);
        }

        [Theory]
        [InlineData(2)]
        [InlineData(10)]
        [InlineData(16)]
        public void Can_subtract_matrices_with_operators(int n) {
            var difference = Matrix.Fill(new Matrix(n), 10);
            var unit = Matrix.Unit(n);
            for (var i = 0; i < n; ++i) {
                difference -= unit;
            }

            var expected = new Complex[n];
            Array.Fill(expected, 10 - n);
            foreach (var row in difference.Rows)
                Assert.Equal(expected, row);
        }

        [Fact]
        public void Can_augment_matrices() {
            var a = new Matrix(3);
            var x = new Matrix(3, 1);
            Helpers.Populate(a, new double[,] {
                { 3, -2, -5 },
                { -5, 2, 8 },
                { -2, 4, 7 },
                { 2, -3, -5 },
            });
            Helpers.Populate(x, new double[,] {
                { 3 },
                { -5 },
                { -2 },
                { 2 },
            });
            var augment = a.Augment(x);
            Assert.Equal(new Complex[] { 3, -2, -5, 3 }, augment[0]);
        }

        [Fact]
        public void Can_calculate_dot_product_of_two_NxN_matrices() {
            var a = Matrix.Identity(2);
            a[1][1] = 0;
            var b = Matrix.Identity(2);
            b[0][0] = 0;
            var product = Matrix.Dot(a, b);
            Assert.Equal(new[] { 2, 2 }, product.Size);
            Assert.Equal(new Complex[] { 0, 0 }, product[0]);
            Assert.Equal(new Complex[] { 0, 0 }, product[1]);
            Helpers.Populate(a, new Complex[,] {
                { 1, 2 },
                { 3, 4 },
            });
            Helpers.Populate(b, new Complex[,] {
                { 1, 1 },
                { 0, 2 },
            });
            product = Matrix.Dot(a, b);
            Assert.Equal(new Complex[] { 1, 5 }, product[0]);
            Assert.Equal(new Complex[] { 3, 11 }, product[1]);
            product = Matrix.Dot(b, a);
            Assert.Equal(new Complex[] { 4, 6 }, product[0]);
            Assert.Equal(new Complex[] { 6, 8 }, product[1]);
        }

        [Fact]
        public void Can_calculate_dot_product_of_two_NxN_matrices_with_operators() {
            var a = Matrix.Identity(2);
            a[1][1] = 0;
            var b = Matrix.Identity(2);
            b[0][0] = 0;
            var product = a * b;
            Assert.Equal(new[] { 2, 2 }, product.Size);
            Assert.Equal(new Complex[] { 0, 0 }, product[0]);
            Assert.Equal(new Complex[] { 0, 0 }, product[1]);
            Helpers.Populate(a, new double[,] {
                { 1, 2 },
                { 3, 4 },
            });
            Helpers.Populate(b, new double[,] {
                { 1, 1 },
                { 0, 2 },
            });
            product = a * b;
            Assert.Equal(new Complex[] { 1, 5 }, product[0]);
            Assert.Equal(new Complex[] { 3, 11 }, product[1]);
            product = b * a;
            Assert.Equal(new Complex[] { 4, 6 }, product[0]);
            Assert.Equal(new Complex[] { 6, 8 }, product[1]);
        }

        [Fact]
        public void Can_calculate_dot_product_of_two_MxN_matrices() {
            var a = new Matrix(1, 2);
            var b = new Matrix(2, 3);
            Helpers.Populate(a, new double[,] {
                { 2, 1 },
            });
            Helpers.Populate(b, new double[,] {
                { 1, -2, 0 },
                { 4, 5, -3 },
            });
            var product = Matrix.Dot(a, b);
            Assert.Equal(new[] { 1, 3 }, product.Size);
            Assert.Equal(new Complex[] { 6, 1, -3 }, product[0]);
        }

        [Fact]
        public void Can_verify_the_dot_product_of_a_matrix_and_inverse_is_identity() {
            var a = new Matrix(2);
            var b = new Matrix(2);
            Helpers.Populate(a, new double[,] {
                { 2, 5 },
                { 1, 3 },
            });
            Helpers.Populate(b, new double[,] {
                { 3, -5 },
                { -1, 2 },
            });
            var product = Matrix.Dot(a, b);
            Assert.Equal(new[] { 2, 2 }, product.Size);
            Assert.Equal(Matrix.Identity(2).Rows, product.Rows);
        }

        [Fact]
        public void Can_calculate_dot_exponential() {
            var a = Matrix.Unit(2);
            var result = Matrix.Pow(a, 1);
            Assert.Equal(new Complex[] { 1, 1 }, result[0]);
            Assert.Equal(new Complex[] { 1, 1 }, result[1]);
            result = Matrix.Pow(a, 2);
            Assert.Equal(new Complex[] { 2, 2 }, result[0]);
            Assert.Equal(new Complex[] { 2, 2 }, result[1]);
            result = Matrix.Pow(a, 3);
            Assert.Equal(new Complex[] { 4, 4 }, result[0]);
            Assert.Equal(new Complex[] { 4, 4 }, result[1]);
            result = Matrix.Pow(a, 4);
            Assert.Equal(new Complex[] { 8, 8 }, result[0]);
            Assert.Equal(new Complex[] { 8, 8 }, result[1]);
            var b = Matrix.Unit(2, 4);
            var message = "Matrix exponentiation only supports square matrices";
            var ex = Assert.Throws<ArgumentException>(() => Matrix.Pow(b, 2));
            Assert.Equal(message, ex.Message);
        }

        [Theory]
        [InlineData(1)]
        [InlineData(7)]
        public void Can_multiply_matrix_by_scalar(int k) {
            var sum = new Matrix(2);
            var identity = Matrix.Identity(2);
            for (var i = 0; i < k; ++i) {
                sum += identity;
            }

            var a = Matrix.Identity(2);
            var product = a * k;
            Assert.Equal(sum.Rows, product.Rows);
            Assert.Equal(new Complex[] { k, 0 }, product[0]);
            Assert.Equal(new Complex[] { 0, k }, product[1]);
            product = k * a;
            Assert.Equal(sum.Rows, product.Rows);
            Assert.Equal(new Complex[] { k, 0 }, product[0]);
            Assert.Equal(new Complex[] { 0, k }, product[1]);
            var c = new Complex(k, 1);
            product = a * c;
            Assert.Equal(new[] { c, 0 }, product[0]);
            Assert.Equal(new[] { 0, c }, product[1]);
            product = c * a;
            Assert.Equal(new[] { c, 0 }, product[0]);
            Assert.Equal(new[] { 0, c }, product[1]);
        }

        [Theory]
        [InlineData(3)]
        [InlineData(8)]
        public void Can_multiply_matrix_by_scalar_constant_with_operators(int k) {
            var sum = new Matrix(2);
            var identity = Matrix.Identity(2);
            for (var i = 0; i < k; ++i) {
                sum += identity;
            }

            var a = Matrix.Identity(2);
            var product = a * k;
            Assert.Equal(sum.Rows, product.Rows);
            Assert.Equal(new Complex[] { k, 0 }, product[0]);
            Assert.Equal(new Complex[] { 0, k }, product[1]);
            product = k * a;
            Assert.Equal(sum.Rows, product.Rows);
            Assert.Equal(new Complex[] { k, 0 }, product[0]);
            Assert.Equal(new Complex[] { 0, k }, product[1]);
        }

        [Theory]
        [InlineData(2)]
        [InlineData(5)]
        public void Can_divide_matrix_by_scalar_constant_with_operators(int k) {
            var a = Matrix.Fill(Matrix.Unit(2), 10);
            var quotient = a / k;
            Assert.Equal(new Complex[] { 10 / k, 10 / k }, quotient[0]);
            Assert.Equal(new Complex[] { 10 / k, 10 / k }, quotient[1]);
        }

        [Fact]
        public void Can_calculate_matrix_inverse() {
            var a = new Matrix(3);
            Helpers.Populate(a, new double[,] {
                { 1, 2, 3 },
                { 2, 3, 4 },
                { 1, 5, 7 },
            });
            var inverse = Matrix.Invert(a);
            Assert.Equal(Matrix.Identity(3).Rows, Matrix.Dot(a, inverse).Rows);
            Assert.Equal(new Complex[] { 0.5, 0.5, -0.5 }, inverse[0]);
            Assert.Equal(new Complex[] { -5, 2, 1 }, inverse[1]);
            Assert.Equal(new Complex[] { 3.5, -1.5, -0.5 }, inverse[2]);
            var b = new Matrix(2);
            Helpers.Populate(b, new Complex[,] {
                { new(1, 2), new(7, -2) },
                { new(12, 3), new(3, 1) },
            });
            inverse = Matrix.Invert(b);
            Assert.Equal(new[] { new Complex(-0.03204089265677597, -0.01483605535469393), new Complex(0.08016456800897645, -0.01346465527989029) }, inverse[0]);
            Assert.Equal(new[] { new Complex(0.12941029796783443, 0.04824834808627353), new Complex(-0.008602418651041019, -0.023438474005734948) }, inverse[1]);
        }

        [Fact]
        public void Can_calculate_matrix_trace() {
            var a = new Matrix(3);
            var b = new Matrix(2);
            var x = new Complex(1, 3);
            var y = new Complex(5, 2);
            Helpers.Populate(a, new double[,] {
                { 1, 2, 3 },
                { 4, 5, 6 },
                { 7, 8, 9 },
            });
            Helpers.Populate(b, new[,] {
                { x, 2 },
                { 4, y },
            });
            Assert.Equal(15, Matrix.Trace(a));
            Assert.Equal(new Complex(6, 5), Matrix.Trace(b));
        }

        [Fact]
        public void Can_solve_system_of_equations() {
            var a = new Matrix(3, 4);
            var b = new Matrix(3);
            var c = new Matrix(3, 1);
            Helpers.Populate(a, new double[,] {
                { 9, 3, 4, 7 },
                { 4, 3, 4, 8 },
                { 1, 1, 1, 3 },
            });
            var solutions = Matrix.Solve(a);
            Assert.Equal(new[] { 3, 1 }, solutions.Size);
            Assert.Equal(new Complex[] { -0.2 }, solutions[0]);
            Assert.Equal(new Complex[] { 4 }, solutions[1]);
            Assert.Equal(new Complex[] { -0.8 }, solutions[2]);
            Helpers.Populate(b, new double[,] {
                { 4, 3, 4 },
                { 1, 1, 1 },
                { 9, 3, 4 },
            });
            Helpers.Populate(c, new double[,] {
                { 8 },
                { 3 },
                { 7 },
            });
            solutions = Matrix.Solve(b, c);
            Assert.Equal(new[] { 3, 1 }, solutions.Size);
            Assert.Equal(new Complex[] { -0.2 }, solutions[0]);
            Assert.Equal(new Complex[] { 4 }, solutions[1]);
            Assert.Equal(new Complex[] { -0.8 }, solutions[2]);
        }

        [Fact]
        public void Can_solve_system_of_equations_directly_with_gaussian_elimination() {
            var a = new Matrix(3, 4);
            Helpers.Populate(a, new double[,] {
                { 9, 3, 4, 7 },
                { 4, 3, 4, 8 },
                { 1, 1, 1, 3 },
            });
            var b = Matrix.GaussianElimination(a);
            Assert.Equal(new[] { 3, 1 }, b.Size);
            Assert.Equal(new Complex[] { -0.2 }, b[0]);
            Assert.Equal(new Complex[] { 4 }, b[1]);
            Assert.Equal(new Complex[] { -0.8 }, b[2]);
            a = new Matrix(3, 4);
            Helpers.Populate(a, new double[,] {
                { 4, 3, 4, 8 },
                { 1, 1, 1, 3 },
                { 9, 3, 4, 7 },
            });
            b = Matrix.GaussianElimination(a);
            Assert.Equal(new[] { 3, 1 }, b.Size);
            Assert.Equal(new Complex[] { -0.2 }, b[0]);
            Assert.Equal(new Complex[] { 4 }, b[1]);
            Assert.Equal(new Complex[] { -0.8 }, b[2]);
        }

        [Fact]
        [Trait("Category", "Instance")]
        public void Can_create_clones() {
            var a = new Matrix(2);
            Helpers.Populate(a, new double[,] {
                { 1, 2 },
                { 3, 4 },
            });
            var b = a.Clone();
            Assert.Equal(new Complex[] { 1, 2 }, b[0]);
            Assert.Equal(new Complex[] { 3, 4 }, b[1]);
        }

        [Fact]
        public void Can_fill_matrices_with_different_values() {
            int value = 42;
            var a = Matrix.Fill(new Matrix(2), value);
            Assert.Equal(new Complex[] { value, value }, a[0]);
            Assert.Equal(new Complex[] { value, value }, a[1]);
            Complex newValue = 7;
            var b = Matrix.Fill(a, newValue);
            Assert.Equal(new Complex[] { newValue, newValue }, b[0]);
            Assert.Equal(new Complex[] { newValue, newValue }, b[1]);
        }

        [Fact]
        public void Can_coerce_arbitrarily_small_values_to_zero() {
            var a = Matrix.Fill(new Matrix(1, 2), 1E-14);
            var b = Matrix.Fill(new Matrix(1, 2), 1E-15);
            var c = Matrix.Fill(new Matrix(1, 2), 1E-16);
            var c1 = Matrix.Fill(new Matrix(1, 2), new Complex(1E-16, 1E-17));
            var d = Matrix.Fill(new Matrix(1, 2), 1E-16);
            Assert.Equal(new Complex[] { 1E-14, 1E-14 }, a.CoerceZero()[0]);
            Assert.Equal(new Complex[] { 1E-15, 1E-15 }, b.CoerceZero()[0]);
            Assert.Equal(new Complex[] { 0, 0 }, c.CoerceZero()[0]);
            Assert.Equal(new Complex[] { 0, 0 }, c1.CoerceZero()[0]);
            Assert.Equal(new Complex[] { 0, 0 }, a.CoerceZero(1E-13)[0]);
            Assert.Equal(new Complex[] { 1E-16, 1E-16 }, d.CoerceZero(1E-16)[0]);
        }

        [Fact]
        [Trait("Category", "Instance")]
        public void Can_perform_elementary_row_operations() {
            var a = new Matrix(2);
            Helpers.Populate(a, new double[,] {
                { 1, 2 },
                { 3, 4 },
            });
            var b = a.ElementaryRowOperation(0, 1);
            Assert.Equal(new Complex[] { 1, 2 }, b[0]);
            Assert.Equal(new Complex[] { 4, 6 }, b[1]);
            b = a.ElementaryRowOperation(0, 1, 5);
            Assert.Equal(new Complex[] { 1, 2 }, b[0]);
            Assert.Equal(new Complex[] { 8, 14 }, b[1]);
            b = a.ElementaryRowOperation(0, 1, -3);
            Assert.Equal(new Complex[] { 1, 2 }, b[0]);
            Assert.Equal(new Complex[] { 0, -2 }, b[1]);
        }

        [Fact]
        public void Can_calculate_L1_Norm() {
            var a = new Matrix(3);
            Helpers.Populate(a, new double[,] {
                { -3, 5, 7 },
                { 2, 6, 4 },
                { 0, 2, 8 },
            });
            Assert.Equal(19, a.L1Norm());
        }

        [Fact]
        public void Can_calculate_Frobenius_norm() {
            var a = new Matrix(3);
            var b = new Matrix(3);
            Helpers.Populate(a, new double[,] {
                { 2, -2, 1 },
                { -1, 3, -1 },
                { 2, -4, 1 },
            });
            Helpers.Populate(b, new double[,] {
                { -4, -3, -2 },
                { -1, 0, 1 },
                { 2, 3, 4 },
            });
            Assert.Equal(6.4, a.FrobeniusNorm(), 2);
            Assert.Equal(7.75, b.FrobeniusNorm(), 2);
        }

        [Fact(Skip = "Intermittent failures")]
        public void Can_calculate_Spectral_Norm() {
            var a = new Matrix(2);
            Helpers.Populate(a, new double[,] {
                { 1, 1 },
                { 2, 1 },
            });
            Assert.Equal(2.6180, a.SpectralNorm());
        }

        [Fact]
        public void Can_normalize_matrix_values() {
            var a = new Matrix(2);
            Helpers.Populate(a, new double[,] {
                { 1, 1 },
                { 1, 0 },
            });
            var normalized = a.Normalize();
            Assert.Equal(new List<Complex> { 0.5773502691896258, 0.5773502691896258 }, normalized[0]);
            Assert.Equal(new List<Complex> { 0.5773502691896258, 0 }, normalized[1]);
        }

        [Fact]
        public void Can_calculate_dominant_eigenvector_with_power_method() {
            var a = new Matrix(2);
            Helpers.Populate(a, new double[,] {
                { 1, 1 },
                { 1, 0 },
            });
            var eigenvector = a.Eigenvector();
            Assert.Equal(0.8507, eigenvector[0][0].Real, 4);
            Assert.Equal(0.5257, eigenvector[1][0].Real, 4);
        }

        [Fact]
        public void Can_throw_exception_when_eigenvector_does_not_converge() {
            var a = new Matrix(2);
            Helpers.Populate(a, new double[,] {
                { 1, 1 },
                { 1, 0 },
            });
            var ex = Assert.Throws<Exception>(() => a.Eigenvector(1));
            var message = "Eigenvector algorithm failed to converge";
            Assert.Equal(message, ex.Message);
        }

        [Fact]
        public void Can_calculate_dominant_eigenvalue_with_power_method() {
            var a = new Matrix(2);
            Helpers.Populate(a, new double[,] {
                { 1, 1 },
                { 1, 0 },
            });
            var eigenvalue = a.Eigenvalue().Real;
            Assert.Equal(1.618, eigenvalue, 3);
        }

        [Fact]
        public void Can_map_function_over_matrix_values() {
            var a = new Matrix(2);
            Helpers.Populate(a, new double[,] {
                { 1, 2 },
                { 3, 4 },
            });
            Func<Complex, Complex> f = x => x + 1;
            Func<Complex, int, int, Complex> g = (x, i, j) => x + i + j;
            Func<Complex, int, int, Matrix, Complex> h = (x, i, j, m) => x + m.Size[0];
            var b = a.Map(f);
            Assert.Equal(new Complex[] { 2, 3 }, b[0]);
            Assert.Equal(new Complex[] { 4, 5 }, b[1]);

            // A is unchanged
            Assert.Equal(new Complex[] { 1, 2 }, a[0]);
            Assert.Equal(new Complex[] { 3, 4 }, a[1]);
            var c = a.Map(g);
            Assert.Equal(new Complex[] { 1, 3 }, c[0]);
            Assert.Equal(new Complex[] { 4, 6 }, c[1]);

            // A is unchanged
            Assert.Equal(new Complex[] { 1, 2 }, a[0]);
            Assert.Equal(new Complex[] { 3, 4 }, a[1]);
            var d = a.Map(h);
            Assert.Equal(new Complex[] { 3, 4 }, d[0]);
            Assert.Equal(new Complex[] { 5, 6 }, d[1]);

            // A is unchanged
            Assert.Equal(new Complex[] { 1, 2 }, a[0]);
            Assert.Equal(new Complex[] { 3, 4 }, a[1]);
        }

        [Fact]
        [Trait("Category", "Instance")]
        public void Can_multiply_row_by_scalar() {
            var a = new Matrix(2);
            Helpers.Populate(a, new double[,] {
                { 1, 2 },
                { 3, 4 },
            });
            var b = a.MultiplyRowByScalar(1, 4);
            Assert.Equal(new Complex[] { 1, 2 }, b[0]);
            Assert.Equal(new Complex[] { 12, 16 }, b[1]);
            var c = a.MultiplyRowByScalar(1, 4).MultiplyRowByScalar(0, 5);
            Assert.Equal(new Complex[] { 5, 10 }, c[0]);
            Assert.Equal(new Complex[] { 12, 16 }, c[1]);
        }

        [Fact]
        [Trait("Category", "Instance")]
        public void Can_insert_columns() {
            var a = new Matrix(3);
            Helpers.Populate(a, new double[,] {
                { 1, 2, 3 },
                { 4, 5, 6 },
                { 7, 8, 9 },
            });
            var edited = a.InsertColumn(0, new Complex[] { 11, 22, 33 });
            Assert.Equal(new[] { 3, 4 }, edited.Size);
            Assert.Equal(new Complex[] { 11, 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 22, 4, 5, 6 }, edited[1]);
            Assert.Equal(new Complex[] { 33, 7, 8, 9 }, edited[2]);
            edited = a.InsertColumn(1, new Complex[] { 11, 22, 33 });
            Assert.Equal(new[] { 3, 4 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 11, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 22, 5, 6 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 33, 8, 9 }, edited[2]);
            edited = a.InsertColumn(3, new Complex[] { 11, 22, 33 });
            Assert.Equal(new[] { 3, 4 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3, 11 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 5, 6, 22 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 8, 9, 33 }, edited[2]);
            edited = a.InsertColumn(4, new Complex[] { 11, 22, 33 });
            Assert.Equal(new[] { 3, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[2]);
            edited = a.InsertColumn(4, new double[] { 11, 22, 33 });
            Assert.Equal(new[] { 3, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[2]);
            edited = a.InsertColumn(3, new Complex[] { 11, 22, 33 }).InsertColumn(3, new double[] { 44, 55, 66 });
            Assert.Equal(new[] { 3, 5 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3, 44, 11 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 5, 6, 55, 22 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 8, 9, 66, 33 }, edited[2]);
            edited = a.InsertColumn(1, new Complex[] { 11, 22, 33 }).InsertColumn(4, new double[] { 44, 55, 66 });
            Assert.Equal(new[] { 3, 5 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 11, 2, 3, 44 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 22, 5, 6, 55 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 33, 8, 9, 66 }, edited[2]);
        }

        [Fact]
        [Trait("Category", "Instance")]
        public void Can_insert_rows() {
            var a = new Matrix(3);
            Helpers.Populate(a, new double[,] {
                { 1, 2, 3 },
                { 4, 5, 6 },
                { 7, 8, 9 },
            });
            var edited = a.InsertRow(0, new Complex[] { 11, 22, 33 });
            Assert.Equal(new[] { 4, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 11, 22, 33 }, edited[0]);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[1]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[2]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[3]);
            edited = a.InsertRow(1, new Complex[] { 11, 22, 33 });
            Assert.Equal(new[] { 4, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 11, 22, 33 }, edited[1]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[2]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[3]);
            edited = a.InsertRow(1, new double[] { 11, 22, 33 });
            Assert.Equal(new[] { 4, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 11, 22, 33 }, edited[1]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[2]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[3]);
            edited = a.InsertRow(3, new Complex[] { 11, 22, 33 });
            Assert.Equal(new[] { 4, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[2]);
            Assert.Equal(new Complex[] { 11, 22, 33 }, edited[3]);
            edited = a.InsertRow(4, new Complex[] { 11, 22, 33 });
            Assert.Equal(new[] { 3, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[2]);
            edited = a.InsertRow(4, new double[] { 11, 22, 33 });
            Assert.Equal(new[] { 3, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[2]);
            edited = a.InsertRow(1, new Complex[] { 11, 22, 33 }).InsertRow(1, new Complex[] { 44, 55, 66 });
            Assert.Equal(new[] { 5, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 44, 55, 66 }, edited[1]);
            Assert.Equal(new Complex[] { 11, 22, 33 }, edited[2]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[3]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[4]);
            edited = a.InsertRow(1, new Complex[] { 11, 22, 33 }).InsertRow(4, new Complex[] { 44, 55, 66 });
            Assert.Equal(new[] { 5, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 11, 22, 33 }, edited[1]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[2]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[3]);
            Assert.Equal(new Complex[] { 44, 55, 66 }, edited[4]);
            edited = a.InsertRow(1, new double[] { 11, 22, 33 }).InsertRow(4, new double[] { 44, 55, 66 });
            Assert.Equal(new[] { 5, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 11, 22, 33 }, edited[1]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[2]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[3]);
            Assert.Equal(new Complex[] { 44, 55, 66 }, edited[4]);
            edited = a.InsertRow(1, new double[] { 11, 22, 33 }).InsertRow(4, new Complex[] { 44, 55, 66 });
            Assert.Equal(new[] { 5, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 11, 22, 33 }, edited[1]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[2]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[3]);
            Assert.Equal(new Complex[] { 44, 55, 66 }, edited[4]);
        }

        [Fact]
        [Trait("Category", "Instance")]
        public void Can_remove_columns() {
            var a = new Matrix(3);
            Helpers.Populate(a, new double[,] {
                { 1, 2, 3 },
                { 4, 5, 6 },
                { 7, 8, 9 },
            });
            var edited = a.RemoveColumn(0);
            Assert.Equal(new[] { 3, 2 }, edited.Size);
            Assert.Equal(new Complex[] { 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 5, 6 }, edited[1]);
            Assert.Equal(new Complex[] { 8, 9 }, edited[2]);
            edited = a.RemoveColumn(1);
            Assert.Equal(new[] { 3, 2 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 6 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 9 }, edited[2]);
            edited = a.RemoveColumn(2);
            Assert.Equal(new[] { 3, 2 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 5 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 8 }, edited[2]);
            edited = a.RemoveColumn(3);
            Assert.Equal(new[] { 3, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[2]);
            edited = a.RemoveColumn(-1);
            Assert.Equal(new[] { 3, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[2]);
            edited = a.RemoveColumn(0).RemoveRow(0);
            Assert.Equal(new[] { 2, 2 }, edited.Size);
            Assert.Equal(new Complex[] { 5, 6 }, edited[0]);
            Assert.Equal(new Complex[] { 8, 9 }, edited[1]);
        }

        [Fact]
        [Trait("Category", "Instance")]
        public void Can_remove_rows() {
            var a = new Matrix(3);
            Helpers.Populate(a, new double[,] {
                { 1, 2, 3 },
                { 4, 5, 6 },
                { 7, 8, 9 },
            });
            var edited = a.RemoveRow(0);
            Assert.Equal(new[] { 2, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[0]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[1]);
            edited = a.RemoveRow(1);
            Assert.Equal(new[] { 2, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[1]);
            edited = a.RemoveRow(2);
            Assert.Equal(new[] { 2, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[1]);
            edited = a.RemoveRow(3);
            Assert.Equal(new[] { 3, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[2]);
            edited = a.RemoveRow(-1);
            Assert.Equal(new[] { 3, 3 }, edited.Size);
            Assert.Equal(new Complex[] { 1, 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 4, 5, 6 }, edited[1]);
            Assert.Equal(new Complex[] { 7, 8, 9 }, edited[2]);
            edited = a.RemoveRow(2).RemoveColumn(0);
            Assert.Equal(new[] { 2, 2 }, edited.Size);
            Assert.Equal(new Complex[] { 2, 3 }, edited[0]);
            Assert.Equal(new Complex[] { 5, 6 }, edited[1]);
        }

        [Fact]
        [Trait("Category", "Instance")]
        public void Can_swap_rows() {
            var a = new Matrix(2);
            Helpers.Populate(a, new double[,] {
                { 1, 2 },
                { 3, 4 },
            });
            var b = a.SwapRows(0, 1);
            Assert.Equal(new Complex[] { 3, 4 }, b[0]);
            Assert.Equal(new Complex[] { 1, 2 }, b[1]);
            b = a.SwapRows(1, 0);
            Assert.Equal(new Complex[] { 3, 4 }, b[0]);
            Assert.Equal(new Complex[] { 1, 2 }, b[1]);
            Assert.Throws<IndexOutOfRangeException>(() => a.SwapRows(-1, 0));
            Assert.Throws<IndexOutOfRangeException>(() => a.SwapRows(3, 1));
        }

        [Fact]
        [Trait("Category", "Instance")]
        public void Can_be_converted_to_string() {
            var a = new Matrix(2);
            Helpers.Populate(a, new double[,] {
                { 1, 2 },
                { 3, 4 },
            });
            Assert.Equal("(1, 0),(2, 0)\r\n(3, 0),(4, 0)", a.ToString());
        }

        [Fact]
        public void Can_be_converted_to_upper_triangular() {
            var a = new Matrix(3, 3);
            Helpers.Populate(a, new double[,] {
                { 1, 1, 1 },
                { 4, 3, 4 },
                { 9, 3, 4 },
            });
            var b = a.ToUpperTriangular();
            Assert.Equal(new[] { 3, 3 }, b.Size);
            Assert.Equal(new Complex[] { 9, 3, 4 }, b[0]);
            Assert.Equal(new Complex[] { 0, 1.6666666666666667, 2.2222222222222223 }, b[1]);
            Assert.Equal(new Complex[] { 0, 0, -0.33333333333333337 }, b[2]);
            a = new Matrix(3, 3);
            Helpers.Populate(a, new double[,] {
                { 9, 3, 4 },
                { 4, 3, 4 },
                { 1, 1, 1 },
            });
            b = a.ToUpperTriangular();
            Assert.Equal(new[] { 3, 3 }, b.Size);
            Assert.Equal(new Complex[] { 9, 3, 4 }, b[0]);
            Assert.Equal(new Complex[] { 0, 1.6666666666666667, 2.2222222222222223 }, b[1]);
            Assert.Equal(new Complex[] { 0, 0, -0.33333333333333337 }, b[2]);
            a = new Matrix(3, 4);
            Helpers.Populate(a, new double[,] {
                { 9, 3, 4, 7 },
                { 4, 3, 4, 8 },
                { 1, 1, 1, 3 },
            });
            b = a.ToUpperTriangular();
            Assert.Equal(new[] { 3, 4 }, b.Size);
            Assert.Equal(new Complex[] { 9, 3, 4, 7 }, b[0]);
            Assert.Equal(new Complex[] { 0, 1.6666666666666667, 2.2222222222222223, 4.888888888888889 }, b[1]);
            Assert.Equal(new Complex[] { 0, 0, -0.33333333333333337, 0.2666666666666666 }, b[2]);
            a = new Matrix(3, 4);
            Helpers.Populate(a, new double[,] {
                { 1, 1, 1, 3 },
                { 4, 3, 4, 8 },
                { 9, 3, 4, 7 },
            });
            b = a.ToUpperTriangular();
            Assert.Equal(new[] { 3, 4 }, b.Size);
            Assert.Equal(new Complex[] { 9, 3, 4, 7 }, b[0]);
            Assert.Equal(new Complex[] { 0, 1.6666666666666667, 2.2222222222222223, 4.888888888888889 }, b[1]);
            Assert.Equal(new Complex[] { 0, 0, -0.33333333333333337, 0.2666666666666666 }, b[2]);
        }

        [Fact]
        [Trait("Category", "Determinant")]
        public void Can_calculate_determinant_for_1x1_matrices() {
            var a = new Matrix(1);
            Helpers.Populate(a, new double[,] {
                { 1 },
            });
            Assert.Equal(1, Matrix.Det(a));
        }

        [Fact]
        [Trait("Category", "Determinant")]
        public void Can_calculate_determinant_for_2x2_matrices() {
            var a = new Matrix(2);
            Helpers.Populate(a, new double[,] {
                { 1, 2 },
                { 3, 4 },
            });
            Assert.Equal(-2, Matrix.Det(a));
            Assert.Equal(0, Matrix.Det(Matrix.Unit(2)));
        }

        [Theory]
        [InlineData(3)]
        [Trait("Category", "Determinant")]
        public void Can_calculate_determinant_for_3x3_matrices(int n) {
            var a = new Matrix(n);
            var b = new Matrix(n);
            Helpers.Populate(a, new double[,] {
                { 2, 3, -4 },
                { 0, -4, 2 },
                { 1, -1, 5 },
            });
            Helpers.Populate(b, new double[,] {
                { 1, 2, 3 },
                { 4, -2, 3 },
                { 2, 5, -1 },
            });
            Assert.Equal(-46, Matrix.Det(a));
            Assert.Equal(79, Matrix.Det(b));
            Assert.Equal(0, Matrix.Det(Matrix.Unit(n)));
            Assert.Equal(1, Matrix.Det(Matrix.Identity(n)));
        }

        [Theory]
        [InlineData(4)]
        [Trait("Category", "Determinant")]
        public void Can_calculate_determinant_for_4x4_matrices(int n) {
            var a = new Matrix(n);
            var b = new Matrix(n);
            Helpers.Populate(a, new double[,] {
                { 3, -2, -5, 4 },
                { -5, 2, 8, -5 },
                { -2, 4, 7, -3 },
                { 2, -3, -5, 8 },
            });
            Helpers.Populate(b, new double[,] {
                { 5, 4, 2, 1 },
                { 2, 3, 1, -2 },
                { -5, -7, -3, 9 },
                { 1, -2, -1, 4 },
            });
            Assert.Equal(-54, Matrix.Det(a));
            Assert.Equal(38, Matrix.Det(b));
            Assert.Equal(0, Matrix.Det(Matrix.Unit(n)));
            Assert.Equal(1, Matrix.Det(Matrix.Identity(n)));
        }

        [Theory]
        [InlineData(6)]
        [Trait("Category", "Determinant")]
        [Trait("Category", "LongDuration")]
        public void Can_calculate_determinant_for_matrices_larger_than_4x4(int n) {
            var a = new Matrix(n);
            Helpers.Populate(a, new double[,] {
                { 12, 22, 14, 17, 20, 10 },
                { 16, -4, 7, 1, -2, 15 },
                { 10, -3, -2, 3, -2, 8 },
                { 7, 12, 8, 9, 11, 6 },
                { 11, 2, 4, -8, 1, 9 },
                { 24, 6, 6, 3, 4, 22 },
            });
            Assert.Equal(12228, Matrix.Det(a));
            Assert.Equal(0, Matrix.Det(Matrix.Unit(10)));
            Assert.Equal(1, Matrix.Det(Matrix.Identity(10)));
        }

        public class Helpers {
            public static void Populate(Matrix a, double[,] rows) {
                foreach (var index in a.Indexes()) {
                    int i = index[0], j = index[1];
                    a[i][j] = rows[i, j];
                }
            }

            public static void Populate(Matrix a, Complex[,] rows) {
                foreach (var index in a.Indexes()) {
                    int i = index[0], j = index[1];
                    a[i][j] = rows[i, j];
                }
            }
        }
    }
}