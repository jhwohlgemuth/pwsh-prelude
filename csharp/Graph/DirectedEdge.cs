using System;

namespace Prelude {
    public class DirectedEdge : Edge {
        /// <summary>
        /// This is essentially the only difference between the DirectedEdge and Edge classes.
        /// </summary>
        public override bool IsDirected {
            get {
                return true;
            }
        }
        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="source">Direction of edge is from this node</param>
        /// <param name="destination">Direction of edge is to this node</param>
        /// <param name="weight">Edge weight</param>
        public DirectedEdge(Node source, Node destination, double weight = 1) : base(source, destination, weight) {
            Id = Guid.NewGuid();
            Source = source;
            Destination = destination;
            Weight = weight;
        }
    }
}