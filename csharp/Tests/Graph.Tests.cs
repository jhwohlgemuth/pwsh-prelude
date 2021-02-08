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
            var ab = new Edge(a, b);
            var bc = new Edge(b, c);
            var nodes = new List<Node> { a, b, c };
            var edges = new List<Edge> { ab, bc };
            graph = new Graph(nodes, edges);
            Assert.Equal(36, graph.Id.ToString().Length);
            Assert.Equal(3, graph.Nodes.Count);
            Assert.Equal(2, graph.Edges.Count);
        }
        [Fact]
        public void Can_be_passed_nodes_and_edges_at_creation() {
            var a = new Node();
            var b = new Node();
            var c = new Node();
            var ab = new Edge(a, b);
            var bc = new Edge(b, c);
            var nodes = new List<Node> { a, b, c };
            var edges = new List<Edge> { ab, bc };
            var graph = new Graph(nodes, edges);
            Assert.Equal(3, graph.Nodes.Count);
            Assert.Equal(2, graph.Edges.Count);
        }
        [Fact]
        public void Can_maintain_matrix_representation_with_undirected_edges() {
            var a = new Node();
            var b = new Node();
            var c = new Node();
            var ab = new Edge(a, b);
            var bc = new Edge(b, c);
            var nodes = new List<Node> { a, b, c };
            var edges = new List<Edge> { ab, bc };
            var graph = new Graph(nodes, edges);
            var adjacencyMatrix = graph.AdjacencyMatrix;
            Assert.Equal(new List<double> { 0, 1, 0 }, adjacencyMatrix.Rows[0]);
            Assert.Equal(new List<double> { 0, 0, 1 }, adjacencyMatrix.Rows[1]);
            Assert.Equal(new List<double> { 0, 0, 0 }, adjacencyMatrix.Rows[2]);
        }
        [Fact]
        public void Can_maintain_matrix_representation_with_directed_edges() {
            var a = new Node();
            var b = new Node();
            var c = new Node();
            var ab = new DirectedEdge(a, b);
            var bc = new DirectedEdge(b, c, 5);
            var nodes = new List<Node> { a, b, c };
            var edges = new List<Edge> { ab, bc };
            var graph = new Graph(nodes, edges);
            var adjacencyMatrix = graph.AdjacencyMatrix;
            Assert.Equal(new List<double> { 0, 1, 0 }, adjacencyMatrix.Rows[0]);
            Assert.Equal(new List<double> { 1, 0, 5 }, adjacencyMatrix.Rows[1]);
            Assert.Equal(new List<double> { 0, 5, 0 }, adjacencyMatrix.Rows[2]);
        }
        [Fact]
        public void Graph_can_get_nodes() {
            var graph = new Graph();
            var a = new Node("a");
            graph.Add(a);
            Assert.Equal(a, graph.GetNode(a));
            Assert.Equal(a, graph.GetNode(a.Id));
            Assert.Equal(a, graph.GetNode("a"));
        }
        [Fact]
        public void Graph_can_add_nodes_one_at_a_time() {
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
        [Fact]
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
        public void Graph_can_add_edges_one_at_a_time() {
            var graph = new Graph();
            var a = new Node();
            var b = new Node();
            var ab = new Edge(a, b);
            Assert.Empty(graph.Nodes);
            Assert.Empty(graph.Edges);
            graph.Add(ab);
            Assert.Empty(graph.Edges);
            graph.Add(a, b).Add(ab);
            Assert.Equal(2, graph.Nodes.Count);
            Assert.Single(graph.Edges);
        }
        [Fact]
        public void Graph_will_only_add_unique_edges() {
            var valid = "a";
            var graph = new Graph();
            var a = new Node(valid);
            var b = new Node("b");
            var c = new Node("c");
            var d = new Node("d");
            var ab = new Edge(a, b);
            var bc = new Edge(b, c);
            var ac = new Edge(a, c);
            var cd = new Edge(c, d);
            graph.Add(a, b).Add(ab, bc, ac, cd);
            Assert.Equal(2, graph.Nodes.Count);
            Assert.Single(graph.Edges);
            Assert.Equal(valid, graph.Edges[0].Source.Label);
        }
        [Fact]
        public void Graph_can_add_array_of_edges() {
            var graph = new Graph();
            var a = new Node("a");
            var b = new Node("b");
            var c = new Node("c");
            var ab = new Edge(a, b);
            var bc = new Edge(b, c);
            var ac = new Edge(a, c);
            var nodes = new Node[] { a, b, c };
            var edges = new Edge[] { ab, bc, ac };
            graph.Add(nodes).Add(edges);
            Assert.Equal(3, graph.Nodes.Count);
            Assert.Equal(3, graph.Edges.Count);
        }
        [Fact]
        public void Graph_can_add_list_of_edges() {
            var graph = new Graph();
            var a = new Node("a");
            var b = new Node("b");
            var c = new Node("c");
            var ab = new Edge(a, b);
            var bc = new Edge(b, c);
            var ac = new Edge(a, c);
            var nodes = new List<Node> { a, b, c };
            var edges = new List<Edge> { ab, bc, ac };
            graph.Add(nodes).Add(edges);
            Assert.Equal(3, graph.Nodes.Count);
            Assert.Equal(3, graph.Edges.Count);
        }
        [Fact]
        public void Graph_can_add_nodes_and_edges_from_graphs() {
            var graph = new Graph();
            var a = new Node("a");
            var b = new Node("b");
            var c = new Node("c");
            var ab = new Edge(a, b);
            var bc = new Edge(b, c);
            var ac = new Edge(a, c);
            graph.Add(a, b, c).Add(ab, bc, ac);
            var fromGraph = Graph.From(graph);
            Assert.Equal(3, fromGraph.Nodes.Count);
            Assert.Equal(3, fromGraph.Edges.Count);
            var addGraph = new Graph();
            addGraph.Add(graph);
            Assert.Equal(3, fromGraph.Nodes.Count);
            Assert.Equal(3, fromGraph.Edges.Count);
        }
        [Fact]
        public void Graph_can_clear_nodes_and_edges() {
            var graph = new Graph();
            var a = new Node();
            var b = new Node();
            var c = new Node();
            var ab = new Edge(a, b);
            var bc = new Edge(b, c);
            var ac = new Edge(a, c);
            graph.Add(a, b, c).Add(ab, bc, ac);
            Assert.Equal(3, graph.Nodes.Count);
            Assert.Equal(3, graph.Edges.Count);
            graph.Clear();
            Assert.Empty(graph.Nodes);
            Assert.Empty(graph.Edges);
        }
        [Fact]
        public void Graph_can_remove_nodes_one_at_a_time() {
            var graph = new Graph();
            var a = new Node("a");
            var b = new Node("b");
            var c = new Node("c");
            var ab = new Edge(a, b);
            var bc = new Edge(b, c);
            var ac = new Edge(a, c);
            graph.Add(a, b, c).Add(ab, bc, ac);
            Assert.Equal(3, graph.Nodes.Count);
            Assert.Equal(3, graph.Edges.Count);
            Assert.True(graph.Contains(a));
            graph.Remove(a);
            Assert.False(graph.Contains(a));
            Assert.Equal(2, graph.Nodes.Count);
            Assert.Single(graph.Edges);
        }
        [Fact]
        public void Graph_can_remove_edges_one_at_a_time() {
            var graph = new Graph();
            var a = new Node("a");
            var b = new Node("b");
            var c = new Node("c");
            var ab = new Edge(a, b);
            var bc = new Edge(b, c);
            var ac = new Edge(a, c);
            graph.Add(a, b, c).Add(ab, bc, ac);
            Assert.Equal(3, graph.Edges.Count);
            Assert.Equal(2, graph.GetNode(a).Degree);
            Assert.Equal(2, graph.GetNode(b).Degree);
            Assert.Equal(2, graph.GetNode(c).Degree);
            graph.Remove(bc);
            Assert.Equal(2, graph.Edges.Count);
            Assert.Equal(2, graph.GetNode(a).Degree);
            Assert.Equal(1, graph.GetNode(b).Degree);
            Assert.Equal(1, graph.GetNode(c).Degree);
        }
    }
}