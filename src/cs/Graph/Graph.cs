using System;

namespace Prelude {
    public class Graph {
        public Guid Id;
        public Edge[] Edges;
        public Graph() {
            Id = Guid.NewGuid();
        }
    }
}