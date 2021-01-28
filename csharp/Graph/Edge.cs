using System;
using static System.Math;

namespace Prelude {
    public class Edge {
        public Guid Id;
        public Node To;
        public Node From;
        public double Weight = 1;
        public bool IsWeighted {
            get {
                return Abs(Weight) > 0;
            }
        }
        public Edge(Node to, Node from, double weight = 0) {
            Id = Guid.NewGuid();
            To = to;
            From = from;
            Weight = weight;
        }
    }
}