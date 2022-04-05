using Xunit;
using System;
using System.Collections.Generic;
using Prelude;

namespace ItemTests {
    public class UnitTests {
        [Fact]
        public void Can_be_created_from_a_double() {
            var defaultValue = 0;
            var value = 42;
            var x = new Item();
            var y = new Item(value);
            Assert.Equal(defaultValue, x.Value);
            Assert.Equal(value, y.Value);
        }
        [Fact]
        public void Can_be_created_from_a_node_and_value() {
            var defaultValue = 0;
            var value = 42;
            var a = new Node("a");
            var x = new Item(a);
            var y = new Item(a, value);
            Assert.Equal(defaultValue, x.Value);
            Assert.Equal(a, x.Node);
            Assert.Equal(value, y.Value);
            Assert.Equal(a, y.Node);
        }
        [Fact]
        public void Can_be_compared_in_various_contexts() {
            var a = new Item(42);
            var b = new Item(43);
            Assert.True(a.Equals(a));
            Assert.False(a.Equals(b));
            Assert.False(a.Equals(null));
            Assert.True(Equals(a, a));
            Assert.False(Equals(a, b));
            Assert.False(Equals(null, a));
            Assert.False(Equals(a, null));
            Assert.True(Equals(null, null));
#pragma warning disable CS1718 // Comparison made to same variable
            Assert.True(a == a);
            Assert.False(a != a);
            Assert.True(a <= a);
            Assert.True(a >= a);
#pragma warning restore CS1718 // Comparison made to same variable
            Assert.False(a == b);
            Assert.True(a != b);
            Assert.True(a != null);
            Assert.True(null != a);
            Assert.Equal(a.GetHashCode(), a.GetHashCode());
            Assert.True(a < b);
            Assert.True(a <= b);
            Assert.False(a > b);
            Assert.False(a >= b);
            Assert.True(b > a);
            Assert.True(b >= a);
            Assert.False(b < a);
            Assert.False(b <= a);
            Assert.False(a < null);
            Assert.False(a <= null);
            Assert.False(a > null);
            Assert.False(a >= null);
        }
    }
}