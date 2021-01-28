using System;
using System.Collections.Generic;

namespace Prelude {
    public class Graph {
        public Guid Id;
        public List<Node> Nodes;
        public List<Edge> Edges;
        public Matrix AdjacencyMatrix;
        public Graph() {
            Id = Guid.NewGuid();
        }
        public Graph(List<Node> nodes, List<Edge> edges) {
            Id = Guid.NewGuid();
            Nodes = nodes;
            Edges = edges;
        }
    }
}