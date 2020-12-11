using Xunit;

namespace Prelude.GraphTests {
    public class UnitTests {
        [Fact]
        public void Can_Be_Created() {
            var g = new Graph();
            Assert.Equal(36, g.Id.ToString().Length);
        }
    }
}