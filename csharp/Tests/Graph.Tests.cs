// <copyright file="Graph.Tests.cs" company="Jason Wohlgemuth">
// Copyright (c) 2022 Jason Wohlgemuth. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
// </copyright>

namespace GraphTests {
    using System;
    using System.Collections.Generic;
    using System.Numerics;
    using Prelude;
    using Xunit;

    public class UnitTests {
        [Theory]
        [InlineData(2, 3)]
        [InlineData(4, 6)]
        [InlineData(7, 5)]
        [InlineData(1, 1)]
        public void Can_create_Bipartite_graph(int m, int n) {
            var graph = Graph.Bipartite(m, n);
            Assert.Equal(m + n, graph.Nodes.Count);
            Assert.Equal(m * n, graph.Edges.Count);
        }

        [Theory]
        [InlineData(2)]
        [InlineData(3)]
        [InlineData(4)]
        [InlineData(6)]
        [InlineData(13)]
        public void Can_create_complete_graph(int n) {
            var graph = Graph.Complete(n);
            Assert.Equal(n, graph.Nodes.Count);
            Assert.Equal(n * (n - 1) / 2, graph.Edges.Count);
            Assert.Equal("node-0", graph.Nodes[0].Label);
            foreach (var node in graph.Nodes)
                Assert.Equal(n - 1, node.Neighbors.Count);
        }

