using Xunit;
using Prelude;

namespace EdgeTests {
    public class UnitTests {
        [Theory]
        [InlineData("a", "b")]
        [InlineData("a", "b", 42)]
        public void Edge_Can_Be_Created_With_String_Parameters(string to, string from, double weight = 1) {
            var e = new Edge(to, from, weight);
            Assert.Equal(36, e.Id.ToString().Length);
            Assert.Equal(to, e.To);
            Assert.Equal(from, e.From);
            Assert.Equal(weight, e.Weight);
        }
        [Fact]
        public void Edge_Can_Be_Created_With_Integer_Parameters() {
            var e = new Edge(1, 2);
            Assert.Equal(36, e.Id.ToString().Length);
            Assert.Equal("1", e.To);
            Assert.Equal("2", e.From);
            Assert.Equal(1, e.Weight);
            e = new Edge(1, 2, 3);
            Assert.Equal(36, e.Id.ToString().Length);
            Assert.Equal("1", e.To);
            Assert.Equal("2", e.From);
            Assert.Equal(3, e.Weight);
        }
    }
}