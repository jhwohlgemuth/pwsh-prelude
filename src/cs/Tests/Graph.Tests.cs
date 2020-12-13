using Xunit;
using Prelude;

namespace GraphTests {
    public class UnitTests {
        [Fact]
        public void Graph_Can_Be_Created() {
            var g = new Graph();
            Assert.Equal(36, g.Id.ToString().Length);
        }
    }
}