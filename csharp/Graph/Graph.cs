using System;
using System.Collections.Generic;

namespace Prelude {
    public class Graph {
        public Guid Id;
        public List<Node> Nodes = new List<Node> { };
        public List<Edge> Edges = new List<Edge> { };
        public Matrix AdjacencyMatrix {
            get;
            set;
        }
        public Graph() {
            Id = Guid.NewGuid();
        }
        public Graph(List<Node> nodes, List<Edge> edges) {
            Id = Guid.NewGuid();
            Nodes = nodes;
            Edges = edges;
            UpdateNodeIndexValues();
        }
        public static Graph From(Graph other) {
            return new Graph(other.Nodes, other.Edges);
        }
        private void UpdateNodeIndexValues() {
            for (var i = 0; i < Nodes.Count; ++i)
                Nodes[i].Index = i;
        }
        private void UpdateAdjacencyMatrix() {
            var A = new Matrix(Nodes.Count);
            AdjacencyMatrix = A;
        }
        public Graph Add(Graph graph) {
            Add(graph.Nodes);
            Add(graph.Edges);
            return this;
        }
        private bool Add(Node node) {
            Nodes.Add(node);
            return Has(node);
        }
        private bool Add(Edge edge) {
            var source = edge.Source;
            var destination = edge.Destination;
            if (Has(source) && Has(destination)) {
                Edges.Add(edge);
                source.Neighbors.Add(destination);
                destination.Neighbors.Add(source);
            }
            return Has(edge);
        }
        public Graph Add(params Node[] nodes) {
            bool Changed = false;
            foreach (var node in nodes)
                if (!Has(node))
                    Changed = Add(node);
            if (Changed) {
                UpdateNodeIndexValues();
                UpdateAdjacencyMatrix();
            }
            return this;
        }
        public Graph Add(List<Node> nodes) {
            throw new NotImplementedException();
        }
        public Graph Add(params Edge[] edges) {
            bool Changed = false;
            foreach (var edge in edges)
                if (!Has(edge))
                    Changed = Add(edge);
            if (Changed)
                UpdateAdjacencyMatrix();
            return this;
        }
        public Graph Add(List<Edge> edges) {
            throw new NotImplementedException();
        }
        public Graph Clear() {
            Nodes.Clear();
            Edges.Clear();
            return this;
        }
        public bool Has(Node node) {
            return Nodes.Contains(node);
        }
        public bool Has(Edge edge) {
            return Edges.Contains(edge);
        }
    }
}