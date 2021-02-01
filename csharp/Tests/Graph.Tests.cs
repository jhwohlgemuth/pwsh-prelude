using Xunit;
using System.Collections.Generic;
using Prelude;

namespace GraphTests {
    public class UnitTests {
        [Fact]
        public void Graph_will_be_assigned_Id_automatically() {
            var graph = new Graph();
            Assert.Equal(36, graph.Id.ToString().Length);
            var a = new Node();
            var b = new Node();
            var c = new Node();
            var x = new Edge(a, b);
            var y = new Edge(b, c);
            var nodes = new List<Node> { a, b, c };
            var edges = new List<Edge> { x, y };
            graph = new Graph(nodes, edges);
            Assert.Equal(36, graph.Id.ToString().Length);
            Assert.Equal(3, graph.Nodes.Count);
            Assert.Equal(2, graph.Edges.Count);
        }
        [Fact]
        public void Graph_can_add_node() {
            var graph = new Graph();
            var a = new Node();
            var b = new Node();
            Assert.Empty(graph.Nodes);
            graph.Add(a);
            Assert.Single(graph.Nodes);
            Assert.Equal(0, graph.Nodes[0].Index);
            graph.Add(b);
            Assert.Equal(2, graph.Nodes.Count);
            Assert.Equal(1, graph.Nodes[1].Index);
        }
        [Fact]
        public void Graph_can_add_array_of_nodes() {
            var graph = new Graph();
            var a = new Node();
            var b = new Node();
            Assert.Empty(graph.Nodes);
            graph.Add(a, b);
            Assert.Equal(2, graph.Nodes.Count);
            Assert.Equal(1, graph.Nodes[1].Index);
            graph = new Graph();
            var NodeArray = new Node[] { a, b };
            Assert.Empty(graph.Nodes);
            graph.Add(NodeArray);
            Assert.Equal(2, graph.Nodes.Count);
            Assert.Equal(1, graph.Nodes[1].Index);
        }
        [Fact(Skip = "Not Implemented")]
        public void Graph_can_add_list_of_nodes() {
            var graph = new Graph();
            var a = new Node();
            var b = new Node();
            Assert.Empty(graph.Nodes);
            graph = new Graph();
            Assert.Empty(graph.Nodes);
            var NodeList = new List<Node> { a, b };
            graph.Add(NodeList);
            Assert.Equal(2, graph.Nodes.Count);
            Assert.Equal(1, graph.Nodes[1].Index);
        }
        [Fact]
        public void Graph_can_add_edge() {
            var graph = new Graph();
            var a = new Node();
            var b = new Node();
            var c = new Node();
            var x = new Edge(a, b);
            var y = new Edge(b, c);
            var z = new Edge(a, c);
        }
        [Fact]
        public void Graph_can_clear_nodes() {
            var graph = new Graph();
            var a = new Node();
            var b = new Node();
            graph.Add(a, b);
            Assert.Equal(2, graph.Nodes.Count);
            graph.Clear();
            Assert.Empty(graph.Nodes);
        }
    }
}