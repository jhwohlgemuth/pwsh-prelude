// <copyright file="Edge.Tests.cs" company="Jason Wohlgemuth">
// Copyright (c) 2022 Jason Wohlgemuth. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
// </copyright>

namespace EdgeTests {
    using System;
    using System.Collections.Generic;
    using Prelude;
    using Xunit;

    public class UnitTests {
        [Fact]
        public void Will_be_assigned_Id_automatically() {
            Node a = new();
            Node b = new();
            Edge e = new(a, b);
            Assert.Equal(36, e.Id.ToString().Length);
        }

        [Fact]
        public void Can_be_compared() {
            Node a = new();
            Node b = new();
            Node c = new();
            Edge ab = new(a, b);
            Edge bc = new(b, c);
            Edge ac = new(a, c);
            Assert.Equal(ab, ab);
            Assert.NotEqual(ab, bc);
            Assert.Equal(ab, new Edge(a, b));
            Assert.NotEqual(ab, new Edge(a, b, 2));
            Assert.True(ab.Equals(ab));
            Assert.False(ab.Equals(bc));
            Assert.False(ab.Equals(ac));
            Assert.False(ab.Equals(null));
            Assert.True(Equals(ab, ab));
            Assert.False(Equals(ab, bc));
            Assert.False(Equals(ab, ac));
            Assert.False(Equals(null, ab));
            Assert.False(Equals(ab, null));
            Assert.True(Equals(null, null));
#pragma warning disable CS1718 // Comparison made to same variable
            Assert.True(ab == ab);
            Assert.False(ab != ab);
#pragma warning restore CS1718 // Comparison made to same variable
            Assert.False(ab == bc);
            Assert.True(ab != bc);
            Assert.True(ab != ac);
            Assert.True(ab != null);
#pragma warning disable SA1131 // Use readable conditions
            Assert.True(null != ab);
#pragma warning restore SA1131 // Use readable conditions
            var values = new List<Edge> { ab, bc, ac };
            values.Sort();
            Assert.Contains(bc, values);
            values = new List<Edge> { ab, bc, null };
            Assert.Throws<InvalidOperationException>(() => values.Sort());
            var message = "Parameter is not an Edge";
            var ex = Assert.Throws<ArgumentException>(() => ab.CompareTo(null));
            Assert.Equal(message, ex.Message);
        }

        [Fact]
        public void Can_create_clones() {
            Node a = new("A");
            Node b = new("B");
            Edge ab = new(a, b);
            var clone = ab.Clone();
            Assert.Equal(ab.Source, clone.Source);
            Assert.Equal(ab.Target, clone.Target);
            Assert.Equal(ab, clone);
            Assert.NotEqual(ab.Id, clone.Id);
        }

        [Fact]
        public void Can_create_edge_with_nodes_reversed() {
            Node a = new("A");
            Node b = new("B");
            Edge ab = new(a, b);
            var reversed = ab.Reverse();
            Assert.Equal(ab.Source, reversed.Target);
            Assert.Equal(ab.Target, reversed.Source);
            Assert.NotEqual(ab, reversed);
            Assert.NotEqual(ab.Id, reversed.Id);
        }

        [Fact]
        public void Can_be_directed() {
            Node a = new("A");
            Node b = new("B");
            DirectedEdge ab = new(a, b);
            Node x = new("x");
            Node y = new("y");
            Edge xy = new(x, y);
            Assert.True(ab.IsDirected);
            Assert.Equal(a, ab.Source);
            Assert.Equal(b, ab.Target);
            Assert.False(xy.IsDirected);
            Assert.Equal(x, xy.Source);
            Assert.Equal(y, xy.Target);
        }
    }
}