using Xunit;
using System.Collections.Generic;
using Prelude;

namespace GraphTests {
    public class UnitTests {
        [Fact]
        public void Graph_will_be_assigned_Id_automatically() {
            var g = new Graph();
            Assert.Equal(36, g.Id.ToString().Length);
            Node a = new Node();
            Node b = new Node();
            Node c = new Node();
            Edge x = new Edge(a, b);
            Edge y = new Edge(b, c);
            var nodes = new List<Node> { a, b, c };
            var edges = new List<Edge> { x, y };
            g = new Graph(nodes, edges);
            Assert.Equal(36, g.Id.ToString().Length);
            Assert.Equal(3, g.Nodes.Count);
            Assert.Equal(2, g.Edges.Count);
        }
    }
}