        [Fact]
        public void Complete_graph_requires_at_least_two_nodes() {
            var message = "Complete graph requires at least two nodes";
            var ex = Assert.Throws<ArgumentException>(() => Graph.Complete(1));
            Assert.Equal(message, ex.Message);
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
        public void Can_create_ring_graph(int n) {
            var graph = Graph.Ring(n);
            Assert.Equal(n, graph.Nodes.Count);
            Assert.Equal(n, graph.Edges.Count);
            Assert.Equal("node-0", graph.Nodes[0].Label);
            foreach (var node in graph.Nodes)
                Assert.Equal(2, node.Neighbors.Count);
        }

        [Fact]
        public void Ring_graph_requires_at_least_two_nodes() {
            var message = "Ring graph requires at least two nodes";
            var ex = Assert.Throws<ArgumentException>(() => Graph.Ring(1));
            Assert.Equal(message, ex.Message);
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
        public void Can_get_edges() {
            Graph graph = new();
            Node a = new("a");
            Node b = new("b");
            Node c = new("c");
            var w = 42;
            Edge ab = new(a, b, w);
            Edge bc = new(b, c);
            graph.Add(a, b, c);
            graph.Add(ab, bc);
            Assert.Equal(ab, graph.GetEdge(a, b));
            Assert.Equal(w, graph.GetEdge(a, b).Weight);
            Assert.NotEqual(ab, graph.GetEdge(a, c));
            Assert.Equal(ab, graph.GetEdge(a.Id, b.Id));
            Assert.Equal(ab, graph.GetEdge(a.Label, b.Label));
        }

        [Fact]
        public void Can_get_edge_weight() {
            Graph graph = new();
            Node a = new("a");
            Node b = new("b");
            Node c = new("c");
            Node d = new("d");
            var w = 42;
            Edge ab = new(a, b, w);
            Edge bc = new(b, c);
            graph.Add(a, b, c);
            graph.Add(ab, bc);
            Assert.Equal(w, graph.GetEdgeWeight(a, b));
            var message = "Graph does not contain source and/or target node";
            var ex = Assert.Throws<ArgumentException>(() => graph.GetEdgeWeight(a, d));
            Assert.Equal(message, ex.Message);
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
            var nodeArray = new Node[] { a, b };
            Assert.Empty(graph.Nodes);
            graph.Add(nodeArray);
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
            var nodeList = new List<Node> { a, b };
            graph.Add(nodeList);
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
            Assert.Equal(3, addGraph.Nodes.Count);
            Assert.Equal(3, addGraph.Edges.Count);
        }

        [Fact]
        public void Can_add_nodes_and_edges_from_graphs_using_operator() {
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
            Graph result = addGraph + graph;
            Assert.Equal(3, result.Nodes.Count);
            Assert.Equal(3, result.Edges.Count);
            Assert.Empty(addGraph.Nodes);
            Assert.Empty(addGraph.Edges);
            result = graph + addGraph;
            Assert.Equal(3, result.Nodes.Count);
            Assert.Equal(3, result.Edges.Count);
            Assert.Empty(addGraph.Nodes);
            Assert.Empty(addGraph.Edges);
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
        public void Can_calculate_degree_distribution(int n) {
            var graph = Graph.Complete(n);
            Assert.Equal(new Dictionary<int, int> { { n - 1, n } }, graph.DegreeDistribution());
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
        public void Degree_matrix_is_diagonal(int n) {
            var graph = Graph.Complete(n);
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
            graph = new Graph();
            a = new Node("a");
            b = new Node("b");
            c = new Node("c");
            Node d = new("d");
            Node e = new("e");
            Node f = new("f");
            Node g = new("g");
            Edge ab = new(a, b);
            Edge bc = new(b, c);
            Edge be = new(b, e);
            Edge bg = new(b, g);
            Edge cd = new(c, d);
            Edge ce = new(c, e);
            Edge df = new(d, f);
            Edge gf = new(g, f);
            graph.Add(a, b, c, d, e, f, g);
            graph.Add(ab, bc, be, bg, cd, ce, df, gf);
            Assert.Equal(3, graph.GetShortestPathLength(a, f));
            Assert.Equal(3, graph.GetShortestPathLength(f, a));
            Assert.Equal(2, graph.GetShortestPathLength(e, a));
            Assert.Equal(2, graph.GetShortestPathLength(d, g));
            Assert.Equal(1, graph.GetShortestPathLength(c, e));
            Assert.Equal(3, graph.GetShortestPathLength("a", "f"));
            Assert.Equal(3, graph.GetShortestPathLength("f", "a"));
            Assert.Equal(2, graph.GetShortestPathLength("e", "a"));
            Assert.Equal(2, graph.GetShortestPathLength("d", "g"));
            Assert.Equal(1, graph.GetShortestPathLength("c", "e"));
            graph.Remove(g);
            Assert.Equal(4, graph.GetShortestPathLength(a, f));
        }

        [Fact]
        public void Can_calculate_the_shortest_path_using_Dijkstra_algorithm() {
            var graph = Graph.Complete(3);
            Node x = graph.Nodes[0];
            Node y = graph.Nodes[1];
            Node z = graph.Nodes[2];
            Assert.Equal(new List<Node> { x, y }, graph.GetShortestPath(x, y));
            Assert.Equal(new List<Node> { x, z }, graph.GetShortestPath(x, z));
            graph = new Graph();
            Node a = new("a");
            Node b = new("b");
            Node c = new("c");
            Node d = new("d");
            Node e = new("e");
            Node f = new("f");
            Node g = new("g");
            Edge ab = new(a, b);
            Edge bc = new(b, c);
            Edge be = new(b, e);
            Edge bg = new(b, g);
            Edge cd = new(c, d);
            Edge ce = new(c, e);
            Edge df = new(d, f);
            Edge gf = new(g, f);
            graph.Add(a, b, c, d, e, f, g);
            graph.Add(ab, bc, be, bg, cd, ce, df, gf);
            Assert.Equal(new List<Node> { a, b, g }, graph.GetShortestPath(a, g));
            Assert.Equal(new List<Node> { e, b, g, f }, graph.GetShortestPath(e, f));
            Assert.Equal(new List<Node> { a, b, g }, graph.GetShortestPath("a", "g"));
            Assert.Equal(new List<Node> { e, b, g, f }, graph.GetShortestPath("e", "f"));
            graph.Remove(g);
            Assert.Equal(new List<Node> { e, c, d, f }, graph.GetShortestPath(e, f));
        }
    }
}