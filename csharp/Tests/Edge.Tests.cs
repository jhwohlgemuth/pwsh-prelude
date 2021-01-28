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
        public void Edges_support_weight() {
            Node a = new Node();
            Node b = new Node();
            Assert.False((new Edge(a, b)).IsWeighted);
            Assert.True((new Edge(a, b, 1)).IsWeighted);
            Assert.True((new Edge(a, b, -1)).IsWeighted);
        }
    }
}