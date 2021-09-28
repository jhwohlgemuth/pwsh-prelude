using Xunit;
using System;
using System.Collections.Generic;
using System.Numerics;
using Prelude;

namespace GraphTests {
    public class UnitTests {
        [Theory]
        [InlineData(2, 3)]
        [InlineData(4, 6)]
        [InlineData(7, 5)]
        [InlineData(1, 1)]
        public void Can_create_Bipartite_graph(int M, int N) {
            var graph = Graph.Bipartite(M, N);
            Assert.Equal(M + N, graph.Nodes.Count);
            Assert.Equal(M * N, graph.Edges.Count);
        }
        [Theory]
        [InlineData(2)]
        [InlineData(3)]
        [InlineData(4)]
        [InlineData(6)]
        [InlineData(13)]
        public void Can_create_complete_graph(int N) {
            var graph = Graph.Complete(N);
            Assert.Equal(N, graph.Nodes.Count);
            Assert.Equal(N * (N - 1) / 2, graph.Edges.Count);
            foreach (var node in graph.Nodes)
                Assert.Equal(N - 1, node.Neighbors.Count);
        }
        [Fact]
        public void Complete_graph_requires_at_least_two_nodes() {
            Assert.Throws<ArgumentException>(() => Graph.Complete(1));
        }
        [Fact]
        public void Graph_creators_update_adjacency_matrix() {
            var bipartite = Graph.Bipartite(1, 2);
            Assert.Equal(new Complex[] { 0, 1, 1 }, bipartite.AdjacencyMatrix[0]);
            Assert.Equal(new Complex[] { 1, 0, 0 }, bipartite.AdjacencyMatrix[1]);
            Assert.Equal(new Complex[] { 1, 0, 0 }, bipartite.AdjacencyMatrix[2]);
            var complete = Graph.Complete(3);
            Assert.Equal(new Complex[] { 0, 1, 1 }, complete.AdjacencyMatrix[0]);
            Assert.Equal(new Complex[] { 1, 0, 1 }, complete.AdjacencyMatrix[1]);
            Assert.Equal(new Complex[] { 1, 1, 0 }, complete.AdjacencyMatrix[2]);
            var ring = Graph.Ring(4);
            Assert.Equal(new Complex[] { 0, 1, 0, 1 }, ring.AdjacencyMatrix[0]);
            Assert.Equal(new Complex[] { 1, 0, 1, 0 }, ring.AdjacencyMatrix[1]);
            Assert.Equal(new Complex[] { 0, 1, 0, 1 }, ring.AdjacencyMatrix[2]);
            Assert.Equal(new Complex[] { 1, 0, 1, 0 }, ring.AdjacencyMatrix[3]);
        }
        [Theory]
        [InlineData(2)]
        [InlineData(3)]
        [InlineData(4)]
        [InlineData(6)]
        [InlineData(13)]
        public void Can_create_ring_graph(int N) {
            var graph = Graph.Ring(N);
            Assert.Equal(N, graph.Nodes.Count);
            Assert.Equal(N, graph.Edges.Count);
            foreach (var node in graph.Nodes)
                Assert.Equal(2, node.Neighbors.Count);
        }
        [Fact]
        public void Ring_graph_requires_at_least_two_nodes() {
            Assert.Throws<ArgumentException>(() => Graph.Ring(1));
        }
        [Fact]
        public void Can_be_created_from_edges() {
            var a = new Node("a");
            var b = new Node("b");
            var c = new Node("c");
            var ab = new Edge(a, b);
            var bc = new Edge(b, c);
            var edges = new List<Edge> { ab, bc };
            var graph = new Graph(edges);
            Assert.Equal(3, graph.Nodes.Count);
            Assert.Equal(2, graph.Edges.Count);
            Assert.Equal("a", graph.GetNode(a).Label);
            Assert.Equal("b", graph.GetNode(b).Label);
            Assert.Equal("c", graph.GetNode(c).Label);
            Assert.Single(graph.GetNode(a).Neighbors);
            Assert.Equal(2, graph.GetNode(b).Neighbors.Count);
            Assert.Single(graph.GetNode(c).Neighbors);
        }
        [Fact]
        public void Will_be_assigned_Id_automatically() {
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
            var ab = new Edge(a, b, 2);
            var bc = new Edge(b, c);
            var nodes = new List<Node> { a, b, c };
            var edges = new List<Edge> { ab, bc };
            var graph = new Graph(nodes, edges);
            var adjacencyMatrix = graph.AdjacencyMatrix;
            Assert.Equal(new List<Complex> { 0, 2, 0 }, adjacencyMatrix.Rows[0]);
            Assert.Equal(new List<Complex> { 2, 0, 1 }, adjacencyMatrix.Rows[1]);
            Assert.Equal(new List<Complex> { 0, 1, 0 }, adjacencyMatrix.Rows[2]);
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
            Assert.Equal(new List<Complex> { 0, 1, 0 }, adjacencyMatrix.Rows[0]);
            Assert.Equal(new List<Complex> { 0, 0, 5 }, adjacencyMatrix.Rows[1]);
            Assert.Equal(new List<Complex> { 0, 0, 0 }, adjacencyMatrix.Rows[2]);
        }
        [Fact]
        public void Can_get_nodes() {
            var graph = new Graph();
            var a = new Node("a");
            graph.Add(a);
            Assert.Equal(a, graph.GetNode(a));
            Assert.Equal(a, graph.GetNode(a.Id));
            Assert.Equal(a, graph.GetNode("a"));
        }
        [Fact]
        public void Can_add_nodes_one_at_a_time() {
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
        public void Has_density_property_for_undirected_graphs() {
            var graph = new Graph();
            var a = new Node();
            var b = new Node();
            var c = new Node();
            var ab = new Edge(a, b);
            var bc = new Edge(b, c);
            var ac = new Edge(a, c);
            graph.Add(a, b, c).Add(ab, bc);
            Assert.Equal(3, graph.Nodes.Count);
            Assert.Equal(2, graph.Edges.Count);
            Assert.Equal(0.6666666865348816, graph.Density);
            graph.Add(ac);
            Assert.Equal(3, graph.Edges.Count);
            Assert.Equal(1, graph.Density);
        }
        [Fact]
        public void Has_density_property_for_directed_graphs() {
            var graph = new Graph();
            var a = new Node();
            var b = new Node();
            var c = new Node();
            var ab = new DirectedEdge(a, b);
            var bc = new DirectedEdge(b, c);
            var ac = new DirectedEdge(a, c);
            graph.Add(a, b, c).Add(ab, bc);
            Assert.Equal(3, graph.Nodes.Count);
            Assert.Equal(2, graph.Edges.Count);
            Assert.Equal(0.3333333432674408, graph.Density);
            graph.Add(ac);
            Assert.Equal(3, graph.Edges.Count);
            Assert.Equal(0.5, graph.Density);
        }
        [Fact]
        public void Will_only_add_unique_nodes() {
            var label = "unique";
            var graph = new Graph();
            var a = new Node(label);
            var b = new Node();
            Assert.Empty(graph.Nodes);
            graph.Add(a);
            Assert.Single(graph.Nodes);
            graph.Add(a);
            Assert.Single(graph.Nodes);
            Assert.Equal(label, graph.GetNode(a).Label);
            graph.Add(b);
            Assert.Equal(2, graph.Nodes.Count);
        }
        [Fact]
        public void Can_add_array_of_nodes() {
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
        public void Can_add_list_of_nodes() {
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
        public void Can_add_edges_one_at_a_time() {
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
        public void Will_only_add_unique_edges() {
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
        public void Can_add_array_of_edges() {
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
        public void Can_add_list_of_edges() {
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
        public void Can_add_nodes_and_edges_from_graphs() {
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
        public void Can_update_node_neighbors_when_edges_are_added() {
            var a = new Node();
            var b = new Node();
            var c = new Node();
            var ab = new Edge(a, b);
            var bc = new Edge(b, c);
            var graph = new Graph();
            graph.Add(a, b, c).Add(ab, bc);
            Assert.Equal(3, graph.Nodes.Count);
            Assert.Equal(2, graph.Edges.Count);
            Assert.Single(graph.GetNode(a).Neighbors);
            Assert.Equal(2, graph.GetNode(b).Neighbors.Count);
            Assert.Single(graph.GetNode(c).Neighbors);
        }
        [Fact]
        public void Can_update_node_neighbors_at_creation() {
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
            Assert.Single(graph.GetNode(a).Neighbors);
            Assert.Equal(2, graph.GetNode(b).Neighbors.Count);
            Assert.Single(graph.GetNode(c).Neighbors);
        }
        [Fact]
        public void Can_clear_nodes_and_edges() {
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
        public void Can_remove_nodes_one_at_a_time() {
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
        public void Can_remove_edges_one_at_a_time() {
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
        [Theory]
        [InlineData(2)]
        [InlineData(3)]
        [InlineData(5)]
        [InlineData(10)]
        public void Can_calculate_degree_distribution(int N) {
            var graph = Graph.Complete(N);
            Assert.Equal(new Dictionary<int, int> { { N - 1, N } }, graph.DegreeDistribution());
        }
        [Fact]
        public void Can_calculate_degree_matrix() {
            var graph = Graph.Complete(3);
            Matrix d = graph.DegreeMatrix();
            Assert.Equal(new Complex[] { 2, 0, 0 }, d[0]);
            Assert.Equal(new Complex[] { 0, 2, 0 }, d[1]);
            Assert.Equal(new Complex[] { 0, 0, 2 }, d[2]);
        }
        [Theory]
        [InlineData(2)]
        [InlineData(3)]
        [InlineData(5)]
        [InlineData(10)]
        public void Degree_matrix_is_diagonal(int N) {
            var graph = Graph.Complete(N);
            Assert.True(graph.DegreeMatrix().IsDiagonal());
        }
        [Fact]
        public void Can_calculate_shortest_path_length_between_two_nodes() {
            var graph = Graph.Complete(3);
            var a = graph.Nodes[0];
            var b = graph.Nodes[1];
            var c = graph.Nodes[2];
            Assert.Equal(1, graph.GetShortestPathLength(a, b));
            Assert.Equal(1, graph.GetShortestPathLength(a, c));
            Assert.Equal(1, graph.GetShortestPathLength(b, c));
            graph = Graph.Ring(7);
            a = graph.Nodes[0];
            b = graph.Nodes[3];
            c = graph.Nodes[6];
            Assert.Equal(0, graph.GetShortestPathLength(a, a));
            Assert.Equal(3, graph.GetShortestPathLength(a, b));
            Assert.Equal(1, graph.GetShortestPathLength(a, c));
        }
    }
}