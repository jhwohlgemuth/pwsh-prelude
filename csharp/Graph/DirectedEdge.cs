using System;

namespace Prelude {
    public class DirectedEdge : Edge {
        public override bool IsDirected {
            get {
                return true;
            }
        }
        public DirectedEdge(Node source, Node destination, double weight = 1) : base(source, destination, weight) {
            Id = Guid.NewGuid();
            Source = source;
            Destination = destination;
            Weight = weight;
        }
    }
}