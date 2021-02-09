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
        public static Graph From(Graph other) {
            return new Graph(other.Nodes, other.Edges);
        }
        public Graph() {
            Id = Guid.NewGuid();
        }
        public Graph(List<Node> nodes, List<Edge> edges) {
            Id = Guid.NewGuid();
            Add(nodes);
            Add(edges);
            UpdateNodeIndexValues();
            UpdateAdjacencyMatrix();
        }
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
        public Graph Add(params Node[] nodes) {
            AddNodes(nodes);
            return this;
        }
        public Graph Add(List<Node> nodes) {
            AddNodes(nodes);
            return this;
        }
        public Graph Add(params Edge[] edges) {
            AddEdges(edges);
            return this;
        }
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
        public Graph Clear() {
            Nodes.Clear();
            Edges.Clear();
            return this;
        }
        public bool Contains(Node node) {
            return Nodes.Contains(node);
        }
        public bool Contains(Edge edge) {
            return Edges.Contains(edge);
        }
        public Node GetNode(Node node) {
            return Nodes.Find(x => x == node);
        }
        public Node GetNode(Guid id) {
            return Nodes.Find(x => x.Id == id);
        }
        public Node GetNode(string label) {
            return Nodes.Find(x => x.Label == label);
        }
        public Graph Remove(Node node) {
            Edges.FindAll(edge => edge.Contains(node)).ForEach(edge => Remove(edge));
            Nodes.Remove(node);
            UpdateNodeIndexValues();
            UpdateAdjacencyMatrix();
            return this;
        }
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