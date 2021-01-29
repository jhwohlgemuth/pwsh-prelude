using System;
using static System.Math;

namespace Prelude {
    public class Edge : IComparable<Edge> {
        public Guid Id;
        public Node Source;
        public Node Destination;
        public double Weight = 1;
        public bool IsWeighted {
            get {
                return Abs(Weight) > 0;
            }
        }
        public Edge(Node source, Node destination, double weight = 0) {
            Id = Guid.NewGuid();
            Source = source;
            Destination = destination;
            Weight = weight;
        }
        public int CompareTo(Edge other) {
            if (other != null) {
                var sameSource = Source == other.Source;
                var sameDestination = Destination == other.Destination;
                if (sameSource && sameDestination) {
                    return Weight.CompareTo(other.Weight);
                } else {
                    return -1;
                }
            } else {
                throw new ArgumentException("Parameter is not an Edge");
            }
        }
    }
}