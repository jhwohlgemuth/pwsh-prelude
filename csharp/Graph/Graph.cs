using System;
using System.Collections.Generic;

namespace Prelude {
    public class Graph {
        public Guid Id;
        public List<Node> Nodes = new List<Node> { };
        public List<Edge> Edges = new List<Edge> { };
        private Matrix _AdjacencyMatrix;
        public Matrix AdjacencyMatrix {
            get {
                return _AdjacencyMatrix;
            }
        }
        /// <summary>
        /// Create new graph from input graph object
        /// </summary>
        /// <param name="other">Graph to add nodes and edges from</param>
        /// <returns>Graph</returns>
        public static Graph From(Graph other) {
            return new Graph(other.Nodes, other.Edges);
        }
        /// <summary>
        /// Create empty graph object
        /// </summary>
        public Graph() {
            Id = Guid.NewGuid();
        }
        /// <summary>
        /// Create graph object with nodes and edges
        /// </summary>
        /// <param name="edges">List of edges to be added</param>
        /// <remarks>Nodes will be added from edges</remarks>
        public Graph(List<Edge> edges) {
            Id = Guid.NewGuid();
            foreach (var edge in edges)
                Add(edge.Source, edge.Destination);
            Add(edges);
        }
        /// <summary>
        /// Create graph object with nodes and edges
        /// </summary>
        /// <param name="nodes">List of nodes to be added</param>
        /// <param name="edges">List of edges to be added</param>
        public Graph(List<Node> nodes, List<Edge> edges) {
            Id = Guid.NewGuid();
            Add(nodes);
            Add(edges);
        }
        /// <summary>
        /// Add nodes and edges from an another graph object
        /// </summary>
        /// <param name="graph">Graph to add nodes and edges from</param>
        /// <returns>Graph</returns>
        /// <remarks>This method supports a fluent interface</remarks>
        public Graph Add(Graph graph) {
            Add(graph.Nodes);
            Add(graph.Edges);
            return this;
        }
        private bool Add(Node node) {
            Nodes.Add(node);
            return Contains(node);
        }
        private bool Add(Edge edge) {
            var source = edge.Source;
            var destination = edge.Destination;
            if (Contains(source) && Contains(destination)) {
                Edges.Add(edge);
                source.Neighbors.Add(destination);
                destination.Neighbors.Add(source);
            }
            return Contains(edge);
        }
        /// <summary>
        /// Add node(s) to the graph
        /// </summary>
        /// <example>
        ///     var graph = new Graph();
        ///     var a = new Node();
        ///     var b = new Node();
        ///     var c = new Node();
        ///     $graph.Add(a, b, c);
        /// </example>
        /// <param name="nodes">Node(s) to add to graph</param>
        /// <returns>Graph</returns>
        /// <remarks>This method supports a fluent interface</remarks>
        public Graph Add(params Node[] nodes) {
            AddNodes(nodes);
            return this;
        }
        /// <summary>
        /// Add node(s) to the graph, passed as a list
        /// </summary>
        /// <example>
        ///     var graph = new Graph();
        ///     var a = new Node();
        ///     var b = new Node();
        ///     var c = new Node();
        ///     var nodes = new List<Node> { a, b, c };
        ///     $graph.Add(nodes);
        /// </example>
        /// <param name="nodes">List of nodes to add to graph</param>
        /// <returns>Graph</returns>
        /// <remarks>This method supports a fluent interface</remarks>
        public Graph Add(List<Node> nodes) {
            AddNodes(nodes);
            return this;
        }
        /// <summary>
        /// Add edge(s) to the graph
        /// </summary>
        /// <example>
        ///     var graph = new Graph();
        ///     var a = new Node();
        ///     var b = new Node();
        ///     var c = new Node();
        ///     var ab = new Edge(a, b);
        ///     var bc = new Edge(b, c);
        ///     $graph.Add(ab, bc);
        /// </example>
        /// <param name="edges">Edge(s) to add to graph</param>
        /// <returns>Graph</returns>
        /// <remarks>This method supports a fluent interface</remarks>
        public Graph Add(params Edge[] edges) {
            AddEdges(edges);
            return this;
        }
        /// <summary>
        /// Add edge(s) to the graph, passed as a list
        /// </summary>
        /// <example>
        ///     var graph = new Graph();
        ///     var a = new Node();
        ///     var b = new Node();
        ///     var c = new Node();
        ///     var ab = new Edge(a, b);
        ///     var bc = new Edge(b, c);
        ///     var nodes = new List<Edge> { ab, bc };
        ///     $graph.Add(edges);
        /// </example>
        /// <param name="edges">List of edges to add to graph</param>
        /// <returns>Graph</returns>
        /// <remarks>This method supports a fluent interface</remarks>
        public Graph Add(List<Edge> edges) {
            AddEdges(edges);
            return this;
        }
        private void AddEdges(IEnumerable<Edge> edges) {
            bool Changed = false;
            foreach (var edge in edges)
                if (!Contains(edge))
                    Changed = Add(edge);
            if (Changed)
                UpdateAdjacencyMatrix();
        }
        private void AddNodes(IEnumerable<Node> nodes) {
            bool Changed = false;
            foreach (var node in nodes)
                if (!Contains(node))
                    Changed = Add(node);
            if (Changed) {
                UpdateNodeIndexValues();
                UpdateAdjacencyMatrix();
            }
        }
        /// <summary>
        /// Clear node and edge lists
        /// </summary>
        /// <returns>Graph</returns>
        /// <remarks>This method supports a fluent interface</remarks>
        public Graph Clear() {
            Nodes.Clear();
            Edges.Clear();
            return this;
        }
        /// <summary>
        /// Check if the graph contains the passed node
        /// </summary>
        /// <param name="node">Node to check for</param>
        /// <returns>true or false</returns>
        public bool Contains(Node node) => Nodes.Contains(node);
        /// <summary>
        /// Check if the graph contains the passed edge
        /// </summary>
        /// <param name="edge">Edge to check for</param>
        /// <returns></returns>
        public bool Contains(Edge edge) => Edges.Contains(edge);
        /// <summary>
        /// Get reference to node using node object
        /// </summary>
        /// <param name="node">Node to get</param>
        /// <returns>Node</returns>
        public Node GetNode(Node node) => Nodes.Find(x => x == node);
        /// <summary>
        /// Get reference to node using node ID property
        /// </summary>
        /// <param name="id">ID to use to get node</param>
        /// <returns></returns>
        public Node GetNode(Guid id) => Nodes.Find(x => x.Id == id);
        /// <summary>
        /// Get reference to node using node label
        /// </summary>
        /// <param name="label">Label value to use to get node</param>
        /// <returns></returns>
        public Node GetNode(string label) => Nodes.Find(x => x.Label == label);
        /// <summary>
        /// Remove node from graph
        /// </summary>
        /// <param name="node">Node to remove</param>
        /// <returns>Graph</returns>
        /// <remarks>This method supports a fluent interface</remarks>
        public Graph Remove(Node node) {
            Edges.FindAll(edge => edge.Contains(node)).ForEach(edge => Remove(edge));
            Nodes.Remove(node);
            UpdateNodeIndexValues();
            UpdateAdjacencyMatrix();
            return this;
        }
        /// <summary>
        /// Remove edge from graph
        /// </summary>
        /// <param name="edge">Edge to remove</param>
        /// <returns>Graph</returns>
        /// <remarks>This method supports a fluent interface</remarks>
        public Graph Remove(Edge edge) {
            Node source = edge.Source;
            Node destination = edge.Destination;
            if (Edges.Remove(edge)) {
                if (Nodes.Remove(source))
                    source.Neighbors.Remove(destination);
                if (Nodes.Remove(destination))
                    destination.Neighbors.Remove(source);
            }
            Nodes.Add(source);
            Nodes.Add(destination);
            UpdateAdjacencyMatrix();
            return this;
        }
        private void UpdateAdjacencyMatrix() {
            var A = new Matrix(Nodes.Count);
            foreach (var edge in Edges) {
                var source = edge.Source.Index;
                var destination = edge.Destination.Index;
                var weight = edge.Weight;
                A.Rows[source][destination] = weight;
                if (!edge.IsDirected)
                    A.Rows[destination][source] = weight;
            }
            _AdjacencyMatrix = A;
        }
        private void UpdateNodeIndexValues() {
            for (var i = 0; i < Nodes.Count; ++i)
                Nodes[i].Index = i;
        }
    }
}