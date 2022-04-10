// <copyright file="Graph.cs" company="Jason Wohlgemuth">
// Copyright (c) 2022 Jason Wohlgemuth. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
// </copyright>

namespace Prelude {
    using System;
    using System.Collections.Generic;
    using static System.Linq.Enumerable;

    /// <summary>
    /// Represents a graph.
    /// </summary>
    public class Graph {
        private int[] pathData = Array.Empty<int>();
        private Node pathSourceNode = new();
        private Matrix adjacencyMatrix;

        /// <summary>
        /// Initializes a new instance of the <see cref="Graph"/> class.
        /// </summary>
        public Graph() {
            Id = Guid.NewGuid();
            Nodes = new List<Node> { };
            Edges = new List<Edge> { };
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="Graph"/> class.
        /// </summary>
        /// <param name="edges">List of edges to be added.</param>
        /// <remarks>
        /// Nodes will be added from edges.
        /// </remarks>
        public Graph(List<Edge> edges) {
            Id = Guid.NewGuid();
            Nodes = new List<Node> { };
            Edges = new List<Edge> { };
            foreach (var edge in edges)
                Add(edge.Source, edge.Target);
            Add(edges);
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="Graph"/> class.
        /// </summary>
        /// <param name="nodes">List of nodes to be added.</param>
        /// <param name="edges">List of edges to be added.</param>
        public Graph(List<Node> nodes, List<Edge> edges) {
            Id = Guid.NewGuid();
            Nodes = new List<Node> { };
            Edges = new List<Edge> { };
            Add(nodes);
            Add(edges);
        }

        /// <summary>
        /// Gets the identifier of the graph.
        /// </summary>
        public Guid Id {
            get;
        }

        /// <summary>
        /// Gets or sets the list of nodes.
        /// </summary>
        public List<Node> Nodes {
            get;
            set;
        }

        /// <summary>
        /// Gets or sets the list of edges.
        /// </summary>
        public List<Edge> Edges {
            get;
            set;
        }

        /// <summary>
        /// Gets the adjacency matrix.
        /// </summary>
        public Matrix AdjacencyMatrix => adjacencyMatrix;

        /// <summary>
        /// Gets the graph density.
        /// </summary>
        public float Density {
            get {
                var multiplier = Edges.Exists(e => e.IsDirected) ? 1 : 2;
                return multiplier * (float)Edges.Count / (Nodes.Count * (Nodes.Count - 1));
            }
        }

        /// <summary>
        /// Create new graph from input graph object.
        /// </summary>
        /// <param name="other">Graph to add nodes and edges from.</param>
        /// <returns>New graph from other graph.</returns>
        public static Graph From(Graph other) {
            return new Graph(other.Nodes, other.Edges);
        }

        /// <summary>
        /// Create a k-Partite graph with k = 2 where every node on the "left" is connected to every node on the "right", via an edge.
        /// </summary>
        /// <param name="m">Number of nodes in "left" sub-graph.</param>
        /// <param name="n">Number of nodes in "right" sub-graph.</param>
        /// <returns>Bipartite graph with (m + n) nodes.</returns>
        public static Graph Bipartite(int m, int n) {
            var left = Range(0, m).Select(i => new Node($"left-{i}")).ToList();
            var right = Range(0, n).Select(i => new Node($"right-{i}")).ToList();
            var graph = new Graph();
            graph.Add(left).Add(right);
            foreach (var a in left)
                foreach (var b in right)
                    graph.Add(new Edge(a, b));
            return graph;
        }

        /// <summary>
        /// Create a graph with N nodes where each node is connected to every other node via an edge.
        /// </summary>
        /// <param name="n">Number of nodes.</param>
        /// <returns>Complete graph with n nodes.</returns>
        /// <remarks>
        /// A complete graph with N nodes will have N * (N - 1) / 2 edges.
        /// </remarks>
        public static Graph Complete(int n) {
            if (n < 2)
                throw new ArgumentException("Complete graph requires at least two nodes");
            var nodes = Range(0, n).Select(i => new Node($"node-{i}")).ToList();
            var edges = new List<Edge> { };
            var graph = new Graph(nodes, edges);
            foreach (var a in nodes)
                foreach (var b in nodes) {
                    var ab = new Edge(a, b);
                    if (a != b && !graph.Edges.Exists(x => x.Contains(a) && x.Contains(b)))
                        graph.Add(ab);
                }

            return graph;
        }

        /// <summary>
        /// Create a ring graph where for a graph with N nodes, every node has degree 2 and there are N edges.
        /// </summary>
        /// <param name="n">Number of nodes.</param>
        /// <returns>Ring graph with n nodes.</returns>
        public static Graph Ring(int n) {
            if (n < 2)
                throw new ArgumentException("Ring graph requires at least two nodes");
            var nodes = Range(0, n).Select(x => new Node($"node-{x}")).ToList();
            var edges = new List<Edge> { };
            for (var i = 0; i < n; ++i)
                edges.Add(new Edge(nodes[i], nodes[(i + 1) % n]));
            return new Graph(nodes, edges);
        }

        /// <summary>
        /// Create a small world graph.
        /// </summary>
        /// <param name="n">Number of nodes.</param>
        /// <param name="k">Parameter controlling probability of connections within the graph.</param>
        /// <returns>Small world graph.</returns>
        public static Graph SmallWorld(int n, double k) {
            throw new NotImplementedException();
        }

        /// <summary>
        /// Add nodes and edges from an another graph object.
        /// </summary>
        /// <param name="graph">Graph to add nodes and edges from.</param>
        /// <returns>Graph to which nodes and edges were added to.</returns>
        /// <remarks>
        /// This method supports a fluent interface.
        /// </remarks>
        public Graph Add(Graph graph) {
            Add(graph.Nodes);
            Add(graph.Edges);
            return this;
        }

        /// <summary>
        /// Add node(s) to the graph, passed as function parameters.
        /// </summary>
        /// <param name="nodes">Node(s) to add to graph.</param>
        /// <returns>Graph to which node(s) were added.</returns>
        /// <remarks>
        /// This method supports a fluent interface.
        /// </remarks>
        public Graph Add(params Node[] nodes) {
            AddNodes(nodes);
            return this;
        }

        /// <summary>
        /// Add node(s) to the graph, passed as a list.
        /// </summary>
        /// <param name="nodes">List of nodes to add to the graph.</param>
        /// <returns>Graph to which node(s) were added.</returns>
        /// <remarks>
        /// This method supports a fluent interface.
        /// </remarks>
        public Graph Add(List<Node> nodes) {
            AddNodes(nodes);
            return this;
        }

        /// <summary>
        /// Add edge(s) to the graph, passed as function parameters.
        /// </summary>
        /// <param name="edges">Edge(s) to add to graph.</param>
        /// <returns>Graph to which edge(s) were added.</returns>
        /// <remarks>
        /// This method supports a fluent interface.
        /// </remarks>
        public Graph Add(params Edge[] edges) {
            AddEdges(edges);
            return this;
        }

        /// <summary>
        /// Add edge(s) to the graph, passed as a list.
        /// </summary>
        /// <param name="edges">List of edges to add to the graph.</param>
        /// <returns>Graph to which the edges were added.</returns>
        /// <remarks>
        /// This method supports a fluent interface.
        /// </remarks>
        public Graph Add(List<Edge> edges) {
            AddEdges(edges);
            return this;
        }

        /// <summary>
        /// Clear node and edge lists.
        /// </summary>
        /// <returns>Graph with empty node and edge lists.</returns>
        /// <remarks>
        /// This method supports a fluent interface.
        /// </remarks>
        public Graph Clear() {
            Nodes.Clear();
            Edges.Clear();
            return ResetGraphData();
        }

        /// <summary>
        /// Check if the graph contains the passed node.
        /// </summary>
        /// <param name="node">Node to check for.</param>
        /// <returns>True if the graph contains the node, false otherwise.</returns>
        public bool Contains(Node node) => Nodes.Contains(node);

        /// <summary>
        /// Check if the graph contains the passed edge.
        /// </summary>
        /// <param name="edge">Edge to check for.</param>
        /// <returns>True if the graph contains the edge, false otherwise.</returns>
        public bool Contains(Edge edge) => Edges.Contains(edge);

        /// <summary>
        /// Calculate degree distribution dictionary for the graph.
        /// </summary>
        /// <returns>Degree distribution as a dictionary.</returns>
        public Dictionary<int, int> DegreeDistribution() {
            return Nodes
                .GroupBy(x => x.Degree, (deg, n) => new int[] { deg, n.Count() })
                .ToDictionary(x => x[0], x => x[1]);
        }

        /// <summary>
        /// Return diagonal matrix of degree values of the graph.
        /// </summary>
        /// <returns>Degree values as a diagonal <see cref="Matrix"/>.</returns>
        public Matrix DegreeMatrix() {
            var temp = Matrix.Fill(new Matrix(Nodes.Count), 0);
            for (var i = 0; i < Nodes.Count; ++i)
                temp[i][i] = Nodes[i].Degree;
            return temp;
        }

        /// <summary>
        /// Get reference to edge within the graph using passed source and target nodes.
        /// </summary>
        /// <param name="source">Source node.</param>
        /// <param name="target">Target node.</param>
        /// <returns>Graph edge with source and target nodes values.</returns>
        public Edge GetEdge(Node source, Node target) => Edges.Find(e => e.Source == source && e.Target == target);

        /// <summary>
        /// Get reference to edge within the graph using passed source and target node IDs.
        /// </summary>
        /// <param name="sourceId">Source node ID.</param>
        /// <param name="targetId">Target node ID.</param>
        /// <returns>Graph edge with source and target nodes with passed IDs.</returns>
        public Edge GetEdge(Guid sourceId, Guid targetId) => GetEdge(GetNode(sourceId), GetNode(targetId));

        /// <summary>
        /// Get reference to edge within the graph using passed source and target node string labels.
        /// </summary>
        /// <param name="sourceLabel">Source node label.</param>
        /// <param name="targetLabel">Target node label.</param>
        /// <returns>Graph edge with source and target nodes with passed labels.</returns>
        public Edge GetEdge(string sourceLabel, string targetLabel) => GetEdge(GetNode(sourceLabel), GetNode(targetLabel));

        /// <summary>
        /// Get weight of edge given the associated edge's source and target nodes.
        /// </summary>
        /// <param name="source">Source node.</param>
        /// <param name="target">Target node.</param>
        /// <returns>Weight of edge with associated source and target nodes.</returns>
        public double GetEdgeWeight(Node source, Node target) {
            if (Contains(source) && Contains(target))
                return AdjacencyMatrix[source.Index][target.Index].Real;
            else
                throw new ArgumentException("Graph does not contain source and/or target node");
        }

        /// <summary>
        /// Get reference to a node within the graph using a <see cref="Node"/> value.
        /// </summary>
        /// <param name="node">Node to get.</param>
        /// <returns>Node with the passed ID.</returns>
        public Node GetNode(Node node) => Nodes.Find(x => x == node);

        /// <summary>
        /// Get reference to a node using an ID.
        /// </summary>
        /// <param name="id">ID of desired node.</param>
        /// <returns>Node with the passed ID.</returns>
        public Node GetNode(Guid id) => Nodes.Find(x => x.Id == id);

        /// <summary>
        /// Get reference to a node using a label.
        /// </summary>
        /// <param name="label">Label value of desired node.</param>
        /// <returns>Node with the passed label.</returns>
        public Node GetNode(string label) => Nodes.Find(x => x.Label == label);

        /// <summary>
        /// Calculate shortest path between two nodes of the graph.
        /// </summary>
        /// <param name="source">Starting node.</param>
        /// <param name="target">Ending node.</param>
        /// <param name="update">Whether or not to force re-calculate path data using <see cref="Dijkstra"/>.</param>
        /// <returns>List of nodes that comprise the shortest path within the graph.</returns>
        /// <remarks>
        /// This function uses Dijkstra's shortest path algorithm.
        /// </remarks>
        public List<Node> GetShortestPath(Node source, Node target, bool update = false) {
            if (update || (pathSourceNode != source))
                pathData = Dijkstra(source);
            var shortestPath = new List<Node> { };
            var cost = 0.0;
            var temp = target;
            while (pathData[temp.Index] != -1) {
                shortestPath.Add(temp);
                if (temp != source) {
                    foreach (var v in temp.Neighbors) {
                        if (v.Index == pathData[temp.Index]) {
                            cost += GetEdgeWeight(temp, v);
                            break;
                        }
                    }
                }

                temp = Nodes[pathData[temp.Index]];
            }

            shortestPath.Add(source);
            shortestPath.Reverse();
            return shortestPath;
        }

        /// <summary>
        /// Calculate shortest path between two nodes of the graph.
        /// </summary>
        /// <param name="source">String label of source node.</param>
        /// <param name="target">String label of target node.</param>
        /// <param name="update">Flag to force update of path data.</param>
        /// <returns>List of nodes that comprise the shortest path within the graph.</returns>
        public List<Node> GetShortestPath(string source, string target, bool update = false) => GetShortestPath(GetNode(source), GetNode(target), update);

        /// <summary>
        /// Calculate length of shortest path between two nodes of the graph.
        /// </summary>
        /// <param name="source">Source node of the path within the graph.</param>
        /// <param name="target">Target node of the path within the graph.</param>
        /// <returns>Number value equal to sum of weights of every edge in shortest path.</returns>
        public double GetShortestPathLength(Node source, Node target) {
            var edge = GetEdge(source, target);
            if (Contains(edge))
                return 1;
            else
                return GetShortestPath(source, target).Count - 1;
        }

        /// <summary>
        /// Calculate length of shortest path between two nodes of the graph.
        /// </summary>
        /// <param name="source">String label of the source node.</param>
        /// <param name="target">String label of the target node.</param>
        /// <returns>Number value equal to sum of weights of every edge in shortest path.</returns>
        public double GetShortestPathLength(string source, string target) => GetShortestPathLength(GetNode(source), GetNode(target));

        /// <summary>
        /// Remove node from graph.
        /// </summary>
        /// <param name="node">Node to remove.</param>
        /// <returns>Graph which called Remove.</returns>
        /// <remarks>
        /// This method supports a fluent interface.
        /// </remarks>
        public Graph Remove(Node node) {
            Edges.FindAll(edge => edge.Contains(node)).ForEach(edge => Remove(edge));
            Nodes.Remove(node);
            UpdateNodeIndexValues();
            UpdateAdjacencyMatrix();
            ResetGraphData();
            return this;
        }

        /// <summary>
        /// Remove edge from the graph.
        /// </summary>
        /// <param name="edge">Edge to remove.</param>
        /// <returns>Graph which called Remove.</returns>
        /// <remarks>
        /// This method supports a fluent interface.
        /// </remarks>
        public Graph Remove(Edge edge) {
            Node source = edge.Source;
            Node target = edge.Target;
            if (Edges.Remove(edge)) {
                if (Nodes.Remove(source))
                    source.Neighbors.Remove(target);
                if (Nodes.Remove(target))
                    target.Neighbors.Remove(source);
            }

            Nodes.Add(source);
            Nodes.Add(target);
            UpdateAdjacencyMatrix();
            ResetGraphData();
            return this;
        }

        private bool Add(Node node) {
            if (!Contains(node)) {
                Nodes.Add(node);
                ResetGraphData();
            }

            return Contains(node);
        }

        private bool Add(Edge edge) {
            var source = edge.Source;
            var target = edge.Target;
            if (Contains(source) && Contains(target)) {
                Edges.Add(edge);
                source.Neighbors.Add(target);
                target.Neighbors.Add(source);
                UpdateAdjacencyMatrix();
                ResetGraphData();
            }

            return Contains(edge);
        }

        private void AddEdges(IEnumerable<Edge> edges) {
            bool changed = false;
            foreach (var edge in edges)
                if (!Contains(edge))
                    changed = Add(edge);
            if (changed) {
                UpdateAdjacencyMatrix();
                ResetGraphData();
            }
        }

        private void AddNodes(IEnumerable<Node> nodes) {
            bool changed = false;
            foreach (var node in nodes)
                if (!Contains(node))
                    changed = Add(node);
            if (changed) {
                UpdateNodeIndexValues();
                UpdateAdjacencyMatrix();
                ResetGraphData();
            }
        }

        /// <summary>
        /// Use Dijkstra shortest path algorithm to generate shortest path.
        /// </summary>
        /// <param name="source">Starting node.</param>
        /// <returns>Integer array of node indices.</returns>
        private int[] Dijkstra(Node source) {
            var pathIndex = Range(0, Nodes.Count).Select(i => -1).ToArray();
            var distance = new double[Nodes.Count];
            distance[source.Index] = 0;
            var q = new PriorityQueue();
            q.Insert(0, source);
            foreach (var u in Nodes) {
                if (u != source) {
                    pathIndex[u.Index] = -1;
                    distance[u.Index] = double.MaxValue;
                }
            }

            while (!q.IsEmpty()) {
                var u = q.ExtractMinimum();
                foreach (Node v in u.Neighbors) {
                    var w = GetEdgeWeight(u, v);
                    var updatedDistance = distance[u.Index] + w;
                    if (distance[v.Index] > updatedDistance) {
                        if (distance[v.Index] == double.MaxValue)
                            q.Insert(updatedDistance, v);
                        else
                            q.DecreaseKey(v, updatedDistance);
                        distance[v.Index] = updatedDistance;
                        pathIndex[v.Index] = u.Index;
                    }
                }
            }

            return pathIndex;
        }

        private Graph ResetGraphData() {
            pathData = Array.Empty<int>();
            pathSourceNode = new Node();
            return this;
        }

        private void UpdateAdjacencyMatrix() {
            var m = new Matrix(Nodes.Count);
            foreach (var edge in Edges) {
                var source = edge.Source.Index;
                var target = edge.Target.Index;
                var weight = edge.Weight;
                m.Rows[source][target] = weight;
                if (!edge.IsDirected)
                    m.Rows[target][source] = weight;
            }

            adjacencyMatrix = m;
        }

        private void UpdateNodeIndexValues() {
            for (var i = 0; i < Nodes.Count; ++i)
                Nodes[i].Index = i;
        }
    }
}