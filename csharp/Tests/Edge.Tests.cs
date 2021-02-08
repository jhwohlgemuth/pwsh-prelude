using Xunit;
using Prelude;

namespace EdgeTests {
    public class UnitTests {
        [Fact]
        public void Edge_will_be_assigned_Id_automatically() {
            Node a = new Node();
            Node b = new Node();
            Edge e = new Edge(a, b);
            Assert.Equal(36, e.Id.ToString().Length);
        }
        [Fact]
        public void Edges_can_be_compared() {
            Node a = new Node();
            Node b = new Node();
            Node c = new Node();
            Edge x = new Edge(a, b);
            Edge y = new Edge(b, c);
            Assert.Equal(x, x);
            Assert.NotEqual(x, y);
            Assert.Equal(x, new Edge(a, b));
            Assert.NotEqual(x, new Edge(a, b, 2));
        }
    }
}