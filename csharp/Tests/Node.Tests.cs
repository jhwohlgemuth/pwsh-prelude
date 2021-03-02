using Xunit;
using Prelude;
using System;
using System.Collections.Generic;

namespace NodeTests {
    public class UnitTests {
        [Fact]
        public void Can_be_assigned_a_label() {
            Node n = new Node();
            Assert.Equal(36, n.Id.ToString().Length);
            Assert.Equal("node", n.Label);
            Node m = new Node("test");
            Assert.Equal(36, m.Id.ToString().Length);
            Assert.Equal("test", m.Label);
        }
        [Theory]
        [InlineData("7a402e3c-827a-40e2-a69d-d83248f62a74", "Not valid")]
        [InlineData("7a402e3c-827a-40e2-a69d-d83248f62a74", "Also not valid")]
        [InlineData("f57eba10-1302-4f9c-890c-1f99fed0743c", "f57eba10-1302-4f9c-890c-fed0743c")]
        public void Can_validate_node_identifiers(string valid, string invalid) {
            Assert.True(Node.IsValidIdentifier(valid));
            Assert.False(Node.IsValidIdentifier(invalid));
        }
        [Fact]
        public void Can_be_assigned_a_valid_Id() {
            var valid = Guid.NewGuid();
            var invalid = "not valid";
            var id = "7a402e3c-827a-40e2-a69d-d83248f62a74";
            var a = new Node(valid);
            var b = new Node(id, "valid");
            Assert.Equal(valid, a.Id);
            Assert.Equal(id, b.Id.ToString());
            Assert.Throws<ArgumentException>(() => new Node(invalid, "invalid node"));
        }
        [Fact]
        public void Can_be_assigned_Id_automatically() {
            var n = new Node();
            Assert.Equal(36, n.Id.ToString().Length);
        }
        [Theory]
        [InlineData("foo")]
        [InlineData("bar")]
        [InlineData("baz")]
        public void Can_set_node_label_text(string text) {
            var id = "7a402e3c-827a-40e2-a69d-d83248f62a74";
            var a = new Node(id);
            a.SetLabel(text);
            Assert.Equal(text, a.Label);
        }
        [Fact]
        public void Nodes_can_be_compared() {
            Node a = new Node();
            Node b = new Node();
            Node c = new Node();
            Assert.Equal(a, a);
            Assert.NotEqual(a, b);
            Assert.NotEqual(b, a);
            Assert.Equal(b, b);
            Assert.True(a.Equals(a));
            Assert.False(a.Equals(b));
            Assert.False(a.Equals(c));
            Assert.False(a.Equals(null));
            Assert.True(Equals(a, a));
            Assert.False(Equals(a, b));
            Assert.False(Equals(a, c));
            Assert.False(Equals(null, a));
            Assert.False(Equals(a, null));
            Assert.True(Equals(null, null));
#pragma warning disable CS1718 // Comparison made to same variable
            Assert.True(a == a);
            Assert.False(a != a);
#pragma warning restore CS1718 // Comparison made to same variable
            Assert.False(a == b);
            Assert.True(a != b);
            Assert.True(a != c);
            Assert.True(a != null);
            Assert.True(null != a);
            var values = new List<Node> { a, b, c };
            values.Sort();
            Assert.Contains(a, values);
            values = new List<Node> { a, b, null };
            Assert.Throws<InvalidOperationException>(() => values.Sort());
        }
    }
}