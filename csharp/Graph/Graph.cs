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
        public Graph Add(params Node[] nodes) {
            bool Changed = false;
            foreach (var node in nodes) {
                if (!HasNode(node)) {
                    Nodes.Add(node);
                    Changed = true;
                } else {
                    // replace node?
                    throw new NotImplementedException();
                }
            }
            if (Changed) {
                UpdateNodeIndexValues();
                UpdateAdjacencyMatrix();
            }
            return this;
        }
        public Graph Add(List<Node> nodes) {
            throw new NotImplementedException();
        }
        public Graph Add(Edge edge) {
            if (!HasEdge(edge)) {
                Edges.Add(edge);
                var Source = edge.Source;
                var Destination = edge.Destination;
                Source.Neighbors.Add(Destination);
                Destination.Neighbors.Add(Source);
            }
            return this;
        }
        public Graph Add(params Edge[] edges) {
            foreach (var edge in edges) {
                Add(edge);
            }
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
        public bool HasNode(Node a) {
            return false;
        }
        public bool HasEdge(Edge a) {
            return false;
        }
    }
}