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
        public void Graph_will_only_add_unique_nodes() {
            var label = "unique";
            var graph = new Graph();
            var a = new Node(label);
            Assert.Empty(graph.Nodes);
            graph.Add(a);
            Assert.Single(graph.Nodes);
            graph.Add(a);
            Assert.Single(graph.Nodes);
            Assert.Equal(label, graph.Nodes[0].Label);
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
            graph.Add(a, b, c);
            graph.Add(x, y, z);
            Assert.Equal(3, graph.Nodes.Count);
            Assert.Equal(3, graph.Edges.Count);
            graph.Clear();
            Assert.Empty(graph.Nodes);
            Assert.Empty(graph.Edges);
        }
        [Fact]
        public void Graph_will_only_add_unique_edges() {
            var valid = "a";
            var graph = new Graph();
            var a = new Node(valid);
            var b = new Node("b");
            var c = new Node("c");
            var d = new Node("d");
            var w = new Edge(a, b);
            var x = new Edge(b, c);
            var y = new Edge(a, c);
            var z = new Edge(c, d);
            graph.Add(a, b);
            graph.Add(w, x, y, z);
            Assert.Equal(2, graph.Nodes.Count);
            Assert.Single(graph.Edges);
            Assert.Equal(valid, graph.Edges[0].Source.Label);
        }
        [Fact]
        public void Graph_can_clear_nodes_and_edges() {
            var graph = new Graph();
            var a = new Node();
            var b = new Node();
            var c = new Node();
            var x = new Edge(a, b);
            var y = new Edge(b, c);
            var z = new Edge(a, c);
            graph.Add(a, b, c);
            Assert.Equal(2, graph.Nodes.Count);
            graph.Clear();
            Assert.Empty(graph.Nodes);
        }
    }
}