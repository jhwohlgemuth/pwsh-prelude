using Xunit;
using System;
using System.Collections.Generic;
using Prelude;

namespace EdgeTests {
    public class UnitTests {
        [Fact]
        public void Will_be_assigned_Id_automatically() {
            Node a = new Node();
            Node b = new Node();
            Edge e = new Edge(a, b);
            Assert.Equal(36, e.Id.ToString().Length);
        }
        [Fact]
        public void Can_be_compared() {
            Node a = new Node();
            Node b = new Node();
            Node c = new Node();
            Edge ab = new Edge(a, b);
            Edge bc = new Edge(b, c);
            Edge ac = new Edge(a, c);
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
            Assert.True(null != ab);
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
            var a = new Node("A");
            var b = new Node("B");
            var ab = new Edge(a, b);
            var clone = ab.Clone();
            Assert.Equal(ab.Source, clone.Source);
            Assert.Equal(ab.Target, clone.Target);
            Assert.Equal(ab, clone);
            Assert.NotEqual(ab.Id, clone.Id);
        }
        [Fact]
        public void Can_create_edge_with_nodes_reversed() {
            var a = new Node("A");
            var b = new Node("B");
            var ab = new Edge(a, b);
            var reversed = ab.Reverse();
            Assert.Equal(ab.Source, reversed.Target);
            Assert.Equal(ab.Target, reversed.Source);
            Assert.NotEqual(ab, reversed);
            Assert.NotEqual(ab.Id, reversed.Id);
        }
    }
}